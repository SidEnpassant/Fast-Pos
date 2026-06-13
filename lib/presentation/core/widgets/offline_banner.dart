import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventopos/presentation/core/bloc/connectivity_bloc.dart';
import 'package:inventopos/presentation/core/bloc/connectivity_state.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ConnectivityBloc, ConnectivityState, bool>(
      selector: (state) => state.isOnline,
      builder: (context, isOnline) {
        if (isOnline) {
          return child;
        }
        return BlocSelector<ConnectivityBloc, ConnectivityState, int>(
          selector: (state) => state.pendingSyncCount,
          builder: (context, pendingSyncCount) {
            return Column(
              children: [
                MaterialBanner(
                  content: Text(
                    pendingSyncCount > 0
                        ? 'Offline — $pendingSyncCount changes pending sync'
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
      },
    );
  }
}
