// import 'dart:convert';
// import 'dart:ui';
// import 'package:flutter/foundation.dart';
// import 'package:http/http.dart' as http;
//
// import '../models/map_file_data.dart'; // Importing the required model.
//
// class ImageDataProvider with ChangeNotifier {
//   ImageData? _imageData;
//   final String url = "https://map-editor-be.onrender.com/map";
//
//   ImageData? get imageData => _imageData;
//
//   Future<void> saveImage(
//       String fileName, Uint8List buffer, List<Offset?> points) async {
//     ImageData data = ImageData(
//       name: fileName,
//       imageUrl: "",
//       zones: [
//         Zone(points: points.map((e) => Point(x: e!.dx, y: e!.dy)).toList())
//       ],
//       routes: [],
//     );
//
//     try {
//       final response = await http.post(
//         Uri.parse(url),
//         headers: {'Content-Type': 'application/json'},
//         body: json.encode(data),
//       );
//
//       if (response.statusCode == 200) {
//         print('Successfully uploaded data to the backend.');
//         // Here, you can set the _imageData if the API returns the saved data.
//         // _imageData = ImageData.fromJSON(json.decode(response.body));
//         // notifyListeners(); // Notify all the listeners about the data change.
//       } else {
//         print('Failed to upload data. Status code: ${response.statusCode}');
//       }
//     } catch (error) {
//       print('Error uploading data: $error');
//     }
//   }
// }
