import 'bp_input_parser.dart';

/// Web 等平台：拍照识别不可用时的占位实现。
class BpOcr {
  static Future<bool> get isSupported async => false;

  static Future<BpParsedValues> recognizeFromGallery() async {
    throw UnsupportedError('当前平台暂不支持拍照识别，请使用手机 App 或手动输入');
  }

  static Future<BpParsedValues> recognizeFromCamera() async {
    throw UnsupportedError('当前平台暂不支持拍照识别，请使用手机 App 或手动输入');
  }
}
