import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:inventopos/application/ai/build_briefing_metrics_use_case.dart';
import 'package:inventopos/application/ai/observe_ai_insights_use_case.dart';
import 'package:inventopos/application/ai/run_daily_business_brief_use_case.dart';
import 'package:inventopos/data/ai/ai_briefing_cache_service.dart';
import 'package:inventopos/domain/ai/failures/ai_failure.dart';
import 'package:inventopos/domain/ai/repositories/ai_insights_port.dart';
import 'package:inventopos/domain/entities/bill.dart';
import 'package:inventopos/domain/entities/expense.dart';
import 'package:inventopos/domain/entities/product.dart';
import 'package:inventopos/presentation/insights/bloc/business_insights_ai_event.dart';
import 'package:inventopos/presentation/insights/bloc/business_insights_ai_state.dart';

class BusinessInsightsAiBloc
    extends Bloc<BusinessInsightsAiEvent, BusinessInsightsAiState> {
  BusinessInsightsAiBloc(
    this._brief,
    this._metrics,
    this._observeInsights,
    this._insightsPort,
  )   : _cache = AiBriefingCacheService(),
        super(const BusinessInsightsAiState()) {
    on<BusinessInsightsAiStarted>(_onStarted);
    on<BusinessInsightsAiBriefingRequested>(_onBriefRequested);
    on<BusinessInsightsAiBriefingReceived>(_onBriefReceived);
    on<BusinessInsightsAiInsightsReceived>(_onInsights);
    on<BusinessInsightsAiInsightMarkedRead>(_onMarkRead);
  }

  final RunDailyBusinessBriefUseCase _brief;
  final BuildBriefingMetricsUseCase _metrics;
  final ObserveAiInsightsUseCase _observeInsights;
  final AiInsightsPort _insightsPort;
  final AiBriefingCacheService _cache;

  String _userId = '';
  List<Bill> _bills = [];
  List<Expense> _expenses = [];
  List<Product> _products = [];
  StreamSubscription? _insightsSub;

  Future<void> _onStarted(
    BusinessInsightsAiStarted event,
    Emitter<BusinessInsightsAiState> emit,
  ) async {
    _userId = event.userId;
    _bills = event.bills;
    _expenses = event.expenses;
    _products = event.products;

    // ── Restore cached briefing on start ──
    final cached = _cache.loadBriefing(_userId);
    final cachedAt = _cache.lastGeneratedAt(_userId);
    if (cached != null) {
      emit(state.copyWith(
        briefing: cached,
        lastGeneratedAt: cachedAt,
        loadingBrief: false,
      ));
    }

    await _insightsSub?.cancel();
    _insightsSub = _observeInsights(event.userId).listen(
      (list) => add(BusinessInsightsAiInsightsReceived(list)),
    );
  }

  Future<void> _onBriefRequested(
    BusinessInsightsAiBriefingRequested event,
    Emitter<BusinessInsightsAiState> emit,
  ) async {
    if (_userId.isEmpty) return;
    emit(state.copyWith(loadingBrief: true, error: null));
    final metrics = _metrics(
      bills: _bills,
      expenses: _expenses,
      products: _products,
    );
    final result = await _brief(userId: _userId, metrics: metrics);
    switch (result) {
      case AiSuccess(:final value):
        // ── Persist to local cache ──
        _cache.saveBriefing(_userId, value);
        add(BusinessInsightsAiBriefingReceived(value, null));
      case AiError(:final failure):
        add(BusinessInsightsAiBriefingReceived(null, failure.message));
    }
  }

  void _onBriefReceived(
    BusinessInsightsAiBriefingReceived event,
    Emitter<BusinessInsightsAiState> emit,
  ) {
    emit(state.copyWith(
      briefing: event.briefing ?? state.briefing,
      loadingBrief: false,
      error: event.error,
      lastGeneratedAt:
          event.briefing != null ? DateTime.now() : state.lastGeneratedAt,
      insights: event.briefing?.insights.isNotEmpty == true
          ? event.briefing!.insights
          : state.insights,
    ));
  }

  void _onInsights(
    BusinessInsightsAiInsightsReceived event,
    Emitter<BusinessInsightsAiState> emit,
  ) {
    emit(state.copyWith(
      insights: event.insights,
      loadingInsights: false,
    ));
  }

  Future<void> _onMarkRead(
    BusinessInsightsAiInsightMarkedRead event,
    Emitter<BusinessInsightsAiState> emit,
  ) async {
    await _insightsPort.markRead(event.insightId);
  }

  @override
  Future<void> close() async {
    await _insightsSub?.cancel();
    return super.close();
  }
}
