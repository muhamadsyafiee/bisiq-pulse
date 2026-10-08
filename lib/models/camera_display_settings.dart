/// Position within the available travel area of the video, independent of
/// screen size. The complete panel stays inside a 2% safe margin.
class CameraDisplaySettings {
  const CameraDisplaySettings({
    this.x = .5,
    this.y = .92,
    this.transparent = false,
  });
  final double x;
  final double y;
  final bool transparent;
  static const panelWidth = .84;
  static const panelHeightRatio = .43;
  static const margin = .02;

  CameraDisplaySettings copyWith({double? x, double? y, bool? transparent}) =>
      CameraDisplaySettings(
        x: (x ?? this.x).clamp(0.0, 1.0),
        y: (y ?? this.y).clamp(0.0, 1.0),
        transparent: transparent ?? this.transparent,
      );
  Map<String, Object> toJson() => {'x': x, 'y': y, 'transparent': transparent};
  factory CameraDisplaySettings.fromJson(Map<String, dynamic> json) {
    double position(String key, double fallback) {
      final value = json[key];
      return value is num && value.isFinite
          ? value.toDouble().clamp(0.0, 1.0)
          : fallback;
    }

    return CameraDisplaySettings(
      x: position('x', .5),
      y: position('y', .92),
      transparent: json['transparent'] == true,
    );
  }
}
