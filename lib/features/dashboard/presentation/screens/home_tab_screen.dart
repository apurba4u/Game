import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/common_widgets/glass_container.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../presentation/providers/stats_provider.dart';

class HomeTabScreen extends ConsumerWidget {
  const HomeTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final statsAsync = ref.watch(statsProvider);

    return profileAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(
          color: AppTheme.cyanBlue,
        ),
      ),
      error: (err, stack) => Center(
        child: Text(
          'GRID CORRELATION ERROR: $err',
          style: const TextStyle(
            color: AppTheme.electricPink,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ),
      data: (profile) {
        return statsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.cyanBlue),
          ),
          error: (err, stack) => Center(
            child: Text(
              'TELEMETRY DATA OFFLINE: $err',
              style: const TextStyle(color: AppTheme.electricPink),
            ),
          ),
          data: (stats) {
            return RefreshIndicator(
              color: AppTheme.cyanBlue,
              backgroundColor: AppTheme.darkBackground,
              onRefresh: () async {
                ref.invalidate(userProfileProvider);
                ref.invalidate(statsProvider);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Greeting Header with Live Profile Sync
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'WELCOME BACK,',
                                style: TextStyle(
                                  fontSize: 11,
                                  letterSpacing: 2,
                                  color: AppTheme.cyanBlue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                profile.fullName.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppTheme.electricPink, width: 1.5),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.bolt, color: AppTheme.electricPink, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${profile.streakCount}D STREAK',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ).animate().shimmer(duration: 1.5.seconds),
                            const SizedBox(width: 12),
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: AppTheme.cyanBlue,
                              child: CircleAvatar(
                                radius: 18,
                                backgroundImage: NetworkImage(profile.avatarUrl),
                                backgroundColor: Colors.transparent,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Daily XP Target & Profile Stats
                    GlassContainer(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'LEVEL ${stats.level} SYSTEM OPERATOR',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1,
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Collect ${stats.maxXp - stats.currentXp} more XP to level up. Total games: ${stats.gamesInitiated}.',
                                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                                ),
                                const SizedBox(height: 12),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: LinearProgressIndicator(
                                    value: stats.progress,
                                    backgroundColor: Colors.white12,
                                    color: AppTheme.neonPurple,
                                    minHeight: 8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: AppTheme.cyanBlue,
                            child: Text(
                              '${(stats.progress * 100).toInt()}%',
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 400.ms),

                    const SizedBox(height: 28),
                    const Text(
                      'QUICK SYSTEM INITIATION',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Horizontal mini-games lists with real route triggers
                    SizedBox(
                      height: 120,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildQuickPlayCard(
                            context,
                            'Tic Tac Toe',
                            Icons.grid_3x3,
                            AppTheme.neonPurple,
                            '/game/tic-tac-toe',
                          ),
                          _buildQuickPlayCard(
                            context,
                            'Snake Game',
                            Icons.gesture,
                            AppTheme.cyanBlue,
                            '/game/snake',
                          ),
                          _buildQuickPlayCard(
                            context,
                            'Space Shooter',
                            Icons.rocket_launch,
                            AppTheme.electricPink,
                            '/game/space-shooter',
                          ),
                          _buildQuickPlayCard(
                            context,
                            'Neon Pong',
                            Icons.sports_tennis,
                            Colors.amber,
                            '/game/pong',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),
                    const Text(
                      'NEXUS NEWS FEED',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // News Glass Card
                    GlassContainer(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 120,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.white.withOpacity(0.02),
                              border: Border.all(color: Colors.white.withOpacity(0.05)),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.newspaper,
                                size: 40,
                                color: AppTheme.cyanBlue,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'SUPABASE REALTIME MATCHMAKING ONLINE',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Realtime multiplayer lobbies are now deployable. Build or join rooms instantly with room codes and compete in high score synchronization!',
                            style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.4),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 200.ms),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildQuickPlayCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    String route,
  ) {
    return GestureDetector(
      onTap: () => context.push(route),
      child: Container(
        width: 105,
        margin: const EdgeInsets.only(right: 12),
        child: GlassContainer(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 30, color: color),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
