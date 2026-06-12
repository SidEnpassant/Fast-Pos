import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:inventopos/application/automation/automation_use_cases.dart';
import 'package:inventopos/domain/automation/entities/repeat_order_template.dart';
import 'package:inventopos/domain/entities/bill.dart';

// Events
sealed class RepeatOrderEvent extends Equatable {
  const RepeatOrderEvent();
  @override
  List<Object?> get props => [];
}

class RepeatOrderStarted extends RepeatOrderEvent {
  const RepeatOrderStarted({required this.customerId, required this.bills});
  final String customerId;
  final List<Bill> bills;
  @override
  List<Object?> get props => [customerId, bills];
}

// State
class RepeatOrderState extends Equatable {
  const RepeatOrderState({this.template, this.loading = false});
  final RepeatOrderTemplate? template;
  final bool loading;

  @override
  List<Object?> get props => [template, loading];
}

// Bloc
class RepeatOrderBloc extends Bloc<RepeatOrderEvent, RepeatOrderState> {
  RepeatOrderBloc(this._buildTemplate) : super(const RepeatOrderState()) {
    on<RepeatOrderStarted>((event, emit) {
      emit(const RepeatOrderState(loading: true));
      final template = _buildTemplate(
        customerId: event.customerId,
        bills: event.bills,
      );
      emit(RepeatOrderState(template: template, loading: false));
    });
  }

  final BuildRepeatOrderTemplateUseCase _buildTemplate;
}
