import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';

Future<String> _renderTextToPng(String text) async {
  // Create an image with drawn text
  const int width = 800;
  const int height = 300;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()));
  final bgPaint = Paint()..color = const Color(0xFFFFFFFF);
  canvas.drawRect(Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()), bgPaint);

  // Draw black text
  final paragraphStyle = ui.ParagraphStyle(textAlign: TextAlign.left, fontSize: 48.0);
  final textStyle = ui.TextStyle(color: const Color(0xFF000000));
  final builder = ui.ParagraphBuilder(paragraphStyle)..pushStyle(textStyle)..addText(text);
  final paragraph = builder.build()..layout(const ui.ParagraphConstraints(width: width - 40.0));
  canvas.drawParagraph(paragraph, const Offset(20, 100));

  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  final bytes = byteData!.buffer.asUint8List();

  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/ocr_sample.png');
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('ML Kit OCR end-to-end on generated image', (tester) async {
    // Generate an image with text
    final path = await _renderTextToPng('Ingredients: MILK, SUGAR, E951');
    final input = InputImage.fromFilePath(path);

    // Run recognizer
    final recognizer = TextRecognizer();
    final result = await recognizer.processImage(input);
    await recognizer.close();

    // Basic assertions: we got some text, and likely key tokens are present
    expect(result.text.trim().isNotEmpty, true, reason: 'OCR returned no text');
    final lower = result.text.toLowerCase();
    expect(lower.contains('milk') || lower.contains('sugar') || lower.contains('e951'), true,
        reason: 'Expected at least one of MILK/SUGAR/E951 in OCR output.\nGot: ${result.text}');
  });
}
