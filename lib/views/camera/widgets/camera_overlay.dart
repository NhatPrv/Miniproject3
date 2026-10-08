import 'package:flutter/material.dart';

class CameraOverlay extends StatelessWidget {
  final Rect cutoutRect;

  const CameraOverlay({
    super.key,
    required this.cutoutRect,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _OverlayPainter(cutoutRect: cutoutRect),
    );
  }
}

class _OverlayPainter extends CustomPainter {
  final Rect cutoutRect;

  _OverlayPainter({required this.cutoutRect});

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.65)
      ..style = PaintingStyle.fill;

    // Vẽ lớp phủ tối toàn màn hình trừ phần khung cắt
    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final cutoutPath = Path()
      ..addRRect(RRect.fromRectAndRadius(cutoutRect, const Radius.circular(16)));

    final overlayPath = Path.combine(
      PathOperation.difference,
      backgroundPath,
      cutoutPath,
    );
    canvas.drawPath(overlayPath, backgroundPaint);

    // Vẽ viền khung cắt
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(cutoutRect, const Radius.circular(16)),
      borderPaint,
    );

    // Vẽ 4 góc định vị (Corner brackets)
    final cornerPaint = Paint()
      ..color = const Color(0xFF10B981) // Emerald Green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;

    const cornerLength = 26.0;

    // Góc trên bên trái
    canvas.drawLine(
      Offset(cutoutRect.left, cutoutRect.top + cornerLength),
      Offset(cutoutRect.left, cutoutRect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(cutoutRect.left, cutoutRect.top),
      Offset(cutoutRect.left + cornerLength, cutoutRect.top),
      cornerPaint,
    );

    // Góc trên bên phải
    canvas.drawLine(
      Offset(cutoutRect.right - cornerLength, cutoutRect.top),
      Offset(cutoutRect.right, cutoutRect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(cutoutRect.right, cutoutRect.top),
      Offset(cutoutRect.right, cutoutRect.top + cornerLength),
      cornerPaint,
    );

    // Góc dưới bên trái
    canvas.drawLine(
      Offset(cutoutRect.left, cutoutRect.bottom - cornerLength),
      Offset(cutoutRect.left, cutoutRect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(cutoutRect.left, cutoutRect.bottom),
      Offset(cutoutRect.left + cornerLength, cutoutRect.bottom),
      cornerPaint,
    );

    // Góc dưới bên phải
    canvas.drawLine(
      Offset(cutoutRect.right - cornerLength, cutoutRect.bottom),
      Offset(cutoutRect.right, cutoutRect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(cutoutRect.right, cutoutRect.bottom),
      Offset(cutoutRect.right, cutoutRect.bottom - cornerLength),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _OverlayPainter oldDelegate) {
    return oldDelegate.cutoutRect != cutoutRect;
  }
}
