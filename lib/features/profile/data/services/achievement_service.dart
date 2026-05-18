import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

enum AchievementRarity { common, rare, legendary }

enum AchievementCategory { arcade, puzzle, social }

class Achievement {
  final String id;
  final String title;
  final String description;
  final AchievementRarity rarity;
  final AchievementCategory category;
  final int xpReward;
  final double maxProgress;
  double currentProgress;
  bool isUnlocked;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.rarity,
    required this.category,
    required this.xpReward,
    required this.maxProgress,
    this.currentProgress = 0,
    this.isUnlocked = false,
  });

  Color get rarityColor {
    switch (rarity) {
      case AchievementRarity.common:
        return AppTheme.cyanBlue;
      case AchievementRarity.rare:
        return AppTheme.neonPurple;
      case AchievementRarity.legendary:
        return AppTheme.electricPink;
    }
  }

  String get rarityLabel {
    switch (rarity) {
      case AchievementRarity.common:
        return 'COMMON';
      case AchievementRarity.rare:
        return 'RARE';
      case AchievementRarity.legendary:
        return 'LEGENDARY';
    }
  }
}

class AchievementService extends ChangeNotifier {
  static final AchievementService instance = AchievementService._internal();

  factory AchievementService() => instance;

  AchievementService._internal() {
    _initAchievements();
  }

  final List<Achievement> _achievements = [];

  List<Achievement> get achievements => _achievements;

  void _initAchievements() {
    _achievements.addAll([
      Achievement(
        id: 'first_login',
        title: 'Cyber Initiate',
        description: 'Establish initial uplink connection with GameHub.',
        rarity: AchievementRarity.common,
        category: AchievementCategory.social,
        xpReward: 100,
        maxProgress: 1,
      ),
      Achievement(
        id: 'snake_100',
        title: 'Retro Serpent',
        description: 'Earn 100 points in a single Snake run.',
        rarity: AchievementRarity.rare,
        category: AchievementCategory.arcade,
        xpReward: 250,
        maxProgress: 100,
      ),
      Achievement(
        id: 'win_10_games',
        title: 'Nezha Unleashed',
        description: 'Secure 10 game victories across the grid.',
        rarity: AchievementRarity.legendary,
        category: AchievementCategory.arcade,
        xpReward: 500,
        maxProgress: 10,
      ),
      Achievement(
        id: 'quiz_master',
        title: 'Terminal Sage',
        description: 'Answer all Quiz questions correctly.',
        rarity: AchievementRarity.rare,
        category: AchievementCategory.puzzle,
        xpReward: 300,
        maxProgress: 3,
      ),
    ]);
  }

  void updateProgress(String id, double progress, BuildContext context) {
    final achievementIndex = _achievements.indexWhere((a) => a.id == id);
    if (achievementIndex == -1) return;

    final achievement = _achievements[achievementIndex];
    if (achievement.isUnlocked) return;

    achievement.currentProgress = (achievement.currentProgress + progress)
        .clamp(0, achievement.maxProgress);

    if (achievement.currentProgress >= achievement.maxProgress) {
      achievement.isUnlocked = true;
      _triggerUnlockNotification(achievement, context);
    }
    notifyListeners();
  }

  void _triggerUnlockNotification(
    Achievement achievement,
    BuildContext context,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: achievement.rarityColor, width: 2),
            boxShadow: [
              BoxShadow(
                color: achievement.rarityColor.withOpacity(0.3),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.emoji_events,
                color: achievement.rarityColor,
                size: 40,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ACHIEVEMENT UNLOCKED',
                      style: TextStyle(
                        color: achievement.rarityColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      achievement.title.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '+${achievement.xpReward} XP REWARD',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
