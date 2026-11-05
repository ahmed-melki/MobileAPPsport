import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../core/api/app_repositories.dart';
import '../../core/currency_formatter.dart';
import '../../core/shop_keys.dart';
import '../../data/shop_models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_spacing.dart';
import '../../viewmodels/shop_view_models.dart';
import '../../widgets/widgets.dart';

class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key, required this.orderNumber, this.onOrderChanged});

  final String orderNumber;
  final VoidCallback? onOrderChanged;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (context) => OrderDetailViewModel(context.read<AppRepositories>().shop, orderNumber)..load(),
        child: _OrderDetailView(onOrderChanged: onOrderChanged),
      );
}

class _OrderDetailView extends StatefulWidget {
  const _OrderDetailView({this.onOrderChanged});
  final VoidCallback? onOrderChanged;

  @override
  State<_OrderDetailView> createState() => _OrderDetailViewState();
}

class _OrderDetailViewState extends State<_OrderDetailView> {
  OrderDetailViewModel get vm => Provider.of<OrderDetailViewModel>(context, listen: false);

  Future<void> _cancel() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: const Text('Annuler la commande ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Non')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Oui, annuler', style: TextStyle(color: AppColors.coral)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    if (await vm.cancel()) {
      widget.onOrderChanged?.call();
    } else {
      messenger.showSnackBar(SnackBar(content: Text(vm.error ?? 'Erreur')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final vm = context.watch<OrderDetailViewModel>();
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.screenH, AppSpacing.md, AppSpacing.screenH, AppSpacing.md),
              child: Row(
                children: [
                  ApexIconButton(icon: Icons.arrow_back_rounded, onPressed: () => Navigator.of(context).pop()),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('COMMANDE', style: text.labelSmall?.copyWith(color: AppColors.coral)),
                        Text(vm.orderNumber, style: text.headlineMedium),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // ── Body ──
            Expanded(child: _buildBody(text)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(TextTheme text) {
    if (vm.loading) return const Center(child: CircularProgressIndicator());
    if (vm.order == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 44, color: AppColors.coral),
              const SizedBox(height: AppSpacing.md),
              Text(vm.error ?? 'Commande introuvable', textAlign: TextAlign.center, style: text.bodyMedium),
              const SizedBox(height: AppSpacing.md),
              ApexButton(label: 'Réessayer', onPressed: vm.load),
            ],
          ),
        ),
      );
    }
    final order = vm.order!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.screenH, 0, AppSpacing.screenH, AppSpacing.xxxl),
      children: [
        // ── Status pill ──
        Row(
          children: [
            _StatusPill(label: orderStatusLabel(order.status), color: orderStatusColor(order.status)),
            const Spacer(),
            if (order.date.isNotEmpty) Text(order.date, style: text.bodySmall),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // ── Items ──
        Text('Articles', style: text.headlineSmall),
        const SizedBox(height: AppSpacing.sm),
        for (final item in order.items) ...[
          ApexCard(
            tone: ApexCardTone.muted,
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.productName, style: text.titleSmall),
                      const SizedBox(height: 4),
                      Text('${item.quantity} × ${formatDinar(item.unitPrice)}', style: text.bodySmall),
                    ],
                  ),
                ),
                Text(formatDinar(item.lineTotal), style: text.titleSmall),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],

        // ── Prices ──
        const SizedBox(height: AppSpacing.sm),
        ApexCard(
          tone: ApexCardTone.muted,
          child: Column(
            children: [
              _SummaryRow(label: 'Sous-total', value: formatDinar(order.subtotal)),
              const SizedBox(height: 8),
              _SummaryRow(
                label: 'Livraison',
                value: order.shippingCost == 0 ? 'Offerte' : formatDinar(order.shippingCost),
                valueColor: AppColors.mint,
              ),
              const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
              _SummaryRow(label: 'Total', value: formatDinar(order.total), large: true),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // ── Status Timeline ──
        if (order.statusHistory.isNotEmpty) ...[
          Text('Suivi', style: text.headlineSmall),
          const SizedBox(height: AppSpacing.sm),
          for (var i = 0; i < order.statusHistory.length; i++)
            _TimelineEntry(
              entry: order.statusHistory[i],
              isFirst: i == 0,
              isLast: i == order.statusHistory.length - 1,
            ),
          const SizedBox(height: AppSpacing.lg),
        ],

        // ── Address ──
        if (order.shippingAddress != null) ...[
          Text('Adresse de livraison', style: text.headlineSmall),
          const SizedBox(height: AppSpacing.sm),
          ApexCard(
            tone: ApexCardTone.muted,
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.shippingAddress!.fullName, style: text.titleSmall),
                const SizedBox(height: 4),
                Text(order.shippingAddress!.phone, style: text.bodyMedium),
                const SizedBox(height: 4),
                Text(order.shippingAddress!.addressLine1, style: text.bodyMedium),
                if (order.shippingAddress!.addressLine2 != null && order.shippingAddress!.addressLine2!.isNotEmpty)
                  Text(order.shippingAddress!.addressLine2!, style: text.bodyMedium),
                Text('${order.shippingAddress!.postalCode} ${order.shippingAddress!.city}, ${order.shippingAddress!.governorate}', style: text.bodyMedium),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],

        // ── Payment ──
        Text('Paiement', style: text.headlineSmall),
        const SizedBox(height: AppSpacing.sm),
        ApexCard(
          tone: ApexCardTone.muted,
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Icon(Icons.payments_outlined, color: AppColors.mint, size: 22),
              const SizedBox(width: 12),
              Expanded(child: Text(_paymentLabel(order.paymentMethod), style: text.bodyMedium)),
              _StatusPill(
                label: order.paymentStatus == 'paid' ? 'Payé' : 'Non payé',
                color: order.paymentStatus == 'paid' ? AppColors.mint : AppColors.amber,
              ),
            ],
          ),
        ),

        // ── Notes ──
        if (order.notes != null && order.notes!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Text('Notes', style: text.headlineSmall),
          const SizedBox(height: AppSpacing.sm),
          ApexCard(
            tone: ApexCardTone.muted,
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(order.notes!, style: text.bodyMedium),
          ),
        ],

        // ── Cancel button ──
        if (order.isPending) ...[
          const SizedBox(height: AppSpacing.xl),
          OutlinedButton.icon(
            onPressed: vm.cancelling ? null : _cancel,
            icon: vm.cancelling
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.cancel_outlined),
            label: Text(vm.cancelling ? 'Annulation...' : 'Annuler la commande'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.coral,
              side: const BorderSide(color: AppColors.coral),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: AppRadii.mdAll),
            ),
          ),
        ],
      ],
    );
  }

  String _paymentLabel(String? method) => switch (method) {
    'cash_on_delivery' => 'Paiement à la livraison',
    _ => method ?? '',
  };
}

