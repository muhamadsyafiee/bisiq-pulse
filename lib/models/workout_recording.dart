import 'workout_plan.dart';

class WorkoutRecording {
  const WorkoutRecording({
    required this.id,
    required this.plan,
    required this.createdAt,
    this.exported = false,
    this.gallerySaved = false,
  });
  final String id;
  final WorkoutPlan plan;
  final DateTime createdAt;
  final bool exported;
  final bool gallerySaved;

  WorkoutRecording copyWith({bool? exported, bool? gallerySaved}) =>
      WorkoutRecording(
        id: id,
        plan: plan,
        createdAt: createdAt,
        exported: exported ?? this.exported,
        gallerySaved: gallerySaved ?? this.gallerySaved,
      );
  Map<String, Object?> toJson() => {
    'id': id,
    'plan': plan.toJson(),
    'createdAt': createdAt.toIso8601String(),
    'exported': exported,
    'gallerySaved': gallerySaved,
  };
  factory WorkoutRecording.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    if (!RegExp(r'^[a-zA-Z0-9-]+$').hasMatch(id)) {
      throw const FormatException('Invalid recording id');
    }
    return WorkoutRecording(
      id: id,
      plan: WorkoutPlan.fromJson(
        Map<String, dynamic>.from(json['plan'] as Map),
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      exported: json['exported'] == true,
      gallerySaved: json['gallerySaved'] == true,
    );
  }
}
