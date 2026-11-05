import 'package:flutter/material.dart';

import '../../data/profile_models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/widgets.dart';

class GoalsTab extends StatelessWidget {
  const GoalsTab({
    super.key,
    required this.goals,
    required this.onSetPrimary,
    required this.onToggleActive,
    required this.onAdd,
    required this.onDelete,
  });

  final List<SportGoal> goals;
  final ValueChanged<GoalKind> onSetPrimary;
  final ValueChanged<GoalKind> onToggleActive;
  final ValueChanged<SportGoal> onAdd;
  final ValueChanged<SportGoal> onDelete;

  static const _suggestions = <SportGoal>[
    SportGoal(kind: GoalKind.massGain, detail: 'Gagner 3 kg de masse musculaire en 12 semaines.', target: '+3 kg', deadline: '', progress: 0, active: true, primary: false),
    SportGoal(kind: GoalKind.weightLoss, detail: 'Perdre 4 kg de façon progressive.', target: '-4 kg', deadline: '', progress: 0, active: true, primary: false),
    SportGoal(kind: GoalKind.endurance, detail: 'Tenir le rythme sur un 10 km.', target: '10 km < 55 min', deadline: '', progress: 0, active: true, primary: false),
    SportGoal(kind: GoalKind.fitness, detail: 'S’entraîner 3 fois par semaine.', target: '3 séances / semaine', deadline: '', progress: 0, active: true, primary: false),
  ];

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final primaryList = goals.where((g) => g.primary);
    final primary = primaryList.isEmpty ? null : primaryList.first;
    final others = goals.where((g) => !g.primary).toList();

    final content = <Widget>[
      Text(
        'Un cap principal, le reste en soutien. Touche une carte pour la placer en tête.',
        style: text.bodyMedium,
      ),
      const SizedBox(height: AppSpacing.lg),
      ApexButton(label: 'Ajouter un objectif', icon: Icons.add_rounded, onPressed: () => _openSheet(context, null)),
    ];
    if (goals.isEmpty) {
      content.addAll([
        const SizedBox(height: AppSpacing.xl),
        const ApexCard(tone: ApexCardTone.muted, child: Padding(padding: EdgeInsets.all(AppSpacing.xl), child: Center(child: Text('Aucun objectif')))),
      ]);
    } else {
      content.addAll([
        if (primary != null) ...[
          const SizedBox(height: AppSpacing.lg),
          Text('OBJECTIF PRINCIPAL', style: text.labelSmall),
          const SizedBox(height: AppSpacing.sm),
          _GoalCard(goal: primary, featured: true, onPrimary: () => onSetPrimary(primary.kind), onToggle: () => onToggleActive(primary.kind), onDelete: () => onDelete(primary)),
        ],
        const SizedBox(height: AppSpacing.xl),
        const ApexSectionHeader(title: 'Autres caps'),
        const SizedBox(height: AppSpacing.sm),
        for (final goal in others) ...[
          _GoalCard(goal: goal, featured: false, onPrimary: () => onSetPrimary(goal.kind), onToggle: () => onToggleActive(goal.kind), onDelete: () => onDelete(goal)),
          const SizedBox(height: AppSpacing.sm),
        ],
      ]);
    }
    final remainingSuggestions = _suggestions.where((suggestion) => !goals.any((goal) => goal.kind == suggestion.kind));
    if (remainingSuggestions.isNotEmpty) {
      content.addAll([
        const SizedBox(height: AppSpacing.xl),
        const ApexSectionHeader(title: 'Objectifs suggérés'),
        const SizedBox(height: AppSpacing.sm),
        for (final suggestion in remainingSuggestions) ...[
          _SuggestedGoalCard(goal: suggestion, onTap: () => _openSheet(context, suggestion)),
          const SizedBox(height: AppSpacing.sm),
        ],
      ]);
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        AppSpacing.md,
        AppSpacing.screenH,
        AppSpacing.xxxl,
      ),
      children: content,
    );
  }

  void _openSheet(BuildContext context, SportGoal? suggestion) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (ctx) => _GoalSheet(suggestion: suggestion, primary: goals.isEmpty, onSubmit: (goal) { Navigator.of(ctx).pop(); onAdd(goal); }),
    );
  }
}

