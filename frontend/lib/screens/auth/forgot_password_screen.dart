import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/app_repositories.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../viewmodels/auth_view_models.dart';
import '../../widgets/widgets.dart';
import 'reset_password_screen.dart';

/// Step 1 of the forgot-password flow: enter email → code sent.
class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (context) => ForgotPasswordViewModel(context.read<AppRepositories>().auth),
        child: const _ForgotPasswordView(),
      );
}

class _ForgotPasswordView extends StatefulWidget {
  const _ForgotPasswordView();

  @override
  State<_ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<_ForgotPasswordView> {
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final ok = await context.read<ForgotPasswordViewModel>().sendCode(email);
    if (!ok || !mounted) return;
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(builder: (_) => ResetPasswordScreen(email: email)),
    );
    if (result == 'success' && mounted) Navigator.of(context).pop('success');
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final vm = context.watch<ForgotPasswordViewModel>();
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(title: const Text('Mot de passe oublié')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenH),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: AppSpacing.md),
            Text('Réinitialisation', style: text.headlineMedium),
            const SizedBox(height: AppSpacing.sm),
            Text('Saisis ton adresse email. On t\'envoie un code à 6 chiffres.', style: text.bodyMedium),
            const SizedBox(height: AppSpacing.xl),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(labelText: 'Email', errorText: vm.fieldError('email')),
              onSubmitted: (_) => vm.busy ? null : _submit(),
            ),
            if (vm.error != null && vm.fieldError('email') == null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(vm.error!, style: const TextStyle(color: AppColors.coral)),
            ],
            const SizedBox(height: AppSpacing.lg),
            ApexButton(label: vm.busy ? 'Envoi…' : 'Envoyer le code', icon: Icons.send_rounded, onPressed: vm.busy ? null : _submit),
          ]),
        ),
      ),
    );
  }
}
