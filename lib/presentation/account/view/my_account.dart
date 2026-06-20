import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:inventopos/core/design/app_spacing.dart';
import 'package:inventopos/core/widgets/m3/app_metric_card.dart';
import 'package:inventopos/core/widgets/m3/app_screen_scaffold.dart';
import 'package:inventopos/core/widgets/m3/app_section_card.dart';
import 'package:inventopos/presentation/account/bloc/account_bloc.dart';
import 'package:inventopos/presentation/account/bloc/account_event.dart';
import 'package:inventopos/presentation/account/bloc/account_state.dart';
import 'package:inventopos/presentation/account/widgets/account_editable_field_tile.dart';
import 'package:inventopos/presentation/account/widgets/account_field_edit_dialog.dart';
import 'package:inventopos/presentation/account/widgets/account_mutation_overlay.dart';
import 'package:inventopos/presentation/account/widgets/account_profile_header_section.dart';
import 'package:inventopos/presentation/auth_login/bloc/auth_bloc.dart';

class _AccountToolTile extends StatelessWidget {
  const _AccountToolTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class MyAccountPage extends StatefulWidget {
  const MyAccountPage({super.key});

  @override
  State<MyAccountPage> createState() => _MyAccountPageState();
}

class _MyAccountPageState extends State<MyAccountPage> {
  Future<void> _pickAndReplaceSignature() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (image == null || !mounted) return;
    context.read<AccountBloc>().add(
          AccountReplaceSignatureRequested(image.path),
        );
  }

  String _str(Map<String, dynamic> fields, String key) =>
      fields[key]?.toString().trim() ?? '';

  int _filledFieldCount(Map<String, dynamic> fields) {
    const keys = [
      'name',
      'phoneNumber',
      'businessName',
      'businessAddress',
      'gstNumber',
      'billRules',
    ];
    return keys.where((k) => _str(fields, k).isNotEmpty).length;
  }

  String _formatPdfSize(String? val) {
    if (val == 'A5') return 'A5 (Half)';
    if (val == '80mm') return '80mm (3-inch Roll)';
    if (val == '58mm') return '58mm (2-inch Roll)';
    return 'A4 (Standard)';
  }

  void _showPdfSizeDialog(BuildContext context, String currentValue) {
    showDialog(
      context: context,
      builder: (ctx) {
        return SimpleDialog(
          title: const Text('Select Invoice PDF Size'),
          children: [
            _buildPdfSizeOption(ctx, 'A4', currentValue),
            _buildPdfSizeOption(ctx, 'A5', currentValue),
            _buildPdfSizeOption(ctx, '80mm', currentValue),
            _buildPdfSizeOption(ctx, '58mm', currentValue),
          ],
        );
      },
    );
  }

