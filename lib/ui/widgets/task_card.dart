import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../engine/date_time_parser.dart';
import '../../models/task_item.dart';
import '../../models/task_priority.dart';

class TaskCard extends StatelessWidget {
  final TaskItem task;
  final bool isContextActive;
  final VoidCallback? onToggleDone;
  final VoidCallback? onDelete;

  const TaskCard({
    super.key,
    required this.task,
    this.isContextActive = false,
    this.onToggleDone,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dueFormatted = DateTimeParser.formatFullDateTime(task.dueDateTime);
    final isDone = task.isCompleted;

    return Semantics(
      label: 'Task: ${task.title}, priority ${task.priority.displayName}, due $dueFormatted, ${isDone ? "completed" : "pending"}',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        decoration: BoxDecoration(
          color: isDone ? const Color(0xFFF8FAFC) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isContextActive
                ? const Color(0xFF2563EB)
                : (isDone ? const Color(0xFFE2E8F0) : const Color(0xFFCBD5E1)),
            width: isContextActive ? 2.5 : 1.0,
          ),
          boxShadow: [
            if (isContextActive)
              BoxShadow(
                color: const Color(0xFF2563EB).withValues(alpha: 0.18),
                blurRadius: 10,
                offset: const Offset(0, 3),
              )
            else
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Context Header Pill (Rule C3)
              if (isContextActive) ...[
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF3B82F6)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.gps_fixed, size: 12, color: Color(0xFF1D4ED8)),
                          SizedBox(width: 4),
                          Text(
                            'ACTIVE CONTEXT ("it" / "that")',
                            style: TextStyle(
                              color: Color(0xFF1D4ED8),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // Title and Status
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Icon (Tappable for glove convenience)
                  Semantics(
                    label: isDone ? 'Mark task as pending' : 'Mark task as done',
                    button: true,
                    child: InkWell(
                      onTap: onToggleDone,
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                          color: isDone ? const Color(0xFF16A34A) : Colors.grey,
                          size: 26,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: isDone ? const Color(0xFF64748B) : const Color(0xFF0F172A),
                            decoration: isDone ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.access_time, size: 15, color: Color(0xFF64748B)),
                            const SizedBox(width: 5),
                            Text(
                              dueFormatted,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDone ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Priority Badge
                  _buildPriorityBadge(task.priority),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityBadge(TaskPriority priority) {
    Color bg;
    Color fg;
    switch (priority) {
      case TaskPriority.high:
        bg = const Color(0xFFFEE2E2);
        fg = AppTheme.highPriorityRed;
        break;
      case TaskPriority.normal:
        bg = const Color(0xFFDBEAFE);
        fg = AppTheme.accentBlue;
        break;
      case TaskPriority.low:
        bg = const Color(0xFFDCFCE7);
        fg = AppTheme.lowPriorityGreen;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        priority.displayName.toUpperCase(),
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
