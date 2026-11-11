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

    return Semantics(
      label: 'Demo Reference Clock: $clockStr',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: const BoxDecoration(
          color: Color(0xFFF8FAFC),
          border: Border(
            bottom: BorderSide(color: Color(0xFFE2E8F0), width: 0.8),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.schedule, size: 14, color: Color(0xFF64748B)),
            const SizedBox(width: 8),
            const Text(
              'DEMO CLOCK',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF64748B),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                clockStr,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF334155),
                ),
              ),
            ),
            InkWell(
              borderRadius: BorderRadius.circular(4),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Text(
                  'Change',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
