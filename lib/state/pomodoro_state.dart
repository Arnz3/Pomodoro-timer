import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/task.dart';
import '../models/timer_enums.dart';
import '../models/avatar_level.dart';

class PomodoroState extends ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

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

  // Avatar / Gamification
  AvatarLevel _previousAvatarLevel = AvatarLevel.seed;
  bool _justLeveledUp = false;

  bool get justLeveledUp => _justLeveledUp;

  AvatarLevelInfo get avatarLevelInfo =>
      getAvatarLevelInfo(_totalFocusSeconds ~/ 60);

  double get avatarProgressToNextLevel =>
      getProgressToNextLevel(_totalFocusSeconds ~/ 60);

  void clearLevelUpFlag() {
    _justLeveledUp = false;
    // No notifyListeners needed — purely reactive flag
  }

  // Tasks
  final List<Task> _tasks = [];
  List<Task> get tasks => List.unmodifiable(_tasks);

  PomodoroState() {
    _resetToMode(_currentMode);
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Load settings
      final settingsStr = await _storage.read(key: 'pomodoro_settings');
      if (settingsStr != null) {
        final Map<String, dynamic> settings = jsonDecode(settingsStr);
        _workMinutes = settings['workMinutes'] as int? ?? 25;
        _shortBreakMinutes = settings['shortBreakMinutes'] as int? ?? 5;
        _longBreakMinutes = settings['longBreakMinutes'] as int? ?? 15;
      }

      // Load stats
      final statsStr = await _storage.read(key: 'pomodoro_stats');
      if (statsStr != null) {
        final Map<String, dynamic> stats = jsonDecode(statsStr);
        _totalFocusSeconds = stats['totalFocusSeconds'] as int? ?? 0;
        _completedSessions = stats['completedSessions'] as int? ?? 0;
      }
      _previousAvatarLevel = getAvatarLevelInfo(_totalFocusSeconds ~/ 60).level;

      // Load tasks
      final tasksStr = await _storage.read(key: 'pomodoro_tasks');
      if (tasksStr != null) {
        final List<dynamic> decoded = jsonDecode(tasksStr);
        _tasks.clear();
        _tasks.addAll(decoded.map((t) => Task.fromJson(t as Map<String, dynamic>)));
      } else {
        // Seeding baseline tasks if no tasks are saved (first run)
        _tasks.clear();
        _tasks.addAll([
          Task(id: '1', title: 'Start met focussen 🎯'),
          Task(id: '2', title: 'Water drinken 💧', isCompleted: true),
        ]);
      }

      // Re-apply values based on loaded settings
      _resetToMode(_currentMode);
    } catch (e) {
      debugPrint('Error loading saved pomodoro data: $e');
      if (_tasks.isEmpty) {
        _tasks.addAll([
          Task(id: '1', title: 'Start met focussen 🎯'),
          Task(id: '2', title: 'Water drinken 💧', isCompleted: true),
        ]);
      }
    } finally {
      _isLoaded = true;
      notifyListeners();
    }
  }

  Future<void> saveTasks() async {
    try {
      final tasksJson = jsonEncode(_tasks.map((t) => t.toJson()).toList());
      await _storage.write(key: 'pomodoro_tasks', value: tasksJson);
    } catch (e) {
      debugPrint('Error saving tasks: $e');
    }
  }

  Future<void> saveStats() async {
    try {
      final statsJson = jsonEncode({
        'totalFocusSeconds': _totalFocusSeconds,
        'completedSessions': _completedSessions,
      });
      await _storage.write(key: 'pomodoro_stats', value: statsJson);
    } catch (e) {
      debugPrint('Error saving stats: $e');
    }
  }

  Future<void> saveSettings() async {
    try {
      final settingsJson = jsonEncode({
        'workMinutes': _workMinutes,
        'shortBreakMinutes': _shortBreakMinutes,
        'longBreakMinutes': _longBreakMinutes,
      });
      await _storage.write(key: 'pomodoro_settings', value: settingsJson);
    } catch (e) {
      debugPrint('Error saving settings: $e');
    }
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
          // Check for level-up
          final newLevel = getAvatarLevelInfo(_totalFocusSeconds ~/ 60).level;
          if (newLevel != _previousAvatarLevel) {
            _justLeveledUp = true;
            _previousAvatarLevel = newLevel;
          }
          // Save stats periodically (every 10 seconds of focus time)
          if (_totalFocusSeconds % 10 == 0) {
            saveStats();
          }
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
    saveStats(); // Save stats on pause
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
    saveStats(); // Save stats on skip
    HapticFeedback.mediumImpact();
  }

  void _onTimerFinished(void Function() onFinished) {
    _timer?.cancel();
    SystemSound.play(SystemSoundType.click);
    HapticFeedback.vibrate();

    if (_currentMode == TimerMode.focus) {
      _completedSessions++;
    }

    saveStats(); // Save stats when timer completes
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
    saveTasks(); // Save tasks when added
    HapticFeedback.lightImpact();
  }

  void toggleTask(String id) {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      _tasks[index].isCompleted = !_tasks[index].isCompleted;
      notifyListeners();
      saveTasks(); // Save tasks when toggled
      HapticFeedback.lightImpact();
    }
  }

  void deleteTask(String id) {
    _tasks.removeWhere((t) => t.id == id);
    notifyListeners();
    saveTasks(); // Save tasks when deleted
    HapticFeedback.mediumImpact();
  }

  // Update configuration
  void updateSettings(int work, int short, int long) {
    _workMinutes = work;
    _shortBreakMinutes = short;
    _longBreakMinutes = long;
    _resetToMode(_currentMode);
    saveSettings(); // Save settings when changed
    HapticFeedback.mediumImpact();
  }
}
