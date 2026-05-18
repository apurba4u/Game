import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/theme/app_theme.dart';

class CyberpunkBanner {
  final String name;
  final List<Color> colors;
  final IconData icon;

  const CyberpunkBanner({
    required this.name,
    required this.colors,
    required this.icon,
  });
}

class UserProfile {
  final String id;
  final String fullName;
  final String username;
  final String bio;
  final String avatarUrl;
  final String gender;
  final String nationality;
  final String bannerTheme;
  final DateTime? dateOfBirth;
  final String email;
  final String favoriteGame;
  final int streakCount;

  UserProfile({
    required this.id,
    required this.fullName,
    required this.username,
    required this.bio,
    required this.avatarUrl,
    required this.gender,
    required this.nationality,
    required this.bannerTheme,
    required this.dateOfBirth,
    required this.email,
    required this.favoriteGame,
    required this.streakCount,
  });

  UserProfile copyWith({
    String? id,
    String? fullName,
    String? username,
    String? bio,
    String? avatarUrl,
    String? gender,
    String? nationality,
    String? bannerTheme,
    DateTime? dateOfBirth,
    String? email,
    String? favoriteGame,
    int? streakCount,
  }) {
    return UserProfile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      gender: gender ?? this.gender,
      nationality: nationality ?? this.nationality,
      bannerTheme: bannerTheme ?? this.bannerTheme,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      email: email ?? this.email,
      favoriteGame: favoriteGame ?? this.favoriteGame,
      streakCount: streakCount ?? this.streakCount,
    );
  }
}

class UserProfileController extends AsyncNotifier<UserProfile> {
  static const String _bannerKey = 'cyberpunk_profile_banner_theme';
  static const String _streakKey = 'gamehub_login_streak_count';
  static const String _lastLoginKey = 'gamehub_last_login_date_timestamp';
  static const String _favGameKey = 'gamehub_favorite_game_name';

  final List<CyberpunkBanner> banners = const [
    CyberpunkBanner(
      name: 'Neon Overdrive',
      colors: [AppTheme.neonPurple, AppTheme.cyanBlue],
      icon: Icons.bolt,
    ),
    CyberpunkBanner(
      name: 'Chiba Matrix',
      colors: [Colors.greenAccent, Colors.black87],
      icon: Icons.api,
    ),
    CyberpunkBanner(
      name: 'Megacorp Gold',
      colors: [Colors.amber, AppTheme.electricPink],
      icon: Icons.workspace_premium,
    ),
    CyberpunkBanner(
      name: 'Grid Core',
      colors: [AppTheme.electricPink, AppTheme.neonPurple],
      icon: Icons.radar,
    ),
  ];

