import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/common_widgets/glass_container.dart';
import '../../../../../../core/common_widgets/cyber_button.dart';
import '../../../../core/base_game_controller.dart';
import '../../../../../auth/presentation/providers/auth_provider.dart';

class RunnerObstacle {
  double x;
  final double width;
  final double height;
  final Color color;

  RunnerObstacle({
    required this.x,
    required this.width,
    required this.height,
    required this.color,
  });
}

class EndlessRunnerScreen extends ConsumerStatefulWidget {
  const EndlessRunnerScreen({super.key});

  @override
  ConsumerState<EndlessRunnerScreen> createState() => _EndlessRunnerScreenState();
}

class _EndlessRunnerScreenState extends ConsumerState<EndlessRunnerScreen> implements BaseGameController {
  late Timer _runnerTimer;
  double _playerY = 0.0; // Vertical coordinate
  double _velocity = 0.0;
  final double _gravity = 0.9;
  final double _jumpStrength = -14.0;
  double _floorY = 0.0; // Assigned in layout

  List<RunnerObstacle> _obstacles = [];
  bool _isGameOver = false;
  bool _isPaused = false;
  int _score = 0;
  double _gameSpeed = 6.0;
  final Random _rand = Random();

  @override
  void initState() {
    super.initState();
    startGame();
  }

  @override
  void dispose() {
    _runnerTimer.cancel();
    super.dispose();
  }

  @override
  void startGame() {
    setState(() {
      _playerY = 0.0;
      _velocity = 0.0;
      _obstacles = [];
      _isGameOver = false;
      _isPaused = false;
      _score = 0;
      _gameSpeed = 6.0;
    });

    _runnerTimer = Timer.periodic(const Duration(milliseconds: 25), _updatePhysics);
  }

  @override
  void pauseGame() {
    setState(() {
      _isPaused = true;
    });
  }

  @override
  void resumeGame() {
    setState(() {
      _isPaused = false;
    });
  }

  @override
  void restartGame() {
    _runnerTimer.cancel();
    startGame();
  }

