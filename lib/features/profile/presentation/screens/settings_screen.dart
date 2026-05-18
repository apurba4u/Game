import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/common_widgets/glass_container.dart';
import '../../../../core/common_widgets/cyber_button.dart';
import '../../../../core/audio/audio_manager.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _audioManager = AudioManager.instance;
  bool _isMusicOn = true;
  bool _isSFXOn = true;
  bool _isVibrationOn = true;
  bool _isPerformanceOn = true;

  @override
  void initState() {
    super.initState();
    _isMusicOn = _audioManager.isMusicEnabled;
    _isSFXOn = _audioManager.isSFXEnabled;
  }

  void _clearCache() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('LOCAL PERSISTENCE CORE FLUSHED SUCCESSFULLY'),
        backgroundColor: AppTheme.cyanBlue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.cyanBlue),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'CORE PREFERENCES',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Audio Panel
              const Text(
                'NEURAL BROADCAST SETTINGS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 12),
              GlassContainer(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      activeThumbColor: AppTheme.cyanBlue,
                      title: const Text(
                        'AMBIENT MUSIC',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: const Text(
                        'Toggle global BGM stream.',
                        style: TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                      value: _isMusicOn,
                      onChanged: (val) {
                        setState(() => _isMusicOn = val);
                        _audioManager.toggleMusic(val);
                      },
                    ),
                    const Divider(color: Colors.white10),
                    SwitchListTile(
                      activeThumbColor: AppTheme.cyanBlue,
                      title: const Text(
                        'TACTILE EFFECTS (SFX)',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: const Text(
                        'Play sound triggers on game events.',
                        style: TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                      value: _isSFXOn,
                      onChanged: (val) {
                        setState(() => _isSFXOn = val);
                        _audioManager.toggleSFX(val);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Gameplay & Performance
              const Text(
                'GRID PERFORMANCE OPTIMIZATION',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 12),
              GlassContainer(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      activeThumbColor: AppTheme.neonPurple,
                      title: const Text(
                        'HAPTIC FEEDBACK',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: const Text(
                        'Trigger physical rumble cycles.',
                        style: TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                      value: _isVibrationOn,
                      onChanged: (val) => setState(() => _isVibrationOn = val),
                    ),
                    const Divider(color: Colors.white10),
                    SwitchListTile(
                      activeThumbColor: AppTheme.neonPurple,
                      title: const Text(
                        'AAA RENDER CYCLE',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: const Text(
                        'Unlock maximum canvas framerate.',
                        style: TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                      value: _isPerformanceOn,
                      onChanged: (val) =>
                          setState(() => _isPerformanceOn = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // System Operations
              const Text(
                'STORAGE OPERATIONS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 12),
              CyberButton(
                text: 'FLUSH CORE CACHE',
                icon: Icons.cleaning_services,
                isSecondary: true,
                onPressed: _clearCache,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
