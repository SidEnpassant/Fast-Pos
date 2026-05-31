import 'package:inventopos/domain/repositories/bills_repository.dart';

/// Partial-bill reminders are created server-side (Edge Functions + dedup_key).
class SyncOverduePartialBillNotificationsUseCase {
  SyncOverduePartialBillNotificationsUseCase(this._bills);

  final BillsRepository _bills;

  Future<void> call({
    required String userId,
    Duration overdueAfter = const Duration(days: 5),
  }) async {
    // Server-side only — client no longer inserts duplicate notifications.
    await _bills.fetchPartialBillsForUser(userId);
  }
}
