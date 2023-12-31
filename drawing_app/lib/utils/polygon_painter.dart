import 'package:flutter/material.dart';
export 'polygon_painter.dart';

class PolygonPainter extends CustomPainter {
  final List<Offset?> points;
  final Function(Offset)? onNewPointAdded;
  final Matrix4 transformationMatrix;
  final double canvasWidth;
  final double canvasHeight;

  PolygonPainter({
    required this.points,
    this.onNewPointAdded,
    required this.transformationMatrix,
    required this.canvasWidth,
    required this.canvasHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0;

    // If points are empty just render an empty canvas
    if (points.isEmpty) {
      return;
    }

    // Scale the points using canvasWidth and canvasHeight
    final List<Offset> scaledPoints =
        points.where((point) => point != null).map((point) {
      final double scaleX = canvasWidth / size.width;
      final double scaleY = canvasHeight / size.height;
      return Offset(point!.dx * scaleX, point.dy * scaleY);
    }).toList();

    // Draw the polygon if points are not empty
    if (scaledPoints.isNotEmpty) {
      final path = Path()..addPolygon(scaledPoints, true);
      canvas.drawPath(path, borderPaint);
    }

    final double squareSize = 10.0;

    final borderCanvasPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRect(
        Rect.fromPoints(Offset(0, 0), Offset(size.width, size.height)),
        borderCanvasPaint);

    // Paint for filling the polygon
    final fillPaint = Paint()
      ..color = Colors.green.withOpacity(0.5) // Semi-transparent fill color
      ..style = PaintingStyle.fill;
    canvas.drawRect(
        Rect.fromPoints(Offset(0, 0), Offset(size.width, size.height)),
        borderCanvasPaint);

    for (final point in points) {
      if (point != null) {
        Rect rect = Rect.fromCenter(
            center: point, width: squareSize, height: squareSize);
        canvas.drawRect(rect, borderPaint);
      }
    }
    // Draw the polygon's filled region
    Path path = Path()..moveTo(points.first!.dx, points.first!.dy);
    for (int i = 1; i < points.length; i++) {
      if (points[i] != null) {
        path.lineTo(points[i]!.dx, points[i]!.dy);
      }
    }
    path.close();
    canvas.drawPath(path, fillPaint);

    // Draw lines between the points
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, borderPaint);
      }
    }

    // Connect the last and first points to close the polygon
    if (points.length > 2) {
      if (points.last != null && points.first != null) {
        canvas.drawLine(points.last!, points.first!, borderPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
