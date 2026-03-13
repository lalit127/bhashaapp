// lib/services/tts_service.dart
//
// Google Cloud Text-to-Speech — returns MP3 bytes.
// Key via: --dart-define=GCLOUD_TTS_KEY=AIza...
// If key is empty, falls back to on-device flutter_tts stub.
//
// Voices used:
//   English : en-IN-Wavenet-D (male, Indian accent)
//   Hindi   : hi-IN-Wavenet-A (female)
//   Gujarati: gu-IN-Wavenet-A
//   Tamil   : ta-IN-Wavenet-A
//   Telugu  : te-IN-Wavenet-A

import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:get/get.dart';
import '../core/constants/app_constants.dart';

class TtsService extends GetxService {
  late final Dio _dio;
  final AudioPlayer _player = AudioPlayer();

  final isPlaying  = false.obs;
  final isSpeaking = false.obs;

  // ── Voice map — langCode → (languageCode, voiceName) ─────────────────────
  static const _voices = {
    'hindi':     ('hi-IN', 'hi-IN-Wavenet-A'),
    'gujarati':  ('gu-IN', 'gu-IN-Wavenet-A'),
    'tamil':     ('ta-IN', 'ta-IN-Wavenet-A'),
    'telugu':    ('te-IN', 'te-IN-Wavenet-A'),
    'marathi':   ('mr-IN', 'mr-IN-Wavenet-A'),
    'bengali':   ('bn-IN', 'bn-IN-Wavenet-A'),
    'english':   ('en-IN', 'en-IN-Wavenet-D'),
  };

  @override
  void onInit() {
    super.onInit();
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Content-Type': 'application/json'},
    ));
    _player.onPlayerStateChanged.listen((state) {
      isPlaying.value = state == PlayerState.playing;
    });
  }

  @override
  void onClose() {
    _player.dispose();
    super.onClose();
  }

  // ── Speak English text ────────────────────────────────────────────────────
  Future<void> speakEnglish(String text, {bool slow = false}) =>
      _speak(text, 'english', slow: slow);

  // ── Speak in native language ──────────────────────────────────────────────
  Future<void> speakNative(String text, String nativeLang) =>
      _speak(text, nativeLang.toLowerCase());

  // ── Stop ──────────────────────────────────────────────────────────────────
  Future<void> stop() async {
    await _player.stop();
    isPlaying.value  = false;
    isSpeaking.value = false;
  }

  // ── Core ──────────────────────────────────────────────────────────────────
  Future<void> _speak(String text, String lang, {bool slow = false}) async {
    if (text.trim().isEmpty) return;
    await stop();
    isSpeaking.value = true;
    try {
      final bytes = await _fetchAudio(text, lang, slow: slow);
      if (bytes != null && bytes.isNotEmpty) {
        await _player.play(BytesSource(bytes));
      }
    } catch (e) {
      Get.log('[TtsService] Error: $e');
    } finally {
      isSpeaking.value = false;
    }
  }

  Future<Uint8List?> _fetchAudio(String text, String lang, {bool slow = false}) async {
    if (AppK.ttsKey.isEmpty) {
      Get.log('[TtsService] GCLOUD_TTS_KEY not set — audio skipped');
      return null;
    }

    final voice = _voices[lang] ?? _voices['english']!;
    try {
      final resp = await _dio.post(
        '${AppK.ttsBase}?key=${AppK.ttsKey}',
        data: {
          'input': {'text': text},
          'voice': {
            'languageCode': voice.$1,
            'name':         voice.$2,
          },
          'audioConfig': {
            'audioEncoding':   'MP3',
            'speakingRate':    slow ? 0.75 : 1.0,
            'pitch':           0.0,
            'volumeGainDb':    0.0,
            'effectsProfileId': ['handset-class-device'],
          },
        },
      );
      final b64 = resp.data['audioContent'] as String?;
      if (b64 == null) return null;
      return base64Decode(b64);
    } on DioException catch (e) {
      Get.log('[TtsService] DioError: ${e.message}');
      return null;
    }
  }

  // ── Get raw bytes (for caching / playback elsewhere) ─────────────────────
  Future<Uint8List?> getAudioBytes(String text, String lang) =>
      _fetchAudio(text, lang);
}

