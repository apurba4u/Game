import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/common_widgets/glass_container.dart';
import '../providers/stats_provider.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(statsProvider);

    return statsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(
          color: AppTheme.cyanBlue,
        ),
      ),
      error: (err, stack) => Center(
        child: Text(
          'ANALYTICS LINK OFFLINE: $err',
          style: const TextStyle(
            color: AppTheme.electricPink,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ),
      data: (stats) {
        return RefreshIndicator(
          color: AppTheme.cyanBlue,
          backgroundColor: AppTheme.darkBackground,
          onRefresh: () async {
            ref.invalidate(statsProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // XP & Level Progression Ring
                GlassContainer(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 80,
                            height: 80,
                            child: CircularProgressIndicator(
                              value: stats.progress,
                              strokeWidth: 8,
                              backgroundColor: Colors.white10,
                              color: AppTheme.cyanBlue,
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'LVL',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white54,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                stats.level.toString(),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'GRID EXPERIENCE (XP)',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.cyanBlue,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${stats.currentXp} / ${stats.maxXp} XP',
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  fontFamily: 'monospace'),
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: stats.progress,
                                backgroundColor: Colors.white12,
                                color: AppTheme.neonPurple,
                                minHeight: 6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0),
                const SizedBox(height: 24),

                // Double stats grid
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        'GAMES INITIATED',
                        stats.gamesInitiated.toString(),
                        AppTheme.neonPurple,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricCard(
                        'WIN RATIO',
                        '${stats.winRatio}%',
                        AppTheme.cyanBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        'SYSTEM PLAYTIME',
                        '${stats.systemPlaytimeHours} Hrs',
                        Colors.amber,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricCard(
                        'TOTAL TROPHIES',
                        '${stats.totalTrophies} / 24',
                        AppTheme.electricPink,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Playtime analytical charts
                const Text(
                  'WEEKLY PLAYTIME FREQUENCY',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 12),
                GlassContainer(
                  height: 200,
                  padding: const EdgeInsets.all(16),
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              const days = [
                                'MON',
                                'TUE',
                                'WED',
                                'THU',
                                'FRI',
                                'SAT',
                                'SUN',
                              ];
                              if (value >= 0 && value < days.length) {
                                return Text(
                                  days[value.toInt()],
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 10,
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: stats.weeklyPlaytime
                              .asMap()
                              .entries
                              .map((entry) => FlSpot(entry.key.toDouble(), entry.value))
                              .toList(),
                          isCurved: true,
                          color: AppTheme.cyanBlue,
                          barWidth: 4,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppTheme.cyanBlue.withOpacity(0.1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(duration: 500.ms),
                const SizedBox(height: 24),

                // Win vs Loss Bar Charts
                const Text(
                  'WIN VS LOSS ANOMALIES',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 12),
                GlassContainer(
                  height: 180,
                  padding: const EdgeInsets.all(16),
                  child: BarChart(
                    BarChartData(
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final games = stats.gameWinLoss.keys.toList();
                              if (value >= 0 && value < games.length) {
                                return Text(
                                  games[value.toInt()],
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 9,
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                      ),
                      barGroups: stats.gameWinLoss.entries.toList().asMap().entries.map((entry) {
                        final idx = entry.key;
                        final val = entry.value.value;
                        return _buildBarGroup(idx, val['wins']!, val['losses']!);
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Top Played Games Section
                const Text(
                  'MOST FREQUENTED UPLINKS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 12),
                ...stats.topGames.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final item = entry.value;
                  final colors = [Colors.amber, AppTheme.cyanBlue, AppTheme.electricPink];
                  return _buildTopGameItem(
                    item.title,
                    item.playedText,
                    item.winRateText,
                    colors[idx % colors.length],
                  ).animate().fadeIn(delay: (idx * 100).ms, duration: 400.ms);
                }),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricCard(String title, String value, Color accentColor) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 9,
              color: Colors.white54,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _buildBarGroup(int x, double wins, double losses) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: wins,
          color: AppTheme.cyanBlue,
          width: 8,
          borderRadius: BorderRadius.circular(4),
        ),
        BarChartRodData(
          toY: losses,
          color: AppTheme.electricPink,
          width: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildTopGameItem(
    String title,
    String played,
    String winRate,
    Color accent,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.sports_esports, color: accent, size: 28),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      played,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Text(
              winRate,
              style: TextStyle(fontWeight: FontWeight.w900, color: accent),
            ),
          ],
        ),
      ),
    );
  }
}
