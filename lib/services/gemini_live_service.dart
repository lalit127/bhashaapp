// lib/services/gemini_live_service.dart
//
// Gemini Live API — bidirectional WebSocket voice conversation.
// Flow:
//   1. connect()  → sends setup message with system prompt
//   2. startRecording() → streams 16kHz PCM mic audio to Gemini
//   3. Gemini replies with audio chunks → decoded + played via audioplayers
//   4. stopRecording() → sends end-of-turn signal
//   5. disconnect() → closes socket
//
// Audio pipeline:
//   Mic → record package (PCM 16kHz mono) → base64 → WebSocket
//   WebSocket → base64 PCM → just_audio BytesSource → speaker

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:get/get.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/constants/app_constants.dart';

// ── Call state ────────────────────────────────────────────────────────────────
enum CallState { idle, connecting, connected, listening, aiSpeaking, error }

class GeminiLiveService extends GetxService {
  WebSocketChannel?    _ws;
  final AudioRecorder  _recorder  = AudioRecorder();
  final AudioPlayer    _player    = AudioPlayer();

  // ── Observables (bind to UI) ──────────────────────────────────────────────
  final callState    = CallState.idle.obs;
  final transcript   = ''.obs;       // running STT from Gemini
  final aiReply      = ''.obs;       // running AI text reply
  final sessionScore = 0.obs;        // 0-100
  final errorMsg     = RxnString();

  // ── Internal state ────────────────────────────────────────────────────────
  bool   _setupComplete  = false;
  bool   _isRecording    = false;
  StreamSubscription? _recordSub;

  // PCM buffer for smooth streaming
  final List<int> _pcmBuffer = [];
  static const _chunkSize    = 4096; // bytes per send (~128ms at 16kHz mono 16-bit)
  Timer? _sendTimer;

  // ── Callbacks (set from controller/screen) ────────────────────────────────
  void Function(String text)?    onTextChunk;
  void Function(Uint8List pcm)?  onAudioChunk;
  void Function()?               onTurnComplete;
  void Function(String error)?   onError;

  // ── Mic permission ────────────────────────────────────────────────────────
  Future<bool> requestMicPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  // ── Connect ───────────────────────────────────────────────────────────────
  Future<void> connect({
    required String cefrLevel,
    required String nativeLang,
    required String topic,
    required String occupation,
  }) async {
    assert(AppK.geminiKey.isNotEmpty, 'GEMINI_API_KEY not set');
    await disconnect();

    callState.value   = CallState.connecting;
    transcript.value  = '';
    aiReply.value     = '';
    errorMsg.value    = null;
    _setupComplete    = false;

    try {
      _ws = WebSocketChannel.connect(
          Uri.parse('${AppK.geminiLiveWs}?key=${AppK.geminiKey}'));

      _ws!.stream.listen(
        _onMessage,
        onDone:  _onDisconnected,
        onError: (e) {
          errorMsg.value  = e.toString();
          callState.value = CallState.error;
          onError?.call(e.toString());
        },
        cancelOnError: false,
      );

      // ── Setup message ─────────────────────────────────────────────────
      _ws!.sink.add(jsonEncode({
        'setup': {
          'model': AppK.geminiLiveModel,
          'generation_config': {
            'response_modalities': ['AUDIO', 'TEXT'],
            'speech_config': {
              'voice_config': {
                'prebuilt_voice_config': {'voice_name': 'Aoede'},
              },
            },
          },
          'system_instruction': {
            'parts': [{'text': _buildSystemPrompt(
                cefrLevel, nativeLang, topic, occupation)}],
          },
          // Enable automatic VAD so Gemini knows when user stops speaking
          'realtime_input_config': {
            'automatic_activity_detection': {
              'disabled': false,
              'start_of_speech_sensitivity': 'START_SENSITIVITY_HIGH',
              'end_of_speech_sensitivity':   'END_SENSITIVITY_MEDIUM',
              'prefix_padding_ms':  200,
              'silence_duration_ms': 600,
            },
          },
        },
      }));
    } catch (e) {
      errorMsg.value  = 'Connection failed: $e';
      callState.value = CallState.error;
      onError?.call(errorMsg.value!);
    }
  }

