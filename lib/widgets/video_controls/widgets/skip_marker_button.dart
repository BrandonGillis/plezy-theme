import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show KeyDownEvent, LogicalKeyboardKey;
import 'package:material_symbols_icons/symbols.dart';

import '../../../focus/focusable_wrapper.dart';
import '../../../i18n/strings.g.dart';
import '../../../media/media_source_info.dart';
import '../../../theme/mono_tokens.dart';
import '../../app_icon.dart';
import '../../../theme/liquid_glass.dart';

class SkipMarkerButton extends StatelessWidget {
  final MediaMarker marker;
  final Duration playerDuration;
  final bool hasNextEpisode;
  final bool isAutoSkipActive;
  final bool shouldShowAutoSkip;
  final int autoSkipDelay;
  final double autoSkipProgress;
  final FocusNode focusNode;
  final VoidCallback onActivate;
  final VoidCallback onFocusDown;

  const SkipMarkerButton({
    super.key,
    required this.marker,
    required this.playerDuration,
    required this.hasNextEpisode,
    required this.isAutoSkipActive,
    required this.shouldShowAutoSkip,
    required this.autoSkipDelay,
    required this.autoSkipProgress,
    required this.focusNode,
    required this.onActivate,
    required this.onFocusDown,
  });

  @override
  Widget build(BuildContext context) {
    final isCredits = marker.isCredits;
    final creditsAtEnd =
        isCredits && playerDuration > Duration.zero && (playerDuration - marker.endTime).inMilliseconds <= 1000;
    final showNextEpisode = creditsAtEnd && hasNextEpisode;
    String baseButtonText;
    if (showNextEpisode) {
      baseButtonText = t.videoControls.nextEpisode;
    } else if (isCredits) {
      baseButtonText = t.videoControls.skipCredits;
    } else {
      baseButtonText = t.videoControls.skipIntro;
    }

    final remainingSeconds = isAutoSkipActive && shouldShowAutoSkip
        ? (autoSkipDelay - (autoSkipProgress * autoSkipDelay)).ceil().clamp(0, autoSkipDelay)
        : 0;

    final showAutoSkipCountdown = isAutoSkipActive && shouldShowAutoSkip;
    final buttonText = showAutoSkipCountdown && remainingSeconds > 0
        ? '$baseButtonText ($remainingSeconds)'
        : baseButtonText;
    final buttonIcon = showNextEpisode ? Symbols.skip_next_rounded : Symbols.fast_forward_rounded;

    // Liquid Glass: a frosted capsule with a white label, like the tvOS 26
    // player's "Continue Watching".
    final glass = isLiquidGlass(context);
    final radius = glass ? MonoTokens.radiusFull : tokens(context).radiusSm;
    final labelColor = glass ? Colors.white : Colors.black;
    final label = Row(
      mainAxisSize: .min,
      children: [
        Text(
          buttonText,
          style: TextStyle(color: labelColor, fontSize: 16, fontWeight: .w600),
        ),
        const SizedBox(width: 8),
        AppIcon(buttonIcon, fill: 1, color: labelColor, size: 20),
      ],
    );

    return FocusableWrapper(
      focusNode: focusNode,
      onSelect: _activate,
      borderRadius: radius,
      useBackgroundFocus: true,
      autoScroll: false,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.arrowDown) {
          onFocusDown();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _activate,
          borderRadius: BorderRadius.circular(radius),
          child: Stack(
            children: [
              if (glass)
                LiquidGlass(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), child: label)
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(radius),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: label,
                ),
              if (isAutoSkipActive && shouldShowAutoSkip)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(radius),
                    child: Row(
                      children: [
                        Expanded(
                          flex: (autoSkipProgress * 100).round(),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(radius),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: ((1.0 - autoSkipProgress) * 100).round(),
                          child: Container(decoration: const BoxDecoration(color: Colors.transparent)),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _activate() => onActivate();
}
