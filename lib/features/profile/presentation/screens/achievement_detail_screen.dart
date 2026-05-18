import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/common_widgets/glass_container.dart';
import '../../data/services/achievement_service.dart';

class AchievementDetailScreen extends StatelessWidget {
  const AchievementDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final achievementService = AchievementService.instance;
    final achievements = achievementService.achievements;

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'ACHIEVEMENTS ARCHIVE',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Overall Progress Summary
              GlassContainer(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Icon(Icons.stars, color: AppTheme.cyanBlue, size: 48),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'SYSTEM METADATA LOADED',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.cyanBlue,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'ACHIEVEMENT RATIO',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value:
                                  achievements
                                      .where((a) => a.isUnlocked)
                                      .length /
                                  achievements.length,
                              backgroundColor: Colors.white12,
                              color: AppTheme.neonPurple,
                              minHeight: 8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'LOGGED BADGES',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: achievements.length,
                  itemBuilder: (context, index) {
                    final a = achievements[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: GlassContainer(
                        borderColor: a.isUnlocked
                            ? a.rarityColor
                            : Colors.white10,
                        backgroundColor: a.isUnlocked
                            ? a.rarityColor.withOpacity(0.05)
                            : Colors.white10,
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              a.isUnlocked
                                  ? Icons.emoji_events
                                  : Icons.lock_outline,
                              color: a.isUnlocked
                                  ? a.rarityColor
                                  : Colors.white24,
                              size: 36,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        a.title.toUpperCase(),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          color: a.isUnlocked
                                              ? Colors.white
                                              : Colors.white30,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: a.rarityColor.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          border: Border.all(
                                            color: a.rarityColor,
                                            width: 0.5,
                                          ),
                                        ),
                                        child: Text(
                                          a.rarityLabel,
                                          style: TextStyle(
                                            color: a.rarityColor,
                                            fontSize: 8,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    a.description,
                                    style: TextStyle(
                                      color: a.isUnlocked
                                          ? Colors.white70
                                          : Colors.white24,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // Progress Bar
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          child: LinearProgressIndicator(
                                            value:
                                                a.currentProgress /
                                                a.maxProgress,
                                            color: a.rarityColor,
                                            backgroundColor: Colors.white10,
                                            minHeight: 4,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        '${a.currentProgress.toInt()}/${a.maxProgress.toInt()}',
                                        style: TextStyle(
                                          color: a.isUnlocked
                                              ? Colors.white70
                                              : Colors.white30,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
