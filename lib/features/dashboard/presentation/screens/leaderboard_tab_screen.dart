import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/common_widgets/glass_container.dart';
import '../providers/leaderboard_provider.dart';

class LeaderboardTabScreen extends ConsumerStatefulWidget {
  const LeaderboardTabScreen({super.key});

  @override
  ConsumerState<LeaderboardTabScreen> createState() => _LeaderboardTabScreenState();
}

class _LeaderboardTabScreenState extends ConsumerState<LeaderboardTabScreen> {
  final List<String> _gameFilters = [
    'Global Grid',
    'Tic Tac Toe',
    'Snake Game',
    'Neon Pong',
    'Flappy Cyber',
    '2048 Matrix',
  ];

  @override
  Widget build(BuildContext context) {
    final selectedGame = ref.watch(leaderboardGameFilterProvider);
    final leaderboardAsync = ref.watch(leaderboardDataProvider(selectedGame));

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Game Selector list
          SizedBox(
            height: 38,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _gameFilters.length,
              itemBuilder: (context, index) {
                final filter = _gameFilters[index];
                final isSelected = selectedGame == filter;
                return GestureDetector(
                  onTap: () {
                    ref.read(leaderboardGameFilterProvider.notifier).state = filter;
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.cyanBlue
                          : AppTheme.glassBackground,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.cyanBlue
                            : AppTheme.glassBorder,
                      ),
                    ),
                    child: Text(
                      filter.toUpperCase(),
                      style: TextStyle(
                        color: isSelected ? Colors.black : Colors.white60,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          leaderboardAsync.when(
            loading: () => const Expanded(
              child: Center(
                child: CircularProgressIndicator(
                  color: AppTheme.cyanBlue,
                ),
              ),
            ),
            error: (err, stack) => Expanded(
              child: Center(
                child: Text(
                  'LINK ERROR: $err',
                  style: const TextStyle(color: AppTheme.electricPink, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            data: (leaderboardList) {
              if (leaderboardList.isEmpty) {
                return const Expanded(
                  child: Center(
                    child: Text(
                      'NO ACTIVE ARCHIVES DETECTED',
                      style: TextStyle(color: Colors.white30, letterSpacing: 2),
                    ),
                  ),
                );
              }

              // Extract top 3 elements for the podium safely
              final top1 = leaderboardList.isNotEmpty ? leaderboardList[0] : null;
              final top2 = leaderboardList.length > 1 ? leaderboardList[1] : null;
              final top3 = leaderboardList.length > 2 ? leaderboardList[2] : null;

              // Remaining ranks for the list
              final scrollableList = leaderboardList.length > 3
                  ? leaderboardList.sublist(3)
                  : <LeaderboardEntry>[];

              return Expanded(
                child: Column(
                  children: [
                    // Dynamic Visual Podium
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // 2nd Place
                        Expanded(
                          child: top2 != null
                              ? _buildPodiumCol(
                                  name: top2.username,
                                  score: top2.score,
                                  rank: 2,
                                  height: 100,
                                  color: AppTheme.neonPurple,
                                  avatar: top2.avatar,
                                )
                              : const SizedBox(),
                        ),
                        const SizedBox(width: 8),
                        // 1st Place
                        Expanded(
                          child: top1 != null
                              ? _buildPodiumCol(
                                  name: top1.username,
                                  score: top1.score,
                                  rank: 1,
                                  height: 130,
                                  color: AppTheme.cyanBlue,
                                  avatar: top1.avatar,
                                )
                              : const SizedBox(),
                        ),
                        const SizedBox(width: 8),
                        // 3rd Place
                        Expanded(
                          child: top3 != null
                              ? _buildPodiumCol(
                                  name: top3.username,
                                  score: top3.score,
                                  rank: 3,
                                  height: 85,
                                  color: AppTheme.electricPink,
                                  avatar: top3.avatar,
                                )
                              : const SizedBox(),
                        ),
                      ],
                    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
                    const SizedBox(height: 24),

                    // Scrollable Rank Logs
                    Expanded(
                      child: ListView.builder(
                        itemCount: scrollableList.length,
                        itemBuilder: (context, index) {
                          final player = scrollableList[index];
                          final isMe = player.isMe;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: GlassContainer(
                              borderColor: isMe
                                  ? AppTheme.cyanBlue
                                  : AppTheme.glassBorder,
                              backgroundColor: isMe
                                  ? AppTheme.cyanBlue.withOpacity(0.05)
                                  : AppTheme.glassBackground,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    '#${player.rank}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isMe ? AppTheme.cyanBlue : Colors.white70,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  CircleAvatar(
                                    backgroundImage: NetworkImage(player.avatar),
                                    radius: 18,
                                    backgroundColor: Colors.transparent,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      player.username,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isMe ? AppTheme.cyanBlue : Colors.white,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    player.score,
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.w900,
                                      color: isMe ? AppTheme.cyanBlue : Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ).animate().fadeIn(delay: (index * 50).ms, duration: 300.ms);
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumCol({
    required String name,
    required String score,
    required int rank,
    required double height,
    required Color color,
    required String avatar,
  }) {
    return Column(
      children: [
        CircleAvatar(
          backgroundImage: NetworkImage(avatar),
          radius: 20,
          backgroundColor: Colors.transparent,
        ),
        const SizedBox(height: 8),
        Text(
          name.substring(0, name.length > 8 ? 8 : name.length),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 10,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          score,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: height,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            border: Border.all(color: color, width: 1.5),
            boxShadow: [
              BoxShadow(color: color.withOpacity(0.1), blurRadius: 8),
            ],
          ),
          child: Center(
            child: Text(
              '#$rank',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
