import 'package:flutter/material.dart';

class BubblePainter extends CustomPainter {
  final List<Offset> bubbles;
  final double radius;
  final Paint bubblePaint;

  BubblePainter(this.bubbles, this.radius)
      : bubblePaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.1)
          ..style = PaintingStyle.fill;

  @override
  void paint(Canvas canvas, Size size) {
    for (var bubble in bubbles) {
      canvas.drawCircle(bubble, radius, bubblePaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
