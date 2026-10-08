import '../l10n/app_strings.dart';
import 'exercise.dart';

/// A saved routine, independent of an individual timer session.
class WorkoutPlan {
  WorkoutPlan({
    required this.id,
    required this.name,
    this.nameKey,
    required List<Exercise> exercises,
  }) : exercises = List.unmodifiable(exercises) {
    if (id.isEmpty ||
        name.trim().isEmpty ||
        exercises.isEmpty ||
        exercises.any(
          (e) =>
              e.name.trim().isEmpty ||
              e.workoutSeconds <= 0 ||
              e.restSeconds < 0,
        )) {
      throw ArgumentError('A routine needs a name and valid exercises.');
    }
  }

  final String id;
  final String name;
  final String? nameKey;
  String displayName(AppStrings s) => nameKey == null ? name : s.text(nameKey!);
  WorkoutPlan localized(AppStrings s) => WorkoutPlan(
    id: id,
    name: displayName(s),
    nameKey: nameKey,
    exercises: exercises.map((e) => e.localized(s)).toList(),
  );
  final List<Exercise> exercises;

  int get totalSeconds => exercises.asMap().entries.fold(
    0,
    (sum, entry) =>
        sum +
        entry.value.workoutSeconds +
        (entry.key == exercises.length - 1 ? 0 : entry.value.restSeconds),
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    if (nameKey != null) 'nameKey': nameKey,
    'exercises': exercises.map((e) => e.toJson()).toList(),
  };

  factory WorkoutPlan.fromJson(Map<String, dynamic> json) {
    if (json['id'] is! String ||
        json['name'] is! String ||
        json['exercises'] is! List) {
      throw const FormatException('Invalid routine');
    }
    return WorkoutPlan(
      id: json['id'] as String,
      name: json['name'] as String,
      nameKey: json['nameKey'] as String?,
      exercises: (json['exercises'] as List)
          .map((e) => Exercise.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}
