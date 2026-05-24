import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:inventopos/domain/repositories/product_repository.dart';

class ImportInventoryState extends Equatable {
  const ImportInventoryState({
    this.importing = false,
    this.progress = 0,
    this.total = 0,
    this.message,
    this.error,
  });

  final bool importing;
  final int progress;
  final int total;
  final String? message;
  final String? error;

  ImportInventoryState copyWith({
    bool? importing,
    int? progress,
    int? total,
    String? message,
    String? error,
    bool clearError = false,
  }) {
    return ImportInventoryState(
      importing: importing ?? this.importing,
      progress: progress ?? this.progress,
      total: total ?? this.total,
      message: message ?? this.message,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [importing, progress, total, message, error];
}

sealed class ImportInventoryEvent extends Equatable {
  const ImportInventoryEvent();
  @override
  List<Object?> get props => [];
}

class ImportInventoryStarted extends ImportInventoryEvent {
  const ImportInventoryStarted(this.userId, this.rows);

  final String userId;
  final List<Map<String, dynamic>> rows;

  @override
  List<Object?> get props => [userId, rows];
}

class ImportInventoryBloc extends Bloc<ImportInventoryEvent, ImportInventoryState> {
  ImportInventoryBloc(this._products) : super(const ImportInventoryState()) {
    on<ImportInventoryStarted>(_onStarted);
  }

  final ProductRepository _products;

  Future<void> _onStarted(
    ImportInventoryStarted event,
    Emitter<ImportInventoryState> emit,
  ) async {
    final total = event.rows.length;
    emit(
      state.copyWith(
        importing: true,
        clearError: true,
        progress: 0,
        total: total,
      ),
    );
    try {
      await _products.bulkUpsertLocal(event.userId, event.rows);
      emit(
        state.copyWith(
          importing: false,
          message: 'Imported $total products',
          progress: total,
          total: total,
        ),
      );
    } catch (e) {
      emit(state.copyWith(importing: false, error: e.toString()));
    }
  }
}
