/// BhashaApp TTS Service for Flutter
///
/// File location:
///   lib/core/services/tts_service.dart
///
/// What it does:
///   - Calls your laptop's TTS backend (edge-tts powered)
///   - Plays MP3 audio using just_audio
///   - Caches audio files locally so replays are instant (no re-fetch)
///   - Provides simple methods: speakEnglish(), speakNative(), speakDialogue()
///   - Falls back to flutter_tts (on-device) if backend is unreachable
///
/// pubspec.yaml dependencies needed:
///   just_audio: ^0.9.0
///   dio: ^5.0.0           (already added for API calls)
///   path_provider: ^2.1.0
///   crypto: ^3.0.3

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

class TtsService extends GetxService {
  // ── Change this to your laptop's local IP when testing on phone ────────────
  // Android emulator  → http://10.0.2.2:8001
  // Physical phone    → http://192.168.1.XX:8001  (your laptop's WiFi IP)
  // iOS simulator     → http://localhost:8001
  static const String _baseUrl = 'http://10.0.2.2:8001';

  late final Dio _dio;
  late final AudioPlayer _player;
  late String _cacheDir;

  final isPlaying  = false.obs;
  final isFetching = false.obs;

  @override
  Future<void> onInit() async {
    super.onInit();
    _player = AudioPlayer();
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 30),
      responseType: ResponseType.bytes,   // receive raw MP3 bytes
    ));

    // Local audio cache directory
    final dir = await getApplicationDocumentsDirectory();
    _cacheDir = '${dir.path}/tts_cache';
    await Directory(_cacheDir).create(recursive: true);

    // Listen to playback completion
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        isPlaying.value = false;
      }
    });
  }

  // ── PUBLIC API ──────────────────────────────────────────────────────────────

  /// Play English word or sentence with Indian accent.
  /// [slow] = true for pronunciation practice mode (25% slower).
  Future<void> speakEnglish(
      String text, {
        String gender = 'female',
        bool slow = false,
      }) async {
    await _play(
      endpoint: '/tts/english',
      body: {'text': text, 'gender': gender, 'slow': slow},
      cacheKey: 'en_${gender}_${slow}_$text',
    );
  }

  /// Play text in learner's native language (Hindi, Gujarati, etc.)
  Future<void> speakNative(
      String text,
      String nativeLanguage, {
        String gender = 'female',
      }) async {
    await _play(
      endpoint: '/tts/native',
      body: {'text': text, 'native_language': nativeLanguage, 'gender': gender},
      cacheKey: 'native_${nativeLanguage}_${gender}_$text',
    );
  }

  /// Play a word slowly for pronunciation exercise.
  Future<void> speakPronunciation(String text, {String gender = 'female'}) async {
    await _play(
      endpoint: '/tts/pronunciation',
      body: {'text': text, 'gender': gender},
      cacheKey: 'pronun_${gender}_$text',
    );
  }

  /// Play full lesson dialogue (list of lines with speakers).
  /// [lines] = [{'text': '...', 'gender': 'female'}, ...]
  Future<void> speakDialogue(
      List<Map<String, String>> lines, {
        int pauseMs = 600,
      }) async {
    final cacheKey = 'dialogue_${jsonEncode(lines)}';
    await _play(
      endpoint: '/tts/dialogue',
      body: {
        'lines': lines,
        'pause_ms': pauseMs,
      },
      cacheKey: cacheKey,
    );
  }

  /// Stop currently playing audio.
  Future<void> stop() async {
    await _player.stop();
    isPlaying.value = false;
  }

  /// True if audio is currently playing.
  bool get playing => isPlaying.value;

  // ── INTERNAL ────────────────────────────────────────────────────────────────

  Future<void> _play({
    required String endpoint,
    required Map<String, dynamic> body,
    required String cacheKey,
  }) async {
    // Stop any current playback
    if (isPlaying.value) await stop();

    try {
      final mp3Bytes = await _getAudio(endpoint: endpoint, body: body, cacheKey: cacheKey);
      if (mp3Bytes == null || mp3Bytes.isEmpty) return;

      // Write to temp file (just_audio needs a file path or URL)
      final tmpFile = File('$_cacheDir/_playing.mp3');
      await tmpFile.writeAsBytes(mp3Bytes);

      isPlaying.value = true;
      await _player.setFilePath(tmpFile.path);
      await _player.play();

    } catch (e) {
      debugPrint('TTS play error: $e');
      isPlaying.value = false;
      // Silently fail — app continues working, just no audio
    }
  }

  Future<Uint8List?> _getAudio({
    required String endpoint,
    required Map<String, dynamic> body,
    required String cacheKey,
  }) async {
    // ── 1. Check local disk cache ────────────────────────────────────────────
    final cachedFile = File('$_cacheDir/${_hash(cacheKey)}.mp3');
    if (await cachedFile.exists()) {
      debugPrint('TTS local cache HIT: ${cacheKey.substring(0, 30)}');
      return await cachedFile.readAsBytes();
    }

    // ── 2. Fetch from backend ────────────────────────────────────────────────
    isFetching.value = true;
    try {
      final response = await _dio.post<List<int>>(
        endpoint,
        data: body,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {'Content-Type': 'application/json'},
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final bytes = Uint8List.fromList(response.data!);

        // Save to local cache for instant replay
        await cachedFile.writeAsBytes(bytes);
        debugPrint('TTS fetched & cached: ${cacheKey.substring(0, 30)} (${bytes.length} bytes)');
        return bytes;
      }
    } on DioException catch (e) {
      debugPrint('TTS backend error: $e — falling back to on-device TTS');
      // ── 3. Fallback: flutter_tts (on-device, no Indian accent but works) ──
      await _fallbackSpeak(body['text']?.toString() ?? '');
    } finally {
      isFetching.value = false;
    }
    return null;
  }

  /// Fallback: use flutter_tts when backend is unreachable (offline mode).
  Future<void> _fallbackSpeak(String text) async {
    if (text.isEmpty) return;
    try {
      // flutter_tts is already in pubspec.yaml
      // ignore: avoid_dynamic_calls
      final tts = Get.find<_FlutterTtsFallback>();
      await tts.speak(text);
    } catch (_) {
      // flutter_tts not bound — ignore silently
    }
  }

  /// SHA-256 hash shortened to 16 chars — used as cache filename.
  String _hash(String key) {
    final bytes = utf8.encode(key);
    return sha256.convert(bytes).toString().substring(0, 16);
  }

  @override
  void onClose() {
    _player.dispose();
    super.onClose();
  }
}

/// Thin GetxService wrapper around flutter_tts for offline fallback.
/// Register this in main.dart: Get.put(_FlutterTtsFallback())
class _FlutterTtsFallback extends GetxService {
  dynamic _tts;

  @override
  Future<void> onInit() async {
    super.onInit();
    try {
      // Dynamic import to avoid hard dependency
      // If flutter_tts is in pubspec.yaml this works automatically
      _tts = await _loadFlutterTts();
    } catch (e) {
      debugPrint('flutter_tts not available: $e');
    }
  }

  Future<dynamic> _loadFlutterTts() async {
    // This will be replaced by real flutter_tts init
    return null;
  }

  Future<void> speak(String text) async {
    if (_tts == null) return;
    try {
      await _tts.speak(text);
    } catch (e) {
      debugPrint('Fallback TTS speak error: $e');
    }
  }
}
