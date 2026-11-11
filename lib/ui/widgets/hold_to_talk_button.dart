import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
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
  DateTime? _pointerDownTime;
  bool _isTapToggled = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onPointerDown(AssistantProvider provider) {
    _pointerDownTime = DateTime.now();
    if (!_isTapToggled && !provider.isListening) {
      provider.startListening(isHold: true);
    }
  }

  void _onPointerUp(AssistantProvider provider) {
    if (_pointerDownTime == null) return;
    final durationMs = DateTime.now()
        .difference(_pointerDownTime!)
        .inMilliseconds;
    _pointerDownTime = null;

    if (_isTapToggled) {
      _isTapToggled = false;
      provider.stopListening();
    } else if (durationMs < 320) {
      // Tap detected: keep listening hands-free
      _isTapToggled = true;
    } else {
      // Hold released: execute
      provider.stopListening();
    }
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
      _isTapToggled = false;
      if (_animController.isAnimating) {
        _animController.stop();
        _animController.reset();
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Live transcript or mic error notification pill
        if (isListening && liveTranscript.isNotEmpty) ...[
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primarySlate,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.graphic_eq,
                  color: Color(0xFF60A5FA),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    liveTranscript,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ] else if (micError != null) ...[
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.dangerBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Mic: $micError (Use simulated voice bar)',
              style: const TextStyle(color: AppTheme.dangerText, fontSize: 11),
            ),
          ),
        ],

        // Floating thumb button row
        Padding(
          padding: const EdgeInsets.only(right: 20, bottom: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isListening)
                Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.dangerBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _isTapToggled ? 'Tap to finish' : 'Release to send',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.dangerText,
                    ),
                  ),
                ),

              // Large 72x72 Thumb Button (Glove-friendly)
              Semantics(
                label: isListening
                    ? 'Listening. Tap or release to execute.'
                    : 'Microphone button. Hold or tap to speak.',
                button: true,
                child: Listener(
                  onPointerDown: (_) => _onPointerDown(provider),
                  onPointerUp: (_) => _onPointerUp(provider),
                  child: AnimatedBuilder(
                    animation: _scaleAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: isListening ? _scaleAnimation.value : 1.0,
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isListening
                                ? AppTheme.dangerRose
                                : AppTheme.primarySlate,
                            boxShadow: [
                              BoxShadow(
                                color:
                                    (isListening
                                            ? AppTheme.dangerRose
                                            : AppTheme.primarySlate)
                                        .withValues(alpha: 0.28),
                                blurRadius: isListening ? 16 : 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Icon(
                            isListening ? Icons.mic : Icons.mic_none,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
