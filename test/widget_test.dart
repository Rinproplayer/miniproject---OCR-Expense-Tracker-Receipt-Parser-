import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vku_expense_ocr/models/category.dart';
import 'package:vku_expense_ocr/views/charts/animated_donut_chart.dart';
import 'package:vku_expense_ocr/views/charts/animated_weekly_bar_chart.dart';

void main() {
  testWidgets('AnimatedDonutChart renders CustomPaint and legends successfully', (WidgetTester tester) async {
    final categoryTotals = {
      ExpenseCategory.food: 120000.0,
      ExpenseCategory.study: 80000.0,
    };

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AnimatedDonutChart(
            data: categoryTotals,
          ),
        ),
      ),
    );

    // Verify CustomPaint is present in widget tree
    expect(find.byType(CustomPaint), findsWidgets);
    // Verify percent legends are rendered for both categories
    expect(find.text('Food (Ăn uống): 60.0%'), findsOneWidget);
    expect(find.text('Study (Học tập): 40.0%'), findsOneWidget);
  });

  testWidgets('AnimatedWeeklyBarChart renders CustomPaint successfully', (WidgetTester tester) async {
    final dailyTotals = {
      DateTime.now().weekday: 65000.0,
    };

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AnimatedWeeklyBarChart(
            weeklyData: dailyTotals,
          ),
        ),
      ),
    );

    // Verify CustomPaint is present
    expect(find.byType(CustomPaint), findsWidgets);
  });
}
