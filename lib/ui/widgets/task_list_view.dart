import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/task_item.dart';
import '../../providers/assistant_provider.dart';
import 'task_card.dart';

class TaskListView extends StatefulWidget {
  const TaskListView({super.key});

  @override
  State<TaskListView> createState() => _TaskListViewState();
}

class _TaskListViewState extends State<TaskListView> {
  int _selectedFilterIndex = 0; // 0: All, 1: Due Today, 2: Completed

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AssistantProvider>();
    final allTasks = provider.tasks;
    final demoClock = provider.demoClock;

    final todayTasksCount = allTasks.where((t) {
      return t.dueDateTime.year == demoClock.year &&
          t.dueDateTime.month == demoClock.month &&
          t.dueDateTime.day == demoClock.day;
    }).length;

    final completedTasksCount = allTasks.where((t) => t.isCompleted).length;

    List<TaskItem> filteredTasks;
    if (_selectedFilterIndex == 1) {
      filteredTasks = allTasks.where((t) {
        return t.dueDateTime.year == demoClock.year &&
            t.dueDateTime.month == demoClock.month &&
            t.dueDateTime.day == demoClock.day;
      }).toList();
    } else if (_selectedFilterIndex == 2) {
      filteredTasks = allTasks.where((t) => t.isCompleted).toList();
    } else {
      filteredTasks = allTasks;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Sleek Minimal Filter Pills
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              _buildFilterPill(
                title: 'All',
                count: allTasks.length,
                index: 0,
              ),
              const SizedBox(width: 8),
              _buildFilterPill(
                title: 'Today',
                count: todayTasksCount,
                index: 1,
              ),
              const SizedBox(width: 8),
              _buildFilterPill(
                title: 'Done',
                count: completedTasksCount,
                index: 2,
              ),
            ],
          ),
        ),

        // Tasks list or Empty State
        if (filteredTasks.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 40,
                    color: Color(0xFFCBD5E1),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _selectedFilterIndex == 1
                        ? 'No tasks due today'
                        : (_selectedFilterIndex == 2
                            ? 'No completed tasks yet'
                            : 'No tasks created yet'),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textMuted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Speak or type a command to manage your agenda.',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSubtle),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredTasks.length,
            itemBuilder: (context, index) {
              final task = filteredTasks[index];
              final isContextActive = task.id == provider.lastMentionedTaskId;
              return TaskCard(
                task: task,
                isContextActive: isContextActive,
                onToggleDone: () {
                  final action = task.isCompleted ? 'unmark' : 'mark';
                  provider.submitCommand('$action ${task.title} done');
                },
                onDelete: () {
                  provider.submitCommand('delete task ${task.title}');
                },
              );
            },
          ),
      ],
    );
  }

  Widget _buildFilterPill({
    required String title,
    required int count,
    required int index,
  }) {
    final isSelected = _selectedFilterIndex == index;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        setState(() {
          _selectedFilterIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primarySlate : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '$title ($count)',
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}
