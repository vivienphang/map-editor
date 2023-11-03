import 'package:drawing_app/utils/drawing_canvas.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:ui' as ui;
import 'dart:convert';
import '../models/map_file_data.dart';
import '../utils/polygon_painter.dart';

// Global variables
const double canvasWidth = 500.0;
const double canvasHeight = 600.0;

class ViewOneMapScreen extends StatefulWidget {
  final List<ImageData> maps;
  final String mapId;

  const ViewOneMapScreen({
    Key? key,
    required this.mapId,
    required this.maps,
  }) : super(key: key);

  @override
  _ViewOneMapScreenState createState() => _ViewOneMapScreenState();
}

class _ViewOneMapScreenState extends State<ViewOneMapScreen> {
  // All states
  final _repaintKey = GlobalKey();
  late Map<String, dynamic> mapData;
  List<Offset> points = [];
  Offset? selectedPoint;
  Matrix4 transformationMatrix = Matrix4.identity();
  bool isLoading = true;
  bool _isDrawingEnabled = false;

  @override
  void initState() {
    super.initState();
    _fetchDataById();
  }

  bool pointTapped(Offset tapPosition, Offset point) {
    const double touchRadius = 10.0;
    return (tapPosition - point).distance <= touchRadius;
  }

  Future<void> _fetchDataById() async {
    print('this is mapId: ${widget.mapId}');
    try {
      final response = await http.get(
          Uri.parse('https://map-editor-be.onrender.com/map/${widget.mapId}'));

      if (response.statusCode == 200) {
        final mapDetails = json.decode(response.body);
        final List<dynamic> zoneData = mapDetails['zones'];
        final List<Offset> newPoints = zoneData
            .expand((zone) => zone['P'])
            .map(
                (point) => Offset(point['X'].toDouble(), point['Y'].toDouble()))
            .toList();

        setState(() {
          mapData = mapDetails;
          points = newPoints;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load map');
      }
    } catch (error) {
      print('Error fetching map by ID: $error');
    }
  }

  void _onPointsUpdated(List<Offset>? updatedPoints) {
    if (updatedPoints != null) {
      setState(() {
        points = updatedPoints;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map Details'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: FittedBox(
                child: RepaintBoundary(
                  key: _repaintKey,
                  child: Transform(
                    transform: transformationMatrix,
                    child: Container(
                      constraints: const BoxConstraints(
                        maxWidth: canvasWidth,
                        maxHeight: canvasHeight,
                      ),
                      child: _isDrawingEnabled
                          ? DrawingCanvas(
                              points: points,
                              onPointsUpdated: _onPointsUpdated,
                            )
                          : GestureDetector(
                              onPanDown: (details) {
                                setState(() {
                                  for (var point in points!) {
                                    if (pointTapped(
                                        details.localPosition, point)) {
                                      selectedPoint = point;
                                      break;
                                    }
                                  }
                                });
                              },
                              onPanUpdate: (details) {
                                if (selectedPoint != null) {
                                  setState(() {
                                    int index = points.indexOf(selectedPoint!);
                                    if (index != -1) {
                                      points[index] = details.localPosition;
                                      selectedPoint = details.localPosition;
                                    }
                                  });
                                }
                              },
                              onPanEnd: (details) {
                                setState(() {
                                  selectedPoint = null;
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.black),
                                ),
                                child: CustomPaint(
                                  painter: PolygonPainter(
                                    points: points,
                                    canvasWidth: canvasWidth,
                                    canvasHeight: canvasHeight,
                                    transformationMatrix: transformationMatrix,
                                  ),
                                  child: Container(),
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _isDrawingEnabled = !_isDrawingEnabled;
          });
        },
        child: const Icon(Icons.edit),
      ),
    );
  }
}
