import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/map_file_data.dart'; // replace with your actual path to model

class ViewAllMapsScreen extends StatelessWidget {
  final List<ImageData> maps;

  const ViewAllMapsScreen({Key? key, required this.maps}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('All Maps'),
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
          // You can create a custom card widget for your map data
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
            style: TextStyle(color: Colors.white),
          ),
        ),
        child: Image.memory(
          bytes,
          fit: BoxFit.cover,
        ),
        footer: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              // Handle the tap event
              // For example, navigate to a detail page for this map
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              color: Colors.black54,
              child: Text(
                'Tap to view details',
                style: TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
