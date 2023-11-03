import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:drawing_app/screens/view_all_maps.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'package:http/http.dart' as http;
import '../models/map_file_data.dart';
import '../utils/drawing_canvas.dart';

// Global variables
const double canvasWidth = 500.0;
const double canvasHeight = 600.0;

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // All states
  final GlobalKey _repaintKey = GlobalKey();
  final Matrix4 _transformationMatrix = Matrix4.identity();
  List<Offset>? points = [];
  List<ImageData> maps = [];
  Offset? selectedPoint; // Track current dragged point

  // Function to determine if a point was tapped
  bool pointTapped(Offset potentialTap, Offset? point) {
    return (point != null &&
        (potentialTap - point).distance < 20.0); // 20.0 is the touch radius
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

  void _showSaveDialog() async {
    String fileName = ''; // To store the name entered by the user

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
                  fileName = value; // Updating fileName on each change
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
        Zone(points: points!.map((e) => Point(x: e!.dx, y: e.dy)).toList())
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
      return Scaffold(
        appBar: AppBar(
          title: const Text('Map Editor'),
          actions: [
            PopupMenuButton<String>(
              onSelected: (String result) async {
                if (result == 'view_all_maps') {
                  showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (BuildContext context) {
                        return FutureBuilder<List<ImageData>>(
                          future: fetchData(),
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
                    child: DrawingCanvas(
                      points: points,
                      onPointsUpdated: (updatedPoints) {
                        setState(() {
                          points = updatedPoints;
                        });
                      },
                    )),
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
                  points = [];
                });
              },
              tooltip: 'Clear',
              heroTag: null,
              child: const Icon(Icons.clear),
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
      );
    });
  }
}

Future<List<ImageData>> fetchData() async {
  const String url = 'https://map-editor-be.onrender.com/maps';

  try {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      List<dynamic> mapsJson = json.decode(response.body);
      List<ImageData> maps =
          mapsJson.map((json) => ImageData.fromJson(json)).toList();
      return maps;
    } else {
      throw Exception('Failed to load maps');
    }
  } catch (exception) {
    throw Exception('Failed to load maps');
  }
}
