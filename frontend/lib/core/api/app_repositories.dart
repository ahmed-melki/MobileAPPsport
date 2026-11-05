import 'api_client.dart';
import 'auth_repository.dart';
import 'nutrition_coach_repositories.dart';
import 'repositories.dart';
import 'token_storage.dart';

/// All repositories (Model layer), created once and injected with Provider.
/// ViewModels receive the repository they need in their constructor.
class AppRepositories {
  AppRepositories({
    void Function()? onUnauthorized,
    void Function(String email)? onEmailNotVerified,
  })  : client = ApiClient(onUnauthorized: onUnauthorized, onEmailNotVerified: onEmailNotVerified),
        storage = TokenStorage() {
    auth = ApiAuthRepository(client, storage);
    profile = ApiProfileRepository(client);
    training = ApiTrainingRepository(client);
    shop = ApiShopRepository(client);
    nutrition = NutritionRepository(client);
    coach = CoachRepository(client);
    exercises = ExerciseRepository(client);
    admin = AdminRepository(client);
    adminCatalog = AdminCatalogRepository(client);
  }

  final ApiClient client;
  final TokenStorage storage;
  late final AuthRepository auth;
  late final ProfileRepository profile;
  late final TrainingRepository training;
  late final ShopRepository shop;
  late final NutritionRepository nutrition;
  late final CoachRepository coach;
  late final ExerciseRepository exercises;
  late final AdminRepository admin;
  late final AdminCatalogRepository adminCatalog;
}
