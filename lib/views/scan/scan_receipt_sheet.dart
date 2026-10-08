import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/ocr/receipt_regex_parser.dart';
import '../../providers/ocr_provider.dart';
import '../review/receipt_review_screen.dart';
import 'live_camera_scan_screen.dart';

class ScanReceiptSheet extends ConsumerWidget {
  const ScanReceiptSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const ScanReceiptSheet(),
    );
  }

  // Demo receipt raw text for testing OCR logic directly on emulators
  static const String demoVKUReceiptText = '''
CĂN TIN ĐẠI HỌC VKU - ĐÀ NẴNG
Đ/c: Nam Kỳ Khởi Nghĩa, Khu Đô Thị ĐH Đà Nẵng
ĐT: 0236.3667.111
---------------------------------------------
PHIẾU THANH TOÁN
Số HD: VKU-2026-00892
Ngày: 15/10/2026  11:45
Thu ngân: Tuyết Mai

Tên món             SL    Đơn giá     T.Tiền
---------------------------------------------
1. Cơm sườn trứng    2     35.000     70.000
2. Nước ngọt Coca    2     12.000     24.000
3. Canh rau má       1     10.000     10.000
---------------------------------------------
Cộng tiền hàng:                      104.000
Thuế VAT (0%):                             0
TỔNG CỘNG:                           104.000 đ
Tiền khách đưa:                      150.000
Tiền thối lại:                        46.000
---------------------------------------------
Cảm ơn các bạn sinh viên VKU!
Hẹn gặp lại quý khách!
''';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ocrState = ref.watch(ocrProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Quét hóa đơn chi tiêu',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Sử dụng Google ML Kit OCR nhận diện tự động Số tiền, Cửa hàng và Ngày tháng.',
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            if (ocrState.status == OCRScanStatus.scanning) ...[
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Đang xử lý hình ảnh và bóc tách dữ liệu OCR...',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ] else ...[
              // Option 1: Take photo with camera
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
                ),
                title: const Text('Live Camera & Khung cắt (Viewfinder)', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Bật flash, chạm lấy nét, khung căn chỉnh hóa đơn'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const LiveCameraScanScreen(),
                    ),
                  );
                },
              ),
              const Divider(),

              // Option 2: Choose from gallery
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library_outlined, color: AppColors.accent),
                ),
                title: const Text('Chọn ảnh từ thư viện (Gallery)', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Tải lên ảnh chụp hóa đơn có sẵn'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final nav = Navigator.of(context);
                  final parsed = await ref.read(ocrProvider.notifier).captureAndScan(ImageSource.gallery);
                  if (parsed != null && context.mounted) {
                    final savedPath = ref.read(ocrProvider).savedImagePath;
                    nav.pop();
                    nav.push(
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
                },
              ),
              const Divider(),

              // Option 3: Demo Receipt Simulator (Perfect for Emulator test & grading)
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.receipt_long, color: Colors.amber),
                ),
                title: const Text('Dữ liệu mẫu Hóa đơn Căn tin VKU', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Chạy thử thuật toán Heuristic Regex mà không cần camera'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  final parsed = ReceiptRegexParser.parse(demoVKUReceiptText);
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
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
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
