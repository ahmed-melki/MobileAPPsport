import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/app_repositories.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../viewmodels/auth_view_models.dart';
import '../../widgets/widgets.dart';
import 'verify_email_screen.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key, required this.onAuthenticated});
  final VoidCallback onAuthenticated;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (context) => RegisterViewModel(context.read<AppRepositories>().auth),
        child: _RegisterView(onAuthenticated: onAuthenticated),
      );
}

class _RegisterView extends StatefulWidget {
  const _RegisterView({required this.onAuthenticated});
  final VoidCallback onAuthenticated;

  @override
  State<_RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<_RegisterView> {
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();

  @override
  void dispose() {
    for (final c in [_first, _last, _email, _password, _confirmation]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _register() async {
    final session = await context.read<RegisterViewModel>().register(
          firstName: _first.text.trim(),
          lastName: _last.text.trim(),
          email: _email.text.trim(),
          password: _password.text,
          confirmation: _confirmation.text,
        );
    if (session == null || !mounted) return;
    if (session.emailVerified) {
      widget.onAuthenticated();
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => VerifyEmailScreen(
          email: _email.text.trim(),
          emailSent: session.emailSent,
          onVerified: () {
            Navigator.of(context)
              ..pop()
              ..pop();
            widget.onAuthenticated();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RegisterViewModel>();
    InputDecoration deco(String label, String field) => InputDecoration(labelText: label, errorText: vm.fieldError(field));
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(title: const Text('Créer un compte')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenH),
          child: Column(children: [
            TextField(controller: _first, decoration: deco('Prénom', 'firstName')),
            const SizedBox(height: AppSpacing.sm),
            TextField(controller: _last, decoration: deco('Nom', 'lastName')),
            const SizedBox(height: AppSpacing.sm),
            TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: deco('Email', 'email')),
            const SizedBox(height: AppSpacing.sm),
            TextField(controller: _password, obscureText: true, decoration: deco('Mot de passe', 'password')),
            const SizedBox(height: AppSpacing.sm),
            TextField(controller: _confirmation, obscureText: true, decoration: deco('Confirmer le mot de passe', 'passwordConfirmation')),
            if (vm.error != null && vm.fieldErrors.isEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text(vm.error!, style: const TextStyle(color: AppColors.coral)),
            ],
            const SizedBox(height: AppSpacing.lg),
            ApexButton(label: vm.busy ? 'Création…' : 'Créer mon compte', onPressed: vm.busy ? null : _register),
          ]),
        ),
      ),
    );
  }
}
