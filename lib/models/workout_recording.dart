import 'camera_display_settings.dart';
import 'workout_plan.dart';

class WorkoutRecording {
  const WorkoutRecording({
    required this.id,
    required this.plan,
    required this.createdAt,
    this.display,
    this.languageCode = 'ms',
    this.watermarked = true,
    this.exported = false,
    this.gallerySaved = false,
  });
  final String id;
  final WorkoutPlan plan;
  final DateTime createdAt;
  final CameraDisplaySettings? display;
  final String languageCode;
  final bool watermarked;
  final bool exported;
  final bool gallerySaved;

  WorkoutRecording copyWith({bool? exported, bool? gallerySaved}) =>
      WorkoutRecording(
        id: id,
        plan: plan,
        createdAt: createdAt,
        display: display,
        languageCode: languageCode,
        watermarked: watermarked,
        exported: exported ?? this.exported,
        gallerySaved: gallerySaved ?? this.gallerySaved,
      );
  Map<String, Object?> toJson() => {
    'id': id,
    'plan': plan.toJson(),
    'createdAt': createdAt.toIso8601String(),
    if (display != null) 'display': display!.toJson(),
    'languageCode': languageCode,
    'watermarked': watermarked,
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
      languageCode:
          const [
            'ms',
            'en',
            'id',
            'zh',
            'ta',
            'ar',
          ].contains(json['languageCode'])
          ? json['languageCode'] as String
          : 'ms',
      // Pre-Pro recordings preserve the original export appearance.
      watermarked: json['watermarked'] == true,
      exported: json['exported'] == true,
      gallerySaved: json['gallerySaved'] == true,
    );
  }
}
