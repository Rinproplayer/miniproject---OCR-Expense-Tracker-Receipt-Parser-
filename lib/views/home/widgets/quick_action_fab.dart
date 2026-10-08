import 'package:flutter/material.dart';
import 'package:vku_expense_ocr/views/scan/scan_receipt_sheet.dart';

class QuickActionFAB extends StatelessWidget {
  const QuickActionFAB({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => ScanReceiptSheet.show(context),
      icon: const Icon(Icons.document_scanner_outlined),
      label: const Text(
        'Quét hóa đơn',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}
