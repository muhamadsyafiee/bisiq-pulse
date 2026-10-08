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
}
