import 'dart:io' show Platform;

bool get widgetPlatformSupported => Platform.isIOS || Platform.isAndroid;
