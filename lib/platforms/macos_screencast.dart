import 'dart:convert';
import 'dart:io';

import 'package:screencast/screencast.dart';
import 'package:screencast/system_screencast.dart';

class MacosScreencast implements SystemScreencast {
  @override
  Future<void> captureScreen(
      {required String path,
      required String name,
      required ImageFormat format}) async {
        imagePathList.clear();
    var displayIdList = await getDisplayIDsMac();
    for (var i = 0; i < displayIdList.length; i++) {
      var fullPath = "";
      if (format == ImageFormat.jpg) {
        fullPath = "$path/$name${i + 1}.jpg";
      }else{
        fullPath = "$path/$name${i + 1}.png";
      }
      await execute(
          path: fullPath, displayId: (i + 1).toString());
    }
  }

  Future<void> execute({String? path, String? displayId}) async {
    final process =
        await Process.start("screencapture", ["-x", "-D", displayId!, path!]);
    final exitCode = await process.exitCode;
    if (exitCode == 0) {
      imagePathList.add(path);
    } else {
      imagePathList = [];
      print("Screenshot fail to executed.");
    }
  }

  Future<List<String>> getDisplayIDsMac() async {
    var displayList = <String>[];
    final process = await Process.start('ioreg', ['-l']);
    final output = await process.stdout.transform(utf8.decoder).join();
    var matches =
        RegExp(r'"IODisplayEDID" = <([a-zA-Z0-9]+)').allMatches(output);
    for (var element in matches) {
      displayList.add(element.group(1).toString());
    }
    return displayList;
  }

  @override
  List<String> imagePathList = [];
}
