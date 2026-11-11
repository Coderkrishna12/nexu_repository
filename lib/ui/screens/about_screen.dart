import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('About & Architecture'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.mic, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'NEXU VoiceDesk',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.2,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Hands-free task assistant for field technicians',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Compliance Note
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Core Architecture & No-AI Rule',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  '"No AI service or API key is needed or allowed as the core of this task. We want to see your logic: a parser you wrote, rules you can explain, and an app that safely handles sentences it does not understand." (PDF Section 1)',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Color(0xFF475569),
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  '100% pure Dart command engine (intent_classifier.dart, date_time_parser.dart, command_engine.dart). Operates offline without external AI/LLM API calls.',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF64748B),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Submission Details
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Submission Details',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 10),
                _buildInfoRow('Role', 'Mobile Developer Practical Assessment'),
                _buildInfoRow('Received', '11 November 2026, 14:02 IST'),
                _buildInfoRow(
                  'Technology',
                  'Flutter (Dart) • Pure Function Engine',
                ),
                _buildInfoRow(
                  'Target User',
                  'Ravi (Field technician with gloves on)',
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Technical Explanation (Section 10)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(14, 12, 14, 6),
                  child: Text(
                    'Technical Explanation (PDF Section 10)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
                const Divider(color: Color(0xFFF1F5F9)),
                _buildFaqTile(
                  title: '1. Step-by-step trace of "move it to Friday at 10"',
                  content:
                      '1. Speech capture passes words to IntentClassifier.parse().\n'
                      '2. Parser matches RESCHEDULE: target is "it", destination is "Friday at 10".\n'
                      '3. Rule C3 resolves "it" to lastMentionedTaskId ("buy cable").\n'
                      '4. DateTimeParser resolves destination against Demo Clock (Wed 11 Nov 2026, 10:00 AM) to Fri 13 Nov 2026, 10:00 AM.\n'
                      '5. Engine records an UndoAction (reschedule reversal) on the 5-item undo stack and updates the task due timestamp.\n'
                      '6. Confirmation message is spoken and displayed.',
                ),
                _buildFaqTile(
                  title: '2. How intent is decided and wrong guesses avoided',
                  content:
                      '• Acoustic normalization repairs STT slips ("tas" -> "task", "golden" -> "call done").\n'
                      '• Conversational prefixes ("i said...", "please...") are stripped.\n'
                      '• Active multi-turn state (yes/no, ambiguity) is evaluated before general intents.\n'
                      '• Words are matched against workshop vocabulary. Unmatched patterns trigger Rule C6 Low Confidence (no action taken, prompts rephrase).',
                ),
                _buildFaqTile(
                  title:
                      '3. Handling "it" and "Which one?" conversation states',
                  content:
                      '• "it", "that", "the last task" resolve to lastMentionedTaskId. If empty, asks which task is meant.\n'
                      '• Ambiguity (Rule C4): when a query matches >= 2 tasks (e.g. "call" matching "call Ravi" and "call vendor"), engine asks "Which one?" and accepts "one", "two", "the first", or candidate title words.',
                ),
                _buildFaqTile(
                  title:
                      '4. Handling speech while the app is talking (Barge-in)',
                  content:
                      'The instant the microphone is activated or a command is submitted, ttsService.stop() is invoked immediately, stopping audio output with zero overlap.',
                ),
                _buildFaqTile(
                  title: '5. Supporting Hindi or Kannada commands',
                  content:
                      '• Modularize grammar rules into localized intent strategies.\n'
                      '• Map SOV (Subject-Object-Verb) sentence structures for Hindi ("task jodo") and Kannada ("task serisi").\n'
                      '• Set speech_to_text localeId to "hi-IN" or "kn-IN".',
                ),
                _buildFaqTile(
                  title:
                      '6. Code authored vs third-party packages & AI disclosure',
                  content:
                      '• Built by Candidate: Complete command engine, intent classifier, relative date parser, state machine, undo stack, and UI.\n'
                      '• Packages: speech_to_text, flutter_tts, shared_preferences, provider, intl, uuid.\n'
                      '• AI disclosure: Used for setup scaffolding, syntax checks, and testing structure in compliance with Section 11.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqTile({required String title, required String content}) {
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
      childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1E293B),
        ),
      ),
      children: [
        Text(
          content,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF475569),
            height: 1.45,
          ),
        ),
      ],
    );
  }
}
