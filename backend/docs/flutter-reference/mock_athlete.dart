class MockAthlete {
  const MockAthlete({
    required this.firstName,
    required this.lastName,
    required this.sport,
    required this.level,
    required this.weeklySessions,
    required this.streakDays,
    required this.readiness,
  });

  final String firstName;
  final String lastName;
  final String sport;
  final String level;
  final int weeklySessions;
  final int streakDays;
  final int readiness;

  String get initials => '${firstName[0]}${lastName[0]}';
  String get fullName => '$firstName $lastName';
}

const mockAthlete = MockAthlete(
  firstName: 'Lina',
  lastName: 'Moreau',
  sport: 'Hyrox / Force',
  level: 'Avancé',
  weeklySessions: 5,
  streakDays: 12,
  readiness: 86,
);
