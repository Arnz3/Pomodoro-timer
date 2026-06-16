import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FocusTime Pomodoro',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F0F1A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF5E62),
          secondary: Color(0xFF00D2C4),
          surface: Color(0xFF1E1E2C),
          onPrimary: Colors.white,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const PomodoroPage(),
    );
  }
}

enum TimerMode { focus, shortBreak, longBreak }
enum TimerStatus { idle, running, paused }

class Task {
  final String id;
  String title;
  bool isCompleted;

  Task({
    required this.id,
    required this.title,
    this.isCompleted = false,
  });
}

class PomodoroPage extends StatefulWidget {
  const PomodoroPage({super.key});

  @override
  State<PomodoroPage> createState() => _PomodoroPageState();
}

class _PomodoroPageState extends State<PomodoroPage> with SingleTickerProviderStateMixin {
  // Durations in minutes
  int _workMinutes = 25;
  int _shortBreakMinutes = 5;
  int _longBreakMinutes = 15;

  // State variables
  TimerMode _currentMode = TimerMode.focus;
  TimerStatus _timerStatus = TimerStatus.idle;
  int _secondsRemaining = 25 * 60;
  int _totalSeconds = 25 * 60;
  Timer? _timer;

  int _completedSessions = 0;
  final int _sessionsBeforeLongBreak = 4;

  final List<Task> _tasks = [];
  final TextEditingController _taskController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _resetToMode(_currentMode);
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeController.forward();

    // Seed some initial tasks for demonstration
    _tasks.addAll([
      Task(id: '1', title: 'Start met focusen 🎯'),
      Task(id: '2', title: 'Water drinken 💧', isCompleted: true),
    ]);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _taskController.dispose();
    _scrollController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  // Get color based on mode
  Color _getThemeColor() {
    switch (_currentMode) {
      case TimerMode.focus:
        return const Color(0xFFFF5E62); // Warm coral red
      case TimerMode.shortBreak:
        return const Color(0xFF00D2C4); // Mint green
      case TimerMode.longBreak:
        return const Color(0xFF3B82F6); // Ocean blue
    }
  }

  String _getModeName() {
    switch (_currentMode) {
      case TimerMode.focus:
        return 'Focus';
      case TimerMode.shortBreak:
        return 'Korte Pauze';
      case TimerMode.longBreak:
        return 'Lange Pauze';
    }
  }

  String _getModeDescription() {
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
    setState(() {
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
    });
  }

  void _startTimer() {
    if (_timerStatus == TimerStatus.running) return;

    setState(() {
      _timerStatus = TimerStatus.running;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _onTimerFinished();
      }
    });

