import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:provider/provider.dart';

import '../../core/api/app_repositories.dart';
import '../../core/api/nutrition_coach_repositories.dart';
import '../../core/currency_formatter.dart';
import '../../core/shop_keys.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_spacing.dart';
import '../../viewmodels/admin_view_models.dart';
import '../../widgets/widgets.dart';

String _actionLabel(String status) => switch (status) {
      'confirmed' => 'Accepter la commande',
      'shipped' => 'Marquer expédiée',
      'delivered' => 'Marquer livrée (payée)',
      'cancelled' => 'Refuser / annuler',
      _ => status,
    };

IconData _actionIcon(String status) => switch (status) {
      'confirmed' => Icons.check_circle_rounded,
      'shipped' => Icons.local_shipping_rounded,
      'delivered' => Icons.inventory_rounded,
      'cancelled' => Icons.cancel_rounded,
      _ => Icons.arrow_forward_rounded,
    };

String _dateTime(DateTime? d) {
  if (d == null) return '';
  final l = d.toLocal();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(l.day)}/${two(l.month)}/${l.year} ${two(l.hour)}:${two(l.minute)}';
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge(this.status);
  final String status;

  @override
  Widget build(BuildContext context) {
    final color = orderStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
      child: Text(orderStatusLabel(status), style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color)),
    );
  }
}

/// Admin: all customer orders, accept / ship / deliver / cancel.
class AdminOrdersScreen extends StatelessWidget {
  const AdminOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (context) => AdminOrdersViewModel(context.read<AppRepositories>().admin)..load(),
        child: const _AdminOrdersView(),
      );
}

class _AdminOrdersView extends StatelessWidget {
  const _AdminOrdersView();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final vm = context.watch<AdminOrdersViewModel>();
    final visible = vm.visible;
    final pendingTotal = vm.pendingTotal;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.screenH, AppSpacing.md, AppSpacing.screenH, AppSpacing.sm),
            child: Row(children: [
              ApexIconButton(icon: Icons.arrow_back_rounded, onPressed: () => Navigator.of(context).maybePop()),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Administration', style: text.labelSmall?.copyWith(color: AppColors.coral)),
                  Text('Commandes', style: text.headlineMedium),
                ]),
              ),
              ApexIconButton(icon: Icons.refresh_rounded, onPressed: vm.load),
            ]),
          ),
          if (!vm.loading && vm.error == null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
              child: Row(children: [
                Expanded(child: ApexStat(value: '${vm.count('pending')}', label: 'À traiter', accent: AppColors.amber)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: ApexStat(value: '${vm.count('confirmed') + vm.count('shipped')}', label: 'En cours', accent: AppColors.cyan)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: ApexStat(value: pendingTotal.toStringAsFixed(0), unit: 'DT', label: 'En attente', accent: AppColors.coral)),
              ]),
            ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
              itemCount: AdminOrdersViewModel.filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final f = AdminOrdersViewModel.filters[i];
                return Center(
                  child: ApexChip(
                    label: '${f == null ? 'Toutes' : orderStatusLabel(f)} (${vm.count(f)})',
                    selected: vm.filter == f,
                    accent: f == null ? AppColors.volt : orderStatusColor(f),
                    onTap: () => vm.setFilter(f),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: vm.loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.coral))
                : vm.error != null
                    ? Center(child: TextButton.icon(onPressed: vm.load, icon: const Icon(Icons.refresh), label: Text(vm.error!)))
                    : RefreshIndicator(
                        onRefresh: vm.load,
                        child: visible.isEmpty
                            ? ListView(children: [
                                const SizedBox(height: 80),
                                Center(child: Text('Aucune commande ici 🎉', style: text.bodyMedium)),
                              ])
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(AppSpacing.screenH, AppSpacing.sm, AppSpacing.screenH, AppSpacing.xxxl),
                                itemCount: visible.length,
                                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                                itemBuilder: (_, i) => _OrderTile(
                                  item: visible[i],
                                  onTap: () async {
                                    final changed = await Navigator.of(context).push<bool>(
                                      MaterialPageRoute(builder: (_) => AdminOrderDetailScreen(orderNumber: visible[i].order.orderNumber)),
                                    );
                                    if (changed == true) vm.load();
                                  },
                                ),
                              ),
                      ),
          ),
        ]),
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.item, required this.onTap});
  final AdminOrder item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final o = item.order;
    final address = o.shippingAddress;
    final itemsCount = o.items.fold<int>(0, (s, it) => s + it.quantity);
    return ApexCard(
      onTap: onTap,
      accent: o.status == 'pending' ? AppColors.amber : null,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(o.orderNumber, style: text.titleMedium)),
          _StatusBadge(o.status),
        ]),
        const SizedBox(height: 6),
        Text(
          [address?.fullName ?? item.customerName ?? 'Client', if (address != null) address.governorate].join(' · '),
          style: text.bodyMedium,
        ),
        if (address != null) Text(address.phone, style: text.bodySmall),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: Text('$itemsCount article(s) · ${_dateTime(o.createdAt)}', style: text.labelSmall)),
          Text(formatDinar(o.total), style: text.titleSmall?.copyWith(color: AppColors.volt)),
        ]),
      ]),
    );
  }
}