  // ── Start mic streaming ───────────────────────────────────────────────────
  Future<void> startRecording() async {
    if (!_setupComplete || _isRecording) return;
    if (!await requestMicPermission()) {
      errorMsg.value = 'Microphone permission denied';
      return;
    }

    _isRecording    = true;
    callState.value = CallState.listening;
    _pcmBuffer.clear();

    // record package streams raw PCM via RecordConfig
    final stream = await _recorder.startStream(
      const RecordConfig(
        encoder:    AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
        bitRate:    256000,
      ),
    );

    _recordSub = stream.listen((chunk) {
      _pcmBuffer.addAll(chunk);
      // Flush when buffer hits chunk size
      while (_pcmBuffer.length >= _chunkSize) {
        _sendPcmChunk(_pcmBuffer.sublist(0, _chunkSize));
        _pcmBuffer.removeRange(0, _chunkSize);
      }
    });
  }

  // ── Stop mic — flush remaining buffer ─────────────────────────────────────
  Future<void> stopRecording() async {
    if (!_isRecording) return;
    _isRecording = false;

    await _recordSub?.cancel();
    _recordSub = null;
    await _recorder.stop();

    // Flush remainder
    if (_pcmBuffer.isNotEmpty) {
      _sendPcmChunk(_pcmBuffer);
      _pcmBuffer.clear();
    }

    // Signal turn complete
    _ws?.sink.add(jsonEncode({
      'client_content': {'turn_complete': true},
    }));

    callState.value = CallState.aiSpeaking;
  }

  // ── Send raw PCM chunk ────────────────────────────────────────────────────
  void _sendPcmChunk(List<int> bytes) {
    if (_ws == null || !_setupComplete) return;
    _ws!.sink.add(jsonEncode({
      'realtime_input': {
        'media_chunks': [{
          'data':      base64Encode(bytes),
          'mime_type': 'audio/pcm;rate=16000',
        }],
      },
    }));
  }

  // ── Send text (for testing without mic) ───────────────────────────────────
  void sendText(String text) {
    if (!_setupComplete) return;
    _ws?.sink.add(jsonEncode({
      'client_content': {
        'turns': [{'role': 'user', 'parts': [{'text': text}]}],
        'turn_complete': true,
      },
    }));
    callState.value = CallState.aiSpeaking;
  }

  // ── Handle incoming WebSocket message ────────────────────────────────────
  void _onMessage(dynamic raw) {
    try {
      final msg = jsonDecode(raw as String) as Map<String, dynamic>;

      // ── Setup complete ────────────────────────────────────────────────
      if (msg['setupComplete'] != null) {
        _setupComplete  = true;
        callState.value = CallState.connected;
        Get.log('[GeminiLive] Setup complete — ready');
        return;
      }

      // ── Activity detection (VAD) ──────────────────────────────────────
      final activityType = msg['serverContent']?['inputTranscription']
          ?['activityType'] as String?;
      if (activityType == 'START_OF_SPEECH' && callState.value != CallState.listening) {
        callState.value = CallState.listening;
      }

      // ── Inline transcription of user speech ───────────────────────────
      final userTranscript = msg['serverContent']?['inputTranscription']
          ?['transcript'] as String?;
      if (userTranscript != null) {
        transcript.value = userTranscript;
      }

      // ── Model response parts ──────────────────────────────────────────
      final parts = msg['serverContent']?['modelTurn']?['parts'];
      if (parts is List) {
        for (final part in parts as List) {
          // Text chunk
          if (part['text'] != null) {
            final t = part['text'] as String;
            aiReply.value += t;
            onTextChunk?.call(t);
          }
          // Audio chunk — PCM bytes
          if (part['inlineData']?['data'] != null) {
            final bytes = base64Decode(part['inlineData']['data'] as String);
            _playAudioChunk(Uint8List.fromList(bytes));
            onAudioChunk?.call(Uint8List.fromList(bytes));
          }
        }
      }

      // ── Turn complete ─────────────────────────────────────────────────
      if (msg['serverContent']?['turnComplete'] == true) {
        callState.value = CallState.connected; // back to ready
        onTurnComplete?.call();
        _scoreSession();
      }

      // ── Interruption (user spoke while AI was talking) ────────────────
      if (msg['serverContent']?['interrupted'] == true) {
        _player.stop();
        callState.value = CallState.listening;
      }
    } catch (e) {
      Get.log('[GeminiLive] Parse error: $e');
    }
  }

  // ── Play PCM audio from Gemini ────────────────────────────────────────────
  // Gemini Live sends raw PCM (16-bit, 24kHz, mono)
  final List<Uint8List> _audioQueue = [];
  bool _playerBusy = false;

  void _playAudioChunk(Uint8List pcm) {
    _audioQueue.add(pcm);
    _drainQueue();
  }

