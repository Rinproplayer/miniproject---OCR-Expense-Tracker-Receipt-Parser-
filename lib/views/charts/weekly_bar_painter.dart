import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';

class WeeklyBarPainter extends CustomPainter {
  final Map<int, double> weeklyData;
  final double animationProgress;
  final int todayWeekday;
  final Color barColor;
  final Color highlightBarColor;
  final Color gridColor;
  final Color textColor;

  WeeklyBarPainter({
    required this.weeklyData,
    required this.animationProgress,
    required this.todayWeekday,
    required this.barColor,
    required this.highlightBarColor,
    required this.gridColor,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const bottomLabelHeight = 28.0;
    const topPadding = 24.0;
    final chartHeight = size.height - bottomLabelHeight - topPadding;
    final chartWidth = size.width;

    // Find max value in week
    double maxVal = 0.0;
    for (int day = 1; day <= 7; day++) {
      final val = weeklyData[day] ?? 0.0;
      if (val > maxVal) maxVal = val;
    }
    // Prevent division by zero and provide headroom
    if (maxVal <= 0) maxVal = 100000;
    final ceiling = (maxVal * 1.25);

    // Draw horizontal dashed grid lines (0%, 50%, 100%)
    final gridPaint = Paint()
      ..color = gridColor.withOpacity(0.15)
      ..strokeWidth = 1.0;

    for (int i = 0; i <= 3; i++) {
      final y = topPadding + (chartHeight * (1.0 - (i / 3.0)));
      canvas.drawLine(Offset(0, y), Offset(chartWidth, y), gridPaint);
    }

    final barSlotWidth = chartWidth / 7;
    final barWidth = math.min(28.0, barSlotWidth * 0.55);

    for (int day = 1; day <= 7; day++) {
      final val = weeklyData[day] ?? 0.0;
      final isToday = day == todayWeekday;
      final normalizedHeight = (val / ceiling) * chartHeight * animationProgress;

      final centerX = (day - 1) * barSlotWidth + (barSlotWidth / 2);
      final left = centerX - (barWidth / 2);
      final right = centerX + (barWidth / 2);
      final bottom = topPadding + chartHeight;
      final top = bottom - normalizedHeight;

      // Draw background slot capsule
      final bgCapsulePaint = Paint()
        ..color = gridColor.withOpacity(0.06)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(left, topPadding, right, bottom),
          const Radius.circular(8),
        ),
        bgCapsulePaint,
      );

      // Draw animated bar with gradient
      if (normalizedHeight > 0) {
        final barPaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: isToday
                ? [highlightBarColor, highlightBarColor.withOpacity(0.7)]
                : [barColor, barColor.withOpacity(0.65)],
          ).createShader(Rect.fromLTRB(left, top, right, bottom));

        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTRB(left, top, right, bottom),
            const Radius.circular(8),
          ),
          barPaint,
        );

        // Draw amount on top of bar if > 0
        if (animationProgress > 0.6) {
          final amountText = CurrencyFormatter.formatCompact(val);
          final amountSpan = TextSpan(
            text: amountText,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isToday ? highlightBarColor : textColor.withOpacity(0.8),
            ),
          );
          final amountPainter = TextPainter(
            text: amountSpan,
            textAlign: TextAlign.center,
            textDirection: TextDirection.ltr,
          )..layout();
          amountPainter.paint(
            canvas,
            Offset(centerX - (amountPainter.width / 2), math.max(0, top - 16)),
          );
        }
      }

      // Draw X-axis Day Label
      final dayName = DateFormatter.getWeekdayName(day);
      final daySpan = TextSpan(
        text: dayName,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
          color: isToday ? highlightBarColor : textColor.withOpacity(0.7),
        ),
      );
      final dayPainter = TextPainter(
        text: daySpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();
      dayPainter.paint(
        canvas,
        Offset(centerX - (dayPainter.width / 2), bottom + 8),
      );
    }
  }

  @override
  bool shouldRepaint(covariant WeeklyBarPainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress ||
        oldDelegate.weeklyData != weeklyData ||
        oldDelegate.todayWeekday != todayWeekday;
  }
}
