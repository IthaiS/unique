import 'dart:io';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:permission_handler/permission_handler.dart';

class OcrService {
  static Future<String> scanAndRecognizeText() async {
    await Permission.camera.request();
    final cams = await availableCameras();
    final cam = cams.first;
    final controller = CameraController(cam, ResolutionPreset.high, enableAudio: false);
    await controller.initialize();
    final picture = await controller.takePicture();
    await controller.dispose();

    final input = InputImage.fromFilePath(picture.path);
    final textRecognizer = TextRecognizer();
    final recognizedText = await textRecognizer.processImage(input);
    await textRecognizer.close();
    try { File(picture.path).deleteSync(); } catch (_) {}
    return recognizedText.text;
  }
}