  @override
  void endGame() {
    _runnerTimer.cancel();
    setState(() {
      _isGameOver = true;
    });
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
        'game_name': 'Endless Runner',
        'highest_score': _score,
      });

      await supabase.from('game_history').insert({
        'user_id': user.id,
        'game_name': 'Endless Runner',
        'score': _score,
        'duration': 30,
        'win_status': _score > 1000,
      });
    } catch (_) {}
  }

  void _updatePhysics(Timer timer) {
    if (_isPaused || _isGameOver) return;

    setState(() {
      // 1. Gravity & Jumps physics
      _velocity += _gravity;
      _playerY += _velocity;

      if (_playerY >= _floorY) {
        _playerY = _floorY;
        _velocity = 0.0;
      }

      // 2. Obstacles motion
      for (var obs in _obstacles) {
        obs.x -= _gameSpeed;

        // Collision checking (Player is fixed horizontally at x = 50, size 30x30)
        final pLeft = 50.0;
        final pRight = 80.0;
        final pTop = _playerY;
        final pBottom = _playerY + 30;

        final oLeft = obs.x;
        final oRight = obs.x + obs.width;
        final oTop = _floorY + 30 - obs.height;
        final oBottom = _floorY + 30;

        if (oLeft < pRight && oRight > pLeft && oTop < pBottom && oBottom > pTop) {
          endGame();
          return;
        }
      }

      // 3. Score & clean offscreen obstacles
      final len = _obstacles.length;
      _obstacles.removeWhere((o) => o.x < -60);
      final removed = len - _obstacles.length;
      if (removed > 0) {
        _score += 150 * removed;
        _gameSpeed += 0.2; // Speed up
      }

      // 4. Spawn obstacles
      if (_obstacles.isEmpty || (_obstacles.last.x < 180 && _rand.nextDouble() < 0.025)) {
        final obsH = _rand.nextDouble() * 30.0 + 25.0;
        final obsW = 20.0;
        _obstacles.add(RunnerObstacle(
          x: 400.0,
          width: obsW,
          height: obsH,
          color: _rand.nextBool() ? AppTheme.electricPink : Colors.amber,
        ));
      }

      // Steady run score
      _score += 1;
    });
  }

  void _triggerJump() {
    if (_isPaused || _isGameOver) return;
    if (_playerY == _floorY) {
      setState(() {
        _velocity = _jumpStrength;
      });
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
          'GRID MATRIX RUNNER',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2),
        ),
        actions: [
          IconButton(
            icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause, color: AppTheme.cyanBlue),
            onPressed: () => _isPaused ? resumeGame() : pauseGame(),
          )
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // HUD scores
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _hudText('XP DISPATCH', '$_score', Colors.greenAccent),
                  _hudText('VELOCITY FREQ', '${(_gameSpeed * 10).toInt()} MHz', AppTheme.cyanBlue),
                ],
              ),
              const SizedBox(height: 16),

              // Game simulator canvas
              Expanded(
                child: GlassContainer(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      _floorY = constraints.maxHeight - 80.0;
                      return GestureDetector(
                        onTap: _triggerJump,
                        child: ClipRect(
                          child: CustomPaint(
                            size: Size(constraints.maxWidth, constraints.maxHeight),
                            painter: RunnerPainter(
                              playerY: _playerY,
                              floorY: _floorY,
                              obstacles: _obstacles,
                            ),
                            child: Container(),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'TAP ANYWHERE ON SCREEN TO TRIGGER GRAVITATIONAL JUMP',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white30, fontSize: 10, letterSpacing: 1),
              ),
              const SizedBox(height: 12),

              if (_isGameOver || _isPaused)
                CyberButton(
                  text: _isPaused ? 'RESUME RUN' : 'RESTART GRID RUN',
                  onPressed: () => _isPaused ? resumeGame() : restartGame(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hudText(String title, String val, Color highlight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          val,
          style: TextStyle(color: highlight, fontSize: 16, fontWeight: FontWeight.w900, fontFamily: 'monospace'),
        ),
      ],
    );
  }
}

class RunnerPainter extends CustomPainter {
  final double playerY;
  final double floorY;
  final List<RunnerObstacle> obstacles;

  RunnerPainter({
    required this.playerY,
    required this.floorY,
    required this.obstacles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;

    // Floor line
    final floorPaint = Paint()
      ..color = AppTheme.cyanBlue.withOpacity(0.3)
      ..strokeWidth = 3;
    canvas.drawLine(Offset(0, floorY + 30), Offset(w, floorY + 30), floorPaint);

    // Grid Floor scanner hatching
    final gridFloor = Paint()
      ..color = AppTheme.cyanBlue.withOpacity(0.05)
      ..strokeWidth = 1;
    for (double x = 0; x < w; x += 30) {
      canvas.drawLine(Offset(x, floorY + 30), Offset(x - 40, size.height), gridFloor);
    }

    // Draw Obstacles
    for (var obs in obstacles) {
      final rect = Rect.fromLTWH(obs.x, floorY + 30 - obs.height, obs.width, obs.height);
      final obsPaint = Paint()
        ..color = obs.color
        ..style = PaintingStyle.fill;
      final obsGlow = Paint()
        ..color = obs.color.withOpacity(0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawRect(rect.inflate(2), obsGlow);
      canvas.drawRect(rect, obsPaint);
    }

    // Draw Player Runner Pod
    final playerRect = Rect.fromLTWH(50, playerY, 30, 30);
    final pPaint = Paint()
      ..shader = const LinearGradient(
        colors: [AppTheme.cyanBlue, Colors.tealAccent],
      ).createShader(playerRect);

    final pGlow = Paint()
      ..color = AppTheme.cyanBlue.withOpacity(0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    canvas.drawRRect(RRect.fromRectAndRadius(playerRect.inflate(3), const Radius.circular(6)), pGlow);
    canvas.drawRRect(RRect.fromRectAndRadius(playerRect, const Radius.circular(6)), pPaint);

    // Running exhaust trail sparks
    if (playerY == floorY) {
      final exhaustPaint = Paint()..color = Colors.white70;
      canvas.drawCircle(Offset(42, floorY + 25), 2.5, exhaustPaint);
      canvas.drawCircle(Offset(35, floorY + 28), 1.5, exhaustPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
