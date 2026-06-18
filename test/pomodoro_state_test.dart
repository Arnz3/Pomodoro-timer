import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pomodoro/state/pomodoro_state.dart';

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('PomodoroState loads default seed tasks on first initialization', () async {
    final state = PomodoroState();
    
    // Wait for the async loading to complete
    await Future.delayed(Duration.zero);
    
    expect(state.isLoaded, true);
    expect(state.tasks.length, 2);
    expect(state.tasks[0].title, 'Start met focussen 🎯');
    expect(state.tasks[1].title, 'Water drinken 💧');
  });

  test('PomodoroState persists settings, tasks, and stats', () async {
    // 1. Setup mock storage with custom state
    FlutterSecureStorage.setMockInitialValues({
      'pomodoro_settings': '{"workMinutes":20,"shortBreakMinutes":4,"longBreakMinutes":10}',
      'pomodoro_stats': '{"totalFocusSeconds":120,"completedSessions":3}',
      'pomodoro_tasks': '[{"id":"t1","title":"Mijn test taak","isCompleted":false}]',
    });

    final state = PomodoroState();
    
    // Wait for the async loading logic to complete
    await Future.delayed(Duration.zero);
    
    expect(state.isLoaded, true);
    expect(state.workMinutes, 20);
    expect(state.shortBreakMinutes, 4);
    expect(state.longBreakMinutes, 10);
    
    expect(state.totalFocusSeconds, 120);
    expect(state.completedSessions, 3);
    
    expect(state.tasks.length, 1);
    expect(state.tasks[0].id, 't1');
    expect(state.tasks[0].title, 'Mijn test taak');
    expect(state.tasks[0].isCompleted, false);
  });
}