  Widget _buildPdfSizeOption(BuildContext ctx, String value, String currentValue) {
    return RadioListTile<String>(
      title: Text(_formatPdfSize(value)),
      value: value,
      groupValue: currentValue,
      onChanged: (val) {
        if (val != null) {
          context.read<AccountBloc>().add(
            AccountPatchFieldRequested(fieldKey: 'pdfBillSize', value: val),
          );
        }
        Navigator.pop(ctx);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AccountBloc, AccountState>(
      listenWhen: (p, c) =>
          c.feedbackMessage != null && c.feedbackMessage != p.feedbackMessage,
      listener: (context, state) {
        final msg = state.feedbackMessage;
        if (msg == null) return;
        final error = state.feedbackIsError;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: error
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.read<AccountBloc>().add(const AccountUiFeedbackConsumed());
      },
      builder: (context, accountState) {
        final fields = accountState.fields;
        final busy = accountState.loading || accountState.mutationBusy;
        final filled = _filledFieldCount(fields);
        const totalFields = 6;
        final businessReady = _str(fields, 'businessName').isNotEmpty;

        return AppScreenScaffold(
          title: 'My Account',
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: () => context.read<AuthBloc>().signOut(),
            ),
          ],
          body: Stack(
            children: [
              RefreshIndicator(
                onRefresh: () async {
                  await Future<void>.delayed(
                    const Duration(milliseconds: 200),
                  );
                },
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    AccountProfileHeaderSection(
                      fields: fields,
                      onChangeSignature: _pickAndReplaceSignature,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: AppMetricCard.heightWithSubtitle,
                            child: AppMetricCard(
                              title: 'Profile complete',
                              value: '$filled/$totalFields',
                              subtitle: filled == totalFields
                                  ? 'All set'
                                  : 'Fill missing fields',
                              icon: Icons.verified_user_outlined,
                              color: filled == totalFields
                                  ? Colors.green
                                  : Colors.indigo,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: AppMetricCard.heightWithSubtitle,
                            child: AppMetricCard(
                              title: 'Business',
                              value: businessReady ? 'Ready' : 'Setup',
                              subtitle: businessReady
                                  ? _str(fields, 'businessName')
                                  : 'Add business name',
                              icon: Icons.storefront_outlined,
                              color:
                                  businessReady ? Colors.teal : Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    AppSectionCard(
                      title: 'Personal information',
                      child: Column(
                        children: [
                          AccountEditableFieldTile(
                            label: 'Name',
                            fieldKey: 'name',
                            icon: Icons.person_outline,
                            valueText: _str(fields, 'name'),
                            onTap: () => showAccountFieldEditDialog(
                              context,
                              label: 'Name',
                              fieldKey: 'name',
                              initialValue: _str(fields, 'name'),
                            ),
                          ),
                          AccountEditableFieldTile(
                            label: 'Phone number',
                            fieldKey: 'phoneNumber',
                            icon: Icons.phone_outlined,
                            valueText: _str(fields, 'phoneNumber'),
                            showDivider: false,
                            onTap: () => showAccountFieldEditDialog(
                              context,
                              label: 'Phone Number',
                              fieldKey: 'phoneNumber',
                              initialValue: _str(fields, 'phoneNumber'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    AppSectionCard(
                      title: 'Business information',
                      child: Column(
                        children: [
                          AccountEditableFieldTile(
                            label: 'Business name',
                            fieldKey: 'businessName',
                            icon: Icons.business_outlined,
                            valueText: _str(fields, 'businessName'),
                            onTap: () => showAccountFieldEditDialog(
                              context,
                              label: 'Business Name',
                              fieldKey: 'businessName',
                              initialValue: _str(fields, 'businessName'),
                            ),
                          ),
                          AccountEditableFieldTile(
                            label: 'Business address',
                            fieldKey: 'businessAddress',
                            icon: Icons.location_on_outlined,
                            valueText: _str(fields, 'businessAddress'),
                            onTap: () => showAccountFieldEditDialog(
                              context,
                              label: 'Business Address',
                              fieldKey: 'businessAddress',
                              initialValue: _str(fields, 'businessAddress'),
                            ),
                          ),
                          AccountEditableFieldTile(
                            label: 'GST number',
                            fieldKey: 'gstNumber',
                            icon: Icons.receipt_long_outlined,
                            valueText: _str(fields, 'gstNumber'),
                            onTap: () => showAccountFieldEditDialog(
                              context,
                              label: 'GST Number',
                              fieldKey: 'gstNumber',
                              initialValue: _str(fields, 'gstNumber'),
                            ),
                          ),
                          AccountEditableFieldTile(
                            label: 'Bill rules',
                            fieldKey: 'billRules',
                            icon: Icons.rule_outlined,
                            valueText: _str(fields, 'billRules'),
                            onTap: () => showAccountFieldEditDialog(
                              context,
                              label: 'Bill Rules',
                              fieldKey: 'billRules',
                              initialValue: _str(fields, 'billRules'),
                            ),
                          ),
                          AccountEditableFieldTile(
                            label: 'Invoice PDF Size',
                            fieldKey: 'pdfBillSize',
                            icon: Icons.picture_as_pdf_outlined,
                            valueText: _formatPdfSize(fields['pdfBillSize']?.toString()),
                            showDivider: false,
                            onTap: () => _showPdfSizeDialog(
                              context,
                              fields['pdfBillSize']?.toString() ?? 'A4',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    AppSectionCard(
                      title: 'AI & automation settings',
                      child: InkWell(
                        onTap: () => context.push('/ai-settings'),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .secondaryContainer
                                      .withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.architecture_outlined,
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Ai settings',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Enable Automations for daily briefs, collections reminders, and reorder alerts.',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    AppSectionCard(
                      title: 'Tools',
                      child: Column(
                        children: [
                          _AccountToolTile(
                            icon: Icons.account_balance_wallet_outlined,
                            iconColor: Colors.green,
                            title: 'Tax & GST Settings',
                            subtitle:
                                'Configure GSTIN, state code & composition',
                            onTap: () => context.push('/app/tax-settings'),
                          ),
                          const Divider(height: 20),
                          _AccountToolTile(
                            icon: Icons.loyalty_outlined,
                            iconColor: Colors.amber,
                            title: 'Loyalty Program',
                            subtitle: 'Configure points and rewards',
                            onTap: () => context.push('/loyalty-settings'),
                          ),
                          const Divider(height: 20),
                          _AccountToolTile(
                            icon: Icons.menu_book_outlined,
                            iconColor: Colors.cyan.shade700,
                            title: 'Day Book',
                            subtitle: 'View daily cash transactions',
                            onTap: () => context.push('/daybook'),
                          ),
                          const Divider(height: 20),
                          _AccountToolTile(
                            icon: Icons.local_shipping_outlined,
                            iconColor: Colors.purple,
                            title: 'Suppliers',
                            subtitle: 'Manage vendors and suppliers',
                            onTap: () => context.push('/suppliers'),
                          ),
                          const Divider(height: 20),
                          _AccountToolTile(
                            icon: Icons.shopping_cart_checkout_outlined,
                            iconColor: Colors.pink,
                            title: 'Purchase Orders',
                            subtitle: 'Track restocking and costs',
                            onTap: () => context.push('/purchase-orders'),
                          ),
                          const Divider(height: 20),
                          _AccountToolTile(
                            icon: Icons.smart_toy_outlined,
                            iconColor: Colors.deepPurple,
                            title: 'Automations',
                            subtitle: 'AI billing, daily brief, reorder alerts',
                            onTap: () => context.push('/ai-settings'),
                          ),
                          const Divider(height: 20),
                          _AccountToolTile(
                            icon: Icons.print_outlined,
                            iconColor: Theme.of(context).colorScheme.secondary,
                            title: 'Printer setup',
                            subtitle: 'Connect receipt printer',
                            onTap: () => context.push('/printer-setup'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
              AccountMutationOverlay(visible: busy),
            ],
          ),
        );
      },
    );
  }
}
