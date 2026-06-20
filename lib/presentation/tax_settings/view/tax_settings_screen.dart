import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:inventopos/application/profile/observe_profile_for_current_user_use_case.dart';
import 'package:inventopos/core/widgets/app_primary_button.dart';
import 'package:inventopos/core/widgets/m3/app_screen_scaffold.dart';
import 'package:inventopos/core/widgets/m3/app_section_card.dart';
import 'package:inventopos/domain/repositories/auth_repository.dart';
import 'package:inventopos/domain/repositories/profile_repository.dart';

import '../bloc/tax_settings_bloc.dart';
import '../bloc/tax_settings_event.dart';
import '../bloc/tax_settings_state.dart';

class TaxSettingsScreen extends StatelessWidget {
  const TaxSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TaxSettingsBloc(
        observeProfile: context.read<ObserveProfileForCurrentUserUseCase>(),
        profileRepository: context.read<ProfileRepository>(),
        authRepository: context.read<AuthRepository>(),
      )..add(const TaxSettingsStarted()),
      child: const _TaxSettingsView(),
    );
  }
}

class _TaxSettingsView extends StatelessWidget {
  const _TaxSettingsView();

  @override
  Widget build(BuildContext context) {
    return AppScreenScaffold(
      title: 'Tax & GST Settings',
      body: BlocConsumer<TaxSettingsBloc, TaxSettingsState>(
        listenWhen: (previous, current) => previous.status != current.status,
        listener: (context, state) {
          if (state.status == TaxSettingsStatus.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Tax settings saved successfully')),
            );
            context.pop();
          } else if (state.status == TaxSettingsStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${state.error}')),
            );
          }
        },
        builder: (context, state) {
          if (state.status == TaxSettingsStatus.loading &&
              state.gstin.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            padding:const EdgeInsets.all(16),
            children: [
              AppSectionCard(
                title: 'GST Configuration',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'GSTIN',
                        hintText: 'Enter 15-digit GSTIN',
                      ),
                      initialValue: state.gstin,
                      onChanged: (v) => context
                          .read<TaxSettingsBloc>()
                          .add(TaxSettingsGstinUpdated(v)),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'State Code (2 digits)',
                        hintText: 'e.g., 27 for Maharashtra',
                      ),
                      initialValue: state.stateCode,
                      onChanged: (v) => context
                          .read<TaxSettingsBloc>()
                          .add(TaxSettingsStateCodeUpdated(v)),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Composition Dealer'),
                      subtitle: const Text(
                          'Enable if you are registered under the composition scheme (no tax calculation on bills).'),
                      value: state.isComposition,
                      onChanged: (v) => context
                          .read<TaxSettingsBloc>()
                          .add(TaxSettingsCompositionToggled(isComposition: v)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              AppPrimaryButton(
                label: 'Save Settings',
                isLoading: state.status == TaxSettingsStatus.loading,
                onPressed: () {
                  context.read<TaxSettingsBloc>().add(const TaxSettingsSaved());
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
