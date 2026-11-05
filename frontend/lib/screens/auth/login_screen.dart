import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/app_repositories.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../viewmodels/auth_view_models.dart';
import '../../widgets/widgets.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';
import 'verify_email_screen.dart';

/// View of the login (MVVM): state & logic live in [LoginViewModel].
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key, required this.onAuthenticated, this.successMessage});

  final VoidCallback onAuthenticated;

  /// Optional message shown at the top (e.g. after a password reset).
  final String? successMessage;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (context) => LoginViewModel(context.read<AppRepositories>().auth, successMessage: successMessage),
        child: _LoginView(onAuthenticated: onAuthenticated),
      );
}

class _LoginView extends StatefulWidget {
  const _LoginView({required this.onAuthenticated});
  final VoidCallback onAuthenticated;

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> {
  final _email = TextEditingController(text: 'lina.moreau@apex.app');
  final _password = TextEditingController(text: 'Password123!');

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final vm = context.read<LoginViewModel>();
    final session = await vm.login(_email.text.trim(), _password.text);
    if (session == null || !mounted) return;
    if (session.emailVerified) {
      widget.onAuthenticated();
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => VerifyEmailScreen(
          email: _email.text.trim(),
          emailSent: true,
          onVerified: () {
            Navigator.of(context).pop();
            widget.onAuthenticated();
          },
        ),
      ),
    );
  }

  void _goToRegister() => Navigator.of(context).push<void>(
        MaterialPageRoute<void>(builder: (_) => RegisterScreen(onAuthenticated: widget.onAuthenticated)),
      );

  Future<void> _goToForgotPassword() async {
    final vm = context.read<LoginViewModel>();
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(builder: (_) => const ForgotPasswordScreen()),
    );
    if (result == 'success') vm.showSuccess('Mot de passe réinitialisé ! Tu peux te connecter.');
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LoginViewModel>();
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.screenH),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('APEX', style: Theme.of(context).textTheme.displaySmall),
                const SizedBox(height: AppSpacing.sm),
                Text('Reprendre la cadence.', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: AppSpacing.xl),
                if (vm.successMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.volt.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.volt.withValues(alpha: 0.4)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.check_circle_outline_rounded, color: AppColors.volt, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(vm.successMessage!, style: const TextStyle(color: AppColors.volt))),
                    ]),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Mot de passe'),
                  onSubmitted: (_) => vm.busy ? null : _login(),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(onPressed: _goToForgotPassword, child: const Text('Mot de passe oublié ?')),
                ),
                if (vm.error != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(vm.error!, style: const TextStyle(color: AppColors.coral)),
                ],
                const SizedBox(height: AppSpacing.sm),
                ApexButton(
                  label: vm.busy ? 'Connexion…' : 'Se connecter',
                  icon: Icons.login_rounded,
                  onPressed: vm.busy ? null : _login,
                ),
                const SizedBox(height: AppSpacing.sm),
                ApexButton(label: 'Créer un compte', variant: ApexButtonVariant.ghost, onPressed: _goToRegister),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
