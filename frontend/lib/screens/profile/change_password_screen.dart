import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/app_repositories.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../viewmodels/auth_view_models.dart';
import '../../widgets/widgets.dart';

/// Change the logged-in user's password (from the Profile module).
class ChangePasswordScreen extends StatelessWidget {
  const ChangePasswordScreen({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (context) => ChangePasswordViewModel(context.read<AppRepositories>().auth),
        child: const _ChangePasswordView(),
      );
}

class _ChangePasswordView extends StatefulWidget {
  const _ChangePasswordView();

  @override
  State<_ChangePasswordView> createState() => _ChangePasswordViewState();
}

class _ChangePasswordViewState extends State<_ChangePasswordView> {
  final _current = TextEditingController();
  final _newPwd = TextEditingController();
  final _confirmation = TextEditingController();

  @override
  void dispose() {
    _current.dispose();
    _newPwd.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final ok = await context.read<ChangePasswordViewModel>().change(
          current: _current.text,
          password: _newPwd.text,
          confirmation: _confirmation.text,
        );
    if (ok) {
      _current.clear();
      _newPwd.clear();
      _confirmation.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final vm = context.watch<ChangePasswordViewModel>();
    Widget field(TextEditingController c, String label, String key, String apiField, bool obscure) => TextField(
          controller: c,
          obscureText: obscure,
          decoration: InputDecoration(
            labelText: label,
            errorText: vm.fieldError(apiField),
            suffixIcon: IconButton(
              icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
              onPressed: () => vm.toggle(key),
            ),
          ),
        );
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(title: const Text('Changer le mot de passe')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenH),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: AppSpacing.md),
            Text('Sécurité', style: text.headlineMedium),
            const SizedBox(height: AppSpacing.sm),
            Text('Le nouveau mot de passe doit faire au moins 8 caractères.', style: text.bodySmall),
            const SizedBox(height: AppSpacing.xl),
            field(_current, 'Mot de passe actuel', 'current', 'currentPassword', vm.obscureCurrent),
            const SizedBox(height: AppSpacing.md),
            field(_newPwd, 'Nouveau mot de passe', 'new', 'password', vm.obscureNew),
            const SizedBox(height: AppSpacing.md),
            field(_confirmation, 'Confirmer le nouveau mot de passe', 'confirmation', 'passwordConfirmation', vm.obscureConfirmation),
            if (vm.error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(vm.error!, style: const TextStyle(color: AppColors.coral)),
            ],
            if (vm.success != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(vm.success!, style: const TextStyle(color: AppColors.volt)),
            ],
            const SizedBox(height: AppSpacing.lg),
            ApexButton(
              label: vm.busy ? 'Modification…' : 'Changer le mot de passe',
              icon: Icons.lock_outline_rounded,
              onPressed: vm.busy ? null : _submit,
            ),
          ]),
        ),
      ),
    );
  }
}
