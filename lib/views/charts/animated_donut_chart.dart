import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/constants/category_constants.dart';
import '../../core/utils/currency_formatter.dart';

class AnimatedDonutChart extends StatefulWidget {
  final Map<String, double> categoryDistribution;
  final double totalAmount;

  const AnimatedDonutChart({
    super.key,
    required this.categoryDistribution,
    required this.totalAmount,
  });

  @override
  State<AnimatedDonutChart> createState() => _AnimatedDonutChartState();
}

class _AnimatedDonutChartState extends State<AnimatedDonutChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant AnimatedDonutChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.totalAmount != widget.totalAmount) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.totalAmount <= 0) {
      return Container(
        height: 220,
        alignment: Alignment.center,
        child: const Text(
          'Chưa có dữ liệu chi tiêu',
          style: TextStyle(color: Colors.white54, fontSize: 14),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 210,
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(200, 200),
                    painter: _DonutChartPainter(
                      distribution: widget.categoryDistribution,
                      total: widget.totalAmount,
                      progress: _animation.value,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Tổng Chi',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyFormatter.formatCompact(widget.totalAmount),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        // Chú giải danh mục (Legend)
        Wrap(
          spacing: 12,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: widget.categoryDistribution.entries.map((entry) {
            if (entry.value <= 0) return const SizedBox.shrink();
            final percentage = (entry.value / widget.totalAmount * 100).toStringAsFixed(1);
            final meta = CategoryConstants.getMetadataByKey(entry.key);
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: meta.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${meta.displayName.split(' ').first}: $percentage%',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final Map<String, double> distribution;
  final double total;
  final double progress;

  _DonutChartPainter({
    required this.distribution,
    required this.total,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 12;
    const strokeWidth = 24.0;

    // Vòng xám nền
    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, bgPaint);

    if (total <= 0) return;

    double startAngle = -math.pi / 2; // Bắt đầu từ 12 giờ
    final totalSweepTarget = 2 * math.pi * progress;
    double currentSwept = 0.0;

    for (final entry in distribution.entries) {
      if (entry.value <= 0) continue;
      final sweepAngle = (entry.value / total) * (2 * math.pi);
      final allowedSweep = math.max(0.0, math.min(sweepAngle, totalSweepTarget - currentSwept));

      if (allowedSweep > 0) {
        final paint = Paint()
          ..color = CategoryConstants.getColorByKey(entry.key)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          allowedSweep,
          false,
          paint,
        );

        startAngle += sweepAngle;
        currentSwept += allowedSweep;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.total != total ||
        oldDelegate.distribution != distribution;
  }
}
