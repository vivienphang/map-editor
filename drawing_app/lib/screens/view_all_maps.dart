import 'dart:convert';
import 'dart:typed_data';
import 'package:drawing_app/screens/view_one_map.dart';
import 'package:flutter/material.dart';
import '../models/map_file_data.dart';

class ViewAllMapsScreen extends StatelessWidget {
  final List<ImageData> maps;
  final String mapId = "";

  const ViewAllMapsScreen({Key? key, required this.maps}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Maps'),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // Number of columns
          crossAxisSpacing: 8, // Horizontal space between cards
          mainAxisSpacing: 8, // Vertical space between cards
          childAspectRatio: 1 / 1, // Aspect ratio of the cards
        ),
        itemCount: maps.length,
        itemBuilder: (context, index) {
          return _buildMapCard(context, maps[index]);
        },
      ),
    );
  }

  Widget _buildMapCard(BuildContext context, ImageData mapData) {
    // Decoding the base64 string to get the image
    final Uint8List bytes = base64.decode(mapData.imageUrl);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: GridTile(
        header: Container(
          padding: const EdgeInsets.all(8),
          color: Colors.black54,
          child: Text(
            mapData.name,
            //'ID: ${mapData.id}',
            style: TextStyle(color: Colors.white),
          ),
        ),
        footer: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              // TODO: Navigate to individual map
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => ViewOneMapScreen(
                          mapId: mapData.id!,
                          maps: maps,
                        )),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              color: Colors.black54,
              child: const Text(
                'Tap to view details',
                style: TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
        child: Image.memory(
          bytes,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
