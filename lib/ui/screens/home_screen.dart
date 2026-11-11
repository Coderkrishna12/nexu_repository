import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
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
      backgroundColor: AppTheme.backgroundMuted,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'NEXU VoiceDesk',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              'Hands-Free Task Assistant',
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.textMuted,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          // Undo Quick Button (Rule C7)
          IconButton(
            tooltip: 'Undo That',
            icon: Badge(
              isLabelVisible: undoCount > 0,
              backgroundColor: AppTheme.primarySlate,
              label: Text('$undoCount', style: const TextStyle(fontSize: 10)),
              child: const Icon(
                Icons.undo,
                size: 20,
                color: AppTheme.textSecondary,
              ),
            ),
            onPressed: () => provider.submitCommand('undo that'),
          ),
          // Mute Audio Toggle (Section 3C)
          IconButton(
            tooltip: provider.isMuted
                ? 'Unmute Speech Feedback'
                : 'Mute Speech Feedback',
            icon: Icon(
              provider.isMuted ? Icons.volume_off : Icons.volume_up_outlined,
              size: 20,
              color: AppTheme.textSecondary,
            ),
            onPressed: () => provider.toggleMute(),
          ),
          // More Menu
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert,
              size: 20,
              color: AppTheme.textSecondary,
            ),
            onSelected: (val) {
              if (val == 'settings') {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              } else if (val == 'about') {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const AboutScreen()));
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.tune, size: 16, color: AppTheme.textSecondary),
                    SizedBox(width: 10),
                    Text('Settings & Clock', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'about',
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: AppTheme.textSecondary,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'About & Architecture',
                      style: TextStyle(fontSize: 13),
                    ),
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
            // Top Persistent Demo Reference Clock Banner
            const DemoClockBanner(),

            // Scrollable Content
            Expanded(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 96),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: const [
                        // Active Conversational Confirmation Banner (C2, C4, C5)
                        ActivePromptBanner(),

                        // Understanding Panel (Rule C6 & Section 3E)
                        UnderstandingPanel(),

                        SizedBox(height: 4),

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
