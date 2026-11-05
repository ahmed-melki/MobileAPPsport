import 'package:flutter_test/flutter_test.dart';
import 'package:sport_app_ui/core/api/api_client.dart';
import 'package:sport_app_ui/core/validators.dart';
import 'package:sport_app_ui/data/training_models.dart';
import 'package:sport_app_ui/viewmodels/base_view_model.dart';

/// Small ViewModel used to test the MVVM base class without the network.
class _CounterViewModel extends BaseViewModel {
  int value = 0;

  Future<bool> increment({bool fail = false}) => guard(() async {
        if (fail) throw ApiException('Erreur serveur', statusCode: 500);
        value++;
      });
}

void main() {
  group('Validators', () {
    test('email', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('ahmed'), isNotNull);
      expect(Validators.email('ahmed@apex.tn'), isNull);
    });

    test('mot de passe et confirmation', () {
      expect(Validators.password('123'), isNotNull);
      expect(Validators.password('12345678'), isNull);
      expect(Validators.confirmation('a', 'b'), isNotNull);
      expect(Validators.confirmation('abc', 'abc'), isNull);
    });

    test('code à 6 chiffres', () {
      expect(Validators.code('12a456'), isNotNull);
      expect(Validators.code('123456'), isNull);
    });
  });

  group('BaseViewModel (MVVM)', () {
    test('guard notifie la vue et gère busy / error', () async {
      final vm = _CounterViewModel();
      var notifications = 0;
      vm.addListener(() => notifications++);

      expect(await vm.increment(), isTrue);
      expect(vm.value, 1);
      expect(vm.busy, isFalse);
      expect(vm.error, isNull);
      expect(notifications, greaterThanOrEqualTo(2));

      expect(await vm.increment(fail: true), isFalse);
      expect(vm.error, 'Erreur serveur');
      expect(vm.value, 1);
    });
  });

  test('niveaux : débutant < intermédiaire < avancé', () {
    expect(levelRank('beginner'), lessThan(levelRank('intermediate')));
    expect(levelRank('intermediate'), lessThan(levelRank('advanced')));
  });
}
