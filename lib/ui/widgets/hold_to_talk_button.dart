import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/assistant_provider.dart';

class HoldToTalkButton extends StatefulWidget {
  const HoldToTalkButton({super.key});

  @override
  State<HoldToTalkButton> createState() => _HoldToTalkButtonState();
}

class _HoldToTalkButtonState extends State<HoldToTalkButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AssistantProvider>();
    final isListening = provider.isListening;
    final liveTranscript = provider.liveTranscript;
    final micError = provider.micErrorMessage;

    if (isListening) {
      if (!_animController.isAnimating) {
        _animController.repeat(reverse: true);
      }
    } else {
      if (_animController.isAnimating) {
        _animController.stop();
        _animController.reset();
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Live transcript or Mic error banner
        if (isListening && liveTranscript.isNotEmpty) ...[
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.graphic_eq, color: Color(0xFF60A5FA), size: 18),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    liveTranscript,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ] else if (micError != null) ...[
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFF87171)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.mic_off, color: Color(0xFFDC2626), size: 16),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Microphone notice: $micError (Use Simulated Voice below)',
                    style: const TextStyle(
                      color: Color(0xFF991B1B),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Floating thumb button row
        Padding(
          padding: const EdgeInsets.only(right: 20, bottom: 12),
          child: Align(
            alignment: Alignment.bottomRight,
            child: Semantics(
              label: isListening
                  ? 'Listening. Release thumb to execute command.'
                  : 'Hold to talk microphone button. Large one-thumb button.',
              button: true,
              child: GestureDetector(
                onLongPressStart: (_) => provider.startListening(),
                onLongPressEnd: (_) => provider.stopListening(),
                onTap: () {
                  // Fallback for tap-to-talk
                  if (isListening) {
                    provider.stopListening();
                  } else {
                    provider.startListening();
                  }
                },
                child: AnimatedBuilder(
                  animation: _scaleAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: isListening ? _scaleAnimation.value : 1.0,
                      child: Container(
                        width: 78,
                        height: 78,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isListening
                              ? const Color(0xFFDC2626)
                              : const Color(0xFF2563EB),
                          boxShadow: [
                            BoxShadow(
                              color: (isListening
                                      ? const Color(0xFFDC2626)
                                      : const Color(0xFF2563EB))
                                  .withValues(alpha: 0.4),
                              blurRadius: isListening ? 18 : 10,
                              spreadRadius: isListening ? 4 : 1,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isListening ? Icons.mic : Icons.mic_none,
                              color: Colors.white,
                              size: 34,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isListening ? 'RELEASE' : 'HOLD',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