  @override
  Future<UserProfile> build() async {
    final supabase = ref.watch(supabaseProvider);
    final user = ref.watch(currentUserProvider);

    final prefs = await SharedPreferences.getInstance();
    final bannerTheme = prefs.getString(_bannerKey) ?? 'Neon Overdrive';
    final favoriteGame = prefs.getString(_favGameKey) ?? 'Tic Tac Toe';

    // 1. Calculate login streak
    int streak = prefs.getInt(_streakKey) ?? 1;
    final lastLoginStr = prefs.getString(_lastLoginKey);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (lastLoginStr != null) {
      final lastLogin = DateTime.parse(lastLoginStr);
      final lastLoginDay = DateTime(lastLogin.year, lastLogin.month, lastLogin.day);
      final difference = today.difference(lastLoginDay).inDays;

      if (difference == 1) {
        streak += 1;
        await prefs.setInt(_streakKey, streak);
      } else if (difference > 1) {
        streak = 1;
        await prefs.setInt(_streakKey, streak);
      }
    }
    await prefs.setString(_lastLoginKey, now.toIso8601String());

    if (user != null) {
      try {
        final data = await supabase
            .from('profiles')
            .select()
            .eq('id', user.id)
            .single();

        DateTime? dob;
        if (data['date_of_birth'] != null) {
          dob = DateTime.tryParse(data['date_of_birth']);
        }

        return UserProfile(
          id: user.id,
          fullName: data['full_name'] ?? 'Cyber Runner',
          username: data['username'] ?? user.email?.split('@').first ?? 'Runner',
          bio: data['bio'] ?? 'Elite cyber-runner navigating the neural grid.',
          avatarUrl: data['avatar_url'] ?? 'https://api.dicebear.com/7.x/pixel-art/png?seed=${user.email}',
          gender: data['gender'] ?? 'Unknown',
          nationality: data['nationality'] ?? 'Unknown',
          bannerTheme: bannerTheme,
          dateOfBirth: dob ?? DateTime(2000, 1, 1),
          email: user.email ?? 'offline@gamehub.com',
          favoriteGame: favoriteGame,
          streakCount: streak,
        );
      } catch (_) {
        // Fall back gracefully
      }
    }

    // Default runner state
    return UserProfile(
      id: user?.id ?? 'offline',
      fullName: 'Cyber Runner',
      username: user?.email?.split('@').first ?? 'APURBA_OVI',
      bio: 'Elite cyber-runner navigating the neural grid. Specialist in puzzle matrix operations.',
      avatarUrl: 'https://api.dicebear.com/7.x/pixel-art/png?seed=Apurba',
      gender: 'N/A',
      nationality: 'N/A',
      bannerTheme: bannerTheme,
      dateOfBirth: DateTime(2000, 1, 1),
      email: user?.email ?? 'offline@gamehub.com',
      favoriteGame: favoriteGame,
      streakCount: streak,
    );
  }

  Future<void> updateBio(String bio) async {
    final stateValue = state.value;
    if (stateValue == null) return;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final supabase = ref.read(supabaseProvider);
      if (stateValue.id != 'offline') {
        try {
          await supabase.from('profiles').update({'bio': bio}).eq('id', stateValue.id);
        } catch (_) {}
      }
      return stateValue.copyWith(bio: bio);
    });
  }

  Future<void> updateFullProfile({
    required String fullName,
    required String username,
    required String gender,
    required String nationality,
    required DateTime dateOfBirth,
    required String bio,
    required String favoriteGame,
    required String avatarUrl,
  }) async {
    final stateValue = state.value;
    if (stateValue == null) return;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final supabase = ref.read(supabaseProvider);
      final prefs = await SharedPreferences.getInstance();

      // Save local favorite game
      await prefs.setString(_favGameKey, favoriteGame);

      if (stateValue.id != 'offline') {
        try {
          final dobString = '${dateOfBirth.year}-${dateOfBirth.month.toString().padLeft(2, '0')}-${dateOfBirth.day.toString().padLeft(2, '0')}';
          await supabase.from('profiles').update({
            'full_name': fullName,
            'username': username,
            'gender': gender,
            'nationality': nationality,
            'date_of_birth': dobString,
            'bio': bio,
            'avatar_url': avatarUrl,
          }).eq('id', stateValue.id);
        } catch (_) {}
      }

      return stateValue.copyWith(
        fullName: fullName,
        username: username,
        gender: gender,
        nationality: nationality,
        dateOfBirth: dateOfBirth,
        bio: bio,
        favoriteGame: favoriteGame,
        avatarUrl: avatarUrl,
      );
    });
  }

  Future<void> updateBannerTheme(String themeName) async {
    final stateValue = state.value;
    if (stateValue == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_bannerKey, themeName);

    state = AsyncData(stateValue.copyWith(bannerTheme: themeName));
  }

  CyberpunkBanner get activeBanner {
    final stateValue = state.value;
    final themeName = stateValue?.bannerTheme ?? 'Neon Overdrive';
    return banners.firstWhere((b) => b.name == themeName, orElse: () => banners.first);
  }
}

final userProfileProvider = AsyncNotifierProvider<UserProfileController, UserProfile>(
  UserProfileController.new,
);
