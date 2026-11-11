import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/assistant_provider.dart';
import '../widgets/active_prompt_banner.dart';
import '../widgets/demo_clock_banner.dart';
import '../widgets/hold_to_talk_button.dart';
import '../widgets/simulated_voice_input.dart';
import '../widgets/task_list_view.dart';
import '../widgets/understanding_panel.dart';
import 'about_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AssistantProvider>();
    final undoCount = provider.undoStack.length;

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('NEXU VoiceDesk'),
            Text(
              'Technician Hands-Free Assistant',
              style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          // Undo Quick Button (Rule C7)
          Semantics(
            label: 'Undo last action. $undoCount actions available.',
            button: true,
            child: IconButton(
              tooltip: 'Undo That',
              icon: Badge(
                isLabelVisible: undoCount > 0,
                label: Text('$undoCount'),
                child: const Icon(Icons.undo),
              ),
              onPressed: () => provider.submitCommand('undo that'),
            ),
          ),
          // Mute Toggle (Section 3C)
          Semantics(
            label: provider.isMuted ? 'Unmute spoken replies' : 'Mute spoken replies',
            button: true,
            child: IconButton(
              tooltip: provider.isMuted ? 'Unmute TTS' : 'Mute TTS',
              icon: Icon(provider.isMuted ? Icons.volume_off : Icons.volume_up),
              onPressed: () => provider.toggleMute(),
            ),
          ),
          // Settings Menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (val) {
              if (val == 'settings') {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              } else if (val == 'about') {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AboutScreen()),
                );
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.tune, size: 18),
                    SizedBox(width: 8),
                    Text('Settings & Clock'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'about',
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 18),
                    SizedBox(width: 8),
                    Text('About NEXU'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Persistent Demo Clock Header
            const DemoClockBanner(),

            // Scrollable Content
            Expanded(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 110),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: const [
                        // Active Conversational Clarification / Confirmation Prompt
                        ActivePromptBanner(),

                        // Understanding Panel (Rule C6 & Section 3E)
                        UnderstandingPanel(),

                        SizedBox(height: 8),

                        // Task List (Section 3F)
                        TaskListView(),
                      ],
                    ),
                  ),

                  // Hold-to-Talk Mic thumb button positioned for easy single-thumb reach
                  const Positioned(
                    bottom: 0,
                    right: 0,
                    left: 0,
                    child: HoldToTalkButton(),
                  ),
                ],
              ),
            ),

            // Simulated Voice input box (always visible & operable)
            const SimulatedVoiceInput(),
          ],
        ),
      ),
    );
  }
}
