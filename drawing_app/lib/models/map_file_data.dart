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

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'image_url': imageUrl,
      'zones': zones.map((zone) => zone.toJson()).toList(),
      'routes': routes,
    };
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
}

class Point {
  final double x;
  final double y;

  Point({required this.x, required this.y});

  Map<String, dynamic> toJson() {
    return {
      'X': x,
      'Y': y,
    };
  }
}
