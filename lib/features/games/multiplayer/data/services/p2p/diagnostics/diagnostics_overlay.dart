import 'package:flutter/material.dart';
import '../../../../../../../core/theme/app_theme.dart';
import '../../../../../../../core/common_widgets/glass_container.dart';

class DiagnosticsOverlay extends StatelessWidget {
  final int latencyMs;
  final String connectionType; // e.g. "P2P Socket" or "Realtime Relay"

  const DiagnosticsOverlay({
    super.key,
    required this.latencyMs,
    required this.connectionType,
  });

  @override
  Widget build(BuildContext context) {
    Color qualityColor;
    String qualityText;

    if (latencyMs <= 0) {
      qualityColor = Colors.white30;
      qualityText = 'OFFLINE';
    } else if (latencyMs < 50) {
      qualityColor = AppTheme.cyanBlue;
      qualityText = 'NEURAL EXCELLENT';
    } else if (latencyMs < 150) {
      qualityColor = AppTheme.neonPurple;
      qualityText = 'NEURAL MODERATE';
    } else {
      qualityColor = AppTheme.electricPink;
      qualityText = 'NEURAL LAGGING';
    }

    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: qualityColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: qualityColor.withOpacity(0.6),
                  blurRadius: 6,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$connectionType : ${latencyMs <= 0 ? "--" : "${latencyMs}MS"} ($qualityText)',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white.withOpacity(0.85),
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
