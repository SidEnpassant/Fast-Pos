import 'package:inventopos/domain/entities/bill.dart';
import 'package:inventopos/domain/repositories/bills_repository.dart';

/// Exposes the bills watch stream (domain-facing façade for Blocs).
class ObserveBillsUseCase {
  const ObserveBillsUseCase(this._billsRepository);

  final BillsRepository _billsRepository;

  Stream<List<Bill>> call() => _billsRepository.watchBillsForCurrentUser();
}
