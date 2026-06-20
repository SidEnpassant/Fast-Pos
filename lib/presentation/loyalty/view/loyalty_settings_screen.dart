import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    
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
        final isLoading = state.status == LoyaltyStatus.loading && state.config.pointsPerCurrencyUnit == 1.0;
        
        return AppScreenScaffold(
          title: 'Loyalty Program',
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Enable Toggle Banner
                            _buildEnableBanner(theme, scheme).animate().fadeIn().slideX(begin: -0.1),
                            
                            SizedBox(height: AppSpacing.lg),
                            
                            if (_isEnabled) ...[
                              // 2. Analytics Mock Row
                              _buildAnalyticsRow(theme).animate().fadeIn(delay: 200.ms),
                              SizedBox(height: AppSpacing.lg),
                              
                              // 3. Customer Preview Card
                              Text(
                                'Customer Card Preview',
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ).animate().fadeIn(delay: 300.ms),
                              SizedBox(height: AppSpacing.sm),
                              _buildCustomerCardPreview(theme).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
                              
                              SizedBox(height: AppSpacing.xl),
                              
                              // 4. Configuration Form
                              Form(
                                key: _formKey,
                                child: Column(
                                  children: [
                                    _buildConfigSection(theme).animate().fadeIn(delay: 500.ms),
                                    SizedBox(height: AppSpacing.xl),
                                    _buildTierSection(theme).animate().fadeIn(delay: 600.ms),
                                  ],
                                ),
                              ),
                              
                              SizedBox(height: AppSpacing.xl),
                              
                              // 5. Save Button
                              SizedBox(
                                width: double.infinity,
                                height: 56,
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
                                  style: FilledButton.styleFrom(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                  child: state.status == LoyaltyStatus.loading
                                      ? const SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                                        )
                                      : const Text('Save Configuration', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                ),
                              ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.1),
                              const SizedBox(height: 40),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildEnableBanner(ThemeData theme, ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: _isEnabled ? scheme.primaryContainer : scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _isEnabled ? scheme.primary.withValues(alpha: 0.5) : Colors.transparent,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _isEnabled ? scheme.primary : scheme.outlineVariant,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.stars,
              color: _isEnabled ? scheme.onPrimary : scheme.surfaceContainerHigh,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Loyalty Program',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _isEnabled ? scheme.onPrimaryContainer : scheme.onSurface,
                  ),
                ),
                Text(
                  _isEnabled ? 'Active and running' : 'Disabled',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: _isEnabled ? scheme.primary : scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isEnabled,
            activeThumbColor: scheme.primary,
            onChanged: (val) => setState(() => _isEnabled = val),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsRow(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            theme,
            title: 'Points Issued',
            value: '45,200',
            icon: Icons.auto_awesome,
            color: Colors.amber.shade700,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            theme,
            title: 'Points Redeemed',
            value: '12,500',
            icon: Icons.card_giftcard,
            color: Colors.green.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(ThemeData theme, {required String title, required String value, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCardPreview(ThemeData theme) {
    return Container(
      width: double.infinity,
      height: 200,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            Colors.amber.shade300,
            Colors.amber.shade700,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.storefront, color: Colors.white, size: 28),
                  const SizedBox(width: 8),
                  Text(
                    'Your Store Name',
                    style: theme.textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'GOLD TIER',
                  style: theme.textTheme.labelSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Avinash Kumar',
                    style: theme.textTheme.titleMedium?.copyWith(color: Colors.white.withValues(alpha: 0.9)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Customer since 2024',
                    style: theme.textTheme.labelSmall?.copyWith(color: Colors.white.withValues(alpha: 0.7)),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '1,240',
                    style: theme.textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w900),
                  ),
                  Text(
                    'Points Available',
                    style: theme.textTheme.labelMedium?.copyWith(color: Colors.white.withValues(alpha: 0.9)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConfigSection(ThemeData theme) {
    return AppSectionCard(
      title: 'Earning & Redemption Rules',
      child: Column(
        children: [
          _buildPremiumTextField(
            controller: _pointsPerCurrencyController,
            label: 'Points earned per ₹1 spent',
            icon: Icons.add_circle_outline,
            theme: theme,
          ),
          SizedBox(height: AppSpacing.lg),
          _buildPremiumTextField(
            controller: _currencyPerPointController,
            label: '₹ Value per 1 Point',
            icon: Icons.currency_rupee,
            theme: theme,
          ),
          SizedBox(height: AppSpacing.lg),
          _buildPremiumTextField(
            controller: _minPointsController,
            label: 'Minimum Points to Redeem',
            icon: Icons.lock_outline,
            theme: theme,
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required ThemeData theme,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: theme.colorScheme.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerLowest,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Required';
        if (double.tryParse(value) == null) return 'Invalid number';
        return null;
      },
    );
  }
  
  Widget _buildTierSection(ThemeData theme) {
    return AppSectionCard(
      title: 'Membership Tiers',
      child: Column(
        children: [
          _buildTierRow('Bronze', '0 points', '1x Earning', Colors.brown.shade400, theme),
          const SizedBox(height: 12),
          _buildTierRow('Silver', '1,000 points', '1.2x Earning', Colors.blueGrey.shade300, theme),
          const SizedBox(height: 12),
          _buildTierRow('Gold', '5,000 points', '1.5x Earning', Colors.amber.shade600, theme),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Custom Tiers coming soon!')));
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Custom Tier'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTierRow(String name, String req, String multiplier, Color color, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.shield, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: color)),
                Text(req, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(multiplier, style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold, color: color)),
          ),
        ],
      ),
    );
  }
}
