import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/task.dart';
import '../models/timer_enums.dart';

class PomodoroState extends ChangeNotifier {
  // Durations in minutes
  int _workMinutes = 25;
  int _shortBreakMinutes = 5;
  int _longBreakMinutes = 15;

  int get workMinutes => _workMinutes;
  int get shortBreakMinutes => _shortBreakMinutes;
  int get longBreakMinutes => _longBreakMinutes;

  // Active Timer State
  TimerMode _currentMode = TimerMode.focus;
  TimerStatus _timerStatus = TimerStatus.idle;
  int _secondsRemaining = 25 * 60;
  int _totalSeconds = 25 * 60;
  Timer? _timer;

  TimerMode get currentMode => _currentMode;
  TimerStatus get timerStatus => _timerStatus;
  int get secondsRemaining => _secondsRemaining;
  int get totalSeconds => _totalSeconds;

  // Statistics
  int _totalFocusSeconds = 0;
  int _completedSessions = 0;
  final int _sessionsBeforeLongBreak = 4;

  int get totalFocusSeconds => _totalFocusSeconds;
  int get completedSessions => _completedSessions;
  int get sessionsBeforeLongBreak => _sessionsBeforeLongBreak;

  // Tasks
  final List<Task> _tasks = [];
  List<Task> get tasks => List.unmodifiable(_tasks);

  PomodoroState() {
    _resetToMode(_currentMode);
    
    // Seed some initial tasks for demonstration
    _tasks.addAll([
      Task(id: '1', title: 'Start met focussen 🎯'),
      Task(id: '2', title: 'Water drinken 💧', isCompleted: true),
    ]);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Color getThemeColor() {
    switch (_currentMode) {
      case TimerMode.focus:
        return const Color(0xFFFF5E62); // Warm coral red
      case TimerMode.shortBreak:
        return const Color(0xFF00D2C4); // Mint green
      case TimerMode.longBreak:
        return const Color(0xFF3B82F6); // Ocean blue
    }
  }

  String getModeName() {
    switch (_currentMode) {
      case TimerMode.focus:
        return 'Focus';
      case TimerMode.shortBreak:
        return 'Korte Pauze';
      case TimerMode.longBreak:
        return 'Lange Pauze';
    }
  }

  String getModeDescription() {
    switch (_currentMode) {
      case TimerMode.focus:
        return 'Blijf gefocust op je taken';
      case TimerMode.shortBreak:
        return 'Neem even adem en ontspan';
      case TimerMode.longBreak:
        return 'Tijd voor een langere rust';
    }
  }

  void _resetToMode(TimerMode mode) {
    _currentMode = mode;
    int minutes;
    switch (mode) {
      case TimerMode.focus:
        minutes = _workMinutes;
        break;
      case TimerMode.shortBreak:
        minutes = _shortBreakMinutes;
        break;
      case TimerMode.longBreak:
        minutes = _longBreakMinutes;
        break;
    }
    _secondsRemaining = minutes * 60;
    _totalSeconds = _secondsRemaining;
    _timerStatus = TimerStatus.idle;
    _timer?.cancel();
    notifyListeners();
  }

  void startTimer(void Function() onFinished) {
    if (_timerStatus == TimerStatus.running) return;

    _timerStatus = TimerStatus.running;
    notifyListeners();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        _secondsRemaining--;
        if (_currentMode == TimerMode.focus) {
          _totalFocusSeconds++;
        }
        notifyListeners();
      } else {
        _onTimerFinished(onFinished);
      }
    });

    HapticFeedback.lightImpact();
  }

  void pauseTimer() {
    if (_timerStatus != TimerStatus.running) return;

    _timer?.cancel();
    _timerStatus = TimerStatus.paused;
    notifyListeners();

    HapticFeedback.lightImpact();
  }

  void resetTimer() {
    _timer?.cancel();
    _resetToMode(_currentMode);
    HapticFeedback.mediumImpact();
  }

  void skipMode(void Function() onTransitioned) {
    _timer?.cancel();
    _transitionToNextMode();
    onTransitioned();
    HapticFeedback.mediumImpact();
  }

  void _onTimerFinished(void Function() onFinished) {
    _timer?.cancel();
    SystemSound.play(SystemSoundType.click);
    HapticFeedback.vibrate();

    if (_currentMode == TimerMode.focus) {
      _completedSessions++;
    }

    onFinished();
    _transitionToNextMode();
  }

  void _transitionToNextMode() {
    TimerMode nextMode;
    if (_currentMode == TimerMode.focus) {
      if (_completedSessions > 0 && _completedSessions % _sessionsBeforeLongBreak == 0) {
        nextMode = TimerMode.longBreak;
      } else {
        nextMode = TimerMode.shortBreak;
      }
    } else {
      nextMode = TimerMode.focus;
    }

    _resetToMode(nextMode);
  }

  // Task methods
  void addTask(String title) {
    if (title.trim().isEmpty) return;
    _tasks.add(Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title.trim(),
    ));
    notifyListeners();
    HapticFeedback.lightImpact();
  }

  void toggleTask(String id) {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      _tasks[index].isCompleted = !_tasks[index].isCompleted;
      notifyListeners();
      HapticFeedback.lightImpact();
    }
  }

  void deleteTask(String id) {
    _tasks.removeWhere((t) => t.id == id);
    notifyListeners();
    HapticFeedback.mediumImpact();
  }

  // Update configuration
  void updateSettings(int work, int short, int long) {
    _workMinutes = work;
    _shortBreakMinutes = short;
    _longBreakMinutes = long;
    _resetToMode(_currentMode);
    HapticFeedback.mediumImpact();
  }
}
