// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:flutter_map_dragmarker/flutter_map_dragmarker.dart';
// import 'package:latlong2/latlong.dart';
//
// class EditImageScreen extends StatefulWidget {
//   const EditImageScreen({Key? key, required this.selectedImage})
//       : super(key: key);
//
//   final String selectedImage;
//
//   @override
//   State<EditImageScreen> createState() => _EditImageScreenState();
// }
//
// class _EditImageScreenState extends State<EditImageScreen> {
//   final MapController _mapController = MapController();
//   final List<Marker> _markers = [];
//
//   void _addMarker(LatLng latLng) {
//     setState(() {
//       _markers.add(
//         Marker(
//           width: 80.0,
//           height: 80.0,
//           point: latLng,
//           builder: (ctx) => const Icon(Icons.pin_drop, color: Colors.red),
//         ),
//       );
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Edit Image')),
//       body: FlutterMap(
//         mapController: _mapController,
//         options: MapOptions(
//           center: LatLng(0, 0), // Center of the image
//           zoom: 1.0, // Adjust this as needed
//         ),
//       ),
//       layers: [
//         ImageLayerOptions(imageProvider: FileImage(File(widget.selectedImage))), // Displaying the full image
//         MarkerLayerOptions(markers: _markers),
//         // DragMarkerPluginOptions isn't directly compatible with ImageLayerOptions
//         // We might need to implement custom logic for draggable markers if needed
//       ],
//     )
//     ,
//     );
//   }
// }
