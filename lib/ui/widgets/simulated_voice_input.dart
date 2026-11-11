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
      'label': '1: Buy cable (High)',
      'cmd': 'add task buy cable tomorrow at 5 pm high priority',
    },
    {
      'label': '2: Call vendor (C2)',
      'cmd': 'add task call vendor',
    },
    {
      'label': '3: Move to Friday at 10',
      'cmd': 'move it to Friday at 10',
    },
    {
      'label': '4: Mark call done (C4)',
      'cmd': 'mark call done',
    },
    {
      'label': '5: Delete last task (C5)',
      'cmd': 'delete the last task',
    },
    {
      'label': '6: What is due today',
      'cmd': 'what is due today',
    },
    {
      'label': '7: Undo that (C7)',
      'cmd': 'undo that',
    },
    {
      'label': '8: Coffee test (C6 Low)',
      'cmd': 'make coffee fly to the moon',
    },
    {
      'label': 'Call done (Shorthand)',
      'cmd': 'call done',
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE2E8F0), width: 0.8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Minimal Header & Presets
          Row(
            children: const [
              Text(
                'SIMULATED VOICE (TYPED INPUT)',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.5,
                ),
              ),
              Spacer(),
              Text(
                'Section 5 Presets',
                style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Presets Scroll
          SizedBox(
            height: 26,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _acceptancePresets.length,
              separatorBuilder: (_, index) => const SizedBox(width: 6),
              itemBuilder: (context, idx) {
                final preset = _acceptancePresets[idx];
                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    _controller.text = preset['cmd']!;
                    _submit();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      preset['label']!,
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: Color(0xFF475569),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Clean Input Row
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                  decoration: InputDecoration(
                    hintText: 'Type command or tap preset above...',
                    hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    isDense: true,
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 0.8),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 0.8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: Color(0xFF0F172A), width: 1.0),
                    ),
                  ),
                  onSubmitted: (_) => _submit(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
                onPressed: _submit,
                child: const Text('Send'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
