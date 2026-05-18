import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/common_widgets/cyber_button.dart';
import '../../../../core/common_widgets/glass_container.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              GlassContainer(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        const Icon(
                              Icons.sports_esports,
                              size: 80,
                              color: AppTheme.neonPurple,
                            )
                            .animate(
                              onPlay: (controller) =>
                                  controller.repeat(reverse: true),
                            )
                            .scale(
                              end: const Offset(1.1, 1.1),
                              duration: 1.seconds,
                              curve: Curves.easeInOut,
                            ),
                        const SizedBox(height: 24),
                        const Text(
                          'ENTER THE\nNEXUS',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4,
                            color: Colors.white,
                          ),
                        ).animate().fadeIn(delay: 300.ms).slideY(),
                        const SizedBox(height: 16),
                        const Text(
                          'Compete. Connect. Conquer.\n30+ Premium Games Await.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.white70),
                        ).animate().fadeIn(delay: 600.ms),
                      ],
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 500.ms)
                  .scale(begin: const Offset(0.9, 0.9)),
              const Spacer(),
              CyberButton(
                text: 'INITIALIZE SEQUENCE',
                icon: Icons.power_settings_new,
                onPressed: () => context.go('/login'),
              ).animate().fadeIn(delay: 900.ms).slideY(begin: 1.0),
            ],
          ),
        ),
      ),
    );
  }
}
