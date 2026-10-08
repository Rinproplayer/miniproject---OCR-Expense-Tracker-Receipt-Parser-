import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'models/expense_receipt.dart';
import 'providers/theme_provider.dart';
import 'views/history/expense_detail_screen.dart';
import 'views/history/expense_history_screen.dart';
import 'views/home/home_screen.dart';
import 'views/review/receipt_review_screen.dart';
import 'views/stats/statistics_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: VKUExpenseApp(),
    ),
  );
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/history',
      builder: (context, state) => const ExpenseHistoryScreen(),
    ),
    GoRoute(
      path: '/stats',
      builder: (context, state) => const StatisticsScreen(),
    ),
    GoRoute(
      path: '/review',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return ReceiptReviewScreen(
          initialReceipt: extra?['initialReceipt'] as ExpenseReceipt?,
          imagePath: extra?['imagePath'] as String?,
          rawOcrText: extra?['rawOcrText'] as String?,
          extractedMerchant: extra?['extractedMerchant'] as String?,
          extractedAmount: extra?['extractedAmount'] as double?,
          extractedDate: extra?['extractedDate'] as DateTime?,
        );
      },
    ),
  ],
);

class VKUExpenseApp extends ConsumerWidget {
  const VKUExpenseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'VKU Expense OCR',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: _router,
    );
  }
}
