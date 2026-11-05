import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../core/api/app_repositories.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_spacing.dart';
import '../../viewmodels/coach_view_models.dart';
import '../../widgets/widgets.dart';

class CoachChatScreen extends StatelessWidget {
  const CoachChatScreen({super.key, this.firstName = ''});
  final String firstName;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (context) => CoachChatViewModel(context.read<AppRepositories>().coach, firstName: firstName),
        child: const _CoachChatView(),
      );
}

class _CoachChatView extends StatefulWidget {
  const _CoachChatView();

  @override
  State<_CoachChatView> createState() => _CoachChatViewState();
}

class _CoachChatViewState extends State<_CoachChatView> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send([String? preset]) async {
    final text = preset ?? _input.text;
    if (preset == null) _input.clear();
    final vm = context.read<CoachChatViewModel>();
    final future = vm.send(text);
    _scrollDown();
    await future;
    _scrollDown();
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final vm = context.watch<CoachChatViewModel>();
    final messages = vm.messages;
    final sending = vm.sending;
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.screenH, AppSpacing.md, AppSpacing.screenH, AppSpacing.sm),
            child: Row(children: [
              ApexIconButton(icon: Icons.arrow_back_rounded, onPressed: () => Navigator.of(context).maybePop()),
              const SizedBox(width: 12),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: AppColors.violet.withValues(alpha: 0.18), shape: BoxShape.circle),
                child: const Icon(Icons.auto_awesome_rounded, color: AppColors.violet),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Coach Apex', style: text.titleMedium),
                  Text(sending ? 'écrit…' : 'Sport · nutrition · récup', style: text.labelSmall),
                ]),
              ),
            ]),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH, vertical: AppSpacing.md),
              itemCount: messages.length + (sending ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= messages.length) {
                  return const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.violet)),
                    ),
                  );
                }
                final m = messages[index];
                return Align(
                  alignment: m.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: m.isUser ? AppColors.violet.withValues(alpha: 0.22) : AppColors.surface,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(AppRadii.md),
                        topRight: const Radius.circular(AppRadii.md),
                        bottomLeft: Radius.circular(m.isUser ? AppRadii.md : 4),
                        bottomRight: Radius.circular(m.isUser ? 4 : AppRadii.md),
                      ),
                      border: Border.all(color: m.isUser ? AppColors.violet.withValues(alpha: 0.4) : AppColors.border),
                    ),
                    child: Text(m.content, style: text.bodyMedium?.copyWith(color: AppColors.textPrimary)),
                  ),
                );
              },
            ),
          ),
          if (messages.length <= 2)
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
                itemCount: CoachChatViewModel.quickQuestions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => Center(child: ApexChip(label: CoachChatViewModel.quickQuestions[i], accent: AppColors.violet, onTap: () => _send(CoachChatViewModel.quickQuestions[i]))),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.screenH, AppSpacing.sm, AppSpacing.screenH, AppSpacing.md),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _input,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  decoration: const InputDecoration(hintText: 'Écris ton message…'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                style: IconButton.styleFrom(backgroundColor: AppColors.violet, foregroundColor: AppColors.textOnVolt),
                onPressed: sending ? null : () => _send(),
                icon: const Icon(Icons.send_rounded),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
