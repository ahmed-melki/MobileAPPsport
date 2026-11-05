import 'training_models.dart';

TrainingCatalog buildInitialTrainingCatalog() {
  const exercises = <CatalogExercise>[
    CatalogExercise(
      id: 'squat',
      name: 'Squat arrière',
      category: ExerciseCategory.strength,
      equipment: 'Barre + rack',
      muscles: 'Quadri, fessiers, core',
      cue: 'Genoux dans l’axe, thorax haut, descendre sous la parallèle sans perdre le dos.',
      lastPerf: '4 × 6 @ 90 kg',
    ),
    CatalogExercise(
      id: 'bench',
      name: 'Développé couché',
      category: ExerciseCategory.strength,
      equipment: 'Barre + banc',
      muscles: 'Pecs, triceps, deltoïdes',
      cue: 'Omoplates serrées, légère arche, barre au sternum, lockout sans rebond.',
      lastPerf: '4 × 6 @ 52,5 kg',
    ),
    CatalogExercise(
      id: 'deadlift',
      name: 'Soulevé de terre',
      category: ExerciseCategory.strength,
      equipment: 'Barre',
      muscles: 'Chaîne postérieure',
      cue: 'Barre collée aux tibias, latissimus engagés, hanches et épaules ensemble.',
      lastPerf: '3 × 5 @ 110 kg',
    ),
    CatalogExercise(
      id: 'hipthrust',
      name: 'Hip thrust',
      category: ExerciseCategory.strength,
      equipment: 'Barre + banc',
      muscles: 'Fessiers',
      cue: 'Menton rentré, extension hanche complète, 1 s en haut.',
      lastPerf: '3 × 10 @ 80 kg',
    ),
    CatalogExercise(
      id: 'pullup',
      name: 'Tractions',
      category: ExerciseCategory.strength,
      equipment: 'Barre de traction',
      muscles: 'Dos, biceps',
      cue: 'Gainage, poitrine vers la barre, descente contrôlée.',
      lastPerf: '4 × 6 lestées +6 kg',
    ),
    CatalogExercise(
      id: 'pclean',
      name: 'Power clean',
      category: ExerciseCategory.olympic,
      equipment: 'Barre',
      muscles: 'Chaîne complète',
      cue: 'Triple extension, barre proche, réception haute et stable.',
      lastPerf: '5 × 3 @ 50 kg',
    ),
    CatalogExercise(
      id: 'farmer',
      name: 'Farmer carry',
      category: ExerciseCategory.hyrox,
      equipment: 'Kettlebells / handles',
      muscles: 'Grip, core, trapèzes',
      cue: 'Épaules basses, pas court, regard loin.',
      lastPerf: '4 × 40 m @ 2×24 kg',
    ),
    CatalogExercise(
      id: 'wallball',
      name: 'Wall balls',
      category: ExerciseCategory.hyrox,
      equipment: 'Medball 6–9 kg',
      muscles: 'Jambes, épaules',
      cue: 'Squat plein, extension explosive, cible 2,7 m.',
      lastPerf: '3 × 20 @ 6 kg',
    ),
    CatalogExercise(
      id: 'ski',
      name: 'SkiErg',
      category: ExerciseCategory.cardio,
      equipment: 'SkiErg',
      muscles: 'Lats, core, cardio',
      cue: 'Chute du buste, hanches, bras relâchés au retour.',
      lastPerf: '4 × 500 m / 2:08',
    ),
    CatalogExercise(
      id: 'row',
      name: 'Rameur',
      category: ExerciseCategory.cardio,
      equipment: 'Concept2',
      muscles: 'Dos, jambes, cardio',
      cue: 'Jambes → hanches → bras, puis l’inverse.',
      lastPerf: '4 × 500 m / 1:58',
    ),
    CatalogExercise(
      id: 'run',
      name: 'Course fractionnée',
      category: ExerciseCategory.cardio,
      equipment: 'Piste / tapis',
      muscles: 'Endurance',
      cue: 'Cadence haute, relâchement épaules, recover actif.',
      lastPerf: '6 × 400 m @ 1:42',
    ),
    CatalogExercise(
      id: 'deadbug',
      name: 'Dead bug',
      category: ExerciseCategory.core,
      equipment: 'Sol',
      muscles: 'Transverse, anti-extension',
      cue: 'Lombaires collés, expir en éloignant bras/jambe.',
      lastPerf: '3 × 10 / côté',
    ),
    CatalogExercise(
      id: 'couch',
      name: 'Couch stretch',
      category: ExerciseCategory.mobility,
      equipment: 'Mur / banc',
      muscles: 'Fléchisseurs de hanche',
      cue: 'Bassin rétroversé, glute du devant serré.',
      lastPerf: '2 × 90 s / jambe',
    ),
  ];

  const sessions = <WorkoutSession>[
    WorkoutSession(
      id: 'hyrox-s1',
      title: 'S1 · Lower power',
      durationMin: 62,
      focus: 'Squat & hanches',
      exercises: [
        SessionExercise(exerciseId: 'squat', sets: 4, reps: 6, loadKg: 90, restSec: 150, kind: RxKind.load),
        SessionExercise(exerciseId: 'hipthrust', sets: 3, reps: 10, loadKg: 80, restSec: 90, kind: RxKind.load),
        SessionExercise(exerciseId: 'deadlift', sets: 3, reps: 5, loadKg: 100, restSec: 150, kind: RxKind.load),
        SessionExercise(exerciseId: 'deadbug', sets: 3, reps: 10, loadKg: 0, restSec: 45, kind: RxKind.bodyweight),
      ],
    ),
    WorkoutSession(
      id: 'hyrox-s2',
      title: 'S2 · Engine',
      durationMin: 48,
      focus: 'Ski / rameur / course',
      exercises: [
        SessionExercise(exerciseId: 'ski', sets: 4, reps: 500, loadKg: 0, restSec: 90, kind: RxKind.distance, unitNote: 'm'),
        SessionExercise(exerciseId: 'row', sets: 4, reps: 500, loadKg: 0, restSec: 90, kind: RxKind.distance, unitNote: 'm'),
        SessionExercise(exerciseId: 'run', sets: 5, reps: 400, loadKg: 0, restSec: 75, kind: RxKind.distance, unitNote: 'm'),
      ],
    ),
    WorkoutSession(
      id: 'hyrox-s3',
      title: 'S3 · Upper + carries',
      durationMin: 55,
      focus: 'Poussée, tirage, grip',
      exercises: [
        SessionExercise(exerciseId: 'bench', sets: 4, reps: 6, loadKg: 52.5, restSec: 120, kind: RxKind.load),
        SessionExercise(exerciseId: 'pullup', sets: 4, reps: 6, loadKg: 6, restSec: 90, kind: RxKind.load),
        SessionExercise(exerciseId: 'farmer', sets: 4, reps: 40, loadKg: 24, restSec: 75, kind: RxKind.distance, unitNote: 'm'),
        SessionExercise(exerciseId: 'wallball', sets: 3, reps: 20, loadKg: 6, restSec: 60, kind: RxKind.load),
      ],
    ),
    WorkoutSession(
      id: 'hyrox-s4',
      title: 'S4 · Mixed piece',
      durationMin: 40,
      focus: 'Hyrox race pace',
      exercises: [
        SessionExercise(exerciseId: 'wallball', sets: 3, reps: 25, loadKg: 6, restSec: 45, kind: RxKind.load),
        SessionExercise(exerciseId: 'farmer', sets: 3, reps: 50, loadKg: 24, restSec: 60, kind: RxKind.distance, unitNote: 'm'),
        SessionExercise(exerciseId: 'ski', sets: 3, reps: 250, loadKg: 0, restSec: 60, kind: RxKind.distance, unitNote: 'm'),
        SessionExercise(exerciseId: 'couch', sets: 2, reps: 90, loadKg: 0, restSec: 20, kind: RxKind.bodyweight, unitNote: 's'),
      ],
    ),
    WorkoutSession(
      id: 'f5-a',
      title: 'Séance A · Squat / bench',
      durationMin: 50,
      focus: '5×5 force',
      exercises: [
        SessionExercise(exerciseId: 'squat', sets: 5, reps: 5, loadKg: 87.5, restSec: 180, kind: RxKind.load),
        SessionExercise(exerciseId: 'bench', sets: 5, reps: 5, loadKg: 50, restSec: 150, kind: RxKind.load),
        SessionExercise(exerciseId: 'pullup', sets: 4, reps: 8, loadKg: 0, restSec: 90, kind: RxKind.bodyweight),
      ],
    ),
    WorkoutSession(
      id: 'f5-b',
      title: 'Séance B · Deadlift / press',
      durationMin: 52,
      focus: '5×5 force',
      exercises: [
        SessionExercise(exerciseId: 'deadlift', sets: 5, reps: 5, loadKg: 105, restSec: 180, kind: RxKind.load),
        SessionExercise(exerciseId: 'pclean', sets: 5, reps: 3, loadKg: 50, restSec: 120, kind: RxKind.load),
        SessionExercise(exerciseId: 'hipthrust', sets: 3, reps: 8, loadKg: 75, restSec: 90, kind: RxKind.load),
      ],
    ),
    WorkoutSession(
      id: 'express-squat',
      title: 'Express · Squat',
      durationMin: 25,
      focus: 'Top set + back-off',
      exercises: [
        SessionExercise(exerciseId: 'squat', sets: 4, reps: 5, loadKg: 90, restSec: 150, kind: RxKind.load),
      ],
    ),
  ];

  const programs = <TrainingProgram>[
    TrainingProgram(
      id: 'hyrox-engine',
      title: 'Hyrox Engine',
      subtitle: 'Force + stations, 8 semaines pour Lina.',
      weeks: 8,
      daysPerWeek: 4,
      level: 'Avancé',
      sessionIds: ['hyrox-s1', 'hyrox-s2', 'hyrox-s3', 'hyrox-s4'],
    ),
    TrainingProgram(
      id: 'five-five',
      title: 'Force 5×5',
      subtitle: 'A/B, charges lentes, récup généreuse.',
      weeks: 6,
      daysPerWeek: 3,
      level: 'Intermédiaire',
      sessionIds: ['f5-a', 'f5-b'],
    ),
  ];

  final logs = [
    SessionLog(
      date: DateTime(2026, 9, 25),
      sessionTitle: 'S1 · Lower power',
      programTitle: 'Hyrox Engine',
      durationMin: 64,
      volumeKg: 8420,
      highlight: 'Squat 4×6 @ 90 kg',
    ),
    SessionLog(
      date: DateTime(2026, 9, 23),
      sessionTitle: 'S2 · Engine',
      programTitle: 'Hyrox Engine',
      durationMin: 47,
      volumeKg: 0,
      highlight: 'Ski 500 m en 2:06',
    ),
    SessionLog(
      date: DateTime(2026, 9, 21),
      sessionTitle: 'Séance A · Squat / bench',
      programTitle: 'Force 5×5',
      durationMin: 51,
      volumeKg: 6125,
      highlight: 'Bench 5×5 @ 50 kg',
    ),
    SessionLog(
      date: DateTime(2026, 9, 18),
      sessionTitle: 'S3 · Upper + carries',
      programTitle: 'Hyrox Engine',
      durationMin: 56,
      volumeKg: 3180,
      highlight: 'Farmer 4×40 m',
    ),
    SessionLog(
      date: DateTime(2026, 9, 16),
      sessionTitle: 'S4 · Mixed piece',
      programTitle: 'Hyrox Engine',
      durationMin: 39,
      volumeKg: 1260,
      highlight: 'Wall balls 3×25',
    ),
  ];

  const lifts = [
    LiftProgress(
      name: 'Squat arrière',
      unit: 'kg',
      points: [85, 87.5, 90, 90, 92.5, 95, 95, 97.5],
    ),
    LiftProgress(
      name: 'Développé couché',
      unit: 'kg',
      points: [47.5, 50, 50, 52.5, 52.5, 52.5, 55, 55],
    ),
    LiftProgress(
      name: 'Soulevé de terre',
      unit: 'kg',
      points: [100, 102.5, 105, 105, 107.5, 110, 110, 115],
    ),
  ];

  return TrainingCatalog(
    exercises: exercises,
    programs: programs,
    sessions: sessions,
    logs: logs,
    lifts: lifts,
  );
}

WorkoutSession expressSessionFor(String exerciseId) {
  return WorkoutSession(
    id: 'express-$exerciseId',
    title: 'Express',
    durationMin: 20,
    focus: 'Travail ciblé',
    exercises: [
      SessionExercise(
        exerciseId: exerciseId,
        sets: 4,
        reps: 6,
        loadKg: exerciseId == 'ski' || exerciseId == 'row' || exerciseId == 'run' ? 0 : 60,
        restSec: 90,
        kind: exerciseId == 'ski' || exerciseId == 'row' || exerciseId == 'run'
            ? RxKind.distance
            : (exerciseId == 'deadbug' || exerciseId == 'couch' || exerciseId == 'pullup'
                ? RxKind.bodyweight
                : RxKind.load),
        unitNote: exerciseId == 'ski' || exerciseId == 'row' || exerciseId == 'run'
            ? 'm'
            : (exerciseId == 'farmer' ? 'm' : null),
      ),
    ],
  );
}
