import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/api/app_repositories.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../viewmodels/auth_view_models.dart';
import '../../widgets/widgets.dart';

/// Shown after register or when a 403 email_not_verified is caught globally.
class VerifyEmailScreen extends StatelessWidget {
  const VerifyEmailScreen({super.key, required this.email, required this.emailSent, required this.onVerified});

  final String email;
  final bool emailSent;
  final VoidCallback onVerified;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (context) => VerifyEmailViewModel(context.read<AppRepositories>().auth, email: email, emailSent: emailSent),
        child: _VerifyEmailView(onVerified: onVerified),
      );
}

class _VerifyEmailView extends StatefulWidget {
  const _VerifyEmailView({required this.onVerified});
  final VoidCallback onVerified;

  @override
  State<_VerifyEmailView> createState() => _VerifyEmailViewState();
}

class _VerifyEmailViewState extends State<_VerifyEmailView> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final ok = await context.read<VerifyEmailViewModel>().verify(_code.text.trim());
    if (ok && mounted) widget.onVerified();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final vm = context.watch<VerifyEmailViewModel>();
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(title: const Text('Vérification email')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenH),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.volt.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.volt.withValues(alpha: 0.3)),
                ),
                child: Row(children: [
                  const Icon(Icons.mark_email_unread_outlined, color: AppColors.volt, size: 28),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Vérifie ton email', style: text.titleMedium?.copyWith(color: AppColors.volt)),
                      const SizedBox(height: 4),
                      Text(
                        vm.emailSent
                            ? 'Un code à 6 chiffres a été envoyé à\n${vm.email}'
                            : 'L\'envoi de l\'email a échoué. Utilise le bouton Renvoyer ci-dessous.',
                        style: text.bodySmall,
                      ),
                    ]),
                  ),
                ]),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text('Code de vérification', style: text.labelLarge),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _code,
                keyboardType: TextInputType.number,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: text.headlineMedium?.copyWith(letterSpacing: 8),
                textAlign: TextAlign.center,
                decoration: const InputDecoration(hintText: '• • • • • •', counterText: ''),
                onSubmitted: (_) => vm.busy ? null : _verify(),
              ),
              if (vm.error != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(vm.error!, style: const TextStyle(color: AppColors.coral)),
              ],
              if (vm.successMessage != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(vm.successMessage!, style: const TextStyle(color: AppColors.volt)),
              ],
              const SizedBox(height: AppSpacing.lg),
              ApexButton(
                label: vm.busy ? 'Vérification…' : 'Vérifier',
                icon: Icons.check_circle_outline_rounded,
                onPressed: vm.busy ? null : _verify,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(vm.canResend ? 'Tu n\'as pas reçu le code ? ' : 'Renvoyer dans ${vm.countdown}s — ', style: text.bodySmall),
                if (vm.canResend)
                  TextButton(
                    onPressed: vm.resending ? null : vm.resend,
                    child: Text(vm.resending ? 'Envoi…' : 'Renvoyer le code'),
                  ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
