import 'profile_models.dart';

const catalogSports = [
  'Hyrox',
  'Force',
  'Course',
  'Mobilité',
  'Boxe',
  'Natation',
  'Vélo',
  'Yoga',
];

ProfileBundle buildInitialProfileBundle() {
  final measurements = [
    BodySnapshot(
      date: DateTime(2026, 9, 22),
      weightKg: 66.4,
      chestCm: 88,
      waistCm: 71,
      hipsCm: 94,
      armCm: 29.0,
      thighCm: 54.5,
    ),
    BodySnapshot(
      date: DateTime(2026, 9, 8),
      weightKg: 66.9,
      chestCm: 88,
      waistCm: 72,
      hipsCm: 94.5,
      armCm: 28.8,
      thighCm: 54.8,
    ),
    BodySnapshot(
      date: DateTime(2026, 8, 25),
      weightKg: 67.3,
      chestCm: 87.5,
      waistCm: 72.5,
      hipsCm: 95,
      armCm: 28.5,
      thighCm: 55.0,
    ),
    BodySnapshot(
      date: DateTime(2026, 8, 11),
      weightKg: 67.8,
      chestCm: 87.5,
      waistCm: 73,
      hipsCm: 95,
      armCm: 28.5,
      thighCm: 55.2,
    ),
    BodySnapshot(
      date: DateTime(2026, 7, 28),
      weightKg: 68.1,
      chestCm: 87,
      waistCm: 73.5,
      hipsCm: 95.5,
      armCm: 28.2,
      thighCm: 55.5,
    ),
    BodySnapshot(
      date: DateTime(2026, 7, 14),
      weightKg: 68.4,
      chestCm: 87,
      waistCm: 74,
      hipsCm: 96,
      armCm: 28.0,
      thighCm: 55.8,
    ),
  ];

  final activity = [
    ActivityWeek(start: DateTime(2026, 8, 4), sessions: 3, minutes: 165, kcal: 1420),
    ActivityWeek(start: DateTime(2026, 8, 11), sessions: 4, minutes: 210, kcal: 1680),
    ActivityWeek(start: DateTime(2026, 8, 18), sessions: 5, minutes: 248, kcal: 1910),
    ActivityWeek(start: DateTime(2026, 8, 25), sessions: 4, minutes: 198, kcal: 1590),
    ActivityWeek(start: DateTime(2026, 9, 1), sessions: 6, minutes: 312, kcal: 2240),
    ActivityWeek(start: DateTime(2026, 9, 8), sessions: 5, minutes: 276, kcal: 2080),
    ActivityWeek(start: DateTime(2026, 9, 15), sessions: 5, minutes: 264, kcal: 2010),
    ActivityWeek(start: DateTime(2026, 9, 22), sessions: 6, minutes: 301, kcal: 2190),
  ];

  return ProfileBundle(
    profile: SportProfile(
      firstName: 'Lina',
      lastName: 'Moreau',
      city: 'Lyon',
      age: 28,
      heightCm: 168,
      bio:
          'Hyrox et force, 5 séances par semaine. Je veux tenir un 10 km sous 50 min sans casser mes perfs de squat.',
      email: 'lina.moreau@apex.app',
      level: SportLevel.advanced,
      sports: {'Hyrox', 'Force', 'Course'},
      memberSince: 'mars 2024',
    ),
    goals: const [
      SportGoal(
        kind: GoalKind.endurance,
        detail: 'Tenir le rythme sur un 10 km, sans exploser au km 7.',
        target: '10 km < 50 min',
        deadline: 'nov. 2026',
        progress: 0.74,
        active: true,
        primary: true,
      ),
      SportGoal(
        kind: GoalKind.weightLoss,
        detail: 'Descendre en douceur, garder la force sur les composés.',
        target: '64,0 kg',
        deadline: 'déc. 2026',
        progress: 0.58,
        active: true,
        primary: false,
      ),
      SportGoal(
        kind: GoalKind.fitness,
        detail: 'Ancrer 5 séances, sommeil et mobilité du lundi.',
        target: '5 séances / sem.',
        deadline: 'continu',
        progress: 0.82,
        active: true,
        primary: false,
      ),
      SportGoal(
        kind: GoalKind.massGain,
        detail: 'Cycle hypertrophie off-season — en pause pour l’instant.',
        target: '+3 kg lean',
        deadline: 'printemps 2027',
        progress: 0.12,
        active: false,
        primary: false,
      ),
    ],
    measurements: measurements,
    activity: activity,
  );
}
