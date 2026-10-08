import 'package:flutter/material.dart';
import 'weekly_bar_painter.dart';

class AnimatedWeeklyBarChart extends StatefulWidget {
  final Map<int, double> weeklyData;
  final double height;

  const AnimatedWeeklyBarChart({
    super.key,
    required this.weeklyData,
    this.height = 200,
  });

  @override
  State<AnimatedWeeklyBarChart> createState() => _AnimatedWeeklyBarChartState();
}

class _AnimatedWeeklyBarChartState extends State<AnimatedWeeklyBarChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant AnimatedWeeklyBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.weeklyData != widget.weeklyData) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = DateTime.now().weekday;

    return SizedBox(
      height: widget.height,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return CustomPaint(
            painter: WeeklyBarPainter(
              weeklyData: widget.weeklyData,
              animationProgress: _animation.value,
              todayWeekday: today,
              barColor: theme.colorScheme.primary,
              highlightBarColor: theme.colorScheme.secondary,
              gridColor: theme.colorScheme.onSurface,
              textColor: theme.colorScheme.onSurface,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}
