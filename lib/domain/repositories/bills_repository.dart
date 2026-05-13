/// Bills table streams for the signed-in user.
abstract class BillsRepository {
  /// Empty stream if there is no signed-in user.
  Stream<List<Map<String, dynamic>>> watchBillsForCurrentUser();
}
