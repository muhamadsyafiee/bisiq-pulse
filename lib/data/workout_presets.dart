import '../models/exercise.dart';

const defaultExercises = <Exercise>[
  Exercise(
    name: 'Pushup',
    workoutSeconds: 20,
    restSeconds: 10,
    description: 'Badan lurus. Turun perlahan, tolak dengan terkawal.',
  ),
  Exercise(
    name: 'Diamond Pushup',
    workoutSeconds: 20,
    restSeconds: 10,
    description: 'Rapatkan tangan membentuk berlian di bawah dada.',
  ),
  Exercise(
    name: 'Widearm Pushup',
    workoutSeconds: 20,
    restSeconds: 10,
    description: 'Buka tangan sedikit lebih luas daripada bahu.',
  ),
  Exercise(
    name: 'Chest Squeeze',
    workoutSeconds: 20,
    restSeconds: 10,
    description: 'Tekan kedua tapak tangan di hadapan dada. Terus bernafas.',
  ),
];

class WorkoutTemplate {
  const WorkoutTemplate(this.name, this.description, this.exercises);
  final String name;
  final String description;
  final List<Exercise> exercises;
}

const workoutTemplates = [
  WorkoutTemplate(
    'Upper Body',
    'Fokus dada dan lengan. Empat gerakan klasik.',
    defaultExercises,
  ),
  WorkoutTemplate(
    'Cardio Express',
    'Gerakkan seluruh badan dengan interval pendek.',
    [
      Exercise(name: 'Jumping Jacks', workoutSeconds: 30, restSeconds: 15),
      Exercise(name: 'High Knees', workoutSeconds: 30, restSeconds: 15),
      Exercise(name: 'Mountain Climbers', workoutSeconds: 30, restSeconds: 15),
      Exercise(name: 'Squat', workoutSeconds: 30, restSeconds: 15),
    ],
  ),
  WorkoutTemplate(
    'Regangan Ringkas',
    'Luangkan sedikit masa untuk mobiliti badan.',
    [
      Exercise(name: 'Shoulder Rolls', workoutSeconds: 30, restSeconds: 5),
      Exercise(name: 'Cat-Cow', workoutSeconds: 30, restSeconds: 5),
      Exercise(name: 'Child’s Pose', workoutSeconds: 30, restSeconds: 5),
    ],
  ),
];
