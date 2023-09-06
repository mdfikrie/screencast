import 'package:screencast/screencast.dart';

abstract class SystemScreencast {
  List<String> imagePathList = [];
  Future<void> captureScreen({required String path,required String name, required ImageFormat format});
}