import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../games/data/services/score_sync_service.dart';

class GameStats {
  final int level;
  final int currentXp;
  final int maxXp;
  final double progress;
  final int gamesInitiated;
  final double winRatio;
  final double systemPlaytimeHours;
  final int totalTrophies;
  final List<double> weeklyPlaytime; // 7 days (Mon-Sun)
  final Map<String, Map<String, double>> gameWinLoss; // gameName -> {'wins': w, 'losses': l}
  final List<FrequentedGame> topGames;

  GameStats({
    required this.level,
    required this.currentXp,
    required this.maxXp,
    required this.progress,
    required this.gamesInitiated,
    required this.winRatio,
    required this.systemPlaytimeHours,
    required this.totalTrophies,
    required this.weeklyPlaytime,
    required this.gameWinLoss,
    required this.topGames,
  });
}

class FrequentedGame {
  final String title;
  final String playedText;
  final String winRateText;
  final double winRateVal;

  FrequentedGame({
    required this.title,
    required this.playedText,
    required this.winRateText,
    required this.winRateVal,
  });
}

final statsProvider = FutureProvider<GameStats>((ref) async {
  final supabase = ref.watch(supabaseProvider);
  final user = ref.watch(currentUserProvider);
  final scoreSync = ref.watch(scoreSyncServiceProvider);

  // Initialize defaults
  int defaultBaseMatches = 248;
  double defaultBasePlaytime = 84.2;
  double defaultBaseWinRatio = 68.5;
  int defaultTrophies = 12;

  List<double> weeklyPlaytime = [1.2, 2.5, 0.8, 3.4, 1.9, 5.0, 4.2];
  Map<String, Map<String, double>> gameWinLoss = {
    'SNAKE': {'wins': 12, 'losses': 4},
    'PONG': {'wins': 8, 'losses': 5},
    '2048': {'wins': 15, 'losses': 2},
    'FLAPPY': {'wins': 6, 'losses': 8},
  };

  List<FrequentedGame> topGames = [
    FrequentedGame(title: '2048 Matrix', playedText: '42 matches played', winRateText: '92% win rate', winRateVal: 0.92),
    FrequentedGame(title: 'Neon Snake', playedText: '38 matches played', winRateText: '74% win rate', winRateVal: 0.74),
    FrequentedGame(title: 'Neon Pong', playedText: '29 matches played', winRateText: '58% win rate', winRateVal: 0.58),
  ];

  int addedXp = 0;
  int userMatchesCount = 0;
  int winsCount = 0;
  double addedDurationSeconds = 0.0;

  try {
    // 1. Fetch live history logs from Supabase
    if (user != null) {
      final response = await supabase
          .from('game_history')
          .select('game_name, score, duration, win_status')
          .eq('user_id', user.id);

      if (response.isNotEmpty) {
        userMatchesCount = response.length;
        for (var row in response) {
          final isWin = row['win_status'] as bool? ?? false;
          if (isWin) winsCount++;

          final duration = (row['duration'] as num?)?.toDouble() ?? 30.0;
          addedDurationSeconds += duration;

          final score = (row['score'] as num?)?.toInt() ?? 0;
          addedXp += (score * 5) + 100; // Formula: 100 XP per match + 5 XP per score point
        }
      }
    }
  } catch (_) {
    // Fail-safe local fallback
  }

  // 2. Fetch offline cache history
  try {
    final cachedHistory = await scoreSync.getCachedHistory();
    if (cachedHistory.isNotEmpty) {
      userMatchesCount += cachedHistory.length;
      for (var row in cachedHistory) {
        final isWin = row['win_status'] as bool? ?? false;
        if (isWin) winsCount++;

        final duration = (row['duration'] as num?)?.toDouble() ?? 30.0;
        addedDurationSeconds += duration;

        final score = (row['score'] as num?)?.toInt() ?? 0;
        addedXp += (score * 5) + 100;
      }
    }
  } catch (_) {}

  // 3. Aggregate totals
  final finalGamesInitiated = defaultBaseMatches + userMatchesCount;
  final finalWinRatio = userMatchesCount > 0
      ? ((defaultBaseWinRatio * defaultBaseMatches + (winsCount / userMatchesCount * 100) * userMatchesCount) / finalGamesInitiated)
      : defaultBaseWinRatio;
  final finalPlaytimeHours = defaultBasePlaytime + (addedDurationSeconds / 3600.0);
  
  // Calculate dynamic XP progression
  int initialXp = 7200;
  int totalXp = initialXp + addedXp;
  
  int level = (totalXp / 10000).floor() + 1;
  int currentXpInLevel = totalXp % 10000;
  int maxXpInLevel = 10000;
  double progress = currentXpInLevel / maxXpInLevel;

  // Let's add trophies dynamically based on level progression
  final finalTrophies = defaultTrophies + (level - 1);

  return GameStats(
    level: level,
    currentXp: currentXpInLevel,
    maxXp: maxXpInLevel,
    progress: progress,
    gamesInitiated: finalGamesInitiated,
    winRatio: double.parse(finalWinRatio.toStringAsFixed(1)),
    systemPlaytimeHours: double.parse(finalPlaytimeHours.toStringAsFixed(1)),
    totalTrophies: finalTrophies,
    weeklyPlaytime: weeklyPlaytime,
    gameWinLoss: gameWinLoss,
    topGames: topGames,
  );
});
