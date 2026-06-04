import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventopos/application/ai/observe_ai_preferences_use_case.dart';
import 'package:inventopos/application/ai/save_ai_preferences_use_case.dart';
import 'package:inventopos/domain/ai/entities/ai_preferences.dart';
import 'package:inventopos/domain/ai/repositories/ai_preferences_port.dart';
import 'package:inventopos/domain/automation/entities/automation_job.dart';
import 'package:inventopos/domain/automation/repositories/automation_job_port.dart';
import 'package:inventopos/presentation/automation_settings/bloc/automation_settings_bloc.dart';
import 'package:inventopos/presentation/automation_settings/bloc/automation_settings_event.dart';
import 'package:inventopos/presentation/automation_settings/bloc/automation_settings_state.dart';

class _FakePrefs implements AiPreferencesPort {
  final _controller = StreamController<AiPreferences>.broadcast();
  AiPreferences prefs = const AiPreferences(userId: 'u1');

  @override
  Future<AiPreferences> fetch(String userId) async => prefs;

  @override
  Future<void> save(AiPreferences preferences) async {
    prefs = preferences;
    _controller.add(preferences);
  }

  @override
  Stream<AiPreferences> watch(String userId) async* {
    yield prefs;
    yield* _controller.stream;
  }
}

class _FakeJobs implements AutomationJobPort {
  @override
  Future<void> ensureDefaults(String userId) async {}

  @override
  Future<List<AutomationJob>> listForUser(String userId) async => [];
}

void main() {
  blocTest<AutomationSettingsBloc, AutomationSettingsState>(
    'toggles enabled',
    build: () => AutomationSettingsBloc(
      ObserveAiPreferencesUseCase(_FakePrefs()),
      SaveAiPreferencesUseCase(_FakePrefs(), _FakeJobs()),
    ),
    act: (b) async {
      b.add(const AutomationSettingsStarted('u1'));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      b.add(const AutomationSettingsEnabledToggled(true));
    },
    skip: 1,
    verify: (b) {
      expect(b.state.preferences?.enabled, isTrue);
    },
  );
}
