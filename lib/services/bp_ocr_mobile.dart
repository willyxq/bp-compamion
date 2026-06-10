import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import 'bp_input_parser.dart';

class BpOcr {
  static final _picker = ImagePicker();
  static final _recognizer = TextRecognizer(script: TextRecognitionScript.chinese);

  static Future<bool> get isSupported async => true;

  static Future<BpParsedValues> recognizeFromGallery() =>
      _recognize(ImageSource.gallery);

  static Future<BpParsedValues> recognizeFromCamera() =>
      _recognize(ImageSource.camera);

  static Future<BpParsedValues> _recognize(ImageSource source) async {
    final file = await _picker.pickImage(
      source: source,
      maxWidth: 2048,
      imageQuality: 92,
    );
    if (file == null) {
      throw StateError('未选择图片');
    }

    final input = InputImage.fromFilePath(file.path);
    final result = await _recognizer.processImage(input);
  final text = result.text;
    if (text.trim().isEmpty) {
      throw StateError('未能从图片中识别到文字，请对准血压计屏幕重试');
    }

    final parsed = BpInputParser.parse(text);
    if (!parsed.hasBp) {
      throw StateError('已识别文字但未找到血压数值，请确保屏幕数字清晰\n识别内容：${text.length > 80 ? '${text.substring(0, 80)}…' : text}');
    }
    return parsed;
  }
}
