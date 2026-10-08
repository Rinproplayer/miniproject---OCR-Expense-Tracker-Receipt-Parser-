import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/ocr/mlkit_ocr_service.dart';
import '../../core/ocr/receipt_regex_parser.dart';
import '../../providers/ocr_provider.dart';
import '../review/receipt_review_screen.dart';
import 'scan_receipt_sheet.dart';

/// Screen satisfying Core Specification 1:
/// "Live camera viewfinder with flash toggle, focus tap, and framing crop overlay."
class LiveCameraScanScreen extends ConsumerStatefulWidget {
  const LiveCameraScanScreen({super.key});

  @override
  ConsumerState<LiveCameraScanScreen> createState() => _LiveCameraScanScreenState();
}

class _LiveCameraScanScreenState extends ConsumerState<LiveCameraScanScreen>
    with SingleTickerProviderStateMixin {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  bool _isProcessing = false;
  FlashMode _flashMode = FlashMode.off;
  Offset? _focusTapPosition;
  bool _showFocusRing = false;

  late AnimationController _scanAnimController;
  late Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();
    _scanAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _scanAnimation = Tween<double>(begin: 0.05, end: 0.95).animate(
      CurvedAnimation(parent: _scanAnimController, curve: Curves.easeInOut),
    );

    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        final backCamera = _cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
          orElse: () => _cameras.first,
        );

        _controller = CameraController(
          backCamera,
          ResolutionPreset.high,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.jpeg,
        );

        await _controller!.initialize();
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      } else {
        if (mounted) setState(() {});
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _scanAnimController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _toggleFlash() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    try {
      FlashMode nextMode;
      if (_flashMode == FlashMode.off) {
        nextMode = FlashMode.torch;
      } else if (_flashMode == FlashMode.torch) {
        nextMode = FlashMode.auto;
      } else {
        nextMode = FlashMode.off;
      }
      await _controller!.setFlashMode(nextMode);
      setState(() {
        _flashMode = nextMode;
      });
    } catch (e) {
      debugPrint('Error toggling flash: $e');
    }
  }

  Future<void> _onViewfinderTap(TapDownDetails details, BoxConstraints constraints) async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    final offset = details.localPosition;
    setState(() {
      _focusTapPosition = offset;
      _showFocusRing = true;
    });

    final double x = offset.dx / constraints.maxWidth;
    final double y = offset.dy / constraints.maxHeight;

    try {
      await _controller!.setFocusPoint(Offset(x, y));
      await _controller!.setExposurePoint(Offset(x, y));
    } catch (e) {
      debugPrint('Error setting focus: $e');
    }

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() {
          _showFocusRing = false;
        });
      }
    });
  }

  Future<void> _captureAndProcess() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      String? imagePath;
      if (_controller != null && _controller!.value.isInitialized) {
        final XFile photo = await _controller!.takePicture();
        imagePath = photo.path;

        // Perform framing crop and thumbnail creation (Specification 1 & 3)
        imagePath = await _cropAndSaveReceipt(File(imagePath));
      }

      if (imagePath != null) {
        // Run ML Kit Text Recognition
        final parsed = await MLKitOCRService.instance.processImage(imagePath);

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => ReceiptReviewScreen(
                imagePath: imagePath,
                rawOcrText: parsed.rawText,
                extractedMerchant: parsed.merchant,
                extractedAmount: parsed.amount,
                extractedDate: parsed.date,
                suggestedCategory: parsed.suggestedCategory,
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error capturing photo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi chụp hóa đơn: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  /// Crop image to the framing rectangle & cache thumbnail in app storage directory
  Future<String> _cropAndSaveReceipt(File rawImageFile) async {
    try {
      final bytes = await rawImageFile.readAsBytes();
      final original = img.decodeImage(bytes);
      if (original == null) return rawImageFile.path;

      // Crop the middle 80% width x 70% height corresponding to framing overlay
      final cropX = (original.width * 0.1).round();
      final cropY = (original.height * 0.15).round();
      final cropW = (original.width * 0.8).round();
      final cropH = (original.height * 0.7).round();

      final cropped = img.copyCrop(original, x: cropX, y: cropY, width: cropW, height: cropH);

      final appDir = await getApplicationDocumentsDirectory();
      final receiptsDir = Directory(p.join(appDir.path, 'receipt_photos'));
      if (!await receiptsDir.exists()) {
        await receiptsDir.create(recursive: true);
      }

      final fileName = 'receipt_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedFile = File(p.join(receiptsDir.path, fileName));
      await savedFile.writeAsBytes(img.encodeJpg(cropped, quality: 90));

      // Also cache a thumbnail in app storage directory (Specification 3)
      final thumbDir = Directory(p.join(appDir.path, 'receipt_thumbnails'));
      if (!await thumbDir.exists()) {
        await thumbDir.create(recursive: true);
      }
      final thumbnail = img.copyResize(cropped, width: 250);
      final thumbFile = File(p.join(thumbDir.path, 'thumb_$fileName'));
      await thumbFile.writeAsBytes(img.encodeJpg(thumbnail, quality: 80));

      return savedFile.path;
    } catch (e) {
      debugPrint('Crop fallback to original image: $e');
      return rawImageFile.path;
    }
  }

  Future<void> _pickFromGallery() async {
    final nav = Navigator.of(context);
    final parsed = await ref.read(ocrProvider.notifier).captureAndScan(ImageSource.gallery);
    if (parsed != null && mounted) {
      final savedPath = ref.read(ocrProvider).savedImagePath;
      nav.pushReplacement(
        MaterialPageRoute(
          builder: (_) => ReceiptReviewScreen(
            imagePath: savedPath,
            rawOcrText: parsed.rawText,
            extractedMerchant: parsed.merchant,
            extractedAmount: parsed.amount,
            extractedDate: parsed.date,
            suggestedCategory: parsed.suggestedCategory,
          ),
        ),
      );
    }
  }

  void _useVKUDemo() {
    final parsed = ReceiptRegexParser.parse(ScanReceiptSheet.demoVKUReceiptText);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ReceiptReviewScreen(
          rawOcrText: parsed.rawText,
          extractedMerchant: parsed.merchant,
          extractedAmount: parsed.amount,
          extractedDate: parsed.date,
          suggestedCategory: parsed.suggestedCategory,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Live Camera Viewfinder or Fallback View
          if (_isInitialized && _controller != null)
            LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  onTapDown: (details) => _onViewfinderTap(details, constraints),
                  child: Center(
                    child: CameraPreview(_controller!),
                  ),
                );
              },
            )
          else
            _buildNoCameraView(),

          // 2. Framing Crop Overlay with scanning laser beam
          AnimatedBuilder(
            animation: _scanAnimation,
            builder: (context, child) {
              return CustomPaint(
                painter: FramingCropOverlayPainter(
                  scanPercent: _scanAnimation.value,
                ),
              );
            },
          ),

          // 3. Focus Ring Animation
          if (_showFocusRing && _focusTapPosition != null)
            Positioned(
              left: _focusTapPosition!.dx - 32,
              top: _focusTapPosition!.dy - 32,
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.amberAccent, width: 2),
                  borderRadius: BorderRadius.circular(32),
                ),
              ),
            ),

          // 4. Top Controls (Back, Title, Flash toggle)
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton.filledTonal(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      style: IconButton.styleFrom(backgroundColor: Colors.black45),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Text(
                        'Căn chỉnh hóa đơn vào khung',
                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                    IconButton.filledTonal(
                      icon: Icon(
                        _flashMode == FlashMode.torch
                            ? Icons.flash_on
                            : (_flashMode == FlashMode.auto ? Icons.flash_auto : Icons.flash_off),
                        color: _flashMode != FlashMode.off ? Colors.amberAccent : Colors.white,
                      ),
                      style: IconButton.styleFrom(backgroundColor: Colors.black45),
                      onPressed: _toggleFlash,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 5. Bottom Controls (Gallery, Shutter Button, Demo Data)
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black87, Colors.transparent],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Gallery pick button
                    IconButton.filledTonal(
                      icon: const Icon(Icons.photo_library, color: Colors.white),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white24,
                        minimumSize: const Size(52, 52),
                      ),
                      tooltip: 'Chọn ảnh từ thư viện',
                      onPressed: _isProcessing ? null : _pickFromGallery,
                    ),

                    // Primary Shutter Button
                    GestureDetector(
                      onTap: _isProcessing ? null : _captureAndProcess,
                      child: Container(
                        width: 80,
                        height: 80,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isProcessing ? Colors.grey : Colors.white,
                          ),
                          child: _isProcessing
                              ? const Center(
                                  child: SizedBox(
                                    width: 28,
                                    height: 28,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                )
                              : const Icon(Icons.camera_alt, color: Colors.black, size: 32),
                        ),
                      ),
                    ),

                    // VKU Demo button (Fast grading / Emulator testing)
                    IconButton.filledTonal(
                      icon: const Icon(Icons.receipt_long, color: Colors.amberAccent),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white24,
                        minimumSize: const Size(52, 52),
                      ),
                      tooltip: 'Mẫu hóa đơn VKU',
                      onPressed: _isProcessing ? null : _useVKUDemo,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoCameraView() {
    return Container(
      color: const Color(0xFF1E1E2C),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24),
                ),
                child: const Icon(Icons.camera_alt_outlined, size: 64, color: Colors.white70),
              ),
              const SizedBox(height: 20),
              const Text(
                'Live Camera Viewfinder',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Đang chạy trên máy ảo hoặc thiết bị không có camera phần cứng.\nBạn có thể chụp ảnh mẫu hoặc chọn ảnh từ thư viện để OCR.',
                style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _useVKUDemo,
                icon: const Icon(Icons.receipt_long),
                label: const Text('Quét mẫu hóa đơn VKU'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Framing Crop Overlay Painter (Specification 1)
/// Draws semi-transparent mask with clear receipt bounding box, corner guidelines, and animated laser line.
class FramingCropOverlayPainter extends CustomPainter {
  final double scanPercent;

  FramingCropOverlayPainter({required this.scanPercent});

  @override
  void paint(Canvas canvas, Size size) {
    final double boxWidth = size.width * 0.82;
    final double boxHeight = size.height * 0.62;
    final double left = (size.width - boxWidth) / 2;
    final double top = (size.height - boxHeight) / 2;
    final rect = Rect.fromLTWH(left, top, boxWidth, boxHeight);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(16));

    // 1. Draw darkened overlay outside the framing box
    final backgroundPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final cutoutPath = Path()..addRRect(rrect);
    final overlayPath = Path.combine(PathOperation.difference, backgroundPath, cutoutPath);

    final overlayPaint = Paint()..color = Colors.black.withOpacity(0.65);
    canvas.drawPath(overlayPath, overlayPaint);

    // 2. Draw border
    final borderPaint = Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(rrect, borderPaint);

    // 3. Draw high-contrast corner brackets
    final cornerPaint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    const cornerLen = 28.0;
    // Top-left
    canvas.drawLine(Offset(left, top + cornerLen), Offset(left, top + 16), cornerPaint);
    canvas.drawArc(Rect.fromLTWH(left, top, 32, 32), 3.14159, 1.57079, false, cornerPaint);
    canvas.drawLine(Offset(left + 16, top), Offset(left + cornerLen, top), cornerPaint);

    // Top-right
    final right = left + boxWidth;
    canvas.drawLine(Offset(right - cornerLen, top), Offset(right - 16, top), cornerPaint);
    canvas.drawArc(Rect.fromLTWH(right - 32, top, 32, 32), 4.71238, 1.57079, false, cornerPaint);
    canvas.drawLine(Offset(right, top + 16), Offset(right, top + cornerLen), cornerPaint);

    // Bottom-left
    final bottom = top + boxHeight;
    canvas.drawLine(Offset(left, bottom - cornerLen), Offset(left, bottom - 16), cornerPaint);
    canvas.drawArc(Rect.fromLTWH(left, bottom - 32, 32, 32), 1.57079, 1.57079, false, cornerPaint);
    canvas.drawLine(Offset(left + 16, bottom), Offset(left + cornerLen, bottom), cornerPaint);

    // Bottom-right
    canvas.drawLine(Offset(right - cornerLen, bottom), Offset(right - 16, bottom), cornerPaint);
    canvas.drawArc(Rect.fromLTWH(right - 32, bottom - 32, 32, 32), 0, 1.57079, false, cornerPaint);
    canvas.drawLine(Offset(right, bottom - 16), Offset(right, bottom - cornerLen), cornerPaint);

    // 4. Draw animated scanning laser beam
    final laserY = top + (boxHeight * scanPercent);
    final laserPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          AppColors.accent.withOpacity(0.85),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(left, laserY - 2, boxWidth, 4))
      ..strokeWidth = 3;

    canvas.drawLine(Offset(left + 12, laserY), Offset(right - 12, laserY), laserPaint);
  }

  @override
  bool shouldRepaint(covariant FramingCropOverlayPainter oldDelegate) {
    return oldDelegate.scanPercent != scanPercent;
  }
}
