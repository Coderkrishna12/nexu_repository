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
      label:
          'Task: ${task.title}, priority ${task.priority.displayName}, due $dueFormatted, ${isDone ? "completed" : "pending"}',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: isDone ? const Color(0xFFF8FAFC) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isContextActive
                ? AppTheme.accentBlue
                : AppTheme.borderSubtle,
            width: isContextActive ? 1.4 : 0.8,
          ),
          boxShadow: [
            if (isContextActive)
              BoxShadow(
                color: AppTheme.accentBlue.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            else
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onToggleDone,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Minimal Circular Checkbox with glove-friendly hit area
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone
                        ? AppTheme.successEmerald
                        : Colors.transparent,
                    border: Border.all(
                      color: isDone
                          ? AppTheme.successEmerald
                          : const Color(0xFF94A3B8),
                      width: 1.8,
                    ),
                  ),
                  child: isDone
                      ? const Icon(Icons.check, size: 15, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 12),

                // Main Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Context tag (if this is the last referenced task for pronoun commands)
                      if (isContextActive)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Row(
                            children: const [
                              Icon(
                                Icons.gps_fixed,
                                size: 10,
                                color: AppTheme.accentBlue,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Active context item',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.accentBlue,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Title
                      Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDone
                              ? AppTheme.textSubtle
                              : AppTheme.textPrimary,
                          decoration: isDone
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor: AppTheme.textSubtle,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Metadata: Due Date & Priority
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 12,
                            color: isDone
                                ? const Color(0xFFCBD5E1)
                                : AppTheme.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            dueFormatted,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDone
                                  ? AppTheme.textSubtle
                                  : AppTheme.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildPriorityTag(task.priority, isDone),
                        ],
                      ),
                    ],
                  ),
                ),

                // Delete Button (Quiet & responsive)
                if (onDelete != null)
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      size: 18,
                      color: AppTheme.textSubtle,
                    ),
                    tooltip: 'Delete task',
                    splashRadius: 20,
                    onPressed: onDelete,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityTag(TaskPriority priority, bool isDone) {
    if (priority == TaskPriority.normal) {
      return const SizedBox.shrink();
    }

    final isHigh = priority == TaskPriority.high;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
      decoration: BoxDecoration(
        color: isDone
            ? const Color(0xFFF1F5F9)
            : (isHigh ? AppTheme.dangerBg : const Color(0xFFF1F5F9)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        priority.displayName.toUpperCase(),
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: isDone
              ? AppTheme.textSubtle
              : (isHigh ? AppTheme.dangerText : AppTheme.textSecondary),
        ),
      ),
    );
  }
}
