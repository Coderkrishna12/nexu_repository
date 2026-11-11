import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../engine/date_time_parser.dart';
import '../../models/confidence_level.dart';
import '../../providers/assistant_provider.dart';

class UnderstandingPanel extends StatefulWidget {
  const UnderstandingPanel({super.key});

  @override
  State<UnderstandingPanel> createState() => _UnderstandingPanelState();
}

class _UnderstandingPanelState extends State<UnderstandingPanel> {
  bool _isHistoryExpanded = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AssistantProvider>();
    final history = provider.history;

    if (history.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Icon(Icons.psychology_outlined, color: Colors.blue.shade700, size: 28),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Understanding Panel ready. Speak or simulate a command to view parsed intent, values, and confidence.',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
            ),
          ],
        ),
      );
    }

    final latest = history.first;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.psychology, color: Color(0xFF60A5FA), size: 22),
                const SizedBox(width: 8),
                const Text(
                  'UNDERSTANDING PANEL',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                const Spacer(),
                _buildConfidenceBadge(latest.confidence),
              ],
            ),
          ),

          // Latest Parsed Command Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // What User Said
                const Text(
                  'WHAT USER SAID:',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    '"${latest.userSpokenText}"',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Extracted Intent & Values
                const Text(
                  'WHAT APP UNDERSTOOD:',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _buildPill(
                      label: 'Intent',
                      value: latest.intent.displayName,
                      color: const Color(0xFF2563EB),
                    ),
                    if (latest.extractedTitle != null)
                      _buildPill(
                        label: 'Title',
                        value: latest.extractedTitle!,
                        color: const Color(0xFF0F172A),
                      ),
                    if (latest.extractedDate != null)
                      _buildPill(
                        label: 'Date',
                        value: DateTimeParser.formatDateOnly(latest.extractedDate!),
                        color: const Color(0xFF0D9488),
                      ),
                    if (latest.extractedTimeMinutes != null)
                      _buildPill(
                        label: 'Time',
                        value: _formatTimeMinutes(latest.extractedTimeMinutes!),
                        color: const Color(0xFF0D9488),
                      ),
                    if (latest.extractedPriority != null)
                      _buildPill(
                        label: 'Priority',
                        value: latest.extractedPriority!.displayName,
                        color: const Color(0xFFD97706),
                      ),
                    if (latest.targetQuery != null)
                      _buildPill(
                        label: 'Target',
                        value: latest.targetQuery!,
                        color: const Color(0xFF7C3AED),
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                // Spoken / Visual Result
                const Text(
                  'RESULT & SPOKEN FEEDBACK:',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  latest.responseMessage,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF334155),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // History Expansion Header
          if (history.length > 1) ...[
            const Divider(height: 1),
            InkWell(
              onTap: () {
                setState(() {
                  _isHistoryExpanded = !_isHistoryExpanded;
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Icon(
                      _isHistoryExpanded ? Icons.expand_less : Icons.expand_more,
                      size: 20,
                      color: const Color(0xFF475569),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Past Command History (${history.length - 1} earlier turns)',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_isHistoryExpanded) ...[
              Container(
                constraints: const BoxConstraints(maxHeight: 280),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: history.length - 1,
                  separatorBuilder: (_, index) => const Divider(height: 1),
                  itemBuilder: (context, idx) {
                    final item = history[idx + 1];
                    return ListTile(
                      dense: true,
                      title: Text(
                        '"${item.userSpokenText}"',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      subtitle: Text(
                        '${item.intent.displayName} • ${item.responseMessage}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: _buildConfidenceBadge(item.confidence, small: true),
                    );
                  },
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildConfidenceBadge(ConfidenceLevel confidence, {bool small = false}) {
    Color bg;
    Color fg;
    switch (confidence) {
      case ConfidenceLevel.high:
        bg = const Color(0xFF16A34A);
        fg = Colors.white;
        break;
      case ConfidenceLevel.medium:
        bg = const Color(0xFFF59E0B);
        fg = Colors.black87;
        break;
      case ConfidenceLevel.low:
        bg = const Color(0xFFDC2626);
        fg = Colors.white;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 6 : 8,
        vertical: small ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'CONFIDENCE ${confidence.displayName.toUpperCase()}',
        style: TextStyle(
          color: fg,
          fontSize: small ? 9 : 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildPill({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: RichText(
        text: TextSpan(
          text: '$label: ',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          children: [
            TextSpan(
              text: value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeMinutes(int minutes) {
    final hour = minutes ~/ 60;
    final minute = minutes % 60;
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    final period = hour >= 12 ? 'PM' : 'AM';
    final minuteStr = minute.toString().padLeft(2, '0');
    return '$hour12:$minuteStr $period';
  }
}
