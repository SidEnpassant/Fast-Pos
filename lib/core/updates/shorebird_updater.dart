import 'package:flutter/material.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

class FastPosShorebirdUpdater {
  static final _updater = ShorebirdUpdater();

  /// Checks for Shorebird updates in the background.
  /// If a patch is available, it downloads it and shows a snackbar to prompt a restart.
  static Future<void> checkForUpdates(BuildContext context) async {
    // Check whether Shorebird is available (it will be false during dev/debug builds)
    if (!_updater.isAvailable) {
      debugPrint(
          'Shorebird is not available in this build (likely a debug build).');
      return;
    }

    try {
      // Check if there is a new patch available
      final status = await _updater.checkForUpdate();

      if (status == UpdateStatus.outdated) {
        debugPrint('New Shorebird patch available! Downloading...');

        // Download the new patch in the background
        await _updater.update();
        debugPrint('Patch downloaded successfully.');

        // Prompt the user to restart the app to apply the update
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                  'A new update was downloaded. Restart the app to apply.'),
              duration: const Duration(seconds: 10),
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'Restart Now',
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Please close the app from your recent apps and open it again.'),
                      duration: Duration(seconds: 5),
                    ),
                  );
                },
              ),
            ),
          );
        }
      } else {
        debugPrint('No Shorebird patches available. App is up to date.');
      }
    } catch (e) {
      debugPrint('Failed to check for Shorebird updates: $e');
    }
  }
}
