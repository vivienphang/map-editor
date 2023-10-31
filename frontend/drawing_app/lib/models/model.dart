class Point {
  final double x;
  final double y;

  Point({required this.x, required this.y});

  // Convert a Point into a Map.
  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
    };
  }

  // Convert a Map into a Point.
  factory Point.fromJson(Map<String, dynamic> json) {
    return Point(
      x: json['x'],
      y: json['y'],
    );
  }
}
