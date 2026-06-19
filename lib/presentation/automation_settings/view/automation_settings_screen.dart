import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventopos/core/design/app_spacing.dart';
import 'package:inventopos/core/widgets/m3/app_screen_scaffold.dart';
import 'package:inventopos/core/widgets/shimmer/app_shimmer.dart';
import 'package:inventopos/core/widgets/shimmer/specialized_skeletons.dart';
import 'package:inventopos/domain/repositories/auth_repository.dart';
import 'package:inventopos/presentation/automation_settings/bloc/automation_settings_bloc.dart';
import 'package:inventopos/presentation/automation_settings/bloc/automation_settings_event.dart';
import 'package:inventopos/presentation/automation_settings/bloc/automation_settings_state.dart';

class AutomationSettingsScreen extends StatefulWidget {
  const AutomationSettingsScreen({super.key});

  @override
  State<AutomationSettingsScreen> createState() =>
      _AutomationSettingsScreenState();
}

class _AutomationSettingsScreenState extends State<AutomationSettingsScreen> {
  final _ownerPhone = TextEditingController();
  final _supplierPhone = TextEditingController();

  @override
  void dispose() {
    _ownerPhone.dispose();
    _supplierPhone.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final uid = context.read<AuthRepository>().currentSession?.userId;
    if (uid != null) {
      context
          .read<AutomationSettingsBloc>()
          .add(AutomationSettingsStarted(uid));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScreenScaffold(
      title: 'Automations',
      body: BlocConsumer<AutomationSettingsBloc, AutomationSettingsState>(
        listener: (context, state) {
          if (state.saved) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Settings saved')),
            );
          }
          final p = state.preferences;
          if (p != null) {
            if (_ownerPhone.text != (p.ownerWhatsAppPhone ?? '')) {
              _ownerPhone.text = p.ownerWhatsAppPhone ?? '';
            }
            if (_supplierPhone.text != (p.supplierWhatsAppPhone ?? '')) {
              _supplierPhone.text = p.supplierWhatsAppPhone ?? '';
            }
          }
        },
        builder: (context, state) {
          if (state.loading) {
            return const AppSkeletonList(itemCount: 12);
          }
          final p = state.preferences;
          if (p == null) {
            return const Center(
                child: Text('Sign in to configure automations'));
          }
          final on = p.enabled;
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              const Text(
                'Automations use rules on-device and optional cloud AI (Groq via secure servers). '
                'WhatsApp and SMS open your messaging app — nothing is sent automatically.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: AppSpacing.lg),
              SwitchListTile(
                title: const Text('Enable Automations'),
                subtitle:
                    const Text('Required for briefs, alerts, and messages'),
                value: p.enabled,
                onChanged: (v) => context
                    .read<AutomationSettingsBloc>()
                    .add(AutomationSettingsEnabledToggled(v)),
              ),
              const Divider(),
              const ListTile(title: Text('Collections')),
              SwitchListTile(
                title: const Text('Partial bill reminders'),
                value: p.partialBillRemindersEnabled,
                onChanged: on
                    ? (v) => context.read<AutomationSettingsBloc>().add(
                          AutomationSettingsPartialBillToggled(v),
                        )
                    : null,
              ),
              SwitchListTile(
                title: const Text('Credit exposure alerts'),
                value: p.creditAlertsEnabled,
                onChanged: on
                    ? (v) => context.read<AutomationSettingsBloc>().add(
                          AutomationSettingsCreditAlertsToggled(v),
                        )
                    : null,
              ),
              SwitchListTile(
                title: const Text('Auto receipt share prompt'),
                value: p.autoReceiptShareEnabled,
                onChanged: on
                    ? (v) => context.read<AutomationSettingsBloc>().add(
                          AutomationSettingsReceiptShareToggled(v),
                        )
                    : null,
              ),
              SwitchListTile(
                title: const Text('Payment thank-you message'),
                value: p.paymentThankYouEnabled,
                onChanged: on
                    ? (v) => context.read<AutomationSettingsBloc>().add(
                          AutomationSettingsThankYouToggled(v),
                        )
                    : null,
              ),
              const Divider(),
              const ListTile(title: Text('Inventory')),
              SwitchListTile(
                title: const Text('Reorder alerts'),
                value: p.reorderAlertsEnabled,
                onChanged: on
                    ? (v) => context.read<AutomationSettingsBloc>().add(
                          AutomationSettingsReorderToggled(v),
                        )
                    : null,
              ),
              const Divider(),
              const ListTile(title: Text('Day operations')),
              SwitchListTile(
                title: const Text('Daily business brief'),
                value: p.dailyBriefEnabled,
                onChanged: on
                    ? (v) => context.read<AutomationSettingsBloc>().add(
                          AutomationSettingsDailyBriefToggled(v),
                        )
                    : null,
              ),
              SwitchListTile(
                title: const Text('End-of-day summary'),
                value: p.eodSummaryEnabled,
                onChanged: on
                    ? (v) => context.read<AutomationSettingsBloc>().add(
                          AutomationSettingsEodSummaryToggled(v),
                        )
                    : null,
              ),
              const Divider(),
              const ListTile(title: Text('Messages & WhatsApp')),
              TextField(
                controller: _ownerPhone,
                decoration: const InputDecoration(
                  labelText: 'Owner WhatsApp (EOD summary)',
                  hintText: '10-digit mobile',
                ),
                keyboardType: TextInputType.phone,
                enabled: on,
                onChanged: (v) => context.read<AutomationSettingsBloc>().add(
                      AutomationSettingsOwnerPhoneChanged(v),
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _supplierPhone,
                decoration: const InputDecoration(
                  labelText: 'Supplier WhatsApp (reorder)',
                  hintText: '10-digit mobile',
                ),
                keyboardType: TextInputType.phone,
                enabled: on,
                onChanged: (v) => context.read<AutomationSettingsBloc>().add(
                      AutomationSettingsSupplierPhoneChanged(v),
                    ),
              ),
              SwitchListTile(
                title: const Text('Enhanced context (AI brief)'),
                value: p.enhancedContext,
                onChanged: on
                    ? (v) => context.read<AutomationSettingsBloc>().add(
                          AutomationSettingsEnhancedToggled(v),
                        )
                    : null,
              ),
              ListTile(
                title: const Text('Language'),
                trailing: DropdownButton<String>(
                  value: p.language,
                  items: const [
                    DropdownMenuItem(value: 'en', child: Text('English')),
                    DropdownMenuItem(
                        value: 'hi', child: Text('Hindi / Hinglish')),
                  ],
                  onChanged: on
                      ? (v) {
                          if (v != null) {
                            context.read<AutomationSettingsBloc>().add(
                                  AutomationSettingsLanguageChanged(v),
                                );
                          }
                        }
                      : null,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: state.saving
                    ? null
                    : () => context
                        .read<AutomationSettingsBloc>()
                        .add(const AutomationSettingsSaveRequested()),
                child: state.saving
                    ? const AppShimmer(
                        child: Text('Save'),
                      )
                    : const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }
}
