import 'package:speech_to_text/speech_to_text.dart';

import 'bp_input_parser.dart';

class BpVoiceInput {
  static final _speech = SpeechToText();

  static Future<bool> initialize() => _speech.initialize(
        onError: (_) {},
        onStatus: (_) {},
      );

  static bool get isListening => _speech.isListening;

  static Future<void> stop() => _speech.stop();

  /// 开始聆听，[onPartial] 返回实时转写，[onResult] 返回解析后的血压值。
  static Future<void> listen({
    required void Function(String partial) onPartial,
    required void Function(BpParsedValues values, String transcript) onResult,
    required void Function(String message) onError,
  }) async {
    final ok = await initialize();
    if (!ok) {
      onError('无法启动语音识别，请检查麦克风权限');
      return;
    }

    if (!_speech.isAvailable) {
      onError('当前设备不支持语音识别');
      return;
    }

    await _speech.listen(
      onResult: (result) {
        final text = result.recognizedWords.trim();
        if (text.isEmpty) return;
        onPartial(text);

        if (!result.finalResult) return;

        final parsed = BpInputParser.parse(text);
        if (!parsed.hasBp) {
          onError('未识别到有效血压，请说「高压一百三十四，低压九十七，脉搏六十三」');
          return;
        }
        onResult(parsed, text);
      },
      listenOptions: SpeechListenOptions(
        localeId: 'zh_CN',
        listenMode: ListenMode.confirmation,
        cancelOnError: true,
        partialResults: true,
      ),
    );
  }
}
