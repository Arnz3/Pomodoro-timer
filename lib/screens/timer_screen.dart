import 'package:flutter/material.dart';
import '../models/timer_enums.dart';
import '../state/pomodoro_state.dart';
import '../widgets/checklist_widget.dart';
import '../widgets/settings_sheet.dart';
import '../widgets/timer_painter.dart';
import '../widgets/avatar_widget.dart';
import '../models/avatar_level.dart';

class TimerScreen extends StatefulWidget {
  final PomodoroState state;

  const TimerScreen({super.key, required this.state});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeController.forward();
    widget.state.addListener(_checkForLevelUp);
  }

  void _checkForLevelUp() {
    if (widget.state.justLeveledUp) {
      widget.state.clearLevelUpFlag();
      final info = widget.state.avatarLevelInfo;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.transparent,
            elevation: 0,
            content: _LevelUpBanner(info: info),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    widget.state.removeListener(_checkForLevelUp);
    _fadeController.dispose();
    super.dispose();
  }

  void _onTimerFinishedAlert() {
    String title = '';
    String content = '';

    if (widget.state.currentMode == TimerMode.focus) {
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
                widget.state.startTimer(_onTimerFinishedAlert);
              },
              child: Text(
                'Start',
                style: TextStyle(color: widget.state.getThemeColor(), fontWeight: FontWeight.bold),
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

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161623),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SettingsSheet(
          initialWorkMinutes: widget.state.workMinutes,
          initialShortBreakMinutes: widget.state.shortBreakMinutes,
          initialLongBreakMinutes: widget.state.longBreakMinutes,
          themeColor: widget.state.getThemeColor(),
          onSave: (work, short, long) {
            widget.state.updateSettings(work, short, long);
          },
        );
      },
    );
  }

  String _formatTime(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.state,
      builder: (context, _) {
        final themeColor = widget.state.getThemeColor();
        final progress = widget.state.totalSeconds > 0
            ? widget.state.secondsRemaining / widget.state.totalSeconds
            : 0.0;

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
                onPressed: _showSettings,
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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final double avatarSize = (constraints.maxWidth * 0.26).clamp(60.0, 108.0).toDouble();
                  final double ringSize = (constraints.maxWidth * 0.56).clamp(160.0, 240.0).toDouble();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),

                      // Make the top portion scrollable if vertical space is tight
                      Flexible(
                        flex: 65,
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Avatar Widget
                              Center(
                                child: AvatarWidget(
                                  level: widget.state.avatarLevelInfo.level,
                                  isTimerRunning:
                                      widget.state.timerStatus == TimerStatus.running,
                                  size: avatarSize,
                                ),
                              ),

                              const SizedBox(height: 8),

                              // Avatar name + level badge
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: themeColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: themeColor.withValues(alpha: 0.2), width: 1),
                                  ),
                                  child: Text(
                                    '${widget.state.avatarLevelInfo.emoji}  ${widget.state.avatarLevelInfo.name}',
                                    style: TextStyle(
                                      color: themeColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Status Badge and description
                              FadeTransition(
                                opacity: _fadeController,
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: themeColor.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(30),
                                        border: Border.all(
                                            color: themeColor.withValues(alpha: 0.3),
                                            width: 1),
                                      ),
                                      child: Text(
                                        widget.state.getModeName().toUpperCase(),
                                        style: TextStyle(
                                          color: themeColor,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 13,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      widget.state.getModeDescription(),
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
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
                                      width: ringSize,
                                      height: ringSize,
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
                                          _formatTime(widget.state.secondsRemaining),
                                          style: const TextStyle(
                                            fontSize: 48,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 2.0,
                                            fontFeatures: [FontFeature.tabularFigures()],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          widget.state.timerStatus == TimerStatus.running
                                              ? 'BEZIG'
                                              : widget.state.timerStatus == TimerStatus.paused
                                                  ? 'GEPAUZEERD'
                                                  : 'START KLAAR',
                                          style: const TextStyle(
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
                                    onPressed: widget.state.resetTimer,
                                    tooltip: 'Herstarten',
                                  ),
                                  const SizedBox(width: 24),
                                  // Play/Pause button
                                  GestureDetector(
                                    onTap: () {
                                      if (widget.state.timerStatus == TimerStatus.running) {
                                        widget.state.pauseTimer();
                                      } else {
                                        widget.state.startTimer(_onTimerFinishedAlert);
                                      }
                                    },
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
                                        widget.state.timerStatus == TimerStatus.running
                                            ? Icons.pause
                                            : Icons.play_arrow,
                                        size: 38,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  // Skip button
                                  _buildControlCircleButton(
                                    icon: Icons.skip_next,
                                    onPressed: () {
                                      _fadeController.reverse().then((_) {
                                        widget.state.skipMode(() {
                                          _fadeController.forward();
                                        });
                                      });
                                    },
                                    tooltip: 'Sla over',
                                  ),
                                ],
                              ),

                              const SizedBox(height: 36),

                              // Session Indicator dots
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  widget.state.sessionsBeforeLongBreak,
                                  (index) {
                                    final completedInCycle =
                                        widget.state.completedSessions % widget.state.sessionsBeforeLongBreak;
                                    final isDone = index < completedInCycle;
                                    final isCurrent = index == completedInCycle &&
                                        widget.state.currentMode == TimerMode.focus;
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

                              // Checklist Section: embedded so it scrolls with the rest of the screen
                              ChecklistWidget(
                                tasks: widget.state.tasks,
                                onAddTask: widget.state.addTask,
                                onToggleTask: widget.state.toggleTask,
                                onDeleteTask: widget.state.deleteTask,
                                themeColor: themeColor,
                                embedded: true,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
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

/// Level-up banner shown in a SnackBar when avatar grows.
class _LevelUpBanner extends StatelessWidget {
  final AvatarLevelInfo info;

  const _LevelUpBanner({required this.info});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1E3A), Color(0xFF2A1A3A)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withValues(alpha: 0.15),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          Text(info.emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Level Up! 🎉',
                  style: TextStyle(
                    color: Color(0xFFFFD700),
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Je plant is een ${info.name}!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  info.description,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
