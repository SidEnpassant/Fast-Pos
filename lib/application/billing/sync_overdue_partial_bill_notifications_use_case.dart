import 'package:inventopos/domain/repositories/bills_repository.dart';
import 'package:inventopos/domain/repositories/notifications_repository.dart';

/// Creates notifications for partial bills older than [olderThan].
class SyncOverduePartialBillNotificationsUseCase {
  SyncOverduePartialBillNotificationsUseCase(
    this._bills,
    this._notifications,
  );

  final BillsRepository _bills;
  final NotificationsRepository _notifications;

  Future<void> call({
    required String userId,
    Duration overdueAfter = const Duration(days: 5),
  }) async {
    final bills = await _bills.fetchPartialBillsForUser(userId);
    final cutoff = DateTime.now().subtract(overdueAfter);
    for (final b in bills) {
      if (b.createdAt.isBefore(cutoff)) {
        await _notifications.insertPaymentDueNotification(
          userId: userId,
          customerName: b.customerName,
        );
      }
    }
  }
}
