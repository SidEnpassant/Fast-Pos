import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventopos/presentation/core/bloc/connectivity_bloc.dart';
import 'package:inventopos/presentation/core/bloc/connectivity_state.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectivityBloc, ConnectivityState>(
      builder: (context, state) {
        return Column(
          children: [
            if (!state.isOnline)
              MaterialBanner(
                content: Text(
                  state.pendingSyncCount > 0
                      ? 'Offline — ${state.pendingSyncCount} changes pending sync'
                      : 'Offline mode — changes will sync when connected',
                ),
                leading: const Icon(Icons.cloud_off),
                actions: const [SizedBox.shrink()],
              ),
            Expanded(child: child),
          ],
        );
      },
    );
  }
}
