
import 'package:flutter/material.dart';
import '../models/strokeModel.dart';

class MapPainter extends CustomPainter {
  final List<Stroke> strokes;
  MapPainter({required this.strokes});

  @override
  void paint(Canvas canvas, Size size) {
    for (var stroke in strokes) {
      if (stroke.points.isEmpty) continue; // ⚠ importante!
      
      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.width / 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final path = Path();
      path.moveTo(stroke.points.first.dx, stroke.points.first.dy);

      for (var point in stroke.points.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant MapPainter oldDelegate) => true;
}
