import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class GameEngineUtils {
  // A reusable vector physics collision check helper
  static bool checkRectCollision(Rect rectA, Rect rectB) {
    return rectA.overlaps(rectB);
  }

  // Neon custom game overlay HUD template
  static Widget buildGameHUD({
    required String score,
    required String level,
    required VoidCallback onPauseToggle,
    bool isPaused = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'SCORE: $score',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'SECTOR: $level',
              style: const TextStyle(
                color: AppTheme.cyanBlue,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        IconButton(
          icon: Icon(
            isPaused ? Icons.play_circle_outline : Icons.pause_circle_outline,
            color: AppTheme.cyanBlue,
            size: 32,
          ),
          onPressed: onPauseToggle,
        ),
      ],
    );
  }

  // Virtual Joypad controller overlay widget for advanced strategy/arcade plays
  static Widget buildVirtualJoystick({
    required Function(Offset direction) onJoystickChange,
  }) {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        color: Colors.black26,
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.cyanBlue, width: 2),
        boxShadow: [
          BoxShadow(color: AppTheme.cyanBlue.withOpacity(0.1), blurRadius: 10),
        ],
      ),
      child: Center(
        child: GestureDetector(
          onPanUpdate: (details) {
            final localPos = details.localPosition;
            final center = const Offset(70, 70);
            final delta = localPos - center;

            // Normalize direction to -1 to 1 bounds
            final normalized = Offset(
              (delta.dx / 70).clamp(-1.0, 1.0),
              (delta.dy / 70).clamp(-1.0, 1.0),
            );
            onJoystickChange(normalized);
          },
          onPanEnd: (_) {
            onJoystickChange(Offset.zero);
          },
          child: Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(
              color: AppTheme.cyanBlue,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black45,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
