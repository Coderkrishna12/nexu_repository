import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../engine/date_time_parser.dart';
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

    List<TaskItem> filteredTasks;
    if (_selectedFilterIndex == 1) {
      // Due Today relative to demoClock
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
        // Filter tabs & count
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: SegmentedButton<int>(
                  segments: [
                    ButtonSegment(
                      value: 0,
                      label: Text('All (${allTasks.length})'),
                    ),
                    ButtonSegment(
                      value: 1,
                      label: Text('Today (${allTasks.where((t) => t.dueDateTime.year == demoClock.year && t.dueDateTime.month == demoClock.month && t.dueDateTime.day == demoClock.day).length})'),
                    ),
                    ButtonSegment(
                      value: 2,
                      label: Text('Done (${allTasks.where((t) => t.isCompleted).length})'),
                    ),
                  ],
                  selected: {_selectedFilterIndex},
                  onSelectionChanged: (val) {
                    setState(() {
                      _selectedFilterIndex = val.first;
                    });
                  },
                ),
              ),
            ],
          ),
        ),

        // Tasks list or Empty State
        if (filteredTasks.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.assignment_outlined, size: 54, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    _selectedFilterIndex == 1
                        ? 'No tasks due today (${DateTimeParser.formatDateOnly(demoClock)})'
                        : (_selectedFilterIndex == 2 ? 'No completed tasks yet' : 'No tasks created yet'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Hold the mic button or type a simulated command below:\n"add task buy cable tomorrow at 5 pm high priority"',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
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
              );
            },
          ),
      ],
    );
  }
}
