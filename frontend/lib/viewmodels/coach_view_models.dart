import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/api/api_client.dart';
import '../core/api/nutrition_coach_repositories.dart';
import '../core/api/repositories.dart';
import '../data/ai_coach_models.dart';
import '../data/nutrition_models.dart';
import '../data/training_models.dart';
import 'base_view_model.dart';

/// Coach Apex: plan of the day + water counter.
class CoachViewModel extends BaseViewModel {
  CoachViewModel(this._coach, this._training);
  final CoachRepository _coach;
  final TrainingRepository _training;
  static const _storage = FlutterSecureStorage();

  DailyPlan? _plan;
  bool _loading = true;
  bool _starting = false;
  int _glasses = 0;

  DailyPlan? get plan => _plan;
  bool get loading => _loading;
  bool get starting => _starting;
  int get glasses => _glasses;
  double get waterLiters => _glasses * 0.25;
  bool get waterDone => _plan != null && waterLiters >= _plan!.waterLiters;

  String get _waterKey => 'apex.water.${apiDate(DateTime.now())}';

  Future<void> load() async {
    _loading = _plan == null;
    notify();
    await guard(() async {
      _plan = await _coach.today();
      try {
        _glasses = int.tryParse(await _storage.read(key: _waterKey) ?? '') ?? 0;
      } catch (_) {}
    });
    _loading = false;
    notify();
  }

  Future<void> addGlass(int delta) async {
    _glasses = (_glasses + delta).clamp(0, 20);
    notify();
    try {
      await _storage.write(key: _waterKey, value: '$_glasses');
    } catch (_) {}
  }

  /// Loads the catalog needed by the session player.
  Future<TrainingCatalog?> prepareWorkout() async {
    _starting = true;
    notify();
    try {
      return await _training.loadCatalog();
    } on ApiException catch (e) {
      setError(e.message);
      return null;
    } finally {
      _starting = false;
      notify();
    }
  }

  Future<SessionLog> saveWorkout(CoachWorkout workout, List<Map<String, dynamic>> sets) => _training.createSessionLog(
        sessionId: workout.sessionId,
        programId: workout.programId,
        completedAt: DateTime.now().toUtc(),
        durationMin: workout.durationMin,
        highlight: '${workout.title} terminée (Coach Apex)',
        sets: sets,
      );
}

/// Chat with Coach Apex.
class CoachChatViewModel extends BaseViewModel {
  CoachChatViewModel(this._coach, {String firstName = ''}) {
    _messages.add(ChatMessage(
      role: 'assistant',
      content: 'Salut${firstName.isNotEmpty ? ' $firstName' : ''} ! Je suis Coach Apex. Je connais ta séance du jour, tes repas et tes objectifs. Pose-moi ta question 💪',
    ));
  }

  final CoachRepository _coach;
  final List<ChatMessage> _messages = [];

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get sending => busy;

  static const quickQuestions = [
    'Quoi manger ce soir ?',
    'C’est quoi ma séance du jour ?',
    'Combien de protéines il me reste ?',
    'Une idée de petit-déj healthy ?',
    'Je suis fatigué, je m’entraîne ?',
  ];

  Future<void> send(String text) async {
    final message = text.trim();
    if (message.isEmpty || busy) return;
    final history = List<ChatMessage>.from(_messages);
    _messages.add(ChatMessage(role: 'user', content: message));
    await guard(() async => _messages.add(await _coach.chat(message, history)));
    if (error != null) {
      _messages.add(ChatMessage(role: 'assistant', content: 'Oups, je n’arrive pas à répondre : $error'));
      notify();
    }
  }
}
