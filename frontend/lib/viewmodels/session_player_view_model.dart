import 'dart:async';

import '../core/api/api_client.dart';
import '../data/training_models.dart';
import 'base_view_model.dart';

class LiveSet {
  LiveSet({required this.reps, required this.loadKg});
  int reps;
  double loadKg;
  bool done = false;
}

/// Live workout: current exercise/set, rest timer, adjustments, saving the log.
class SessionPlayerViewModel extends BaseViewModel {
  SessionPlayerViewModel({
    required this.catalog,
    required this.session,
    required this.programTitle,
    required Future<SessionLog> Function(List<Map<String, dynamic>> sets) save,
  }) : _save = save {
    sets = [
      for (final block in session.exercises) List.generate(block.sets, (_) => LiveSet(reps: block.reps, loadKg: block.loadKg)),
    ];
  }

  final TrainingCatalog catalog;
  final WorkoutSession session;
  final String programTitle;
  final Future<SessionLog> Function(List<Map<String, dynamic>> sets) _save;

  late final List<List<LiveSet>> sets;
  int exerciseIndex = 0;
  int setIndex = 0;
  bool resting = false;
  int restLeft = 0;
  Timer? _timer;

  SessionExercise get rx => session.exercises[exerciseIndex];
  CatalogExercise get exercise => catalog.exerciseById(rx.exerciseId);
  LiveSet get current => sets[exerciseIndex][setIndex];

  bool get isTimed => rx.unitNote == 's';
  bool get showLoad => rx.kind == RxKind.load || (rx.kind == RxKind.distance && rx.loadKg > 0);
  double get progress => (exerciseIndex + (setIndex / rx.sets)) / session.exercises.length;

  String get repsLabel => switch (rx.kind) {
        RxKind.distance => 'Distance (${rx.unitNote ?? 'm'})',
        RxKind.bodyweight when isTimed => 'Secondes',
        _ => 'Répétitions',
      };

  String get loadLabel => rx.kind == RxKind.distance ? 'Charge portée (kg)' : 'Charge (kg)';

  String get repsValue => rx.kind == RxKind.distance ? '${current.reps} ${rx.unitNote ?? 'm'}' : (isTimed ? '${current.reps} s' : '${current.reps}');

  String get loadValue => current.loadKg == current.loadKg.roundToDouble() ? '${current.loadKg.round()}' : current.loadKg.toStringAsFixed(1);

  int get _repsStep => rx.kind == RxKind.distance ? 50 : (isTimed ? 5 : 1);

  void adjustReps(int direction) {
    current.reps = (current.reps + direction * _repsStep).clamp(1, 20000);
    notify();
  }

  void adjustLoad(double delta) {
    current.loadKg = (current.loadKg + delta).clamp(0, 400).toDouble();
    notify();
  }

  /// Returns true when the whole session is done (the View then calls [finish]).
  bool completeSet() {
    _timer?.cancel();
    current.done = true;
    final lastSet = setIndex >= rx.sets - 1;
    final lastExercise = exerciseIndex >= session.exercises.length - 1;
    if (lastSet && lastExercise) {
      notify();
      return true;
    }
    if (!lastSet) {
      resting = true;
      restLeft = rx.restSec;
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (restLeft <= 1) {
          t.cancel();
          resting = false;
          setIndex += 1;
        } else {
          restLeft -= 1;
        }
        notify();
      });
    } else {
      exerciseIndex += 1;
      setIndex = 0;
      resting = false;
    }
    notify();
    return false;
  }

  void skipRest() {
    _timer?.cancel();
    resting = false;
    if (setIndex < rx.sets - 1) setIndex += 1;
    notify();
  }

  List<Map<String, dynamic>> _payload() => [
        for (var e = 0; e < session.exercises.length; e++)
          for (var i = 0; i < sets[e].length; i++)
            {
              'exerciseId': session.exercises[e].exerciseId,
              'setNumber': i + 1,
              'reps': sets[e][i].reps,
              'loadKg': sets[e][i].loadKg,
              'kind': session.exercises[e].kind.name,
              if (session.exercises[e].unitNote != null) 'unitNote': session.exercises[e].unitNote,
            },
      ];

  /// Saves the log; returns it on success (null + [error] on failure).
  Future<SessionLog?> finish() async {
    _timer?.cancel();
    SessionLog? saved;
    await guard(() async => saved = await _save(_payload()), errorMessage: (ApiException e) => e.message);
    return saved;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
