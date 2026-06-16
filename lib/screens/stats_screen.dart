import 'package:flutter/material.dart';
import '../state/pomodoro_state.dart';

class StatsScreen extends StatelessWidget {
  final PomodoroState state;

  const StatsScreen({super.key, required this.state});

  String _formatDuration(int totalSeconds) {
    if (totalSeconds == 0) return '0m 0s';
    
    int hours = totalSeconds ~/ 3600;
    int minutes = (totalSeconds % 3600) ~/ 60;
    int seconds = totalSeconds % 60;

    String result = '';
    if (hours > 0) result += '${hours}u ';
    if (minutes > 0 || hours > 0) result += '${minutes}m ';
    result += '${seconds}s';
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final themeColor = state.getThemeColor();
        final totalTasks = state.tasks.length;
        final completedTasks = state.tasks.where((t) => t.isCompleted).length;
        final completionRate = totalTasks > 0 ? completedTasks / totalTasks : 0.0;

        // Seeding baseline weekly focus data (in minutes) for illustration
        // Monday (1) to Sunday (7). Replace today's value with actual focus time.
        final todayWeekday = DateTime.now().weekday; // 1 = Monday, 7 = Sunday
        final List<String> weekdays = ['Ma', 'Di', 'Wo', 'Do', 'Vr', 'Za', 'Zo'];
        final List<double> baseWeeklyMinutes = [40.0, 65.0, 25.0, 50.0, 35.0, 15.0, 0.0];
        
        // Update today's value with active session focus
        baseWeeklyMinutes[todayWeekday - 1] = state.totalFocusSeconds / 60.0;

        // Find max value to scale chart bars nicely
        double maxMinutes = baseWeeklyMinutes.reduce((a, b) => a > b ? a : b);
        if (maxMinutes < 60) maxMinutes = 60; // Keep scale reasonable

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Row(
              children: [
                Icon(Icons.bar_chart_outlined, color: themeColor),
                const SizedBox(width: 8),
                const Text(
                  'Mijn Voortgang',
                  style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5, fontSize: 20),
                ),
              ],
            ),
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF0F0F1A),
                  themeColor.withValues(alpha: 0.02),
                  const Color(0xFF0F0F1A),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Total Focus Time Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          themeColor.withValues(alpha: 0.15),
                          themeColor.withValues(alpha: 0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: themeColor.withValues(alpha: 0.2), width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: themeColor.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.local_fire_department, color: themeColor, size: 36),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Totaal Gefocust',
                                style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _formatDuration(state.totalFocusSeconds),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Stats grid (Two Columns)
                  Row(
                    children: [
                      // Sessions Completed
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Focus Ronden',
                          value: '${state.completedSessions}',
                          subtitle: 'Sessies afgerond',
                          icon: Icons.check_circle_outline,
                          iconColor: const Color(0xFFFF5E62),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Task Completion
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Taken Afgerond',
                          value: '$completedTasks/$totalTasks',
                          subtitle: totalTasks > 0
                              ? '${(completionRate * 100).round()}% voltooid'
                              : 'Geen open taken',
                          icon: Icons.task_alt_outlined,
                          iconColor: const Color(0xFF00D2C4),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Weekly Chart Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161623),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Wekelijkse Focus Activiteit',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            Text(
                              'Minuten / Dag',
                              style: TextStyle(fontSize: 12, color: themeColor, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        // Bar graph container
                        SizedBox(
                          height: 150,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: List.generate(7, (index) {
                              final min = baseWeeklyMinutes[index];
                              final isToday = (index + 1) == todayWeekday;
                              // Calculate bar height fraction
                              final fraction = maxMinutes > 0 ? min / maxMinutes : 0.0;

                              return Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    // Minutes text tooltip on top of bars
                                    Text(
                                      min > 0 ? '${min.round()}m' : '',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: isToday ? themeColor : Colors.white38,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    // Animated-like bar
                                    Expanded(
                                      child: FractionallySizedBox(
                                        heightFactor: fraction.clamp(0.04, 1.0),
                                        child: Container(
                                          margin: const EdgeInsets.symmetric(horizontal: 6),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: isToday
                                                  ? [themeColor, themeColor.withValues(alpha: 0.6)]
                                                  : [Colors.white24, Colors.white10],
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                            ),
                                            borderRadius: BorderRadius.circular(6),
                                            boxShadow: isToday
                                                ? [
                                                    BoxShadow(
                                                      color: themeColor.withValues(alpha: 0.25),
                                                      blurRadius: 8,
                                                      offset: const Offset(0, 2),
                                                    )
                                                  ]
                                                : null,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    // Weekday Label
                                    Text(
                                      weekdays[index],
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                                        color: isToday ? themeColor : Colors.white60,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Productivity Tip Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.02),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.lightbulb_outline, color: themeColor, size: 24),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Tip van de dag',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _getProductivityTip(state.completedSessions),
                                style: const TextStyle(fontSize: 13, color: Colors.white60, height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161623),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
              Icon(icon, color: iconColor, size: 20),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: Colors.white38),
          ),
        ],
      ),
    );
  }

  String _getProductivityTip(int completedSessions) {
    if (completedSessions == 0) {
      return 'Start je eerste focus-ronde! De Pomodoro-techniek helpt je brein om scherp te blijven door korte periodes van intense focus af te wisselen met rust.';
    } else if (completedSessions < 3) {
      return 'Goed bezig! Vergeet niet om tijdens je korte pauzes echt even weg te lopen van je scherm. Rek je uit of drink een glas water.';
    } else {
      return 'Geweldig! Je hebt al een aantal focus-rondes afgerond. Na 4 rondes verdien je een langere pauze van 15 minuten om je energie volledig op te laden.';
    }
  }
}
