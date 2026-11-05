import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/date_format.dart';
import '../../data/profile_models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/widgets.dart';

String _cm(double? value, {int decimals = 0}) => value == null ? '—' : value.toStringAsFixed(decimals);

class MeasuresTab extends StatelessWidget {
  const MeasuresTab({
    super.key,
    required this.measurements,
    required this.activity,
    required this.heightCm,
    required this.onAddMeasure,
  });

  final List<BodySnapshot> measurements;
  final List<ActivityWeek> activity;
  final int heightCm;
  final ValueChanged<BodySnapshot> onAddMeasure;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    if (measurements.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.screenH),
        children: [
          const SizedBox(height: AppSpacing.xl),
          const ApexCard(tone: ApexCardTone.muted, child: Padding(padding: EdgeInsets.all(AppSpacing.xl), child: Center(child: Text('Aucune mesure')))),
          const SizedBox(height: AppSpacing.lg),
          ApexButton(label: 'Ajouter ma première mesure', icon: Icons.add_rounded, onPressed: () => _openSheet(context, null)),
        ],
      );
    }
    final ordered = [...measurements]..sort((a, b) => b.date.compareTo(a.date));
    final current = ordered[0];
    final oldest = ordered[ordered.length - 1];
    final delta = current.weightKg - oldest.weightKg;
    final deltaLabel = '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)} kg';
    final weights = ordered.reversed.map((m) => m.weightKg).toList();
    final bmi = heightCm > 0 ? current.weightKg / ((heightCm / 100) * (heightCm / 100)) : 0;
    final maxSessions = activity.fold<int>(1, (max, week) => week.sessions > max ? week.sessions : max);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        AppSpacing.md,
        AppSpacing.screenH,
        AppSpacing.xxxl,
      ),
      children: [
        ApexCard(
          tone: ApexCardTone.glow,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('POIDS', style: text.labelSmall),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    current.weightKg.toStringAsFixed(1),
                    style: text.displayMedium?.copyWith(color: AppColors.volt),
                  ),
                  const SizedBox(width: 6),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text('kg', style: text.titleMedium),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.cyan.withValues(alpha: 0.12),
                  borderRadius: const BorderRadius.all(Radius.circular(AppRadii.pill)),
                ),
                child: Text(
                  '$deltaLabel / ${measurements.length} relevés',
                  style: text.labelMedium?.copyWith(color: AppColors.cyan),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ApexSparkline(values: weights, color: AppColors.volt),
              const SizedBox(height: 6),
              Text(
                'Du ${formatShortDate(oldest.date)} au ${formatShortDate(current.date)}',
                style: text.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Mensurations actuelles', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(child: ApexStat(value: _cm(current.chestCm), unit: 'cm', label: 'Poitrine', accent: AppColors.cyan)),
            const SizedBox(width: AppSpacing.xs),
            Expanded(child: ApexStat(value: _cm(current.waistCm), unit: 'cm', label: 'Taille', accent: AppColors.volt)),
            const SizedBox(width: AppSpacing.xs),
            Expanded(child: ApexStat(value: _cm(current.hipsCm), unit: 'cm', label: 'Hanches', accent: AppColors.violet)),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(child: ApexStat(value: _cm(current.armCm, decimals: 1), unit: 'cm', label: 'Bras', accent: AppColors.amber)),
            const SizedBox(width: AppSpacing.xs),
            Expanded(child: ApexStat(value: _cm(current.thighCm, decimals: 1), unit: 'cm', label: 'Cuisse', accent: AppColors.mint)),
            const SizedBox(width: AppSpacing.xs),
            Expanded(child: ApexStat(value: bmi > 0 ? bmi.toStringAsFixed(1) : '—', label: 'IMC', accent: AppColors.coral)),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        ApexButton(
          label: 'Nouvelle mesure',
          icon: Icons.add_rounded,
          onPressed: () => _openSheet(context, current),
        ),
        const SizedBox(height: AppSpacing.xxl),
        const ApexSectionHeader(title: 'Historique'),
        const SizedBox(height: AppSpacing.sm),
        for (final row in ordered) ...[
          _HistoryTile(snapshot: row, latest: row.date == current.date),
          const SizedBox(height: AppSpacing.xs),
        ],
        const SizedBox(height: AppSpacing.xxl),
        const ApexSectionHeader(title: 'Activités'),
        const SizedBox(height: 6),
        Text(
          'Volume hebdo — séances, minutes, kcal.',
          style: text.bodySmall,
        ),
        const SizedBox(height: AppSpacing.md),
        if (activity.isEmpty)
          const ApexCard(tone: ApexCardTone.muted, child: Padding(padding: EdgeInsets.all(AppSpacing.xl), child: Center(child: Text('Aucune activité pour le moment'))))
        else ApexCard(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.md),
          child: Column(
            children: [
              SizedBox(
                height: 140,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final week in activity) ...[
                      Expanded(
                        child: _ActivityBar(
                          week: week,
                          maxSessions: maxSessions,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _ActivityLegend(weeks: activity),
            ],
          ),
        ),
      ],
    );
  }

  void _openSheet(BuildContext context, BodySnapshot? last) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
      ),
      builder: (ctx) {
        return _MeasureSheet(
          last: last,
          onSubmit: (snap) {
            Navigator.of(ctx).pop();
            onAddMeasure(snap);
          },
        );
      },
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.snapshot, required this.latest});

  final BodySnapshot snapshot;
  final bool latest;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ApexCard(
      tone: ApexCardTone.muted,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            child: Text(
              formatShortDate(snapshot.date),
              style: text.titleSmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${snapshot.weightKg.toStringAsFixed(1)} kg',
            style: text.titleMedium?.copyWith(color: AppColors.volt),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              latest
                  ? 'actuel · T ${_cm(snapshot.waistCm)}'
                  : 'T ${_cm(snapshot.waistCm)}  ·  P ${_cm(snapshot.chestCm)}',
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: text.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityBar extends StatelessWidget {
  const _ActivityBar({required this.week, required this.maxSessions});

  final ActivityWeek week;
  final int maxSessions;

  @override
  Widget build(BuildContext context) {
    final h = 16.0 + (week.sessions / maxSessions) * 100;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text('${week.sessions}', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            height: h,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  AppColors.cyan.withValues(alpha: 0.35),
                  AppColors.volt,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityLegend extends StatelessWidget {
  const _ActivityLegend({required this.weeks});

  final List<ActivityWeek> weeks;

  @override
  Widget build(BuildContext context) {
    if (weeks.isEmpty) { return const Padding(padding: EdgeInsets.all(16), child: Text('Aucune activité pour le moment')); }
    final last = weeks.last;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${last.minutes} min  ·  ${last.kcal} kcal', style: text.titleSmall),
        const SizedBox(height: 4),
        Text(
          'Semaine du ${formatShortDate(last.start)}',
          style: text.bodySmall,
        ),
      ],
    );
  }
}

class _MeasureSheet extends StatefulWidget {
  const _MeasureSheet({required this.last, required this.onSubmit});

  /// Previous measurement used to prefill the form (null = empty form).
  final BodySnapshot? last;
  final ValueChanged<BodySnapshot> onSubmit;

  @override
  State<_MeasureSheet> createState() => _MeasureSheetState();
}

class _MeasureSheetState extends State<_MeasureSheet> {
  late final TextEditingController _w;
  late final TextEditingController _chest;
  late final TextEditingController _waist;
  late final TextEditingController _hips;
  late final TextEditingController _arm;
  late final TextEditingController _thigh;

  @override
  void initState() {
    super.initState();
    final l = widget.last;
    String v(double? x) => x == null ? '' : x.toStringAsFixed(1);
    _w = TextEditingController(text: v(l?.weightKg));
    _chest = TextEditingController(text: v(l?.chestCm));
    _waist = TextEditingController(text: v(l?.waistCm));
    _hips = TextEditingController(text: v(l?.hipsCm));
    _arm = TextEditingController(text: v(l?.armCm));
    _thigh = TextEditingController(text: v(l?.thighCm));
  }

  @override
  void dispose() {
    _w.dispose();
    _chest.dispose();
    _waist.dispose();
    _hips.dispose();
    _arm.dispose();
    _thigh.dispose();
    super.dispose();
  }

  /// Empty field → null (mensurations are optional).
  double? _n(TextEditingController c) {
    final t = c.text.replaceAll(',', '.').trim();
    return t.isEmpty ? null : double.tryParse(t);
  }

  void _submit() {
    final weight = _n(_w);
    final others = [_chest, _waist, _hips, _arm, _thigh].map(_n).toList();
    final weightOk = weight != null && weight >= 30 && weight <= 300;
    final othersOk = [_chest, _waist, _hips, _arm, _thigh].every((c) {
      if (c.text.trim().isEmpty) return true;
      final v = _n(c);
      return v != null && v >= 10 && v <= 300;
    });
    if (!weightOk || !othersOk) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Poids obligatoire (30–300 kg). Mensurations facultatives (10–300 cm).')),
      );
      return;
    }
    widget.onSubmit(BodySnapshot(
      date: DateTime.now(),
      weightKg: weight,
      chestCm: others[0],
      waistCm: others[1],
      hipsCm: others[2],
      armCm: others[3],
      thighCm: others[4],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, inset + AppSpacing.xl),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderStrong,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Nouveau relevé', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text('Seul le poids est obligatoire. Un relevé du même jour remplace le précédent.', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _w,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
              decoration: const InputDecoration(labelText: 'Poids (kg) *'),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chest,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Poitrine'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _waist,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Taille'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _hips,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Hanches'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _arm,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Bras'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _thigh,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Cuisse'),
            ),
            const SizedBox(height: AppSpacing.lg),
            ApexButton(
              label: 'Ajouter à l\'historique',
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
