import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventopos/core/design/app_radii.dart';
import 'package:inventopos/core/widgets/m3/app_section_card.dart';
import 'package:inventopos/domain/entities/customer.dart';
import 'package:inventopos/domain/loyalty/loyalty_config.dart';
import 'package:inventopos/domain/loyalty/loyalty_engine.dart';
import 'package:inventopos/domain/repositories/loyalty_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CustomerLoyaltyCard extends StatelessWidget {
  const CustomerLoyaltyCard({super.key, required this.customer});

  final Customer customer;

  Future<LoyaltyConfig> _fetchConfig(BuildContext context) async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return const LoyaltyConfig();
    return context.read<LoyaltyRepository>().getLoyaltyConfig(uid);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return FutureBuilder<LoyaltyConfig>(
      future: _fetchConfig(context),
      builder: (context, snapshot) {
        final config = snapshot.data ?? const LoyaltyConfig();
        
        String tier = 'Standard';
        Color tierColor = Colors.grey;
        
        if (config.isEnabled) {
          final currentTier = LoyaltyEngine.currentTier(customer.lifetimePoints, config.tiers);
          if (currentTier != null) {
            tier = currentTier.name;
            if (tier.toLowerCase().contains('gold')) {
              tierColor = Colors.orange;
            } else if (tier.toLowerCase().contains('plat')) {
              tierColor = Colors.blueGrey;
            } else if (tier.toLowerCase().contains('silver')) {
              tierColor = Colors.grey;
            } else {
              tierColor = Colors.brown;
            }
          }
        }

        return AppSectionCard(
          title: 'Loyalty Program',
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: tierColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadii.xl),
                      border: Border.all(color: tierColor.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.stars, color: tierColor, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          tier,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: tierColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Balance',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '${customer.loyaltyPoints} pts',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lifetime earned',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          '${customer.lifetimePoints} pts',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.history, size: 20, color: Colors.grey),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
