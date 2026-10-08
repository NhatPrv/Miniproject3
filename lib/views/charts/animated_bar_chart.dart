import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/utils/currency_formatter.dart';

class AnimatedBarChart extends StatefulWidget {
  final Map<String, double> weeklySpending;

  const AnimatedBarChart({
    super.key,
    required this.weeklySpending,
  });

  @override
  State<AnimatedBarChart> createState() => _AnimatedBarChartState();
}

class _AnimatedBarChartState extends State<AnimatedBarChart>
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
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant AnimatedBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.weeklySpending != widget.weeklySpending) {
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
    return SizedBox(
      height: 200,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return CustomPaint(
            size: Size.infinite,
            painter: _BarChartPainter(
              spendingData: widget.weeklySpending,
              progress: _animation.value,
            ),
          );
        },
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final Map<String, double> spendingData;
  final double progress;

  _BarChartPainter({
    required this.spendingData,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const bottomPadding = 28.0;
    const topPadding = 24.0;
    const horizontalPadding = 16.0;

    final chartHeight = size.height - bottomPadding - topPadding;
    final chartWidth = size.width - (horizontalPadding * 2);

    final entries = spendingData.entries.toList();
    if (entries.isEmpty) return;

    // Tìm giá trị chi tiêu lớn nhất để chuẩn hóa tỉ lệ chiều cao cột
    double maxSpending = 0;
    for (final e in entries) {
      if (e.value > maxSpending) maxSpending = e.value;
    }
    if (maxSpending <= 0) maxSpending = 100000; // Giá trị cơ sở

    // Vẽ đường kẻ trục đáy (Baseline)
    final baselinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(horizontalPadding, size.height - bottomPadding),
      Offset(size.width - horizontalPadding, size.height - bottomPadding),
      baselinePaint,
    );

    final barCount = entries.length;
    final slotWidth = chartWidth / barCount;
    final barWidth = math.min(22.0, slotWidth * 0.45);

    final barPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF10B981), Color(0xFF3B82F6)],
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final textStyle = const TextStyle(color: Colors.white70, fontSize: 11);
    final valueTextStyle = const TextStyle(
      color: Color(0xFF34D399),
      fontSize: 10,
      fontWeight: FontWeight.bold,
    );

    for (int i = 0; i < barCount; i++) {
      final entry = entries[i];
      final centerX = horizontalPadding + (i * slotWidth) + (slotWidth / 2);
      final normalizedHeight = (entry.value / maxSpending) * chartHeight * progress;

      final barLeft = centerX - (barWidth / 2);
      final barTop = (size.height - bottomPadding) - normalizedHeight;
      final barBottom = size.height - bottomPadding;

      // Vẽ thanh cột bo góc
      if (normalizedHeight > 0) {
        final rrect = RRect.fromRectAndCorners(
          Rect.fromLTRB(barLeft, barTop, barLeft + barWidth, barBottom),
          topLeft: const Radius.circular(6),
          topRight: const Radius.circular(6),
        );
        canvas.drawRRect(rrect, barPaint);

        // Vẽ số tiền trên đỉnh cột
        final valText = CurrencyFormatter.formatCompact(entry.value);
        final valPainter = TextPainter(
          text: TextSpan(text: valText, style: valueTextStyle),
          textDirection: TextDirection.ltr,
        )..layout();
        valPainter.paint(
          canvas,
          Offset(centerX - (valPainter.width / 2), barTop - valPainter.height - 4),
        );
      }

      // Vẽ nhãn ngày dưới chân cột (Format MM/DD)
      String label = entry.key;
      if (label.length >= 10) {
        label = '${label.substring(8, 10)}/${label.substring(5, 7)}';
      }
      final textPainter = TextPainter(
        text: TextSpan(text: label, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(centerX - (textPainter.width / 2), size.height - bottomPadding + 6),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.spendingData != spendingData;
  }
}
