import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/common_widgets/glass_container.dart';
import 'package:go_router/go_router.dart';

class GamesLibraryScreen extends StatefulWidget {
  const GamesLibraryScreen({super.key});

  @override
  State<GamesLibraryScreen> createState() => _GamesLibraryScreenState();
}

class _GamesLibraryScreenState extends State<GamesLibraryScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'All';

  final List<Map<String, dynamic>> _games = [
    {
      'title': 'Tic Tac Toe',
      'category': 'Arcade',
      'icon': Icons.grid_3x3,
      'color': AppTheme.neonPurple,
      'route': '/game/tic-tac-toe',
      'isMultiplayer': true,
      'isTrending': false,
    },
    {
      'title': 'Snake Game',
      'category': 'Arcade',
      'icon': Icons.gesture,
      'color': AppTheme.cyanBlue,
      'route': '/game/snake',
      'isMultiplayer': false,
      'isTrending': true,
    },
    {
      'title': 'Rock Paper Scissors',
      'category': 'Brain Games',
      'icon': Icons.back_hand,
      'color': AppTheme.electricPink,
      'route': '/game/rps',
      'isMultiplayer': true,
      'isTrending': false,
    },
    {
      'title': 'Quiz Game',
      'category': 'Brain Games',
      'icon': Icons.quiz,
      'color': Colors.amber,
      'route': '/game/quiz',
      'isMultiplayer': false,
      'isTrending': true,
    },
    {
      'title': 'Flappy Cyber',
      'category': 'Arcade',
      'icon': Icons.flutter_dash,
      'color': AppTheme.cyanBlue,
      'route': '/game/flappy-bird',
      'isMultiplayer': false,
      'isTrending': true,
    },
    {
      'title': 'Neon Pong',
      'category': 'Arcade',
      'icon': Icons.sports_tennis,
      'color': AppTheme.electricPink,
      'route': '/game/pong',
      'isMultiplayer': true,
      'isTrending': false,
    },
    {
      'title': 'Memory Match',
      'category': 'Puzzle',
      'icon': Icons.psychology,
      'color': AppTheme.neonPurple,
      'route': '/game/memory',
      'isMultiplayer': false,
      'isTrending': false,
    },
    {
      'title': '2048 Matrix',
      'category': 'Puzzle',
      'icon': Icons.grid_4x4,
      'color': Colors.amber,
      'route': '/game/2048',
      'isMultiplayer': false,
      'isTrending': true,
    },
    {
      'title': 'Neon Checkers',
      'category': 'Strategy',
      'icon': Icons.casino,
      'color': AppTheme.neonPurple,
      'route': '/game/checkers',
      'isMultiplayer': false,
      'isTrending': false,
    },
    {
      'title': 'Highway Overdrive',
      'category': 'Racing',
      'icon': Icons.directions_car,
      'color': AppTheme.cyanBlue,
      'route': '/game/highway-racing',
      'isMultiplayer': false,
      'isTrending': true,
    },
    {
      'title': 'Grid Traffic Dodger',
      'category': 'Racing',
      'icon': Icons.traffic,
      'color': AppTheme.electricPink,
      'route': '/game/traffic-dodger',
      'isMultiplayer': false,
      'isTrending': false,
    },
    {
      'title': 'Space Grid Shooter',
      'category': 'Action',
      'icon': Icons.rocket_launch,
      'color': Colors.amber,
      'route': '/game/space-shooter',
      'isMultiplayer': false,
      'isTrending': true,
    },
    {
      'title': 'Grid Matrix Runner',
      'category': 'Action',
      'icon': Icons.directions_run,
      'color': AppTheme.neonPurple,
      'route': '/game/endless-runner',
      'isMultiplayer': false,
      'isTrending': false,
    },
    {
      'title': 'Grid Node Slicer',
      'category': 'Action',
      'icon': Icons.swipe,
      'color': AppTheme.cyanBlue,
      'route': '/game/node-slicer',
      'isMultiplayer': false,
      'isTrending': true,
    },
  ];

  final List<String> _categories = [
    'All',
    'Arcade',
    'Puzzle',
    'Strategy',
    'Racing',
    'Multiplayer',
    'Action',
    'Brain Games',
    'Competitive',
  ];

  @override
  Widget build(BuildContext context) {
    final filteredGames = _games.where((game) {
      final matchesSearch = game['title'].toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      final matchesCategory =
          _selectedCategory == 'All' || game['category'] == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Search Field
          TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'SEARCH SYSTEM...',
              hintStyle: const TextStyle(color: Colors.white30),
              prefixIcon: const Icon(Icons.search, color: AppTheme.cyanBlue),
              filled: true,
              fillColor: AppTheme.glassBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.glassBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.glassBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.cyanBlue),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Categories Filter Tabs
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = category),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.neonPurple
                          : AppTheme.glassBackground,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.neonPurple
                            : AppTheme.glassBorder,
                      ),
                    ),
                    child: Text(
                      category.toUpperCase(),
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white60,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // Grid View of Games
          Expanded(
            child: filteredGames.isEmpty
                ? const Center(
                    child: Text(
                      'NO DATA CORRELATIONS FOUND',
                      style: TextStyle(color: Colors.white30, letterSpacing: 2),
                    ),
                  )
                : GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.85,
                        ),
                    itemCount: filteredGames.length,
                    itemBuilder: (context, index) {
                      final game = filteredGames[index];
                      return GestureDetector(
                        onTap: () {
                          context.push(game['route']);
                        },
                        child: GlassContainer(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  if (game['isTrending'])
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.electricPink,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'TRENDING',
                                        style: TextStyle(
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    )
                                  else if (game['isMultiplayer'])
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.cyanBlue,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'REALTIME',
                                        style: TextStyle(
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                    )
                                  else
                                    const SizedBox.shrink(),
                                  const Icon(
                                    Icons.favorite_border,
                                    color: Colors.white30,
                                    size: 18,
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Icon(
                                game['icon'],
                                size: 48,
                                color: game['color'],
                              ),
                              const Spacer(),
                              Text(
                                game['title'].toUpperCase(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                game['category'].toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ).animate().scale(delay: (index * 50).ms);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
