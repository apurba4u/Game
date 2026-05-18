import 'package:hive_flutter/hive_flutter.dart';

// Ei class ta platform er offline caching/database storage manage kore.
// Database connection offline thakle player er high scores, match records, 
// ar authentication states locally save rakhe, ja pore automatic cloud synced hoy.
class HiveService {
  static final HiveService instance = HiveService._internal();

  factory HiveService() => instance;

  HiveService._internal();

  // Shob custom box names jekhane local storage run kora hoy.
  static const String statsBoxName = 'gamehub_stats';
  static const String leaderboardCacheBoxName = 'gamehub_leaderboard_cache';
  static const String matchesBoxName = 'gamehub_matches';
  static const String authBoxName = 'gamehub_auth';

  // Local storage initialization routine
  Future<void> init() async {
    // Mobile/web locally folder configuration initiate kore.
    await Hive.initFlutter();
    
    // Open all core transaction boxes jate run-time data instantly read/write kora jay.
    await Hive.openBox(statsBoxName);
    await Hive.openBox(leaderboardCacheBoxName);
    await Hive.openBox(matchesBoxName);
    await Hive.openBox(authBoxName);
  }

  // Generic box connection handler
  Box _getBox(String name) => Hive.box(name);

  // Kono specific key er dynamic value local storage box e input write kore.
  Future<void> put(String boxName, String key, dynamic value) async {
    await _getBox(boxName).put(key, value);
  }

  // Database standard value reader fallback matching system
  dynamic get(String boxName, String key, {dynamic defaultValue}) {
    return _getBox(boxName).get(key, defaultValue: defaultValue);
  }

  // Local entry deletion mechanism
  Future<void> delete(String boxName, String key) async {
    await _getBox(boxName).delete(key);
  }

  // Shob records list formatted return path
  List<dynamic> getAllValues(String boxName) {
    return _getBox(boxName).values.toList();
  }

  // Purono tables fully delete/wipeout option for system cleanup
  Future<void> clearBox(String boxName) async {
    await _getBox(boxName).clear();
  }
}
