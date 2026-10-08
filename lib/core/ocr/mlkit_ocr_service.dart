import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'receipt_regex_parser.dart';

class MLKitOCRService {
  static final MLKitOCRService instance = MLKitOCRService._init();
  MLKitOCRService._init();

  /// Process image file with Google ML Kit On-Device Text Recognition
  Future<ParsedReceiptResult> processImage(String imagePath) async {
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

      final fullRawText = recognizedText.text;
      final parsed = ReceiptRegexParser.parse(fullRawText);

      return parsed;
    } catch (e) {
      // In case ML Kit fails on platforms without Google Play services, provide a graceful fallback
      return ParsedReceiptResult(
        merchant: 'Hóa đơn chưa nhận diện',
        amount: 0.0,
        date: DateTime.now(),
        suggestedCategory: ReceiptRegexParser.suggestCategory('', ''),
        rawText: 'Lỗi OCR: ${e.toString()}',
        confidenceScore: 0.0,
      );
    } finally {
      await textRecognizer.close();
    }
  }

  /// Process raw string directly (helpful for unit testing & sample demonstration)
  ParsedReceiptResult processRawText(String text) {
    return ReceiptRegexParser.parse(text);
  }
}
