import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF59E0B), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Prompt Title Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.help_outline, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getPromptLabel(state.status),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF92400E),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      state.questionPrompt ?? 'Action required',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF78350F),
                      ),
                    ),
                  ],
                ),
              ),
              if (state.status == ConversationStatus.awaitingDeleteConfirmation) ...[
                // Rule C5: 8-second countdown badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.timer, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${provider.deleteCountdownSeconds}s',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 14),

          // Action Buttons based on status
          if (state.status == ConversationStatus.awaitingPastTimeConfirmation) ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.check),
                    label: const Text('Yes, Move to Tomorrow'),
                    onPressed: () => provider.confirmPastTimeByTap(true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF991B1B),
                      side: const BorderSide(color: Color(0xFFDC2626)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.close),
                    label: const Text('No, Cancel'),
                    onPressed: () => provider.confirmPastTimeByTap(false),
                  ),
                ),
              ],
            ),
          ] else if (state.status == ConversationStatus.awaitingDeleteConfirmation) ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.delete_forever),
                    label: const Text('Yes, Delete'),
                    onPressed: () => provider.confirmDeleteByTap(true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black87,
                      side: const BorderSide(color: Colors.grey),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.close),
                    label: const Text('Cancel'),
                    onPressed: () => provider.confirmDeleteByTap(false),
                  ),
                ),
              ],
            ),
          ] else if (state.status == ConversationStatus.awaitingAmbiguityResolution) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (int i = 0; i < state.candidateTaskIds.length; i++) ...[
                  Builder(builder: (context) {
                    final taskId = state.candidateTaskIds[i];
                    final task = provider.tasks.firstWhere(
                      (t) => t.id == taskId,
                      orElse: () => provider.tasks.first,
                    );
                    return ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => provider.selectAmbiguityOptionByTap(i),
                      child: Text('${i + 1}: ${task.title}'),
                    );
                  }),
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
        return 'RULE C2 • PAST TIME CLARIFICATION';
      case ConversationStatus.awaitingAmbiguityResolution:
        return 'RULE C4 • AMBIGUOUS MATCH CLARIFICATION';
      case ConversationStatus.awaitingDeleteConfirmation:
        return 'RULE C5 • DELETE SAFETY CONFIRMATION';
      case ConversationStatus.idle:
        return '';
    }
  }
}
