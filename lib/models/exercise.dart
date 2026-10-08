/// A workout interval. Rest follows this exercise, except at the end of a set.
class Exercise {
  const Exercise({
    required this.name,
    required this.workoutSeconds,
    required this.restSeconds,
    this.assetPath,
    this.description = '',
  }) : assert(workoutSeconds > 0),
       assert(restSeconds >= 0);

  final String name;
  final int workoutSeconds;
  final int restSeconds;
  final String? assetPath;
  final String description;

  Map<String, Object?> toJson() => {
    'name': name,
    'workoutSeconds': workoutSeconds,
    'restSeconds': restSeconds,
    'assetPath': assetPath,
    'description': description,
  };

  factory Exercise.fromJson(Map<String, dynamic> json) {
    final name = json['name'];
    final workout = json['workoutSeconds'];
    final rest = json['restSeconds'];
    final description = json['description'];
    final asset = json['assetPath'];
    if (name is! String ||
        name.trim().isEmpty ||
        workout is! int ||
        workout <= 0 ||
        rest is! int ||
        rest < 0 ||
        (description != null && description is! String) ||
        (asset != null && asset is! String)) {
      throw const FormatException('Invalid exercise');
    }
    return Exercise(
      name: name,
      workoutSeconds: workout,
      restSeconds: rest,
      description: description as String? ?? '',
      assetPath: asset as String?,
    );
  }
}
