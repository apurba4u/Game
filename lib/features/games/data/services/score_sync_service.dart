import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ScoreSyncService {
  final SupabaseClient _supabase;
  static const String _offlineScoresKey = 'offline_game_scores';
  static const String _offlineHistoryKey = 'offline_game_history';

  ScoreSyncService(this._supabase);

  /// Saves the score. Tries Supabase first, falls back to local cache if offline.
  Future<void> saveScore({
    required String gameName,
    required int score,
    int durationSeconds = 30,
    bool? winStatus,
  }) async {
    final user = _supabase.auth.currentUser;
    final userId = user?.id;

    // Use a default score win threshold if winStatus is unspecified
    final finalWinStatus = winStatus ?? (score > 100);

    if (userId != null) {
      try {
        // Try uploading to Supabase
        await _supabase.from('game_scores').insert({
          'user_id': userId,
          'game_name': gameName,
          'highest_score': score,
        });

        await _supabase.from('game_history').insert({
          'user_id': userId,
          'game_name': gameName,
          'score': score,
          'duration': durationSeconds,
          'win_status': finalWinStatus,
        });

        // Try syncing any previous offline scores now that we are online
        await syncOfflineScores();
        return;
      } catch (e) {
        // Fall back to local caching on any exception
      }
    }

    // Save to local cache
    await _cacheScoreLocally(
      userId: userId ?? 'offline_user',
      gameName: gameName,
      score: score,
      durationSeconds: durationSeconds,
      winStatus: finalWinStatus,
    );
  }

  /// Caches a score and history item locally in SharedPreferences
  Future<void> _cacheScoreLocally({
    required String userId,
    required String gameName,
    required int score,
    required int durationSeconds,
    required bool winStatus,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Update High Scores
    final scoresJson = prefs.getString(_offlineScoresKey);
    List<dynamic> scoresList = scoresJson != null ? jsonDecode(scoresJson) : [];
    
    // Check if we already have a higher score for this game
    int existingIndex = scoresList.indexWhere((element) =>
        element['game_name'] == gameName && element['user_id'] == userId);

    if (existingIndex != -1) {
      if (scoresList[existingIndex]['highest_score'] < score) {
        scoresList[existingIndex]['highest_score'] = score;
        scoresList[existingIndex]['synced'] = false;
      }
    } else {
      scoresList.add({
        'user_id': userId,
        'game_name': gameName,
        'highest_score': score,
        'synced': false,
      });
    }
    await prefs.setString(_offlineScoresKey, jsonEncode(scoresList));

    // 2. Append to Match History
    final historyJson = prefs.getString(_offlineHistoryKey);
    List<dynamic> historyList = historyJson != null ? jsonDecode(historyJson) : [];
    
    historyList.add({
      'user_id': userId,
      'game_name': gameName,
      'score': score,
      'duration': durationSeconds,
      'win_status': winStatus,
      'created_at': DateTime.now().toIso8601String(),
      'synced': false,
    });
    await prefs.setString(_offlineHistoryKey, jsonEncode(historyList));
  }

  /// Syncs cached offline scores to Supabase once online
  Future<void> syncOfflineScores() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final prefs = await SharedPreferences.getInstance();

    // 1. Sync High Scores
    final scoresJson = prefs.getString(_offlineScoresKey);
    if (scoresJson != null) {
      List<dynamic> scoresList = jsonDecode(scoresJson);
      List<dynamic> unsyncedScores =
          scoresList.where((element) => element['synced'] == false).toList();

      for (var item in unsyncedScores) {
        try {
          await _supabase.from('game_scores').insert({
            'user_id': user.id,
            'game_name': item['game_name'],
            'highest_score': item['highest_score'],
          });
          item['synced'] = true;
          item['user_id'] = user.id; // Map to real user id if signed up
        } catch (_) {
          // If a single row fails, keep unsynced to retry later
        }
      }
      await prefs.setString(_offlineScoresKey, jsonEncode(scoresList));
    }

    // 2. Sync Match History
    final historyJson = prefs.getString(_offlineHistoryKey);
    if (historyJson != null) {
      List<dynamic> historyList = jsonDecode(historyJson);
      List<dynamic> unsyncedHistory =
          historyList.where((element) => element['synced'] == false).toList();

      for (var item in unsyncedHistory) {
        try {
          await _supabase.from('game_history').insert({
            'user_id': user.id,
            'game_name': item['game_name'],
            'score': item['score'],
            'duration': item['duration'],
            'win_status': item['win_status'],
          });
          item['synced'] = true;
          item['user_id'] = user.id;
        } catch (_) {
          // Keep unsynced if single insertion fails
        }
      }
      await prefs.setString(_offlineHistoryKey, jsonEncode(historyList));
    }
  }

  /// Returns cached offline scores
  Future<List<Map<String, dynamic>>> getCachedScores() async {
    final prefs = await SharedPreferences.getInstance();
    final scoresJson = prefs.getString(_offlineScoresKey);
    if (scoresJson == null) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(scoresJson));
  }

  /// Returns cached offline history
  Future<List<Map<String, dynamic>>> getCachedHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_offlineHistoryKey);
    if (historyJson == null) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(historyJson));
  }
}

final scoreSyncServiceProvider = Provider<ScoreSyncService>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return ScoreSyncService(supabase);
});
