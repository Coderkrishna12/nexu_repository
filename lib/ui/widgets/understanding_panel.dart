import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
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
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderSubtle, width: 0.8),
        ),
        child: Row(
          children: const [
            Icon(Icons.mic_none, color: AppTheme.textSubtle, size: 16),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Understanding Panel ready. Speak or enter a command below.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final latest = history.first;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderSubtle, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar: Icon, Label, and Confidence Badge
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
            child: Row(
              children: [
                const Icon(
                  Icons.graphic_eq,
                  size: 15,
                  color: AppTheme.accentBlue,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Assistant Response',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                _buildConfidenceBadge(latest.confidence),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Body: Spoken prompt & Visual confirmation
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User's spoken input
                Text(
                  '"${latest.userSpokenText}"',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),

                // Spoken / Visual response message
                Text(
                  latest.responseMessage,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppTheme.textSecondary,
                    height: 1.35,
                  ),
                ),

                // Extracted parameters (clean, muted chips)
                if (latest.extractedDate != null ||
                    latest.extractedPriority != null) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (latest.extractedDate != null)
                        _buildInfoTag(
                          icon: Icons.calendar_today_outlined,
                          text: latest.extractedTimeMinutes != null
                              ? '${DateTimeParser.formatDateOnly(latest.extractedDate!)}, ${DateTimeParser.formatMinutesToTime(latest.extractedTimeMinutes!)}'
                              : DateTimeParser.formatDateOnly(
                                  latest.extractedDate!,
                                ),
                        ),
                      if (latest.extractedPriority != null)
                        _buildInfoTag(
                          icon: Icons.flag_outlined,
                          text: latest.extractedPriority!.displayName,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Collapsible Command History
          if (history.length > 1) ...[
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            InkWell(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              onTap: () {
                setState(() {
                  _isHistoryExpanded = !_isHistoryExpanded;
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Text(
                      '${history.length - 1} earlier ${history.length - 1 == 1 ? "command" : "commands"}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      _isHistoryExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 15,
                      color: AppTheme.textMuted,
                    ),
                  ],
                ),
              ),
            ),
            if (_isHistoryExpanded)
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 160),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  itemCount: history.length - 1,
                  separatorBuilder: (_, index) =>
                      const Divider(height: 1, color: Color(0xFFF8FAFC)),
                  itemBuilder: (context, idx) {
                    final item = history[idx + 1];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '"${item.userSpokenText}"',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppTheme.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildConfidenceBadge(item.confidence, mini: true),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildConfidenceBadge(
    ConfidenceLevel confidence, {
    bool mini = false,
  }) {
    Color bg;
    Color fg;
    String text;

    switch (confidence) {
      case ConfidenceLevel.high:
        bg = AppTheme.successBg;
        fg = AppTheme.successText;
        text = 'CONFIDENCE HIGH';
        break;
      case ConfidenceLevel.medium:
        bg = AppTheme.warningBg;
        fg = AppTheme.warningText;
        text = 'CONFIDENCE MEDIUM';
        break;
      case ConfidenceLevel.low:
        bg = AppTheme.dangerBg;
        fg = AppTheme.dangerText;
        text = 'CONFIDENCE LOW';
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: mini ? 4 : 6,
        vertical: mini ? 1 : 2,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontSize: mini ? 8.5 : 9.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildInfoTag({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: AppTheme.textMuted),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
