import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/conversation_state.dart';
import '../../providers/assistant_provider.dart';

class ActivePromptBanner extends StatelessWidget {
  const ActivePromptBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AssistantProvider>();
    final state = provider.conversationState;

    if (!state.isWaitingForInput) {
      return const SizedBox.shrink();
    }

    final isDelete =
        state.status == ConversationStatus.awaitingDeleteConfirmation;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDelete ? AppTheme.dangerRose : AppTheme.borderMedium,
          width: 1.2,
        ),
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
          // Header Row
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDelete ? AppTheme.dangerRose : AppTheme.accentBlue,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _getPromptLabel(state.status).toUpperCase(),
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              if (isDelete) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.dangerBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Cancels in ${provider.deleteCountdownSeconds}s',
                    style: const TextStyle(
                      color: AppTheme.dangerText,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),

          // Question Prompt
          Text(
            state.questionPrompt ?? 'Confirmation required',
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),

          // Action Buttons
          if (state.status ==
              ConversationStatus.awaitingPastTimeConfirmation) ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primarySlate,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => provider.confirmPastTimeByTap(true),
                    child: const Text(
                      'Yes, Move to Tomorrow',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textSecondary,
                      side: const BorderSide(color: AppTheme.borderMedium),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => provider.confirmPastTimeByTap(false),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else if (isDelete) ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.dangerRose,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => provider.confirmDeleteByTap(true),
                    child: const Text(
                      'Yes, Delete',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textSecondary,
                      side: const BorderSide(color: AppTheme.borderMedium),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => provider.confirmDeleteByTap(false),
                    child: const Text(
                      'Keep Task',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else if (state.status ==
              ConversationStatus.awaitingAmbiguityResolution) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (int i = 0; i < state.candidateTaskIds.length; i++) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textPrimary,
                        side: const BorderSide(color: AppTheme.borderMedium),
                        padding: const EdgeInsets.symmetric(
                          vertical: 11,
                          horizontal: 12,
                        ),
                        alignment: Alignment.centerLeft,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => provider.selectAmbiguityOptionByTap(i),
                      child: Text(
                        'Option ${i + 1}: ${_getTaskTitle(provider, state.candidateTaskIds[i])}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _getPromptLabel(ConversationStatus status) {
    switch (status) {
      case ConversationStatus.awaitingPastTimeConfirmation:
        return 'Time has passed';
      case ConversationStatus.awaitingAmbiguityResolution:
        return 'Multiple matches found';
      case ConversationStatus.awaitingDeleteConfirmation:
        return 'Confirm deletion';
      case ConversationStatus.idle:
        return '';
    }
  }

  String _getTaskTitle(AssistantProvider provider, String id) {
    final match = provider.tasks.where((t) => t.id == id).firstOrNull;
    return match?.title ?? 'Task';
  }
}
