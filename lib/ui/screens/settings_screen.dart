import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../engine/date_time_parser.dart';
import '../../providers/assistant_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AssistantProvider>();
    final clock = provider.demoClock;
    final isDefault = clock == AssistantProvider.defaultDemoClock;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Demo Clock'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Section 1: Demo Clock Configuration
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.access_time_filled, color: Color(0xFF2563EB)),
                      const SizedBox(width: 8),
                      const Text(
                        'Demo Reference Clock',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      if (isDefault)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDBEAFE),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'DEFAULT',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1D4ED8),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'All relative dates ("today", "tomorrow", "Friday at 10", "at 5 pm") and past-time checks are resolved against this clock rather than real device time.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'CURRENT DEMO CLOCK:',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF64748B),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateTimeParser.formatFullDateTime(clock),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.calendar_month, size: 18),
                          label: const Text('Pick Date'),
                          onPressed: () async {
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: clock,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2035),
                            );
                            if (pickedDate != null) {
                              final updated = DateTime(
                                pickedDate.year,
                                pickedDate.month,
                                pickedDate.day,
                                clock.hour,
                                clock.minute,
                              );
                              await provider.setDemoClock(updated);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.schedule, size: 18),
                          label: const Text('Pick Time'),
                          onPressed: () async {
                            final pickedTime = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay(hour: clock.hour, minute: clock.minute),
                            );
                            if (pickedTime != null) {
                              final updated = DateTime(
                                clock.year,
                                clock.month,
                                clock.day,
                                pickedTime.hour,
                                pickedTime.minute,
                              );
                              await provider.setDemoClock(updated);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.restart_alt),
                      label: const Text('Reset to Assessment Default (Nov 11, 2026 10:00 AM)'),
                      onPressed: () async {
                        await provider.resetDemoClockToDefault();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Demo clock reset to Wed, 11 Nov 2026, 10:00 AM.'),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Section 2: Speech & Spoken Replies
          Card(
            child: SwitchListTile(
              secondary: Icon(
                provider.isMuted ? Icons.volume_off : Icons.volume_up,
                color: provider.isMuted ? Colors.grey : const Color(0xFF2563EB),
              ),
              title: const Text('Mute Spoken Replies'),
              subtitle: const Text('When enabled, results appear visually without reading aloud.'),
              value: provider.isMuted,
              onChanged: (_) => provider.toggleMute(),
            ),
          ),

          const SizedBox(height: 12),

          // Section 3: Reset / Clear Storage
          Card(
            child: ListTile(
              leading: const Icon(Icons.delete_sweep, color: Color(0xFFDC2626)),
              title: const Text('Clear All Tasks & History'),
              subtitle: const Text('Erases persisted tasks, understanding logs, and undo history.'),
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Clear All Data?'),
                    content: const Text('This will delete all saved tasks, command history, and undo steps.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Clear All', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await provider.clearAll();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('All tasks and history cleared.')),
                    );
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
