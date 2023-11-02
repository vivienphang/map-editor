import 'dart:convert';

export 'map_file_data.dart';

class ImageData {
  final String name;
  final String imageUrl;
  final List<Zone>? zones;
  final List<dynamic>? routes; // placeholder

  ImageData({
    required this.name,
    required this.imageUrl,
    this.zones,
    this.routes,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'image_url': imageUrl,
      'zones': zones?.map((zone) => zone.toJson()).toList(),
      'routes': routes,
    };
  }

  factory ImageData.fromJson(Map<String, dynamic> json) {
    return ImageData(
      name: json['name'],
      imageUrl: json['image_url'],
      zones: json['zones'] != null
          ? (json['zones'] as List)
              .map((zoneJson) => Zone.fromJson(zoneJson))
              .toList()
          : null,
      routes: json['routes'], // Assuming 'routes' is directly usable
    );
  }
  // This will use the toJson method to create a string representation
  @override
  String toString() {
    return json.encode(toJson());
  }
}

class Zone {
  final List<Point> points;
  final bool valid;

  Zone({required this.points, this.valid = true});

  Map<String, dynamic> toJson() {
    return {
      'P': points.map((point) => point.toJson()).toList(),
      'Valid': valid,
    };
  }

  factory Zone.fromJson(Map<String, dynamic> json) {
    return Zone(
      points: (json['P'] as List)
          .map((pointJson) => Point.fromJson(pointJson))
          .toList(),
      valid: json['Valid'] ?? true,
    );
  }
}

class Point {
  final double x;
  final double y;

  Point({required this.x, required this.y});

  // toJson converts Dart object into JSON
  Map<String, dynamic> toJson() {
    return {
      'X': x,
      'Y': y,
    };
  }

  // fromJson creates instance of the class from JSON
  factory Point.fromJson(Map<String, dynamic> json) {
    return Point(
      x: json['X'].toDouble(),
      y: json['Y'].toDouble(),
    );
  }
}
