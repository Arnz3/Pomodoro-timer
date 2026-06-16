import 'package:flutter/material.dart';
import '../models/task.dart';

class ChecklistWidget extends StatefulWidget {
  final List<Task> tasks;
  final Function(String title) onAddTask;
  final Function(String id) onToggleTask;
  final Function(String id) onDeleteTask;
  final Color themeColor;

  const ChecklistWidget({
    super.key,
    required this.tasks,
    required this.onAddTask,
    required this.onToggleTask,
    required this.onDeleteTask,
    required this.themeColor,
  });

  @override
  State<ChecklistWidget> createState() => _ChecklistWidgetState();
}

class _ChecklistWidgetState extends State<ChecklistWidget> {
  final TextEditingController _taskController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _taskController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _submitTask() {
    final text = _taskController.text;
    if (text.trim().isNotEmpty) {
      widget.onAddTask(text);
      _taskController.clear();
      
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final completedCount = widget.tasks.where((t) => t.isCompleted).length;
    final totalCount = widget.tasks.length;

    return Container(
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
                '$completedCount/$totalCount',
                style: TextStyle(
                  fontSize: 14,
                  color: widget.themeColor,
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
                  onSubmitted: (_) => _submitTask(),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _submitTask,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: widget.themeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: widget.themeColor.withValues(alpha: 0.3)),
                  ),
                  child: Icon(Icons.add, color: widget.themeColor, size: 20),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Tasks scrollable list
          Expanded(
            child: widget.tasks.isEmpty
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
                    itemCount: widget.tasks.length,
                    itemBuilder: (context, index) {
                      final task = widget.tasks[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.02),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: task.isCompleted
                                ? Colors.white10
                                : widget.themeColor.withValues(alpha: 0.1),
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                          leading: Checkbox(
                            value: task.isCompleted,
                            activeColor: widget.themeColor,
                            checkColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            onChanged: (_) => widget.onToggleTask(task.id),
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
                            onPressed: () => widget.onDeleteTask(task.id),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
