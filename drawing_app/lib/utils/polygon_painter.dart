import 'package:flutter/material.dart';
import 'dart:ui' as ui;
export 'polygon_painter.dart';

class PolygonPainter extends CustomPainter {
  final List<Offset?> points;
  final Function(Offset)? onNewPointAdded;
  final Size? screenSize;

  // NEW
  final Matrix4 transformationMatrix;

  PolygonPainter(
      {required this.points,
      this.onNewPointAdded,
      this.screenSize,

      //NEW
      required this.transformationMatrix});

  @override
  void paint(Canvas canvas, Size size) {
    // NEW Use the transformation matrix to apply scaling and translation
    canvas.transform(transformationMatrix.storage);
    final paint = Paint()
      ..color = Colors.red
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5.0;

    // If points are empty and allowDrawing is true, just draw an empty canvas
    if (points.isEmpty
        //&& allowDrawing
        ) {
      // The canvas is ready for user drawing. Nothing else to render.
      return;
    }

    // Existing points are not empty, scale them to the canvas size
    final List<Offset> scaledPoints =
        points.where((point) => point != null).map((point) {
      final double scaleX = size.width / screenSize!.width;
      final double scaleY = size.height / screenSize!.height;
      return Offset(point!.dx * scaleX, point.dy * scaleY);
    }).toList();

    // Draw the polygon if points are not empty
    if (scaledPoints.isNotEmpty) {
      final path = Path()..addPolygon(scaledPoints, true);
      canvas.drawPath(path, paint);
    }

    final double squareSize = 10.0;

    final borderPaint = Paint()
      ..color = Colors.blue // Color of the border of the square
      ..style = PaintingStyle.stroke // This makes it a border
      ..strokeWidth = 10.0;

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
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }

    // Connect the last and first points to close the polygon
    if (points.length > 2) {
      if (points.last != null && points.first != null) {
        canvas.drawLine(points.last!, points.first!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
