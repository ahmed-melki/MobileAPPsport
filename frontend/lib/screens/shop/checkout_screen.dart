import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../core/api/app_repositories.dart';
import '../../core/currency_formatter.dart';
import '../../data/shop_models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_spacing.dart';
import '../../viewmodels/shop_view_models.dart';
import '../../widgets/widgets.dart';

class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key, required this.cart, required this.onOrderCreated});

  final CartData cart;
  final void Function(ShopOrder order) onOrderCreated;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (context) => CheckoutViewModel(context.read<AppRepositories>().shop, cart)..loadGovernorates(),
        child: _CheckoutView(onOrderCreated: onOrderCreated),
      );
}

class _CheckoutView extends StatefulWidget {
  const _CheckoutView({required this.onOrderCreated});
  final void Function(ShopOrder order) onOrderCreated;

  @override
  State<_CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends State<_CheckoutView> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _complementCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _postalCodeCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  CheckoutViewModel get vm => Provider.of<CheckoutViewModel>(context, listen: false);

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _complementCtrl.dispose();
    _cityCtrl.dispose();
    _postalCodeCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  String? _fieldError(String key) => vm.fieldErrorFor(key);

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final order = await vm.submit(<String, dynamic>{
      'fullName': _fullNameCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim().replaceAll(RegExp(r'[\s\-]+'), ''),
      'addressLine1': _addressCtrl.text.trim(),
      'addressLine2': _complementCtrl.text.trim().isEmpty ? null : _complementCtrl.text.trim(),
      'city': _cityCtrl.text.trim(),
      'postalCode': _postalCodeCtrl.text.trim(),
      'notes': _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      'paymentMethod': 'cash_on_delivery',
    });
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    if (order != null) {
      widget.onOrderCreated(order);
      Navigator.of(context).pop();
      messenger.showSnackBar(const SnackBar(content: Text('Commande confirmée · merci pour votre confiance')));
    } else if (vm.fieldErrors.isEmpty && vm.error != null) {
      messenger.showSnackBar(SnackBar(content: Text(vm.error!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final vm = context.watch<CheckoutViewModel>();
    final shippingCost = vm.shippingCost;
    final total = vm.total;

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
                        Text('Adresse de livraison', style: text.headlineMedium),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // ── Form ──
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.screenH, 0, AppSpacing.screenH, AppSpacing.xxxl),
                  children: [
                    _buildField('Nom complet', _fullNameCtrl, 'fullName', required: true),
                    _buildField('Téléphone', _phoneCtrl, 'phone', required: true, keyboardType: TextInputType.phone,
                      hint: '+216 XX XXX XXX',
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Champ requis';
                        final cleaned = v.trim().replaceAll(RegExp(r'[\s\-]+'), '');
                        if (!RegExp(r'^(\+216)?[0-9]{8}$').hasMatch(cleaned)) return '8 chiffres, optionnel +216';
                        return null;
                      },
                    ),
                    _buildField('Adresse', _addressCtrl, 'addressLine1', required: true),
                    _buildField('Complément d\'adresse', _complementCtrl, 'addressLine2'),
                    _buildField('Ville', _cityCtrl, 'city', required: true),
                    // Governorate dropdown
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Gouvernorat *', style: text.labelMedium),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            initialValue: vm.selectedGovernorate,
                            isExpanded: true,
                            decoration: _inputDecoration(hint: vm.loadingGovernorates ? 'Chargement...' : 'Sélectionner'),
                            dropdownColor: AppColors.surfaceElevated,
                            items: vm.governorates.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                            onChanged: vm.loadingGovernorates ? null : vm.selectGovernorate,
                            validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
                          ),
                          if (_fieldError('governorate') != null) ...[
                            const SizedBox(height: 4),
                            Text(_fieldError('governorate')!, style: text.bodySmall?.copyWith(color: AppColors.coral)),
                          ],
                        ],
                      ),
                    ),
                    _buildField('Code postal', _postalCodeCtrl, 'postalCode', required: true, keyboardType: TextInputType.number),
                    _buildField('Notes', _notesCtrl, 'notes', maxLines: 3),

                    const SizedBox(height: AppSpacing.md),
                    // Payment info
                    ApexCard(
                      tone: ApexCardTone.muted,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        children: [
                          Icon(Icons.payments_outlined, color: AppColors.mint, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Paiement à la livraison', style: text.titleSmall),
                                const SizedBox(height: 2),
                                Text('Vous payez en espèces à la réception.', style: text.bodySmall),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // ── Summary ──
                    ApexCard(
                      tone: ApexCardTone.muted,
                      child: Column(
                        children: [
                          _SummaryRow(label: 'Sous-total', value: formatDinar(vm.cart.subtotal)),
                          const SizedBox(height: 8),
                          _SummaryRow(
                            label: 'Livraison',
                            value: shippingCost == 0 ? 'Offerte' : formatDinar(shippingCost),
                            valueColor: AppColors.mint,
                          ),
                          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
                          _SummaryRow(label: 'Total', value: formatDinar(total), large: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ApexButton(
                      label: vm.busy ? 'Envoi en cours…' : 'Confirmer la commande',
                      icon: Icons.lock_outline_rounded,
                      onPressed: vm.busy ? null : _submit,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller,
    String fieldKey, {
    bool required = false,
    TextInputType? keyboardType,
    String? hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label${required ? ' *' : ''}', style: text.labelMedium),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: text.bodyLarge,
            decoration: _inputDecoration(hint: hint),
            validator: validator ?? (required ? (v) => v == null || v.trim().isEmpty ? 'Champ requis' : null : null),
          ),
          if (_fieldError(fieldKey) != null) ...[
            const SizedBox(height: 4),
            Text(_fieldError(fieldKey)!, style: text.bodySmall?.copyWith(color: AppColors.coral)),
          ],
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({String? hint}) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: AppColors.surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(borderRadius: AppRadii.mdAll, borderSide: const BorderSide(color: AppColors.border)),
    enabledBorder: OutlineInputBorder(borderRadius: AppRadii.mdAll, borderSide: const BorderSide(color: AppColors.border)),
    focusedBorder: OutlineInputBorder(borderRadius: AppRadii.mdAll, borderSide: const BorderSide(color: AppColors.volt)),
    errorBorder: OutlineInputBorder(borderRadius: AppRadii.mdAll, borderSide: const BorderSide(color: AppColors.coral)),
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
