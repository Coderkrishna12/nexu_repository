import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/assistant_provider.dart';

class SimulatedVoiceInput extends StatefulWidget {
  const SimulatedVoiceInput({super.key});

  @override
  State<SimulatedVoiceInput> createState() => _SimulatedVoiceInputState();
}

class _SimulatedVoiceInputState extends State<SimulatedVoiceInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  static const List<Map<String, String>> _acceptancePresets = [
    {
      'num': '1',
      'label': 'Add buy cable (High)',
      'cmd': 'add task buy cable tomorrow at 5 pm high priority',
    },
    {
      'num': '2',
      'label': 'Add call vendor (C2 Past)',
      'cmd': 'add task call vendor',
    },
    {
      'num': '3',
      'label': 'Move it to Friday at 10',
      'cmd': 'move it to Friday at 10',
    },
    {
      'num': '4',
      'label': 'Mark call done (C4 Ambiguity)',
      'cmd': 'mark call done',
    },
    {
      'num': '5',
      'label': 'Delete the last task (C5)',
      'cmd': 'delete the last task',
    },
    {
      'num': '6',
      'label': 'What is due today',
      'cmd': 'what is due today',
    },
    {
      'num': '7',
      'label': 'Undo that (C7)',
      'cmd': 'undo that',
    },
    {
      'num': '8',
      'label': 'Make coffee... (C6 Low)',
      'cmd': 'make coffee fly to the moon',
    },
  ];

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    context.read<AssistantProvider>().submitCommand(text);
    _controller.clear();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Section Label & Quick Examples Bar
          Row(
            children: [
              Icon(Icons.keyboard_outlined, size: 16, color: Colors.blue.shade800),
              const SizedBox(width: 6),
              const Text(
                'SIMULATED VOICE (TYPED INPUT)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: Color(0xFF1E293B),
                ),
              ),
              const Spacer(),
              const Text(
                'Section 5 Presets:',
                style: TextStyle(fontSize: 10, color: Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Horizontal scroll of Section 5 acceptance chips
          SizedBox(
            height: 32,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _acceptancePresets.length,
              separatorBuilder: (_, index) => const SizedBox(width: 6),
              itemBuilder: (context, idx) {
                final preset = _acceptancePresets[idx];
                return ActionChip(
                  backgroundColor: const Color(0xFFF1F5F9),
                  side: BorderSide(color: Colors.grey.shade300),
                  padding: EdgeInsets.zero,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                  avatar: CircleAvatar(
                    radius: 8,
                    backgroundColor: const Color(0xFF2563EB),
                    child: Text(
                      preset['num']!,
                      style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  label: Text(
                    preset['label']!,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  onPressed: () {
                    _controller.text = preset['cmd']!;
                    _submit();
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          // Input Row
          Row(
            children: [
              Expanded(
                child: Semantics(
                  label: 'Simulated voice text box. Enter command here.',
                  textField: true,
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _submit(),
                    style: const TextStyle(fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'Type sentence (e.g. "add task buy cable tomorrow at 5 pm")...',
                      hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Semantics(
                label: 'Send simulated voice command',
                button: true,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.send, size: 18),
                      SizedBox(width: 4),
                      Text('Send', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
