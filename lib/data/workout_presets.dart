import '../l10n/app_strings.dart';
import '../models/workout_plan.dart';
import '../models/exercise.dart';

const defaultExercises = <Exercise>[
  Exercise(
    name: 'Pushup',
    nameKey: 'pushup',
    workoutSeconds: 20,
    restSeconds: 10,
    description: 'Badan lurus. Turun perlahan, tolak dengan terkawal.',
    descriptionKey: 'pushupDescription',
  ),
  Exercise(
    name: 'Diamond Pushup',
    nameKey: 'diamondPushup',
    workoutSeconds: 20,
    restSeconds: 10,
    description: 'Rapatkan tangan membentuk berlian di bawah dada.',
    descriptionKey: 'diamondDescription',
  ),
  Exercise(
    name: 'Widearm Pushup',
    nameKey: 'widePushup',
    workoutSeconds: 20,
    restSeconds: 10,
    description: 'Buka tangan sedikit lebih luas daripada bahu.',
    descriptionKey: 'wideDescription',
  ),
  Exercise(
    name: 'Chest Squeeze',
    nameKey: 'chestSqueeze',
    workoutSeconds: 20,
    restSeconds: 10,
    description: 'Tekan kedua tapak tangan di hadapan dada. Terus bernafas.',
    descriptionKey: 'chestDescription',
  ),
];

class WorkoutTemplate {
  const WorkoutTemplate(
    this.name,
    this.description,
    this.exercises,
    this.nameKey,
    this.descriptionKey,
  );
  final String nameKey, descriptionKey;
  WorkoutTemplate localized(AppStrings s) => WorkoutTemplate(
    s.text(nameKey),
    s.text(descriptionKey),
    exercises.map((e) => e.localized(s)).toList(),
    nameKey,
    descriptionKey,
  );
  final String name;
  final String description;
  final List<Exercise> exercises;
}

const workoutTemplates = [
  WorkoutTemplate(
    'Upper Body',
    'Fokus dada dan lengan. Empat gerakan klasik.',
    defaultExercises,
    'upperBody',
    'upperDescription',
  ),
  WorkoutTemplate(
    'Cardio Express',
    'Gerakkan seluruh badan dengan interval pendek.',
    [
      Exercise(
        name: 'Jumping Jacks',
        nameKey: 'jumpingJacks',
        workoutSeconds: 30,
        restSeconds: 15,
      ),
      Exercise(
        name: 'High Knees',
        nameKey: 'highKnees',
        workoutSeconds: 30,
        restSeconds: 15,
      ),
      Exercise(
        name: 'Mountain Climbers',
        nameKey: 'mountainClimbers',
        workoutSeconds: 30,
        restSeconds: 15,
      ),
      Exercise(
        name: 'Squat',
        nameKey: 'squat',
        workoutSeconds: 30,
        restSeconds: 15,
      ),
    ],
    'cardio',
    'cardioDescription',
  ),
  WorkoutTemplate(
    'Regangan Ringkas',
    'Luangkan sedikit masa untuk mobiliti badan.',
    [
      Exercise(
        name: 'Shoulder Rolls',
        nameKey: 'shoulderRolls',
        workoutSeconds: 30,
        restSeconds: 5,
      ),
      Exercise(
        name: 'Cat-Cow',
        nameKey: 'catCow',
        workoutSeconds: 30,
        restSeconds: 5,
      ),
      Exercise(
        name: 'Child’s Pose',
        nameKey: 'childPose',
        workoutSeconds: 30,
        restSeconds: 5,
      ),
    ],
    'stretch',
    'stretchDescription',
  ),
];

// Upgrade only an exact, untouched legacy template. Custom names/notes are not
// translated by guessing; newly edited fields lose their localization key.
WorkoutPlan tagLegacyTemplate(WorkoutPlan plan) {
  if (plan.nameKey != null) return plan;
  for (final template in workoutTemplates) {
    if (plan.name != template.name ||
        plan.exercises.length != template.exercises.length) {
      continue;
    }
    var exact = true;
    for (var i = 0; i < plan.exercises.length; i++) {
      final a = plan.exercises[i], b = template.exercises[i];
      if (a.name != b.name ||
          a.description != b.description ||
          a.workoutSeconds != b.workoutSeconds ||
          a.restSeconds != b.restSeconds ||
          a.assetPath != b.assetPath) {
        exact = false;
      }
    }
    if (exact) {
      return WorkoutPlan(
        id: plan.id,
        name: plan.name,
        nameKey: template.nameKey,
        exercises: template.exercises,
      );
    }
  }
  return plan;
}
