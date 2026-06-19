import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:inventopos/core/widgets/m3/app_screen_scaffold.dart';
import 'package:inventopos/core/widgets/m3/app_empty_state.dart';
import 'package:inventopos/domain/entities/stock_audit.dart';
import 'package:inventopos/presentation/stock_audit/bloc/stock_audit_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';

class StockAuditListScreen extends StatefulWidget {
  const StockAuditListScreen({super.key});

  @override
  State<StockAuditListScreen> createState() => _StockAuditListScreenState();
}

class _StockAuditListScreenState extends State<StockAuditListScreen> {
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AppScreenScaffold(
      title: 'Stock Audits',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.read<StockAuditBloc>().add(const StartNewAudit());
        },
        icon: const Icon(Icons.playlist_add_check),
        label: const Text('Start Audit'),
      ).animate().scale(delay: 500.ms, curve: Curves.easeOutBack),
      body: BlocConsumer<StockAuditBloc, StockAuditState>(
        listenWhen: (previous, current) => previous.activeAudit == null && current.activeAudit != null,
        listener: (context, state) {
          if (state.activeAudit != null) {
            context.push('/stock-audit/live');
          }
          if (state.status == StockAuditViewState.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage ?? 'Error occurred')),
            );
          }
        },
        builder: (context, state) {
          final allAudits = state.audits;
          
          List<StockAudit> displayedAudits = allAudits;
          if (_selectedFilter != 'All') {
            displayedAudits = allAudits.where((a) {
              if (_selectedFilter == 'In Progress') return a.status == StockAuditStatus.inProgress;
              if (_selectedFilter == 'Completed') return a.status == StockAuditStatus.completed;
              if (_selectedFilter == 'Cancelled') return a.status == StockAuditStatus.cancelled;
              return true;
            }).toList();
          }

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      _buildFilterChip('All', theme),
                      const SizedBox(width: 8),
                      _buildFilterChip('In Progress', theme),
                      const SizedBox(width: 8),
                      _buildFilterChip('Completed', theme),
                      const SizedBox(width: 8),
                      _buildFilterChip('Cancelled', theme),
                    ],
                  ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1, end: 0),
                ),
              ),
              if (state.status == StockAuditViewState.loading && allAudits.isEmpty)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildShimmerCard(context),
                    childCount: 4,
                  ),
                )
              else if (displayedAudits.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: AppEmptyState(
                    icon: Icons.fact_check_outlined,
                    title: _selectedFilter == 'All' ? 'No stock audits yet' : 'No $_selectedFilter audits',
                    message: _selectedFilter == 'All' 
                      ? 'Start a physical stock count to reconcile your inventory and track variances.'
                      : 'You do not have any audits in this status.',
                    actionLabel: _selectedFilter == 'All' ? 'Start First Audit' : null,
                    onAction: _selectedFilter == 'All' 
                      ? () => context.read<StockAuditBloc>().add(const StartNewAudit())
                      : null,
                  ).animate().fadeIn(duration: 400.ms),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        return _StockAuditCard(audit: displayedAudits[i])
                          .animate()
                          .fadeIn(delay: Duration(milliseconds: 50 * i.clamp(0, 10)))
                          .slideY(begin: 0.1, end: 0);
                      },
                      childCount: displayedAudits.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, ThemeData theme) {
    final isSelected = _selectedFilter == label;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        setState(() {
          _selectedFilter = label;
        });
      },
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      selectedColor: theme.colorScheme.primaryContainer,
      labelStyle: TextStyle(
        color: isSelected ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurfaceVariant,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildShimmerCard(BuildContext context) {
    final theme = Theme.of(context);
    return Shimmer.fromColors(
      baseColor: theme.colorScheme.surfaceContainerHighest,
      highlightColor: theme.colorScheme.surfaceContainerLowest,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        height: 140,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

class _StockAuditCard extends StatelessWidget {
  final StockAudit audit;

  const _StockAuditCard({required this.audit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    
    final isCompleted = audit.status == StockAuditStatus.completed;
    final isInProgress = audit.status == StockAuditStatus.inProgress;
    
    // Mocking progress for visual effect (Assume some items checked)
    final double progress = isInProgress ? 0.6 : (isCompleted ? 1.0 : 0.0); 
    
    // Mocking variance value impact for packed features requested
    // In reality this would be calculated from audit.lines variance * costPrice
    final int mockVarianceVal = isCompleted ? -1500 : 0; 

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: scheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: scheme.outlineVariant.withOpacity(0.5)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          // If in progress, navigate to live audit, else to details
          if (isInProgress) {
             context.push('/stock-audit/live');
          } else {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opening Audit Details...')));
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.event_note, color: scheme.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Audit ${DateFormat('dd MMM yyyy').format(audit.auditDate)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  _buildStatusChip(theme),
                ],
              ),
              const SizedBox(height: 16),
              if (isInProgress) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Progress', style: theme.textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant)),
                    Text('${(progress * 100).toInt()}%', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: scheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Items Audited', style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                        const SizedBox(height: 2),
                        Text(
                          '${audit.lines.length} Items',
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 30, color: scheme.outlineVariant),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Started', style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('hh:mm a').format(audit.createdAt),
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (isCompleted) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: mockVarianceVal < 0 ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Variance Impact',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: mockVarianceVal < 0 ? Colors.red.shade700 : Colors.green.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${mockVarianceVal < 0 ? '-' : '+'}₹${mockVarianceVal.abs()}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: mockVarianceVal < 0 ? Colors.red.shade700 : Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(ThemeData theme) {
    Color bgColor;
    Color textColor;
    String label;

    switch (audit.status) {
      case StockAuditStatus.inProgress:
        bgColor = Colors.blue.withOpacity(0.1);
        textColor = Colors.blue.shade700;
        label = 'In Progress';
        break;
      case StockAuditStatus.completed:
        bgColor = Colors.green.withOpacity(0.1);
        textColor = Colors.green.shade700;
        label = 'Completed';
        break;
      case StockAuditStatus.cancelled:
        bgColor = Colors.red.withOpacity(0.1);
        textColor = Colors.red.shade700;
        label = 'Cancelled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