// ─── Timeline Entry ───────────────────────────────────────────────────

class _TimelineEntry extends StatelessWidget {
  const _TimelineEntry({required this.entry, required this.isFirst, required this.isLast});
  final StatusHistoryEntry entry;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final color = orderStatusColor(entry.toStatus);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                if (!isFirst) Container(width: 2, height: 8, color: AppColors.border),
                Container(
                  width: 12, height: 12,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                if (!isLast) Expanded(child: Container(width: 2, color: AppColors.border)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(orderStatusLabel(entry.toStatus), style: text.titleSmall?.copyWith(color: color)),
                  if (entry.comment != null && entry.comment!.isNotEmpty)
                    Text(entry.comment!, style: text.bodySmall),
                  Text(
                    _formatDateTime(entry.createdAt),
                    style: text.labelSmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final d = dt.toLocal();
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, this.color = AppColors.mint});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(AppRadii.pill),
    ),
    child: Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color)),
  );
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value, this.valueColor, this.large = false});
  final String label;
  final String value;
  final Color? valueColor;
  final bool large;
  @override
  Widget build(BuildContext context) {
    final labelStyle = large ? Theme.of(context).textTheme.titleMedium : Theme.of(context).textTheme.bodyMedium;
    final valueStyle = labelStyle?.copyWith(color: valueColor ?? AppColors.textPrimary, fontWeight: large ? FontWeight.w700 : null);
    return Row(children: [Expanded(child: Text(label, style: labelStyle)), Text(value, style: valueStyle)]);
  }
}
