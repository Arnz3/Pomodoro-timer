import 'package:flutter/material.dart';
import '../models/focus_subject.dart';

class FocusLibrarySheet extends StatefulWidget {
  final List<FocusSubject> subjects;
  final String? selectedId;
  final ValueChanged<String> onSelect;
  final void Function(String name, Color color) onAdd;
  final ValueChanged<String> onDelete;
  final Color themeColor;

  const FocusLibrarySheet({
    super.key,
    required this.subjects,
    required this.selectedId,
    required this.onSelect,
    required this.onAdd,
    required this.onDelete,
    required this.themeColor,
  });

  @override
  State<FocusLibrarySheet> createState() => _FocusLibrarySheetState();
}

class _FocusLibrarySheetState extends State<FocusLibrarySheet> {
  final _nameController = TextEditingController();
  static const _colors = [
    Color(0xFF4D9DE0),
    Color(0xFFFF7A59),
    Color(0xFF45C486),
    Color(0xFFC77DFF),
    Color(0xFFF4C95D),
    Color(0xFFE85D75),
  ];
  Color _newColor = _colors.first;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _addSubject() {
    if (_nameController.text.trim().isEmpty) return;
    widget.onAdd(_nameController.text, _newColor);
    _nameController.clear();
    FocusScope.of(context).unfocus();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Focusbibliotheek',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            const Text(
              'Kies waarvoor je nu wilt focussen.',
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 18),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: widget.subjects.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final subject = widget.subjects[index];
                  final selected = subject.id == widget.selectedId;
                  return ListTile(
                    onTap: () {
                      widget.onSelect(subject.id);
                      Navigator.pop(context);
                    },
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: selected ? subject.color : Colors.white10,
                      ),
                    ),
                    leading: CircleAvatar(
                      radius: 12,
                      backgroundColor: subject.color,
                    ),
                    title: Text(
                      subject.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (selected)
                          Icon(Icons.check_circle, color: subject.color),
                        if (widget.subjects.length > 1)
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20),
                            color: Colors.white38,
                            tooltip: 'Verwijderen',
                            onPressed: () => widget.onDelete(subject.id),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _nameController,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _addSubject(),
              decoration: InputDecoration(
                hintText: 'Nieuw vak toevoegen',
                prefixIcon: const Icon(Icons.add),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: _colors.map((color) {
                final selected = color.value == _newColor.value;
                return GestureDetector(
                  onTap: () => setState(() => _newColor = color),
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? Colors.white : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(radius: 12, backgroundColor: color),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: _addSubject,
              icon: const Icon(Icons.add),
              label: const Text('Vak toevoegen'),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.themeColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
