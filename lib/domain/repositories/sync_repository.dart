abstract class SyncRepository {
  Stream<int> watchPendingOutboxCount(String userId);

  Future<void> enqueue({
    required String userId,
    required String operationType,
    required Map<String, dynamic> payload,
  });

  Future<int> processOutbox(String userId);

  Future<bool> isOnline();
}
