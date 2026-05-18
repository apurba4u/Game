import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/common_widgets/glass_container.dart';
import '../../../../../../core/common_widgets/cyber_button.dart';
import '../../../../core/base_game_controller.dart';
import '../../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../../../core/audio/audio_manager.dart';

class FlappyBirdScreen extends ConsumerStatefulWidget {
  const FlappyBirdScreen({super.key});

  @override
  ConsumerState<FlappyBirdScreen> createState() => _FlappyBirdScreenState();
}

class _FlappyBirdScreenState extends ConsumerState<FlappyBirdScreen>
    with SingleTickerProviderStateMixin
    implements BaseGameController {
  // Game Physics
  late AnimationController _ticker;
  double _birdY = 0; // -1 to 1 (screen ratio)
  double _velocity = 0;
  final double _gravity = 0.007;
  final double _jumpForce = -0.12;

  // Obstacles
  List<Map<String, double>> _pipes = []; // list of {x, topHeight, bottomHeight}
  final double _pipeWidth = 0.25;
  final double _pipeGap = 0.6;
  final double _pipeSpeed = 0.015;

  int _score = 0;
  bool _isPaused = false;
  bool _isGameOver = false;

  @override
  void initState() {
    super.initState();
    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _ticker.addListener(_gameTick);
    startGame();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  void startGame() {
    setState(() {
      _birdY = 0;
      _velocity = 0;
      _score = 0;
      _isPaused = false;
      _isGameOver = false;
      _pipes = [
        {'x': 1.0, 'top': 0.3, 'bottom': 0.3},
        {'x': 1.8, 'top': 0.5, 'bottom': 0.1},
      ];
    });
    _ticker.repeat();
  }

  void _gameTick() {
    if (_isPaused || _isGameOver) return;

    setState(() {
      // Apply gravity to velocity, velocity to displacement
      _velocity += _gravity;
      _birdY += _velocity;

      // Handle ground/ceiling bounds checks
      if (_birdY > 1.0 || _birdY < -1.0) {
        endGame();
      }

      // Move pipes and check collisions
      for (var pipe in _pipes) {
        pipe['x'] = pipe['x']! - _pipeSpeed;

        // Score logic (whenever a pipe passes the bird center x=0)
        if (pipe['x']! < 0 && pipe['x']! > -_pipeSpeed) {
          _score += 10;
          AudioManager.instance.playSFX('sfx/score.mp3');
        }

        // Collision logic
        if (pipe['x']! > -_pipeWidth && pipe['x']! < 0.1) {
          // Inside horizontal boundary of the pipe
          double topBarrier = -1.0 + pipe['top']!;
          double bottomBarrier = 1.0 - pipe['bottom']!;

          if (_birdY < topBarrier || _birdY > bottomBarrier) {
            endGame();
          }
        }
      }

      // Cycle pipes once they leave the left side of the screen
      if (_pipes.first['x']! < -1.5) {
        _pipes.removeAt(0);
        final random = Random();
        double top = 0.2 + random.nextDouble() * 0.4;
        double bottom = 0.8 - top - _pipeGap;
        _pipes.add({'x': 1.5, 'top': top, 'bottom': bottom});
      }
    });
  }

  void _jump() {
    if (_isPaused || _isGameOver) return;
    setState(() {
      _velocity = _jumpForce;
    });
    AudioManager.instance.playSFX('sfx/jump.mp3');
  }

  @override
  void pauseGame() {
    setState(() {
      _isPaused = true;
    });
    _ticker.stop();
  }

  @override
  void resumeGame() {
    setState(() {
      _isPaused = false;
    });
    _ticker.repeat();
  }

  @override
  void restartGame() {
    startGame();
  }

  @override
  void endGame() {
    setState(() {
      _isGameOver = true;
    });
    _ticker.stop();
    AudioManager.instance.playSFX('sfx/fail.mp3');
    saveScore();
  }

  @override
  Future<void> saveScore() async {
    final user = ref.read(currentUserProvider);
    if (user == null || _score == 0) return;

    try {
      final supabase = ref.read(supabaseProvider);

      await supabase.from('game_scores').insert({
        'user_id': user.id,
        'game_name': 'Flappy Bird',
        'highest_score': _score,
      });

      await supabase.from('game_history').insert({
        'user_id': user.id,
        'game_name': 'Flappy Bird',
        'score': _score,
        'duration': 35,
        'win_status': _score > 100,
      });
    } catch (e) {
      // Offline fallback
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'FLAPPY CYBER',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isPaused ? Icons.play_arrow : Icons.pause,
              color: AppTheme.cyanBlue,
            ),
            onPressed: () {
              if (_isPaused) {
                resumeGame();
              } else {
                pauseGame();
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: _jump,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'SCORE: $_score',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 16),

                // Game Window
                Expanded(
                  child: GlassContainer(
                    padding: EdgeInsets.zero,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return CustomPaint(
                          size: Size(
                            constraints.maxWidth,
                            constraints.maxHeight,
                          ),
                          painter: BirdPainter(
                            birdY: _birdY,
                            pipes: _pipes,
                            pipeWidth: _pipeWidth,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                if (_isGameOver || _isPaused)
                  CyberButton(
                    text: _isPaused ? 'RESUME SIGNAL' : 'RESTART CORE',
                    onPressed: () {
                      if (_isPaused) {
                        resumeGame();
                      } else {
                        restartGame();
                      }
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class BirdPainter extends CustomPainter {
  final double birdY;
  final List<Map<String, double>> pipes;
  final double pipeWidth;

  BirdPainter({
    required this.birdY,
    required this.pipes,
    required this.pipeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // Draw Bird
    final birdX = width * 0.2;
    // Map birdY from (-1, 1) to (0, height)
    final yPos = ((birdY + 1) / 2) * height;

    final birdPaint = Paint()..color = AppTheme.cyanBlue;
    canvas.drawCircle(Offset(birdX, yPos), 16, birdPaint);

    // Draw wing glow
    final glowPaint = Paint()
      ..color = AppTheme.cyanBlue.withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset(birdX, yPos), 24, glowPaint);

    // Draw Pipes
    final pipePaint = Paint()..color = AppTheme.neonPurple;
    for (var pipe in pipes) {
      // Map x from (-1, 1.5) to (0, width)
      final xPos = ((pipe['x']! + 1) / 2) * width;
      final pWidth = pipeWidth * width / 2;

      // Top pipe
      final topHeight = pipe['top']! * height;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(xPos - pWidth / 2, 0, pWidth, topHeight),
          const Radius.circular(8),
        ),
        pipePaint,
      );

      // Bottom pipe
      final bottomHeight = pipe['bottom']! * height;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            xPos - pWidth / 2,
            height - bottomHeight,
            pWidth,
            bottomHeight,
          ),
          const Radius.circular(8),
        ),
        pipePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