class AdminOrderDetailScreen extends StatelessWidget {
  const AdminOrderDetailScreen({super.key, required this.orderNumber});
  final String orderNumber;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (context) => AdminOrderDetailViewModel(context.read<AppRepositories>().admin, orderNumber)..load(),
        child: const _AdminOrderDetailView(),
      );
}

class _AdminOrderDetailView extends StatefulWidget {
  const _AdminOrderDetailView();

  @override
  State<_AdminOrderDetailView> createState() => _AdminOrderDetailViewState();
}

class _AdminOrderDetailViewState extends State<_AdminOrderDetailView> {
  AdminOrderDetailViewModel get vm => Provider.of<AdminOrderDetailViewModel>(context, listen: false);

  Future<void> _transition(String status) async {
    final commentController = TextEditingController();
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl))),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(AppSpacing.screenH, AppSpacing.lg, AppSpacing.screenH, MediaQuery.of(sheetContext).viewInsets.bottom + AppSpacing.lg),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_actionLabel(status), style: Theme.of(sheetContext).textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text(
            status == 'cancelled'
                ? 'Le stock des produits sera remis automatiquement. Cette action est définitive.'
                : 'Nouveau statut : ${orderStatusLabel(status)}. Le client le verra dans sa commande.',
            style: Theme.of(sheetContext).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(controller: commentController, decoration: const InputDecoration(labelText: 'Commentaire (optionnel)')),
          const SizedBox(height: AppSpacing.lg),
          ApexButton(label: 'Confirmer', icon: _actionIcon(status), onPressed: () => Navigator.of(sheetContext).pop(true)),
          ApexButton(label: 'Retour', variant: ApexButtonVariant.ghost, onPressed: () => Navigator.of(sheetContext).pop(false)),
        ]),
      ),
    );
    final comment = commentController.text;
    commentController.dispose();
    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final ok = await vm.transition(status, comment);
    messenger.showSnackBar(SnackBar(content: Text(ok ? 'Commande ${orderStatusLabel(status).toLowerCase()}' : (vm.error ?? 'Erreur'))));
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final vm = context.watch<AdminOrderDetailViewModel>();
    final item = vm.item;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(vm.changed);
      },
      child: Scaffold(
        backgroundColor: AppColors.scaffold,
        body: SafeArea(
          child: item == null
              ? Center(
                  child: vm.error != null ? TextButton.icon(onPressed: vm.load, icon: const Icon(Icons.refresh), label: Text(vm.error!)) : const CircularProgressIndicator(color: AppColors.coral),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.screenH, AppSpacing.md, AppSpacing.screenH, AppSpacing.xxxl),
                  children: [
                    Row(children: [
                      ApexIconButton(icon: Icons.arrow_back_rounded, onPressed: () => Navigator.of(context).pop(vm.changed)),
                      const SizedBox(width: 12),
                      Expanded(child: Text(item.order.orderNumber, style: text.headlineMedium)),
                      _StatusBadge(item.order.status),
                    ]),
                    const SizedBox(height: AppSpacing.lg),
                    _section(context, 'Client', [
                      if (item.order.shippingAddress != null) ...[
                        Text(item.order.shippingAddress!.fullName, style: text.titleMedium),
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: item.order.shippingAddress!.phone));
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Numéro copié')));
                          },
                          child: Row(children: [
                            const Icon(Icons.phone_rounded, size: 16, color: AppColors.cyan),
                            const SizedBox(width: 6),
                            Text(item.order.shippingAddress!.phone, style: text.bodyMedium?.copyWith(color: AppColors.cyan)),
                            const SizedBox(width: 6),
                            const Icon(Icons.copy_rounded, size: 14, color: AppColors.textTertiary),
                          ]),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          [
                            item.order.shippingAddress!.addressLine1,
                            if ((item.order.shippingAddress!.addressLine2 ?? '').isNotEmpty) item.order.shippingAddress!.addressLine2!,
                            '${item.order.shippingAddress!.postalCode} ${item.order.shippingAddress!.city}',
                            item.order.shippingAddress!.governorate,
                          ].join('\n'),
                          style: text.bodySmall,
                        ),
                      ],
                      if (item.customerEmail != null) ...[
                        const SizedBox(height: 6),
                        Text('Compte : ${item.customerName ?? ''} · ${item.customerEmail}', style: text.labelSmall),
                      ],
                    ]),
                    const SizedBox(height: AppSpacing.md),
                    _section(context, 'Articles', [
                      for (final it in item.order.items)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(children: [
                            Expanded(child: Text('${it.quantity} × ${it.productName}', style: text.bodyMedium)),
                            Text(formatDinar(it.lineTotal), style: text.labelLarge),
                          ]),
                        ),
                      const Divider(color: AppColors.border),
                      _line(context, 'Sous-total', formatDinar(item.order.subtotal)),
                      _line(context, 'Livraison', formatDinar(item.order.shippingCost)),
                      _line(context, 'Total', formatDinar(item.order.total), strong: true),
                      const SizedBox(height: 6),
                      Text(
                        'Paiement à la livraison · ${item.order.paymentStatus == 'paid' ? 'payée' : 'non payée'}',
                        style: text.labelSmall,
                      ),
                    ]),
                    if ((item.order.notes ?? '').isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      _section(context, 'Note du client', [Text(item.order.notes!, style: text.bodyMedium)]),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    _section(context, 'Historique', [
                      for (final h in item.order.statusHistory)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Icon(Icons.circle, size: 8, color: orderStatusColor(h.toStatus)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(orderStatusLabel(h.toStatus), style: text.titleSmall),
                                if ((h.comment ?? '').isNotEmpty) Text(h.comment!, style: text.bodySmall),
                              ]),
                            ),
                            Text(_dateTime(h.createdAt), style: text.labelSmall),
                          ]),
                        ),
                    ]),
                    const SizedBox(height: AppSpacing.xl),
                    for (final next in adminTransitions[item.order.status] ?? const <String>[]) ...[
                      ApexButton(
                        label: vm.busy ? 'Mise à jour…' : _actionLabel(next),
                        icon: _actionIcon(next),
                        variant: next == 'cancelled' ? ApexButtonVariant.secondary : ApexButtonVariant.primary,
                        onPressed: vm.busy ? null : () => _transition(next),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    if ((adminTransitions[item.order.status] ?? const <String>[]).isEmpty)
                      Center(child: Text('Commande clôturée — aucune action possible.', style: text.bodySmall)),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _section(BuildContext context, String title, List<Widget> children) => ApexCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title.toUpperCase(), style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 8),
          ...children,
        ]),
      );

  Widget _line(BuildContext context, String label, String value, {bool strong = false}) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(children: [
        Expanded(child: Text(label, style: strong ? text.titleSmall : text.bodySmall)),
        Text(value, style: strong ? text.titleSmall?.copyWith(color: AppColors.volt) : text.bodySmall),
      ]),
    );
  }
}
