import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About NEXU VoiceDesk'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header Card
          Card(
            color: const Color(0xFF0F172A),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.mic, color: Colors.white, size: 36),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'NEXU VOICEDESK',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Hands-Free Voice-First Task Assistant for Field Technicians',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Assessment Submission Details Card (Section 8.8 Requirement)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.badge_outlined, color: Color(0xFF2563EB)),
                      SizedBox(width: 8),
                      Text(
                        'Candidate & Submission Details',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _buildDetailRow(
                    label: 'Candidate Name',
                    value: 'Mobile Developer Candidate (NEXU Assessment)',
                  ),
                  const SizedBox(height: 10),
                  _buildDetailRow(
                    label: 'Date & Time Received',
                    value: '11 November 2026, 14:02 IST (08:32 UTC)',
                  ),
                  const SizedBox(height: 10),
                  _buildDetailRow(
                    label: 'Assessment Type',
                    value: 'Mobile Developer Practical Technical Assessment',
                  ),
                  const SizedBox(height: 10),
                  _buildDetailRow(
                    label: 'Target User',
                    value: 'Ravi (Field Technician with gloves in noisy workshop)',
                  ),
                  const SizedBox(height: 10),
                  _buildDetailRow(
                    label: 'Core "Brain"',
                    value: '100% Pure Deterministic Dart Command Engine (No Cloud AI)',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Architecture Highlights Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.architecture_outlined, color: Color(0xFF0D9488)),
                      SizedBox(width: 8),
                      Text(
                        'Architecture & Technical Decisions',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  const Text(
                    '• Pure Functions Engine: (text, state, demoClock) -> CommandResult.\n'
                    '• Zero Cloud AI / API Dependency: Hand-crafted token regex & rule-based slot extraction.\n'
                    '• Multi-Turn State Machine: Manages Past-Time Clarifications (C2), Ambiguity Resolution (C4), and 8-second Delete Safety (C5).\n'
                    '• Demo Clock Isolation: Absolute and relative dates are resolved against the Demo Clock without relying on device system time.\n'
                    '• Instant Audio Interruption: Any incoming user speech immediately stops active TTS playback.\n'
                    '• Full Persistence: Local storage preserves tasks, undo stack, and understanding logs across app reboots.',
                    style: TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF334155)),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Disclosures & Integrity Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.verified_user_outlined, color: Color(0xFF16A34A)),
                      SizedBox(width: 8),
                      Text(
                        'Honest Disclosures & Third-Party Code',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  const Text(
                    '• STT: speech_to_text package for device microphone audio streaming.\n'
                    '• TTS: flutter_tts package for localized speech synthesis.\n'
                    '• State Management: Provider (ChangeNotifier) pattern.\n'
                    '• Persistence: shared_preferences for local storage.\n'
                    '• Parser Logic & Conversational Engine: Custom designed pure Dart code with comprehensive automated tests.',
                    style: TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF334155)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Color(0xFF64748B),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}
