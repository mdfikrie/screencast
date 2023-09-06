library screencast;
import 'dart:io';
import 'package:screencast/platforms/macos_screencast.dart';
import 'package:screencast/platforms/windows_screencast.dart';
import 'package:screencast/system_screencast.dart';

enum ImageFormat {
  jpg,png
}

class Screencast {
  late SystemScreencast? _systemScreencast;
  Screencast._constructor() {
    if (Platform.isWindows) {
      _systemScreencast = WindowsScreencast();
    } else if (Platform.isMacOS) {
      _systemScreencast = MacosScreencast();
    }
  }

  static final Screencast instance = Screencast._constructor();

  Future<List<String>> capture({required String path,required String imageName,required ImageFormat format}) async {
    await _systemScreencast!.captureScreen(path: path, name: imageName,format: format);
    return _systemScreencast!.imagePathList;
  }

}

final screencast = Screencast.instance;