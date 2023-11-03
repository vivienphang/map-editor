import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:drawing_app/utils/drawing_canvas.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
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
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
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

  Future<void> _showSaveDialog() async {
    String currentMapName = mapData['name'] ?? 'Map File';

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Are you sure you want to save updated map?"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text("File name: $currentMapName"),
              ),
              const SizedBox(height: 10),
            ],
          ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text("Save Image"),
              onPressed: () {
                _saveImage(context);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveImage(BuildContext context) async {
    String base64String = '';
    RenderRepaintBoundary boundary =
        _repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    var image = await boundary.toImage(pixelRatio: 1.0);
    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData != null) {
      Uint8List pngBytes = byteData.buffer.asUint8List();
      base64String = base64.encode(pngBytes); // assigning base64 string
    }
    // Create the zones object
    List<Zone> zones = [
      Zone(points: points.map((e) => Point(x: e.dx, y: e.dy)).toList()),
    ];
    ImageData data = ImageData(
      name: mapData['name'],
      imageUrl: base64String,
      zones: zones,
    );

    String url = 'https://map-editor-be.onrender.com/map/${widget.mapId}';
    try {
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        print('Successfully updated data to the backend.');
        scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(
            content: Text('Map updated successfully!'),
            duration: Duration(seconds: 5),
          ),
        );
        Future.delayed(const Duration(seconds: 5)).then((_) {
          Navigator.of(context).pop();
        });
      } else {
        print('Failed to upload data. Status code: ${response.statusCode}');
      }
    } catch (error) {
      print('Error uploading data: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: scaffoldMessengerKey,
      child: Scaffold(
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
                                      int index =
                                          points.indexOf(selectedPoint!);
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
                                      transformationMatrix:
                                          transformationMatrix,
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
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
              onPressed: () {
                setState(() {
                  _isDrawingEnabled = !_isDrawingEnabled;
                });
              },
              tooltip: 'Edit map',
              child: const Icon(Icons.edit),
            ),
            const SizedBox(height: 8),
            FloatingActionButton(
              onPressed: _showSaveDialog,
              tooltip: 'Save Image',
              heroTag: null,
              child: const Icon(Icons.save),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
