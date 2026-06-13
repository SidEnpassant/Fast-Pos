import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:inventopos/presentation/analytics/bloc/analytics_hub_bloc.dart';

class AnalyticsRevenueAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AnalyticsRevenueAppBar({super.key, required this.showChart});

  final bool showChart;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Row(
        children: [
          const Icon(Icons.analytics_outlined),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Revenue Analysis',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: Icon(
              showChart ? Icons.table_chart : Icons.show_chart,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: () => context.read<AnalyticsHubBloc>().toggleChartTable(),
          ),
        ],
      ),
      elevation: 0,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      iconTheme: IconThemeData(
        color: Theme.of(context).textTheme.bodyLarge?.color,
      ),
      titleTextStyle: TextStyle(
        color: Theme.of(context).textTheme.bodyLarge?.color,
      ),
    );
  }
}
