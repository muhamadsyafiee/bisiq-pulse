import 'camera_display_settings.dart';
import 'workout_plan.dart';

class WorkoutRecording {
  const WorkoutRecording({
    required this.id,
    required this.plan,
    required this.createdAt,
    this.display,
    this.exported = false,
    this.gallerySaved = false,
  });
  final String id;
  final WorkoutPlan plan;
  final DateTime createdAt;
  final CameraDisplaySettings? display;
  final bool exported;
  final bool gallerySaved;

  WorkoutRecording copyWith({bool? exported, bool? gallerySaved}) =>
      WorkoutRecording(
        id: id,
        plan: plan,
        createdAt: createdAt,
        display: display,
        exported: exported ?? this.exported,
        gallerySaved: gallerySaved ?? this.gallerySaved,
      );
  Map<String, Object?> toJson() => {
    'id': id,
    'plan': plan.toJson(),
    'createdAt': createdAt.toIso8601String(),
    if (display != null) 'display': display!.toJson(),
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
      display: json['display'] is Map
          ? CameraDisplaySettings.fromJson(
              Map<String, dynamic>.from(json['display'] as Map),
            )
          : null,
      exported: json['exported'] == true,
      gallerySaved: json['gallerySaved'] == true,
    );
  }
}
