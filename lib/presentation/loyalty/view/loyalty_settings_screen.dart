import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventopos/core/design/app_spacing.dart';
import 'package:inventopos/core/widgets/m3/app_screen_scaffold.dart';
import 'package:inventopos/core/widgets/m3/app_section_card.dart';
import 'package:inventopos/domain/loyalty/loyalty_config.dart';
import 'package:inventopos/domain/repositories/auth_repository.dart';
import 'package:inventopos/presentation/loyalty/bloc/loyalty_bloc.dart';
import 'package:inventopos/presentation/loyalty/bloc/loyalty_event.dart';
import 'package:inventopos/presentation/loyalty/bloc/loyalty_state.dart';

class LoyaltySettingsScreen extends StatefulWidget {
  const LoyaltySettingsScreen({super.key});

  @override
  State<LoyaltySettingsScreen> createState() => _LoyaltySettingsScreenState();
}

class _LoyaltySettingsScreenState extends State<LoyaltySettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _pointsPerCurrencyController;
  late TextEditingController _currencyPerPointController;
  late TextEditingController _minPointsController;
  bool _isEnabled = false;

  @override
  void initState() {
    super.initState();
    _pointsPerCurrencyController = TextEditingController();
    _currencyPerPointController = TextEditingController();
    _minPointsController = TextEditingController();

    final userId = context.read<AuthRepository>().currentSession?.userId;
    if (userId != null) {
      context.read<LoyaltyBloc>().add(LoadLoyaltyConfig(userId));
    }
  }

  @override
  void dispose() {
    _pointsPerCurrencyController.dispose();
    _currencyPerPointController.dispose();
    _minPointsController.dispose();
    super.dispose();
  }

  void _updateControllers(LoyaltyConfig config) {
    _isEnabled = config.isEnabled;
    _pointsPerCurrencyController.text = config.pointsPerCurrencyUnit.toString();
    _currencyPerPointController.text = config.currencyUnitPerPoint.toString();
    _minPointsController.text = config.minPointsToRedeem.toString();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LoyaltyBloc, LoyaltyState>(
      listener: (context, state) {
        if (state.status == LoyaltyStatus.success) {
          _updateControllers(state.config);
        } else if (state.status == LoyaltyStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error ?? 'Failed to load config')),
          );
        }
      },
      builder: (context, state) {
        return AppScreenScaffold(
          title: 'Loyalty Program',
          body: state.status == LoyaltyStatus.loading && state.config.pointsPerCurrencyUnit == 1.0
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppSectionCard(
                          title: 'General Settings',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SwitchListTile(
                                title: const Text('Enable Loyalty Program'),
                                subtitle: const Text('Allow customers to earn and redeem points'),
                                value: _isEnabled,
                                onChanged: (value) {
                                  setState(() {
                                    _isEnabled = value;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        if (_isEnabled) ...[
                          const SizedBox(height: AppSpacing.md),
                          AppSectionCard(
                            title: 'Points Configuration',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextFormField(
                                  controller: _pointsPerCurrencyController,
                                  decoration: const InputDecoration(
                                    labelText: 'Points earned per currency unit spent',
                                    helperText: 'e.g., 1 point per \$1',
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) return 'Required';
                                    if (double.tryParse(value) == null) return 'Invalid number';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: AppSpacing.md),
                                TextFormField(
                                  controller: _currencyPerPointController,
                                  decoration: const InputDecoration(
                                    labelText: 'Currency value per point',
                                    helperText: 'e.g., \$0.10 per point (10 points = \$1)',
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) return 'Required';
                                    if (double.tryParse(value) == null) return 'Invalid number';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: AppSpacing.md),
                                TextFormField(
                                  controller: _minPointsController,
                                  decoration: const InputDecoration(
                                    labelText: 'Minimum points to redeem',
                                    helperText: 'Customers must have at least this many points',
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) return 'Required';
                                    if (int.tryParse(value) == null) return 'Invalid number';
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.xl),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: state.status == LoyaltyStatus.loading
                                ? null
                                : () {
                                    if (_formKey.currentState!.validate()) {
                                      final userId = context.read<AuthRepository>().currentSession?.userId;
                                      if (userId != null) {
                                        final config = LoyaltyConfig(
                                          isEnabled: _isEnabled,
                                          pointsPerCurrencyUnit: double.parse(_pointsPerCurrencyController.text),
                                          currencyUnitPerPoint: double.parse(_currencyPerPointController.text),
                                          minPointsToRedeem: int.parse(_minPointsController.text),
                                        );
                                        context.read<LoyaltyBloc>().add(SaveLoyaltyConfig(userId, config));
                                      }
                                    }
                                  },
                            child: state.status == LoyaltyStatus.loading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text('Save Settings'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }
}
