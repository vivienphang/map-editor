import 'package:drawing_app/utils/polygon_painter.dart';
import 'package:flutter/material.dart';

// Global variables
const double canvasWidth = 500.0;
const double canvasHeight = 600.0;

class DrawingCanvas extends StatefulWidget {
  final List<Offset>? points;
  final void Function(List<Offset>?) onPointsUpdated;

  const DrawingCanvas({
    super.key,
    this.points,
    required this.onPointsUpdated,
  });

  @override
  _DrawingCanvasState createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  Offset? selectedPoint;
  List<Offset>? points = [];

  //bool _isDrawingEnabled = false;

  // Function to determine if a point was tapped
  bool pointTapped(Offset potentialTap, Offset? point) {
    return (point != null &&
        (potentialTap - point).distance < 20.0); // 20.0 is the touch radius
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanDown: (details) {
        bool isExistingPoint = false;
        for (var point in widget.points!) {
          if (pointTapped(details.localPosition, point)) {
            selectedPoint = point;
            isExistingPoint = true;
            break;
          }
        }
        if (!isExistingPoint) {
          widget.onPointsUpdated([...widget.points!, details.localPosition]);
        }
      },
      onPanUpdate: (details) {
        if (selectedPoint != null) {
          Offset newPosition = Offset(
            details.localPosition.dx.clamp(0, canvasWidth),
            details.localPosition.dy.clamp(0, canvasHeight),
          );
          final updatedPoints = List<Offset?>.from(widget.points!);
          int index = updatedPoints.indexOf(selectedPoint);
          if (index != -1) {
            updatedPoints[index] = newPosition;
          }
          selectedPoint = newPosition;
          widget.onPointsUpdated(updatedPoints
              .where((point) => point != null)
              .cast<Offset>()
              .toList());
        }
      },
      // When user stops dragging (lifts their finger/ release the mouse)
      onPanEnd: (details) {
        setState(() {
          selectedPoint = null;
        });
      },
      child: Container(
        decoration:
            BoxDecoration(border: Border.all(color: Colors.black, width: 1)),
        child: CustomPaint(
          painter: PolygonPainter(
            points: widget.points!,
            canvasHeight: canvasHeight,
            canvasWidth: canvasWidth,
            transformationMatrix: Matrix4.identity(),
          ),
          child: Container(),
        ),
      ),
    );
  }
}
