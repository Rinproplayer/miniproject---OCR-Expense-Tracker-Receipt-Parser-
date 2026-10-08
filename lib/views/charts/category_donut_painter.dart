import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/category.dart';
import '../../core/utils/currency_formatter.dart';

class CategoryDonutPainter extends CustomPainter {
  final Map<ExpenseCategory, double> categoryTotals;
  final double totalAmount;
  final double animationProgress;
  final Color backgroundColor;
  final Color textColor;
  final Color subtitleColor;

  CategoryDonutPainter({
    required this.categoryTotals,
    required this.totalAmount,
    required this.animationProgress,
    required this.backgroundColor,
    required this.textColor,
    required this.subtitleColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final strokeWidth = size.width * 0.12; // Dynamic proportional stroke
    final radius = (math.min(size.width, size.height) / 2) - (strokeWidth / 2);

    final bgPaint = Paint()
      ..color = backgroundColor.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Draw background base ring
    canvas.drawCircle(center, radius, bgPaint);

    if (totalAmount <= 0 || categoryTotals.isEmpty) {
      _drawCenterText(canvas, center, '0 ₫', 'Chưa có chi tiêu');
      return;
    }

    double startAngle = -math.pi / 2; // Start from 12 o'clock

    final segmentPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    for (final entry in categoryTotals.entries) {
      if (entry.value <= 0) continue;
      final sweepAngle = (entry.value / totalAmount) * 2 * math.pi * animationProgress;

      segmentPaint.color = entry.key.color;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        segmentPaint,
      );

      startAngle += sweepAngle;
    }

    // Center Text: Total Spending & Subtitle
    final formattedTotal = CurrencyFormatter.format(totalAmount * animationProgress);
    _drawCenterText(canvas, center, formattedTotal, 'Tổng chi');
  }

  void _drawCenterText(Canvas canvas, Offset center, String title, String subtitle) {
    // Draw Subtitle
    final subSpan = TextSpan(
      text: subtitle,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: subtitleColor,
      ),
    );
    final subPainter = TextPainter(
      text: subSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    subPainter.paint(
      canvas,
      Offset(center.dx - (subPainter.width / 2), center.dy - subPainter.height - 4),
    );

    // Draw Main Title Amount
    final titleSpan = TextSpan(
      text: title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
    );
    final titlePainter = TextPainter(
      text: titleSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    titlePainter.paint(
      canvas,
      Offset(center.dx - (titlePainter.width / 2), center.dy + 4),
    );
  }

  @override
  bool shouldRepaint(covariant CategoryDonutPainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress ||
        oldDelegate.totalAmount != totalAmount ||
        oldDelegate.categoryTotals != categoryTotals;
  }
}
