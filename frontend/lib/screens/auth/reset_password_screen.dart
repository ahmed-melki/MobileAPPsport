import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/api/app_repositories.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../viewmodels/auth_view_models.dart';
import '../../widgets/widgets.dart';

/// Step 2 of the forgot-password flow: code + new password.
class ResetPasswordScreen extends StatelessWidget {
  const ResetPasswordScreen({super.key, required this.email});
  final String email;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (context) => ResetPasswordViewModel(context.read<AppRepositories>().auth, email: email),
        child: const _ResetPasswordView(),
      );
}

class _ResetPasswordView extends StatefulWidget {
  const _ResetPasswordView();

  @override
  State<_ResetPasswordView> createState() => _ResetPasswordViewState();
}

class _ResetPasswordViewState extends State<_ResetPasswordView> {
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final ok = await context.read<ResetPasswordViewModel>().reset(
          code: _code.text.trim(),
          password: _password.text,
          confirmation: _confirmation.text,
        );
    if (ok && mounted) Navigator.of(context).pop('success');
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final vm = context.watch<ResetPasswordViewModel>();
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(title: const Text('Nouveau mot de passe')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenH),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: AppSpacing.md),
            Text('Code envoyé à', style: text.bodySmall),
            const SizedBox(height: 2),
            Text(vm.email, style: text.titleSmall?.copyWith(color: AppColors.volt)),
            const SizedBox(height: AppSpacing.xl),
            TextField(
              controller: _code,
              keyboardType: TextInputType.number,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: text.headlineSmall?.copyWith(letterSpacing: 6),
              textAlign: TextAlign.center,
              decoration: InputDecoration(labelText: 'Code à 6 chiffres', hintText: '• • • • • •', counterText: '', errorText: vm.fieldError('code')),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _password,
              obscureText: vm.obscurePassword,
              decoration: InputDecoration(
                labelText: 'Nouveau mot de passe',
                errorText: vm.fieldError('password'),
                suffixIcon: IconButton(
                  icon: Icon(vm.obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                  onPressed: vm.togglePassword,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _confirmation,
              obscureText: vm.obscureConfirmation,
              decoration: InputDecoration(
                labelText: 'Confirmer le mot de passe',
                errorText: vm.fieldError('passwordConfirmation'),
                suffixIcon: IconButton(
                  icon: Icon(vm.obscureConfirmation ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                  onPressed: vm.toggleConfirmation,
                ),
              ),
            ),
            if (vm.error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(vm.error!, style: const TextStyle(color: AppColors.coral)),
            ],
            const SizedBox(height: AppSpacing.lg),
            ApexButton(
              label: vm.busy ? 'Réinitialisation…' : 'Réinitialiser le mot de passe',
              icon: Icons.lock_reset_rounded,
              onPressed: vm.busy ? null : _submit,
            ),
          ]),
        ),
      ),
    );
  }
}
