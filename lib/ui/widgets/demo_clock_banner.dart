import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../engine/date_time_parser.dart';
import '../../providers/assistant_provider.dart';
import '../screens/settings_screen.dart';

class DemoClockBanner extends StatelessWidget {
  const DemoClockBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AssistantProvider>();
    final clockStr = DateTimeParser.formatFullDateTime(provider.demoClock);
    final isDefault = provider.demoClock == AssistantProvider.defaultDemoClock;

    return Semantics(
      label: 'Demo Clock Banner. Active demo time is $clockStr.',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          border: Border(
            bottom: BorderSide(
              color: isDefault ? const Color(0xFF3B82F6) : const Color(0xFFF59E0B),
              width: 2,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.schedule,
              color: isDefault ? const Color(0xFF60A5FA) : const Color(0xFFFBBF24),
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        'DEMO CLOCK',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                      if (isDefault) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'ASSESSMENT DEFAULT',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    clockStr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Adjust Demo Clock',
              icon: const Icon(Icons.edit_calendar, color: Colors.white, size: 20),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
