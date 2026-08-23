import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/task.dart';
import '../models/timer_enums.dart';
import '../models/avatar_level.dart';
import '../models/focus_subject.dart';

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
  final Map<String, int> _dailyFocusSeconds = {};
  final int _sessionsBeforeLongBreak = 4;

  int get totalFocusSeconds => _totalFocusSeconds;
  int get completedSessions => _completedSessions;
  int get sessionsBeforeLongBreak => _sessionsBeforeLongBreak;

  Map<String, int> get dailyFocusSeconds =>
      Map.unmodifiable(_dailyFocusSeconds);

  final List<FocusSubject> _focusSubjects = [];
  String? _selectedFocusSubjectId;

  List<FocusSubject> get focusSubjects => List.unmodifiable(_focusSubjects);
  String? get selectedFocusSubjectId => _selectedFocusSubjectId;
  FocusSubject? get selectedFocusSubject {
    for (final subject in _focusSubjects) {
      if (subject.id == _selectedFocusSubjectId) return subject;
    }
    return null;
  }

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
        final dailyStats = stats['dailyFocusSeconds'];
        if (dailyStats is Map) {
          _dailyFocusSeconds
            ..clear()
            ..addAll(
              dailyStats.map(
                (key, value) =>
                    MapEntry(key.toString(), (value as num).toInt()),
              ),
            );
        }
      }
      _previousAvatarLevel = getAvatarLevelInfo(_totalFocusSeconds ~/ 60).level;

      // Load tasks
      final tasksStr = await _storage.read(key: 'pomodoro_tasks');
      if (tasksStr != null) {
        final List<dynamic> decoded = jsonDecode(tasksStr);
        _tasks.clear();
        _tasks.addAll(
          decoded.map((t) => Task.fromJson(t as Map<String, dynamic>)),
        );
      } else {
        // Seeding baseline tasks if no tasks are saved (first run)
        _tasks.clear();
        _tasks.addAll([
          Task(id: '1', title: 'Start met focussen 🎯'),
          Task(id: '2', title: 'Water drinken 💧', isCompleted: true),
        ]);
      }

      final subjectsStr = await _storage.read(key: 'pomodoro_focus_subjects');
      if (subjectsStr != null) {
        final decoded = jsonDecode(subjectsStr) as Map<String, dynamic>;
        _focusSubjects
          ..clear()
          ..addAll(
            (decoded['subjects'] as List<dynamic>).map(
              (subject) =>
                  FocusSubject.fromJson(subject as Map<String, dynamic>),
            ),
          );
        _selectedFocusSubjectId = decoded['selectedId'] as String?;
      } else {
        _focusSubjects.addAll([
          FocusSubject(
            id: 'school',
            name: 'School',
            color: const Color(0xFF4D9DE0),
          ),
          FocusSubject(
            id: 'work',
            name: 'Werk',
            color: const Color(0xFFFF7A59),
          ),
          FocusSubject(
            id: 'personal',
            name: 'Persoonlijk',
            color: const Color(0xFF45C486),
          ),
        ]);
        _selectedFocusSubjectId = _focusSubjects.first.id;
      }
      if (selectedFocusSubject == null && _focusSubjects.isNotEmpty) {
        _selectedFocusSubjectId = _focusSubjects.first.id;
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
        'dailyFocusSeconds': _dailyFocusSeconds,
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

  Future<void> saveFocusSubjects() async {
    try {
      await _storage.write(
        key: 'pomodoro_focus_subjects',
        value: jsonEncode({
          'selectedId': _selectedFocusSubjectId,
          'subjects': _focusSubjects
              .map((subject) => subject.toJson())
              .toList(),
        }),
      );
    } catch (e) {
      debugPrint('Error saving focus subjects: $e');
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
        return selectedFocusSubject?.color ?? const Color(0xFFFF5E62);
      case TimerMode.shortBreak:
        return const Color(0xFF00D2C4); // Mint green
      case TimerMode.longBreak:
        return const Color(0xFF3B82F6); // Ocean blue
    }
  }

  void selectFocusSubject(String id) {
    if (_focusSubjects.every((subject) => subject.id != id)) return;
    _selectedFocusSubjectId = id;
    notifyListeners();
    saveFocusSubjects();
    HapticFeedback.lightImpact();
  }

  void addFocusSubject(String name, Color color) {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return;
    final subject = FocusSubject(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: trimmedName,
      color: color,
    );
    _focusSubjects.add(subject);
    _selectedFocusSubjectId = subject.id;
    notifyListeners();
    saveFocusSubjects();
    HapticFeedback.lightImpact();
  }

  void deleteFocusSubject(String id) {
    if (_focusSubjects.length <= 1) return;
    _focusSubjects.removeWhere((subject) => subject.id == id);
    if (_selectedFocusSubjectId == id) {
      _selectedFocusSubjectId = _focusSubjects.first.id;
    }
    notifyListeners();
    saveFocusSubjects();
    HapticFeedback.mediumImpact();
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
          final today = _dateKey(DateTime.now());
          _dailyFocusSeconds[today] = (_dailyFocusSeconds[today] ?? 0) + 1;
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

  String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

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
      if (_completedSessions > 0 &&
          _completedSessions % _sessionsBeforeLongBreak == 0) {
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
    _tasks.add(
      Task(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title.trim(),
      ),
    );
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