  void _drainQueue() async {
    if (_playerBusy || _audioQueue.isEmpty) return;
    _playerBusy = true;
    while (_audioQueue.isNotEmpty) {
      final chunk = _audioQueue.removeAt(0);
      try {
        // Wrap raw PCM in a minimal WAV header for audioplayer compatibility
        final wav = _pcmToWav(chunk, sampleRate: 24000);
        await _player.setAudioSource(
            AudioSource.uri(Uri.dataFromBytes(wav, mimeType: 'audio/wav')));
        await _player.play();
        await _player.processingStateStream
            .firstWhere((s) => s == ProcessingState.completed)
            .timeout(const Duration(seconds: 30));
      } catch (_) {}
    }
    _playerBusy = false;
  }

  /// Wraps raw 16-bit PCM into a valid WAV byte array.
  Uint8List _pcmToWav(Uint8List pcm,
      {int sampleRate = 24000, int channels = 1, int bitsPerSample = 16}) {
    final byteRate    = sampleRate * channels * bitsPerSample ~/ 8;
    final blockAlign  = channels * bitsPerSample ~/ 8;
    final dataSize    = pcm.length;
    final headerSize  = 44;
    final totalSize   = headerSize + dataSize;

    final buf  = ByteData(totalSize);
    int  offset = 0;

    void writeStr(String s) {
      for (final c in s.codeUnits) { buf.setUint8(offset++, c); }
    }
    void writeU32(int v) { buf.setUint32(offset, v, Endian.little); offset += 4; }
    void writeU16(int v) { buf.setUint16(offset, v, Endian.little); offset += 2; }

    writeStr('RIFF');
    writeU32(totalSize - 8);
    writeStr('WAVE');
    writeStr('fmt ');
    writeU32(16);           // PCM chunk size
    writeU16(1);            // PCM format
    writeU16(channels);
    writeU32(sampleRate);
    writeU32(byteRate);
    writeU16(blockAlign);
    writeU16(bitsPerSample);
    writeStr('data');
    writeU32(dataSize);

    final out = Uint8List(totalSize);
    out.setRange(0, headerSize, buf.buffer.asUint8List());
    out.setRange(headerSize, totalSize, pcm);
    return out;
  }

  void _onDisconnected() {
    _setupComplete  = false;
    _isRecording    = false;
    if (callState.value != CallState.idle) {
      callState.value = CallState.idle;
    }
  }

  // ── Simple session scoring from transcript ────────────────────────────────
  void _scoreSession() {
    final words = transcript.value.split(' ').length;
    // Rough scoring: more words + no errors = higher score
    final score = (words * 3).clamp(0, 100);
    if (score > sessionScore.value) sessionScore.value = score;
  }

  // ── Disconnect ────────────────────────────────────────────────────────────
  Future<void> disconnect() async {
    _sendTimer?.cancel();
    await _recordSub?.cancel();
    _recordSub = null;
    if (_isRecording) {
      await _recorder.stop();
      _isRecording = false;
    }
    await _ws?.sink.close();
    _ws            = null;
    _setupComplete = false;
    _audioQueue.clear();
    _playerBusy = false;
    await _player.stop();
    callState.value = CallState.idle;
  }

  @override
  void onClose() {
    disconnect();
    _recorder.dispose();
    _player.dispose();
    super.onClose();
  }

  // ── System prompt ─────────────────────────────────────────────────────────
  String _buildSystemPrompt(
      String level, String lang, String topic, String occupation) => '''
You are Mira, a warm and encouraging English conversation tutor for Indian learners.
This is a VOICE call — speak naturally, clearly, and at the right pace for $level level.

Student profile:
- CEFR level: $level
- Native language: $lang  
- Occupation: $occupation
- Today's topic: $topic

Your rules:
1. Speak in simple, clear English appropriate for $level level
2. Keep each response SHORT — 2-3 sentences maximum per turn
3. When the student makes a grammar error, gently correct it once, then move on
4. Always respond warmly — like a supportive elder sibling
5. If student speaks in $lang, understand it but reply in English and gently encourage them to try English
6. Ask follow-up questions to keep the conversation flowing
7. Celebrate effort: say "Good try!", "That's right!", "Great sentence!" when appropriate
8. For A1/A2 students: speak slower, use very simple words, repeat if needed
9. Do NOT lecture — keep it conversational
10. After 5 exchanges, give one specific grammar tip relevant to what the student said

Start by warmly greeting the student and asking a simple question about $topic.
''';
}
