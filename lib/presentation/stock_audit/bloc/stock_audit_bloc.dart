import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventopos/application/stock_audit/complete_stock_audit_use_case.dart';
import 'package:inventopos/application/stock_audit/start_stock_audit_use_case.dart';
import 'package:inventopos/domain/entities/stock_audit.dart';
import 'package:inventopos/domain/repositories/auth_repository.dart';
import 'package:inventopos/domain/repositories/stock_audit_repository.dart';
import 'package:inventopos/domain/stock_audit/variance_calculator.dart';

part 'stock_audit_event.dart';
part 'stock_audit_state.dart';

class StockAuditBloc extends Bloc<StockAuditEvent, StockAuditState> {
  final StockAuditRepository _stockAuditRepository;
  final StartStockAuditUseCase _startStockAuditUseCase;
  final CompleteStockAuditUseCase _completeStockAuditUseCase;
  final AuthRepository _authRepository;
  StreamSubscription? _auditsSubscription;

  StockAuditBloc({
    required StockAuditRepository stockAuditRepository,
    required StartStockAuditUseCase startStockAuditUseCase,
    required CompleteStockAuditUseCase completeStockAuditUseCase,
    required AuthRepository authRepository,
  })  : _stockAuditRepository = stockAuditRepository,
        _startStockAuditUseCase = startStockAuditUseCase,
        _completeStockAuditUseCase = completeStockAuditUseCase,
        _authRepository = authRepository,
        super(const StockAuditState()) {
    on<LoadStockAudits>(_onLoadStockAudits);
    on<StockAuditsUpdated>(_onStockAuditsUpdated);
    on<StartNewAudit>(_onStartNewAudit);
    on<UpdateAuditLineQuantity>(_onUpdateAuditLineQuantity);
    on<CompleteAudit>(_onCompleteAudit);
    on<CancelAudit>(_onCancelAudit);
  }

  String? get _userId => _authRepository.currentSession?.userId;

  Future<void> _onLoadStockAudits(
    LoadStockAudits event,
    Emitter<StockAuditState> emit,
  ) async {
    final uid = _userId;
    if (uid == null) {
      emit(state.copyWith(
        status: StockAuditViewState.failure,
        errorMessage: 'User not authenticated',
      ));
      return;
    }
    emit(state.copyWith(status: StockAuditViewState.loading));
    await _auditsSubscription?.cancel();
    _auditsSubscription = _stockAuditRepository.watchAudits(uid).listen(
          (audits) => add(StockAuditsUpdated(audits)),
        );
  }

  void _onStockAuditsUpdated(
    StockAuditsUpdated event,
    Emitter<StockAuditState> emit,
  ) {
    StockAudit? activeAudit;
    try {
      activeAudit = event.audits.firstWhere(
        (a) => a.status == StockAuditStatus.inProgress,
      );
    } catch (_) {
      activeAudit = null;
    }

    emit(state.copyWith(
      status: StockAuditViewState.success,
      audits: event.audits,
      activeAudit: activeAudit,
    ));
  }

  Future<void> _onStartNewAudit(
    StartNewAudit event,
    Emitter<StockAuditState> emit,
  ) async {
    final uid = _userId;
    if (uid == null) return;

    try {
      emit(state.copyWith(status: StockAuditViewState.loading));
      await _startStockAuditUseCase.call(uid, notes: event.notes);
      // The watchAudits will update the state
    } catch (e) {
      emit(state.copyWith(
        status: StockAuditViewState.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onUpdateAuditLineQuantity(
    UpdateAuditLineQuantity event,
    Emitter<StockAuditState> emit,
  ) async {
    if (state.activeAudit == null) return;

    final line = state.activeAudit!.lines.firstWhere((l) => l.productId == event.productId);
    
    final varianceResult = VarianceCalculator.computeVariance(line.systemQty, event.physicalQty);
    
    final updatedLine = line.copyWith(
      physicalQty: event.physicalQty,
      variance: varianceResult.variance,
    );

    await _stockAuditRepository.updateAuditLine(updatedLine);
    
    // Manually update activeAudit in state for immediate UI feedback if needed, 
    // although watchAudits should eventually trigger an update.
    final updatedLines = state.activeAudit!.lines.map((l) => l.productId == event.productId ? updatedLine : l).toList();
    emit(state.copyWith(
      activeAudit: state.activeAudit!.copyWith(lines: updatedLines),
    ));
  }

  Future<void> _onCompleteAudit(
    CompleteAudit event,
    Emitter<StockAuditState> emit,
  ) async {
    try {
      emit(state.copyWith(status: StockAuditViewState.loading));
      await _completeStockAuditUseCase.call(event.auditId);
    } catch (e) {
      emit(state.copyWith(
        status: StockAuditViewState.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onCancelAudit(
    CancelAudit event,
    Emitter<StockAuditState> emit,
  ) async {
    try {
      emit(state.copyWith(status: StockAuditViewState.loading));
      await _stockAuditRepository.cancelAudit(event.auditId);
    } catch (e) {
      emit(state.copyWith(
        status: StockAuditViewState.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  @override
  Future<void> close() {
    _auditsSubscription?.cancel();
    return super.close();
  }
}
