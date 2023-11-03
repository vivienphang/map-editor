import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:drawing_app/screens/view_all_maps.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'package:http/http.dart' as http;
import '../models/map_file_data.dart';
import '../utils/polygon_painter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey _repaintKey = GlobalKey();
  List<Offset?> points = [];
  List<ImageData> maps = [];

  // Fixed canvas dimensions
  static const double canvasWidth = 800.0;
  static const double canvasHeight = 600.0;

  // Define scale value for zoom level
  double _currentScale = 1.0;
  Offset _currentOffset = Offset.zero; // Focal point where user starts scaling
  // Keeping track of scale and translation transformations.
  final Matrix4 _transformationMatrix = Matrix4.identity();

  // selectedPoint: to keep track of the currently dragged point
  Offset? selectedPoint;

  // Function to determine if a point was tapped
  bool pointTapped(Offset potentialTap, Offset? point) {
    return (point != null &&
        (potentialTap - point).distance < 20.0); // 20.0 is the touch radius
  }

  // Function to scale and position the points
  void rescalePoints(
      double oldWidth, double oldHeight, double newWidth, double newHeight) {
    for (int i = 0; i < points.length; i++) {
      if (points[i] != null) {
        double newX = (points[i]!.dx * newWidth) / oldWidth;
        double newY = (points[i]!.dy * newHeight) / oldHeight;
        points[i] = Offset(newX, newY);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    points = [];
    fetchData().then((fetchedMaps) {
      setState(() {
        maps = fetchedMaps;
      });
    });
  }

  Future<void> _showSaveDialog() async {
    String fileName = ''; // to store the name entered by the user

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Save Image"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Enter image details:"),
              const SizedBox(height: 10),
              TextField(
                onChanged: (value) {
                  fileName = value; // updating fileName on each change
                },
                decoration: const InputDecoration(
                  hintText: "Save file name",
                  border: OutlineInputBorder(),
                ),
              ),
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
                // Handle the save image logic here
                if (fileName != null && fileName!.isNotEmpty) {
                  _saveImage(context, fileName!);
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveImage(BuildContext context, String fileName) async {
    String base64String = '';
    RenderRepaintBoundary boundary =
        _repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    //var image = await boundary.toImage(pixelRatio: ui.window.devicePixelRatio);
    var image = await boundary.toImage(pixelRatio: 1.0);
    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData != null) {
      Uint8List pngBytes = byteData.buffer.asUint8List();
      base64String = base64.encode(pngBytes); // assigning base64 string
    }
    // Create the object model using ImageData class
    ImageData data = ImageData(
      name: fileName,
      imageUrl: base64String,
      zones: [
        Zone(points: points.map((e) => Point(x: e!.dx, y: e.dy)).toList())
      ],
    );
    const url = "https://map-editor-be.onrender.com/map";
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        print('Successfully uploaded data to the backend.');
        var responseData = json.decode(response.body);
        var mapId = responseData['id'];
        data = ImageData(id: mapId, name: data.name, imageUrl: data.imageUrl);
      } else {
        print('Failed to upload data. Status code: ${response.statusCode}');
      }
    } catch (error) {
      print('Error uploading data: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      Size canvasSize = const Size(canvasWidth, canvasHeight);

      return Scaffold(
        appBar: AppBar(
          title: const Text('Image Editor'),
          actions: [
            PopupMenuButton<String>(
              onSelected: (String result) async {
                if (result == 'view_all_maps') {
                  showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (BuildContext context) {
                        return FutureBuilder<List<ImageData>>(
                          future:
                              fetchData(), // Your async data fetching operation
                          builder: (BuildContext context,
                              AsyncSnapshot<List<ImageData>> snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              // The future is still working, waiting for data, show the spinner
                              return const AlertDialog(
                                content: Row(
                                  children: [
                                    CircularProgressIndicator(),
                                    SizedBox(width: 10),
                                    Text("Loading..."),
                                  ],
                                ),
                              );
                            } else if (snapshot.connectionState ==
                                ConnectionState.done) {
                              if (snapshot.hasData) {
                                WidgetsBinding.instance
                                    .addPostFrameCallback((_) {
                                  Navigator.of(context)
                                      .pushReplacement(MaterialPageRoute(
                                    builder: (context) =>
                                        ViewAllMapsScreen(maps: snapshot.data!),
                                  ));
                                });
                                return Container();
                              } else if (snapshot.hasError) {
                                Future.delayed(Duration.zero, () {
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (BuildContext context) {
                                      Timer(const Duration(seconds: 3), () {
                                        Navigator.of(context).pop();
                                      });

                                      return const AlertDialog(
                                        title: Text('Error'),
                                        content: Text(
                                            'Error getting maps. Please try again later.'),
                                      );
                                    },
                                  );
                                });
                                return Container();
                              }
                            }
                            // By default, show a loading spinner while the future is still pending
                            return const AlertDialog(
                              content: Row(
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(width: 10),
                                  Text("Loading..."),
                                ],
                              ),
                            );
                          },
                        );
                      });
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'view_all_maps',
                  child: Text('View All Maps'),
                ),
              ],
            ),
          ],
        ),
        body: Center(
          child: FittedBox(
            child: RepaintBoundary(
              key: _repaintKey,
              child: Transform(
                transform: _transformationMatrix,
                child: Container(
                  constraints: const BoxConstraints(
                    maxWidth: canvasWidth,
                    maxHeight: canvasHeight,
                  ),
                  child: Builder(
                    builder: (context) => GestureDetector(
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
                            details.localPosition.dx.clamp(0, canvasWidth),
                            details.localPosition.dy.clamp(0, canvasHeight),
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
                      child: Container(
                        decoration: BoxDecoration(
                            border: Border.all(color: Colors.black, width: 1)),
                        child: CustomPaint(
                          painter: PolygonPainter(
                            points: points,
                            screenSize: canvasSize,
                            transformationMatrix: Matrix4.identity(),
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
              tooltip: 'Clear',
              heroTag: null, // Adding this to avoid Hero tag conflict error
            ),
            const SizedBox(height: 8),
            FloatingActionButton(
              child: const Icon(Icons.save),
              onPressed: _showSaveDialog,
              tooltip: 'Save Image',
              heroTag: null, // Adding this to avoid Hero tag conflict error
            ),
          ],
        ),
      );
    });
  }
}

Future<List<ImageData>> fetchData() async {
  const String url = 'https://map-editor-be.onrender.com/maps';

  try {
    print('fetching data...');
    final response = await http.get(Uri.parse(url));
    print('Response status: ${response.statusCode}');

    if (response.statusCode == 200) {
      List<dynamic> mapsJson = json.decode(response.body);
      List<ImageData> maps =
          mapsJson.map((json) => ImageData.fromJson(json)).toList();
      // This will print the JSON string representation of each ImageData instance in the list.
      for (var map in maps) {
        print(map
            .toString()); // Since toString is overridden, it prints JSON string
      }
      return maps;
    } else {
      throw Exception('Failed to load maps');
    }
  } catch (exception) {
    throw Exception('Failed to load maps');
  }
}