    HapticFeedback.lightImpact();
  }

  void _pauseTimer() {
    if (_timerStatus != TimerStatus.running) return;

    _timer?.cancel();
    setState(() {
      _timerStatus = TimerStatus.paused;
    });

    HapticFeedback.lightImpact();
  }

  void _resetTimer() {
    _timer?.cancel();
    _resetToMode(_currentMode);
    HapticFeedback.mediumImpact();
  }

  void _skipMode() {
    _timer?.cancel();
    _transitionToNextMode(manual: true);
    HapticFeedback.mediumImpact();
  }

  void _onTimerFinished() {
    _timer?.cancel();
    SystemSound.play(SystemSoundType.click);
    HapticFeedback.vibrate();

    // Trigger dialog or sound alert
    _showFinishedDialog();

    setState(() {
      if (_currentMode == TimerMode.focus) {
        _completedSessions++;
      }
      _transitionToNextMode(manual: false);
    });
  }

  void _transitionToNextMode({required bool manual}) {
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

    _fadeController.reverse().then((_) {
      _resetToMode(nextMode);
      _fadeController.forward();
    });
  }

  void _showFinishedDialog() {
    String title = '';
    String content = '';
    
    if (_currentMode == TimerMode.focus) {
      title = 'Lekker gewerkt! 🎉';
      content = 'Tijd voor een welverdiende pauze. Klik om je pauze te starten.';
    } else {
      title = 'Pauze voorbij! 💪';
      content = 'Klaar om weer te focussen? Laten we beginnen.';
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E2C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _startTimer();
              },
              child: Text(
                'Start',
                style: TextStyle(color: _getThemeColor(), fontWeight: FontWeight.bold),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Sluiten', style: TextStyle(color: Colors.grey)),
            ),
          ],
        );
      },
    );
  }

  void _addTask(String title) {
    if (title.trim().isEmpty) return;
    setState(() {
      _tasks.add(Task(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title.trim(),
      ));
      _taskController.clear();
    });
    // Scroll to bottom after frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
    HapticFeedback.lightImpact();
  }

  void _toggleTask(int index) {
    setState(() {
      _tasks[index].isCompleted = !_tasks[index].isCompleted;
    });
    HapticFeedback.lightImpact();
  }

  void _deleteTask(int index) {
    setState(() {
      _tasks.removeAt(index);
    });
    HapticFeedback.mediumImpact();
  }

  String _formatTime(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _showSettingsBottomSheet() {
    int tempWork = _workMinutes;
    int tempShort = _shortBreakMinutes;
    int tempLong = _longBreakMinutes;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161623),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[700],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Pas Timers Aan (minuten)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  _buildSliderSetting(
                    title: 'Focus Tijd',
                    value: tempWork,
                    color: const Color(0xFFFF5E62),
                    min: 5,
                    max: 60,
                    onChanged: (val) {
                      setModalState(() => tempWork = val.round());
                    },
                  ),
                  _buildSliderSetting(
                    title: 'Korte Pauze',
                    value: tempShort,
                    color: const Color(0xFF00D2C4),
                    min: 1,
                    max: 30,
                    onChanged: (val) {
                      setModalState(() => tempShort = val.round());
                    },
                  ),
                  _buildSliderSetting(
                    title: 'Lange Pauze',
                    value: tempLong,
                    color: const Color(0xFF3B82F6),
                    min: 5,
                    max: 45,
                    onChanged: (val) {
                      setModalState(() => tempLong = val.round());
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _workMinutes = tempWork;
                        _shortBreakMinutes = tempShort;
                        _longBreakMinutes = tempLong;
                        _resetToMode(_currentMode);
                      });
                      Navigator.pop(context);
                      HapticFeedback.mediumImpact();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _getThemeColor(),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Opslaan & Herstarten',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSliderSetting({
    required String title,
    required int value,
    required Color color,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
            Text(
              '$value min',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
        Slider(
          value: value.toDouble(),
          min: min,
          max: max,
          activeColor: color,
          inactiveColor: color.withValues(alpha: 0.15),
          onChanged: onChanged,
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = _getThemeColor();
    final progress = _totalSeconds > 0 ? _secondsRemaining / _totalSeconds : 0.0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Icon(Icons.timer_outlined, color: themeColor),
            const SizedBox(width: 8),
            const Text(
              'FocusTime',
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5, fontSize: 20),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white70),
            onPressed: _showSettingsBottomSheet,
            tooltip: 'Instellingen',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF0F0F1A),
              themeColor.withValues(alpha: 0.04),
              const Color(0xFF0F0F1A),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              
              // Status Badge and description
              FadeTransition(
                opacity: _fadeController,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: themeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: themeColor.withValues(alpha: 0.3), width: 1),
                      ),
                      child: Text(
                        _getModeName().toUpperCase(),
                        style: TextStyle(
                          color: themeColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _getModeDescription(),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                        fontWeight: FontWeight.w300,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              // Timer Progress Ring & Counter
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer Ring
                    SizedBox(
                      width: 240,
                      height: 240,
                      child: CustomPaint(
                        painter: TimerPainter(
                          progress: progress,
                          color: themeColor,
                        ),
                      ),
                    ),
                    // Inner Digital Time
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatTime(_secondsRemaining),
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.0,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _timerStatus == TimerStatus.running
                              ? 'BEZIG'
                              : _timerStatus == TimerStatus.paused
                                  ? 'GEPAUZEERD'
                                  : 'START KLAAR',
                          style: TextStyle(
                            fontSize: 11,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w500,
                            color: Colors.white38,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Action Buttons Row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Reset button
                  _buildControlCircleButton(
                    icon: Icons.replay,
                    onPressed: _resetTimer,
                    tooltip: 'Herstarten',
                  ),
                  const SizedBox(width: 24),
                  // Play/Pause button
                  GestureDetector(
                    onTap: _timerStatus == TimerStatus.running ? _pauseTimer : _startTimer,
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: themeColor,
                        boxShadow: [
                          BoxShadow(
                            color: themeColor.withValues(alpha: 0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Icon(
                        _timerStatus == TimerStatus.running ? Icons.pause : Icons.play_arrow,
                        size: 38,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Skip button
                  _buildControlCircleButton(
                    icon: Icons.skip_next,
                    onPressed: _skipMode,
                    tooltip: 'Sla over',
                  ),
                ],
              ),

              const SizedBox(height: 36),

              // Session Indicator dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _sessionsBeforeLongBreak,
                  (index) {
                    final isDone = index < (_completedSessions % _sessionsBeforeLongBreak);
                    final isCurrent = index == (_completedSessions % _sessionsBeforeLongBreak) && _currentMode == TimerMode.focus;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDone
                            ? themeColor
                            : isCurrent
                                ? themeColor.withValues(alpha: 0.5)
                                : Colors.white10,
                        border: isCurrent
                            ? Border.all(color: themeColor, width: 1.5)
                            : null,
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 32),

              // Checklist Section (Expanded to take remaining space nicely)
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF161623),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  padding: const EdgeInsets.only(top: 20, left: 20, right: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Mijn Focus Taken',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '${_tasks.where((t) => t.isCompleted).length}/${_tasks.length}',
                            style: TextStyle(
                              fontSize: 14,
                              color: themeColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Task input field
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _taskController,
                              style: const TextStyle(fontSize: 14),
                              decoration: InputDecoration(
                                hintText: 'Voeg een taak toe...',
                                hintStyle: const TextStyle(color: Colors.white30, fontSize: 14),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                fillColor: Colors.white.withValues(alpha: 0.04),
                                filled: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              onSubmitted: _addTask,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _addTask(_taskController.text),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: themeColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: themeColor.withValues(alpha: 0.3)),
                              ),
                              child: Icon(Icons.add, color: themeColor, size: 20),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Tasks scrollable list
                      Expanded(
                        child: _tasks.isEmpty
                            ? const Center(
                                child: Text(
                                  'Geen taken toegevoegd. Voeg er een toe om gefocust te blijven!',
                                  style: TextStyle(color: Colors.white30, fontSize: 13),
                                  textAlign: TextAlign.center,
                                ),
                              )
                            : ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.only(bottom: 24),
                                itemCount: _tasks.length,
                                itemBuilder: (context, index) {
                                  final task = _tasks[index];
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.02),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: task.isCompleted
                                            ? Colors.white10
                                            : themeColor.withValues(alpha: 0.1),
                                      ),
                                    ),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                                      leading: Checkbox(
                                        value: task.isCompleted,
                                        activeColor: themeColor,
                                        checkColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        onChanged: (_) => _toggleTask(index),
                                      ),
                                      title: Text(
                                        task.title,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: task.isCompleted ? Colors.white38 : Colors.white,
                                          decoration: task.isCompleted
                                              ? TextDecoration.lineThrough
                                              : null,
                                        ),
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.delete_outline, size: 20, color: Colors.white38),
                                        onPressed: () => _deleteTask(index),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlCircleButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white10),
        color: Colors.white.withValues(alpha: 0.03),
      ),
      child: IconButton(
        iconSize: 24,
        icon: Icon(icon, color: Colors.white70),
        onPressed: onPressed,
        tooltip: tooltip,
      ),
    );
  }
}

class TimerPainter extends CustomPainter {
  final double progress;
  final Color color;

  TimerPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Background track ring
    final trackPaint = Paint()
      ..color = color.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0;

    canvas.drawCircle(center, radius, trackPaint);

    // Foreground progress ring (only draw if progress > 0)
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 10.0;

      // Glow effect ring
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 14.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

      const double startAngle = -3.141592653589793 / 2; // top center
      final double sweepAngle = 2 * 3.141592653589793 * progress;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        glowPaint,
      );

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant TimerPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
