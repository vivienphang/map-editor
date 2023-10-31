import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'package:http/http.dart' as http;

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey _repaintKey = GlobalKey();
  List<Offset?> points = [];
  // Define scale value for zoom level
  double _currentScale = 1.0;
  Offset _currentOffset = Offset.zero; // Focal point where user starts scaling
  // Keeping track of scale and translation transformations.
  Matrix4 _transformationMatrix = Matrix4.identity();
  // selectedPoint: to keep track of the currently dragged point
  Offset? selectedPoint;

  // Function to determine if a point was tapped
  bool pointTapped(Offset potentialTap, Offset? point) {
    return (point != null &&
        (potentialTap - point).distance < 20.0); // 20.0 is the touch radius
  }

  @override
  void initState() {
    super.initState();
    points = [];
  }

  Future<void> _saveImage() async {
    RenderRepaintBoundary boundary =
    _repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    var image = await boundary.toImage();
    var byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    var buffer = byteData!.buffer.asUint8List();

    print('Image Captured');
    print('POINTS: $points');

    // Create the object model to send to backend
    Map<String, dynamic> data = {
      'createdAt': DateTime.now().toIso8601String(),
      'points': points.map((e) => {'x': e?.dx, 'y': e?.dy}).toList(),
    };

    print('DATA: $data');

    // PLACEHOLDER: Backend endpoint HTTP POST file
    // final url = http://localhost:8080/upload

    // final response = await http.post(
    //   Uri.parse(url),
    //   headers: {'Content-Type': 'application/json'},
    //   body: json.encode(data),
    // );
    //
    // if (response.statusCode == 200) {
    //   print('Successfully uploaded data to the backend.');
    // } else {
    //   print('Failed to upload data. Status code: ${response.statusCode}');
    // }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width * 0.8;
    double screenHeight = MediaQuery.of(context).size.height * 0.6;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Editor'),
        actions: [
          IconButton(
            icon: Icon(Icons.zoom_in),
            onPressed: () {
              setState(() {
                _currentScale += 0.1; // zoom in by increasing scale factor
                _transformationMatrix = Matrix4.identity()
                  ..translate(_currentOffset.dx, _currentOffset.dy)
                  ..scale(_currentScale);
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.zoom_out),
            onPressed: () {
              setState(() {
                _currentScale -= 0.1; // zoom out by decreasing scale factor
                _transformationMatrix = Matrix4.identity()
                  ..translate(_currentOffset.dx, _currentOffset.dy)
                  ..scale(_currentScale);
              });
            },
          ),
        ],
      ),
      body: Center(
        child: FittedBox(
          child: RepaintBoundary(
            key: _repaintKey,
            child: Transform(
              transform: _transformationMatrix,
              child: SizedBox(
                width: screenWidth,
                height: screenHeight,
                child: Builder(
                  builder: (context) =>
                      GestureDetector(
                        onPanDown: (details) {
                          bool isExistingPoint = false;
                          for (var point in points) {
                            if (pointTapped(details.localPosition, point)) {
                              selectedPoint = point;
                              isExistingPoint = true;
                              break;
                            }
                          }
                          if (!isExistingPoint) {
                            setState(() {
                              points.add(details.localPosition);
                            });
                          }
                        },
                        onPanUpdate: (details) {
                          if (selectedPoint != null) {
                            // Clamp the position within the bounds
                            Offset newPosition = Offset(
                              details.localPosition.dx.clamp(0, screenWidth),
                              details.localPosition.dy.clamp(0, screenHeight),
                            );
                            setState(() {
                              // look for selectedPoint in points list, if not found, it will return -1
                              int index = points.indexOf(selectedPoint);
                              // if it is found, update its index to the new position
                              if (index != -1) {
                                points[index] = newPosition;
                              }
                              selectedPoint =
                                  newPosition; // Update the reference for continuous dragging
                            });
                          }
                        },
                        // When user stops dragging (lifts their finger/ release the mouse)
                        onPanEnd: (details) {
                          selectedPoint = null; // Clear the reference
                        },
                        // onScaleStart: (ScaleStartDetails details) {
                        //   // Store the starting scale and position when the scaling gesture begins
                        //   _currentScale = _transformationMatrix.getMaxScaleOnAxis();
                        //   _currentOffset = details.focalPoint;
                        // },
                        // onScaleUpdate: (ScaleUpdateDetails details) {
                        //   setState(() {
                        //     // Calculate the desired scale. Clamp ensures that the value remains between the given limits
                        //     _currentScale = (_currentScale * details.scale).clamp(1.0, 5.0);
                        //
                        //     // Update the transformation matrix for scale
                        //     _transformationMatrix = Matrix4.identity()
                        //       ..translate(
                        //           details.focalPoint.dx - _currentOffset.dx,
                        //           details.focalPoint.dy - _currentOffset.dy)
                        //       ..scale(_currentScale, _currentScale)
                        //       ..translate(
                        //           -details.focalPoint.dx + _currentOffset.dx,
                        //           -details.focalPoint.dy + _currentOffset.dy);
                        //
                        //     // Reset the current offset to the focal point for continuous scaling
                        //     _currentOffset = details.focalPoint;
                        //   });
                        // },
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.black,
                              width: 1
                            )
                          ),
                          child: CustomPaint(
                            painter: PolygonPainter(points),
                            child: Container(),
                          ),
                        ),
                      ),
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            child: const Icon(Icons.clear),
            onPressed: () {
              setState(() {
                points = [];
              });
            },
            heroTag: null, // Adding this to avoid Hero tag conflict error
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            child: const Icon(Icons.save),
            onPressed: _saveImage,
            heroTag: null, // Adding this to avoid Hero tag conflict error
          ),
        ],
      ),
    );
  }
}

class PolygonPainter extends CustomPainter {
  final List<Offset?> points;

  PolygonPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final linePaint = Paint()
      ..color = Colors.red
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5.0;

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
        canvas.drawLine(points[i]!, points[i + 1]!, linePaint);
      }
    }

    // Connect the last and first points to close the polygon
    if (points.length > 2) {
      if (points.last != null && points.first != null) {
        canvas.drawLine(points.last!, points.first!, linePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