class _SuggestedGoalCard extends StatelessWidget {
  const _SuggestedGoalCard({required this.goal, required this.onTap});
  final SportGoal goal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final accent = goal.kind.accent;
    return ApexCard(
      tone: ApexCardTone.elevated,
      accent: accent,
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(children: [
        Container(width: 40, height: 40, decoration: BoxDecoration(color: accent.withValues(alpha: 0.16), borderRadius: AppRadii.smAll), child: Icon(goal.kind.icon, color: accent, size: 22)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(goal.kind.label, style: text.titleLarge), Text(goal.target, style: text.labelMedium?.copyWith(color: accent)), const SizedBox(height: 4), Text(goal.detail, style: text.bodySmall)])),
        Icon(Icons.add_circle_outline_rounded, color: accent),
      ]),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.goal,
    required this.featured,
    required this.onPrimary,
    required this.onToggle,
    required this.onDelete,
  });

  final SportGoal goal;
  final bool featured;
  final VoidCallback onPrimary;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final accent = goal.kind.accent;
    final pct = (goal.progress * 100).round();

    return Opacity(
      opacity: goal.active ? 1 : 0.55,
      child: ApexCard(
        tone: featured ? ApexCardTone.glow : ApexCardTone.elevated,
        accent: accent,
        onTap: onPrimary,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.16),
                    borderRadius: AppRadii.smAll,
                  ),
                  child: Icon(goal.kind.icon, color: accent, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(goal.kind.label, style: text.titleLarge),
                      Text(goal.target, style: text.labelMedium?.copyWith(color: accent)),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: goal.active,
                  activeThumbColor: AppColors.textOnVolt,
                  activeTrackColor: AppColors.volt,
                  onChanged: (_) => onToggle(),
                ),
                IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline_rounded)),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(goal.detail, style: text.bodyMedium?.copyWith(color: AppColors.textPrimary)),
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(99)),
              child: LinearProgressIndicator(
                value: goal.progress,
                minHeight: 8,
                backgroundColor: AppColors.surfaceMuted,
                color: accent,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Text('$pct %', style: text.titleSmall?.copyWith(color: accent)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Échéance  ${goal.deadline}',
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalSheet extends StatefulWidget {
  const _GoalSheet({required this.suggestion, required this.primary, required this.onSubmit});
  final SportGoal? suggestion;
  final bool primary;
  final ValueChanged<SportGoal> onSubmit;
  @override
  State<_GoalSheet> createState() => _GoalSheetState();
}

class _GoalSheetState extends State<_GoalSheet> {
  late GoalKind _kind;
  late DateTime _deadlineDate;
  final _detail = TextEditingController();
  final _target = TextEditingController();

  @override
  void initState() {
    super.initState();
    _kind = widget.suggestion?.kind ?? GoalKind.fitness;
    _deadlineDate = DateTime.now().add(const Duration(days: 90));
    _detail.text = widget.suggestion?.detail ?? '';
    _target.text = widget.suggestion?.target ?? '';
  }

  @override
  void dispose() { _detail.dispose(); _target.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, inset + AppSpacing.xl),
      child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Nouvel objectif', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.md),
        DropdownButtonFormField<GoalKind>(initialValue: _kind, items: [for (final kind in GoalKind.values) DropdownMenuItem(value: kind, child: Text(kind.label))], onChanged: widget.suggestion == null ? (value) { if (value != null) setState(() => _kind = value); } : null, decoration: const InputDecoration(labelText: 'Type')),
        TextField(controller: _detail, readOnly: widget.suggestion != null, decoration: const InputDecoration(labelText: 'Détail')),
        TextField(controller: _target, readOnly: widget.suggestion != null, decoration: const InputDecoration(labelText: 'Cible')),
        ListTile(contentPadding: EdgeInsets.zero, title: const Text('Échéance'), subtitle: Text(_frenchDate(_deadlineDate)), trailing: const Icon(Icons.calendar_today_rounded), onTap: _pickDeadline),
        const SizedBox(height: AppSpacing.lg),
        ApexButton(label: 'Ajouter', icon: Icons.check_rounded, onPressed: () => widget.onSubmit(SportGoal(kind: _kind, detail: _detail.text, target: _target.text, deadline: _isoDate(_deadlineDate), progress: 0, active: true, primary: widget.primary))),
      ])),
    );
  }

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(context: context, initialDate: _deadlineDate, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 3650)));
    if (picked != null) setState(() => _deadlineDate = picked);
  }

  String _frenchDate(DateTime date) => '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  String _isoDate(DateTime date) => '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
