import "dart:convert";
import "dart:io" show Platform, File;
import "package:flutter/foundation.dart" show kIsWeb;
import "package:http/http.dart" as http;
import "package:file_picker/file_picker.dart";
import "package:camera/camera.dart";
import "package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart";
import "package:permission_handler/permission_handler.dart";

class OcrService {
  static String baseUrl =
      const String.fromEnvironment("BACKEND_BASE_URL", defaultValue: "");
  static Future<String> scanAndRecognizeText() async {
    final isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
    if (isMobile) {
      await Permission.camera.request();
      final cams = await availableCameras();
      final cam = cams.first;
      final c =
          CameraController(cam, ResolutionPreset.high, enableAudio: false);
      await c.initialize();
      final pic = await c.takePicture();
      await c.dispose();
      final input = InputImage.fromFilePath(pic.path);
      final rec = TextRecognizer();
      final res = await rec.processImage(input);
      await rec.close();
      try {
        File(pic.path).deleteSync();
      } catch (_) {}
      return res.text;
    }
    if (baseUrl.isEmpty) {
      throw UnsupportedError(
          "BACKEND_BASE_URL is not set, cloud OCR requires backend.");
    }
    final r = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    if (r == null || r.files.isEmpty) return "";
    final bytes =
        r.files.first.bytes ?? await File(r.files.first.path!).readAsBytes();
    final payload = jsonEncode({"image_base64": base64Encode(bytes)});
    final resp = await http.post(
      Uri.parse("$baseUrl/v1/ocr"),
      headers: {"Content-Type": "application/json"},
      body: payload,
    );
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception("Cloud OCR error: ${resp.statusCode}, ${resp.body}");
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    return (data["text"] as String?) ?? "";
  }
}
