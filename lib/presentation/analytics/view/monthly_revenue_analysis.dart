import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventopos/presentation/analytics/bloc/analytics_hub_bloc.dart';
import 'package:inventopos/presentation/analytics/widgets/analytics_message_center.dart';
import 'package:inventopos/presentation/analytics/widgets/analytics_revenue_app_bar.dart';
import 'package:inventopos/presentation/analytics/widgets/analytics_revenue_content.dart';
import 'package:inventopos/presentation/analytics/widgets/analytics_shimmer_placeholder.dart';

class MonthlyRevenueAnalysis extends StatelessWidget {
  const MonthlyRevenueAnalysis({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AnalyticsHubBloc, AnalyticsHubState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AnalyticsRevenueAppBar(showChart: state.showChart),
          body: state.loading
              ? const AnalyticsShimmerPlaceholder()
              : !state.hasRevenueData
                  ? const AnalyticsMessageCenter(
                      message: 'No transaction data available',
                    )
                  : AnalyticsRevenueContent(state: state),
        );
      },
    );
  }
}
