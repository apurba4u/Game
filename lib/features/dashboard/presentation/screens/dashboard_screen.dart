import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/common_widgets/glass_container.dart';
import '../../../../features/dashboard/presentation/screens/home_tab_screen.dart';
import '../../../../features/games_library/presentation/screens/games_library_screen.dart';
import '../../../../features/dashboard/presentation/screens/stats_screen.dart';
import '../../../../features/dashboard/presentation/screens/leaderboard_tab_screen.dart';
import '../../../../features/profile/presentation/screens/profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeTabScreen(),
    GamesLibraryScreen(),
    StatsScreen(),
    LeaderboardTabScreen(),
    ProfileScreen(),
  ];

  final List<String> _titles = const [
    'SYSTEM HUD',
    'DATABASE LIBRARY',
    'SYSTEM METRICS',
    'LEADERBOARDS',
    'IDENTITY ARCHIVE',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          _titles[_currentIndex],
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: 3,
            fontSize: 20,
          ),
        ),
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: GlassContainer(
            borderRadius: 24,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(Icons.home, 0),
                _buildNavItem(Icons.sports_esports, 1),
                _buildNavItem(Icons.bar_chart, 2),
                _buildNavItem(Icons.emoji_events, 3),
                _buildNavItem(Icons.person, 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.neonPurple.withOpacity(0.2)
              : Colors.transparent,
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(color: AppTheme.neonPurple, width: 1.5)
              : null,
        ),
        child: Icon(
          icon,
          color: isSelected ? AppTheme.cyanBlue : Colors.white60,
          size: 24,
        ),
      ),
    );
  }
}
