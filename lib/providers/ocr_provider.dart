import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../core/ocr/mlkit_ocr_service.dart';
import '../core/ocr/receipt_regex_parser.dart';

enum OCRScanStatus { idle, scanning, success, error }

class OCRScanState {
  final OCRScanStatus status;
  final ParsedReceiptResult? result;
  final String? savedImagePath;
  final String? errorMessage;

  const OCRScanState({
    this.status = OCRScanStatus.idle,
    this.result,
    this.savedImagePath,
    this.errorMessage,
  });

  OCRScanState copyWith({
    OCRScanStatus? status,
    ParsedReceiptResult? result,
    String? savedImagePath,
    String? errorMessage,
  }) {
    return OCRScanState(
      status: status ?? this.status,
      result: result ?? this.result,
      savedImagePath: savedImagePath ?? this.savedImagePath,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class OCRNotifier extends StateNotifier<OCRScanState> {
  final ImagePicker _picker = ImagePicker();

  OCRNotifier() : super(const OCRScanState());

  void reset() {
    state = const OCRScanState();
  }

  /// Capture via camera or pick from gallery and run OCR
  Future<ParsedReceiptResult?> captureAndScan(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 90,
      );

      if (pickedFile == null) {
        state = const OCRScanState(status: OCRScanStatus.idle);
        return null;
      }

      state = const OCRScanState(status: OCRScanStatus.scanning);

      // Persist photo to app permanent directory
      final appDir = await getApplicationDocumentsDirectory();
      final receiptsDir = Directory(p.join(appDir.path, 'receipt_photos'));
      if (!await receiptsDir.exists()) {
        await receiptsDir.create(recursive: true);
      }

      final fileName = 'receipt_${DateTime.now().millisecondsSinceEpoch}${p.extension(pickedFile.path)}';
      final permanentPath = p.join(receiptsDir.path, fileName);
      final savedFile = await File(pickedFile.path).copy(permanentPath);

      // Perform on-device ML Kit OCR & Regex extraction
      final parsedResult = await MLKitOCRService.instance.processImage(savedFile.path);

      state = OCRScanState(
        status: OCRScanStatus.success,
        result: parsedResult,
        savedImagePath: savedFile.path,
      );

      return parsedResult;
    } catch (e) {
      state = OCRScanState(
        status: OCRScanStatus.error,
        errorMessage: 'Quá trình quét hóa đơn thất bại: ${e.toString()}',
      );
      return null;
    }
  }

  /// Process direct image path (e.g. from existing photo)
  Future<ParsedReceiptResult?> scanExistingPath(String imagePath) async {
    state = const OCRScanState(status: OCRScanStatus.scanning);
    try {
      final parsed = await MLKitOCRService.instance.processImage(imagePath);
      state = OCRScanState(
        status: OCRScanStatus.success,
        result: parsed,
        savedImagePath: imagePath,
      );
      return parsed;
    } catch (e) {
      state = OCRScanState(
        status: OCRScanStatus.error,
        errorMessage: e.toString(),
      );
      return null;
    }
  }
}

final ocrProvider = StateNotifierProvider<OCRNotifier, OCRScanState>((ref) {
  return OCRNotifier();
});
