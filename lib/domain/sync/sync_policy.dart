/// Conflict resolution policies for dual-database sync.
abstract final class SyncPolicy {
  static const serverAuthoritativeEntities = {'products'};
  static const clientIdempotentEntities = {'bills'};
  static const lastWriteWinsEntities = {'expenses', 'customers'};
}
