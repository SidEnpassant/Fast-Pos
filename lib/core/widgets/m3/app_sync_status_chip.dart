import 'package:flutter/material.dart';

class AppSyncStatusChip extends StatelessWidget {
  const AppSyncStatusChip({
    super.key,
    required this.isOnline,
    this.pendingCount = 0,
  });

  final bool isOnline;
  final int pendingCount;

  @override
  Widget build(BuildContext context) {
    if (isOnline && pendingCount == 0) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    final offline = !isOnline;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Chip(
        avatar: Icon(
          offline ? Icons.cloud_off : Icons.cloud_upload,
          size: 18,
          color: offline ? theme.colorScheme.error : theme.colorScheme.tertiary,
        ),
        label: Text(
          offline
              ? 'Offline'
              : '$pendingCount pending sync',
          style: theme.textTheme.labelSmall,
        ),
        backgroundColor: offline
            ? theme.colorScheme.errorContainer
            : theme.colorScheme.tertiaryContainer,
      ),
    );
  }
}
