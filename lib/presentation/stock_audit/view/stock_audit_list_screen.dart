import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:inventopos/core/widgets/m3/app_screen_scaffold.dart';
import 'package:inventopos/core/widgets/m3/app_section_card.dart';
import 'package:inventopos/domain/entities/stock_audit.dart';
import 'package:inventopos/presentation/stock_audit/bloc/stock_audit_bloc.dart';

class StockAuditListScreen extends StatelessWidget {
  const StockAuditListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScreenScaffold(
      title: 'Stock Audits',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.read<StockAuditBloc>().add(const StartNewAudit());
        },
        icon: const Icon(Icons.add),
        label: const Text('Start Audit'),
      ),
      body: BlocConsumer<StockAuditBloc, StockAuditState>(
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
          if (state.status == StockAuditViewState.loading && state.audits.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.audits.isEmpty) {
            return const Center(child: Text('No audits yet. Start one to begin.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.audits.length,
            itemBuilder: (context, index) {
              final audit = state.audits[index];
              return AppSectionCard(
                title: 'Audit ${DateFormat('dd MMM yyyy').format(audit.auditDate)}',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                         _getStatusIcon(audit.status),
                         const SizedBox(width: 8),
                         Text('Status: ${audit.status.name.toUpperCase()}'),
                      ]
                    ),
                    const SizedBox(height: 8),
                    Text('Started: ${DateFormat('hh:mm a').format(audit.createdAt)}'),
                    if (audit.completedAt != null)
                      Text('Completed: ${DateFormat('hh:mm a').format(audit.completedAt!)}'),
                    if (audit.notes != null && audit.notes!.isNotEmpty)
                      Text('Notes: ${audit.notes}'),
                    const SizedBox(height: 8),
                    Text('${audit.lines.length} items audited'),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _getStatusIcon(StockAuditStatus status) {
    switch (status) {
      case StockAuditStatus.inProgress:
        return const Icon(Icons.sync, color: Colors.blue);
      case StockAuditStatus.completed:
        return const Icon(Icons.check_circle, color: Colors.green);
      case StockAuditStatus.cancelled:
        return const Icon(Icons.cancel, color: Colors.red);
    }
  }
}
