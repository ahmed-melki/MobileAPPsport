/// Form validators shared by the ViewModels.
abstract final class Validators {
  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? email(String v) {
    if (v.isEmpty) return 'L\'email est requis.';
    if (!_email.hasMatch(v)) return 'Format d\'email invalide.';
    return null;
  }

  static String? password(String v, {String label = 'Le mot de passe'}) {
    if (v.isEmpty) return '$label est requis.';
    if (v.length < 8) return 'Au moins 8 caractères.';
    return null;
  }

  static String? confirmation(String v, String password) =>
      v != password ? 'Les mots de passe ne correspondent pas.' : null;

  static String? code(String v) {
    if (v.isEmpty) return 'Le code est requis.';
    if (v.length != 6 || int.tryParse(v) == null) return 'Le code doit être 6 chiffres.';
    return null;
  }
}
