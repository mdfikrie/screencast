import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:image/image.dart';
import 'package:screencast/screencast.dart';
import 'package:screencast/system_screencast.dart';
import 'package:win32/win32.dart';

class WindowsScreencast implements SystemScreencast {
  @override
  Future<void> captureScreen(
      {required String path,
      required String name,
      required ImageFormat format}) async {
    nameString = name;
    formatString = format;
    pathString = path;
    imagePathList.clear();
    final monitorEnumProcPtr = Pointer.fromFunction<
        Int32 Function(
            IntPtr, IntPtr, Pointer<NativeType>, IntPtr)>(monitorEnumProc, 0);
    EnumDisplayMonitors(NULL, nullptr, monitorEnumProcPtr, 0);
    await Future.delayed(const Duration(seconds: 2));
  }

  @override
  List<String> imagePathList = pathList;
}

List<String> pathList = [];
var logsScreenshot = '';
int monitorCount = 0;
var pathString = "";
var nameString = "";
var formatString = ImageFormat.png;

int monitorEnumProc(int hMonitor, int hdcMonitor, Pointer lpRect, int dwData) {
  pathList.clear();
  monitorCount++;
  final rect = lpRect.cast<RECT>().ref;
  execute(
    rect.left,
    rect.top,
    rect.right - rect.left,
    rect.bottom - rect.top,
    monitorCount,
  );
  return 1; // Continue enumeration
}

void execute(int x, int y, int width, int height, int monitorCount) async {
  final hDesktopWnd = GetDesktopWindow();
  final hdcDesktop = GetWindowDC(hDesktopWnd);
  final hdcCapture = CreateCompatibleDC(hdcDesktop);
  final hBitmap = CreateCompatibleBitmap(hdcDesktop, width, height);
  final hOld = SelectObject(hdcCapture, hBitmap);
  BitBlt(
      hdcCapture, 0, 0, width, height, hdcDesktop, x, y, SRCCOPY | CAPTUREBLT);
  SelectObject(hdcCapture, hOld);
  DeleteDC(hdcCapture);

  final bitmapInfo = calloc<BITMAPINFO>()
    ..ref.bmiHeader.biSize = sizeOf<BITMAPINFOHEADER>()
    ..ref.bmiHeader.biWidth = width
    ..ref.bmiHeader.biHeight = -height // negative because bitmap is top-down
    ..ref.bmiHeader.biPlanes = 1 // must be 1
    ..ref.bmiHeader.biBitCount = 32
    ..ref.bmiHeader.biCompression = BI_RGB;

  final pPixels = calloc<Uint8>(width * height * 4);
  if (GetDIBits(hdcDesktop, hBitmap, 0, height, pPixels, bitmapInfo,
          DIB_RGB_COLORS) ==
      0) {
    throw WindowsException(GetLastError());
  }

  final bitmapFileHeader = calloc<BITMAPFILEHEADER>()
    ..ref.bfType = 0x4D42 //` 'BM'
    ..ref.bfSize = sizeOf<BITMAPFILEHEADER>() +
        sizeOf<BITMAPINFOHEADER>() +
        width * height * 4
    ..ref.bfOffBits = sizeOf<BITMAPFILEHEADER>() + sizeOf<BITMAPINFOHEADER>();
  var checkFile = Directory(pathString);
  if (!checkFile.existsSync()) {
    checkFile.createSync(recursive: true);
  }
  String imageName = '$nameString-$monitorCount';
  String imagePath = '$pathString/$imageName';

  var fileNameBmp = '$imagePath.bmp';
  final bmpFile = File(fileNameBmp);
  final bmpFp = bmpFile.openWrite();
  bmpFp.add(
      bitmapFileHeader.cast<Uint8>().asTypedList(sizeOf<BITMAPFILEHEADER>()));
  bmpFp.add(bitmapInfo.cast<Uint8>().asTypedList(sizeOf<BITMAPINFOHEADER>()));
  bmpFp.add(pPixels.asTypedList(width * height * 4));
  await bmpFp.close();
  final bmpBytes = await bmpFile.readAsBytes();
  final bmpImage = decodeImage(bmpBytes);
  final jpgImage = encodeJpg(bmpImage!, quality: 30);
  if (formatString == ImageFormat.jpg) {
    await File("$imagePath.jpg").writeAsBytes(jpgImage);
    File(fileNameBmp).delete();
    pathList.add("$imagePath.jpg");
  } else {
    await File("$imagePath.png").writeAsBytes(jpgImage);
    File(fileNameBmp).delete();
    pathList.add("$imagePath.png");
  }
  DeleteObject(hBitmap);
  ReleaseDC(hDesktopWnd, hdcDesktop);

  calloc.free(bitmapInfo);
  calloc.free(pPixels);
  calloc.free(bitmapFileHeader);
}
