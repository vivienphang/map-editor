export 'map_file_data.dart';

class ImageData {
  final String name;
  final String imageUrl;
  final List<Zone> zones;
  final List<dynamic> routes; // placeholder

  ImageData({
    required this.name,
    required this.imageUrl,
    required this.zones,
    required this.routes,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'image_url': imageUrl,
      'zones': zones.map((zone) => zone.toMap()).toList(),
      'routes': routes,
    };
  }
}

class Zone {
  final List<Point> points;
  final bool valid;

  Zone({required this.points, this.valid = true});

  Map<String, dynamic> toMap() {
    return {
      'points': points.map((point) => point.toMap()).toList(),
      'Valid': valid,
    };
  }
}

class Point {
  final double x;
  final double y;

  Point({required this.x, required this.y});

  Map<String, dynamic> toMap() {
    return {
      'x': x,
      'y': y,
    };
  }
}
