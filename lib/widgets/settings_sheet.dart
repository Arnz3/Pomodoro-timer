import 'package:flutter/material.dart';

class SettingsSheet extends StatefulWidget {
  final int initialWorkMinutes;
  final int initialShortBreakMinutes;
  final int initialLongBreakMinutes;
  final Function(int work, int short, int long) onSave;
  final Color themeColor;

  const SettingsSheet({
    super.key,
    required this.initialWorkMinutes,
    required this.initialShortBreakMinutes,
    required this.initialLongBreakMinutes,
    required this.onSave,
    required this.themeColor,
  });

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  late int _tempWork;
  late int _tempShort;
  late int _tempLong;

  @override
  void initState() {
    super.initState();
    _tempWork = widget.initialWorkMinutes;
    _tempShort = widget.initialShortBreakMinutes;
    _tempLong = widget.initialLongBreakMinutes;
  }

  @override
  Widget build(BuildContext context) {
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
            value: _tempWork,
            color: const Color(0xFFFF5E62),
            min: 5,
            max: 60,
            onChanged: (val) {
              setState(() => _tempWork = val.round());
            },
          ),
          _buildSliderSetting(
            title: 'Korte Pauze',
            value: _tempShort,
            color: const Color(0xFF00D2C4),
            min: 1,
            max: 30,
            onChanged: (val) {
              setState(() => _tempShort = val.round());
            },
          ),
          _buildSliderSetting(
            title: 'Lange Pauze',
            value: _tempLong,
            color: const Color(0xFF3B82F6),
            min: 5,
            max: 45,
            onChanged: (val) {
              setState(() => _tempLong = val.round());
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              widget.onSave(_tempWork, _tempShort, _tempLong);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.themeColor,
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
}
