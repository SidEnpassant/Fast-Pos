import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventopos/core/design/app_spacing.dart';
import 'package:inventopos/core/widgets/m3/app_screen_scaffold.dart';
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
  @override
  void initState() {
    super.initState();
    final uid = context.read<AuthRepository>().currentSession?.userId;
    if (uid != null) {
      context.read<AutomationSettingsBloc>().add(AutomationSettingsStarted(uid));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScreenScaffold(
      title: 'Smart Assistant',
      body: BlocConsumer<AutomationSettingsBloc, AutomationSettingsState>(
        listener: (context, state) {
          if (state.saved) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Settings saved')),
            );
          }
        },
        builder: (context, state) {
          if (state.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          final p = state.preferences;
          if (p == null) {
            return const Center(child: Text('Sign in to configure AI'));
          }
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              const Text(
                'Fast-Pos uses cloud AI (Groq) via secure servers. '
                'Your API key never lives on this device. '
                'Voice and billing suggestions require your confirmation before applying.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: AppSpacing.lg),
              SwitchListTile(
                title: const Text('Enable Smart Assistant'),
                subtitle: const Text('Required for AI billing, briefings, alerts'),
                value: p.enabled,
                onChanged: (v) => context
                    .read<AutomationSettingsBloc>()
                    .add(AutomationSettingsEnabledToggled(v)),
              ),
              SwitchListTile(
                title: const Text('Daily business brief'),
                value: p.dailyBriefEnabled,
                onChanged: p.enabled
                    ? (v) => context.read<AutomationSettingsBloc>().add(
                          AutomationSettingsDailyBriefToggled(v),
                        )
                    : null,
              ),
              SwitchListTile(
                title: const Text('Reorder alerts'),
                value: p.reorderAlertsEnabled,
                onChanged: p.enabled
                    ? (v) => context.read<AutomationSettingsBloc>().add(
                          AutomationSettingsReorderToggled(v),
                        )
                    : null,
              ),
              SwitchListTile(
                title: const Text('Enhanced context'),
                subtitle: const Text('Send barcode hints for better matching (Hinglish)'),
                value: p.enhancedContext,
                onChanged: p.enabled
                    ? (v) => context.read<AutomationSettingsBloc>().add(
                          AutomationSettingsEnhancedToggled(v),
                        )
                    : null,
              ),
              ListTile(
                title: const Text('Language'),
                subtitle: Text(p.language == 'hi' ? 'Hindi / Hinglish' : 'English'),
                trailing: DropdownButton<String>(
                  value: p.language,
                  items: const [
                    DropdownMenuItem(value: 'en', child: Text('English')),
                    DropdownMenuItem(value: 'hi', child: Text('Hindi / Hinglish')),
                  ],
                  onChanged: p.enabled
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
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
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
