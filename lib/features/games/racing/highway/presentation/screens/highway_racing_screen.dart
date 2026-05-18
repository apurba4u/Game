import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/common_widgets/glass_container.dart';
import '../../../../../../core/common_widgets/cyber_button.dart';
import '../../../../core/base_game_controller.dart';
import '../../../../../auth/presentation/providers/auth_provider.dart';

class ObstacleCar {
  double y; // 0.0 (top) to 1.0 (bottom)
  int lane; // 0, 1, or 2
  final Color color;
  final double speed;

  ObstacleCar({required this.y, required this.lane, required this.color, required this.speed});
}

class HighwayRacingScreen extends ConsumerStatefulWidget {
  const HighwayRacingScreen({super.key});

  @override
  ConsumerState<HighwayRacingScreen> createState() => _HighwayRacingScreenState();
}

class _HighwayRacingScreenState extends ConsumerState<HighwayRacingScreen> implements BaseGameController {
  late Timer _gameTimer;
  int _playerLane = 1; // 0 (left), 1 (middle), 2 (right)
  double _playerTransitionX = 1.0; // Smooth sliding between lanes
  List<ObstacleCar> _obstacles = [];
  bool _isGameOver = false;
  bool _isPaused = false;
  int _score = 0;
  double _gameSpeed = 0.02;
  double _roadOffset = 0.0;
  final Random _rand = Random();

  @override
  void initState() {
    super.initState();
    startGame();
  }

  @override
  void dispose() {
    _gameTimer.cancel();
    super.dispose();
  }

  @override
  void startGame() {
    setState(() {
      _playerLane = 1;
      _playerTransitionX = 1.0;
      _obstacles = [];
      _isGameOver = false;
      _isPaused = false;
      _score = 0;
      _gameSpeed = 0.02;
      _roadOffset = 0.0;
    });

    _gameTimer = Timer.periodic(const Duration(milliseconds: 30), _updateGame);
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
    _gameTimer.cancel();
    startGame();
  }

  @override
  void endGame() {
    _gameTimer.cancel();
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
        'game_name': 'Endless Highway Racing',
        'highest_score': _score,
      });

      await supabase.from('game_history').insert({
        'user_id': user.id,
        'game_name': 'Endless Highway Racing',
        'score': _score,
        'duration': 35,
        'win_status': _score > 1000,
      });
    } catch (_) {}
  }

  void _updateGame(Timer timer) {
    if (_isPaused || _isGameOver) return;

    setState(() {
      // 1. Move road lanes to create motion illusion
      _roadOffset += _gameSpeed * 5;
      if (_roadOffset > 10) _roadOffset = 0;

      // 2. Animate player transition smoothly
      final targetX = _playerLane.toDouble();
      _playerTransitionX += (targetX - _playerTransitionX) * 0.3;

      // 3. Move obstacles down & detect collision
      for (var obs in _obstacles) {
        obs.y += _gameSpeed * 1.5;
        // Collision logic
        if (obs.y >= 0.78 && obs.y <= 0.90 && obs.lane == _playerLane) {
          endGame();
          return;
        }
      }

      // 4. Remove offscreen obstacles & increment score
      final originalLength = _obstacles.length;
      _obstacles.removeWhere((obs) => obs.y > 1.1);
      final removedCount = originalLength - _obstacles.length;
      if (removedCount > 0) {
        _score += 150 * removedCount;
        // Increment speed slowly
        _gameSpeed += 0.0005;
      }

      // 5. Spawn new obstacles
      if (_obstacles.isEmpty || (_obstacles.last.y > 0.4 && _rand.nextDouble() < 0.03)) {
        final obstacleLane = _rand.nextInt(3);
        final obstacleColor = _rand.nextBool() ? AppTheme.electricPink : Colors.amber;
        _obstacles.add(ObstacleCar(
          y: -0.1,
          lane: obstacleLane,
          color: obstacleColor,
          speed: _gameSpeed,
        ));
      }

      // Small steady score increment
      _score += 1;
    });
  }

  void _moveLane(int offset) {
    if (_isGameOver || _isPaused) return;
    setState(() {
      _playerLane = (_playerLane + offset).clamp(0, 2);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'HIGHWAY OVERDRIVE',
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
                  _hudColumn('XP SCORE', '$_score', Colors.amber),
                  _hudColumn('SPEED RATIO', '${(_gameSpeed * 1000).toInt()} KM/H', AppTheme.cyanBlue),
                ],
              ),
              const SizedBox(height: 12),

              // Game View Screen
              Expanded(
                child: GlassContainer(
                  child: ClipRect(
                    child: CustomPaint(
                      painter: HighwayPainter(
                        playerLane: _playerLane,
                        playerTransitionX: _playerTransitionX,
                        obstacles: _obstacles,
                        roadOffset: _roadOffset,
                      ),
                      child: Container(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Controls Panel
              Row(
                children: [
                  Expanded(
                    child: CyberButton(
                      text: 'LANE LEFT',
                      icon: Icons.arrow_back,
                      isSecondary: true,
                      onPressed: () => _moveLane(-1),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CyberButton(
                      text: 'LANE RIGHT',
                      icon: Icons.arrow_forward,
                      isSecondary: true,
                      onPressed: () => _moveLane(1),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Game Over and Start Actions
              if (_isGameOver || _isPaused)
                CyberButton(
                  text: _isPaused ? 'RESUME DRIVE' : 'BOOT ENGINE AGAIN',
                  onPressed: () => _isPaused ? resumeGame() : restartGame(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hudColumn(String label, String val, Color highlight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
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

class HighwayPainter extends CustomPainter {
  final int playerLane;
  final double playerTransitionX;
  final List<ObstacleCar> obstacles;
  final double roadOffset;

  HighwayPainter({
    required this.playerLane,
    required this.playerTransitionX,
    required this.obstacles,
    required this.roadOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Draw dark horizon sky gradient
    final skyPaint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.black87, AppTheme.darkBackground.withOpacity(0.9)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, w, h * 0.3));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h * 0.3), skyPaint);

    // Horizon line
    final horizonPaint = Paint()
      ..color = AppTheme.cyanBlue.withOpacity(0.3)
      ..strokeWidth = 2;
    canvas.drawLine(Offset(0, h * 0.3), Offset(w, h * 0.3), horizonPaint);

    // Draw ground grid / road perspective
    final roadPath = Path()
      ..moveTo(w * 0.15, h)
      ..lineTo(w * 0.35, h * 0.3)
      ..lineTo(w * 0.65, h * 0.3)
      ..lineTo(w * 0.85, h)
      ..close();

    final roadPaint = Paint()
      ..color = Colors.white10
      ..style = PaintingStyle.fill;
    canvas.drawPath(roadPath, roadPaint);

    // Draw perspective divider lines
    final laneDividerPaint = Paint()
      ..color = AppTheme.cyanBlue.withOpacity(0.4)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final dashPaint = Paint()
      ..color = Colors.white30
      ..strokeWidth = 3;

    // 2 Divider lines (dividing into 3 lanes)
    for (var i = 1; i <= 2; i++) {
      final t = i / 3.0;
      final bottomX = w * (0.15 + t * 0.7);
      final topX = w * (0.35 + t * 0.3);

      // Dash indicators running down
      for (double d = 0.3; d <= 1.0; d += 0.1) {
        final currentD = d + (roadOffset / 100.0);
        final clampedD = currentD > 1.0 ? currentD - 0.7 : currentD;

        final dy1 = h * clampedD;
        final dy2 = h * (clampedD + 0.05);

        if (dy1 > h * 0.3 && dy2 < h) {
          final interp1 = (dy1 - h * 0.3) / (h * 0.7);
          final interp2 = (dy2 - h * 0.3) / (h * 0.7);

          final dx1 = topX + (bottomX - topX) * interp1;
          final dx2 = topX + (bottomX - topX) * interp2;

          canvas.drawLine(Offset(dx1, dy1), Offset(dx2, dy2), dashPaint);
        }
      }
    }

    // Draw Obstacle Cars
    for (var obs in obstacles) {
      if (obs.y < 0.0) continue;

      final t = obs.lane / 3.0 + 0.16; // Lane middle offset
      final bottomX = w * (0.15 + t * 0.7);
      final topX = w * (0.35 + t * 0.3);

      final carY = h * (0.3 + obs.y * 0.7);
      final scale = obs.y; // Bigger as it gets closer

      final carX = topX + (bottomX - topX) * obs.y;
      final carW = 40.0 * scale;
      final carH = 25.0 * scale;

      final carPaint = Paint()
        ..color = obs.color
        ..style = PaintingStyle.fill;

      final glowPaint = Paint()
        ..color = obs.color.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      // Draw cyber glowing box
      canvas.drawRect(
        Rect.fromCenter(center: Offset(carX, carY), width: carW + 4, height: carH + 4),
        glowPaint,
      );
      canvas.drawRect(
        Rect.fromCenter(center: Offset(carX, carY), width: carW, height: carH),
        carPaint,
      );

      // Cyber neon lights
      final lightPaint = Paint()..color = Colors.red;
      canvas.drawCircle(Offset(carX - carW * 0.35, carY + carH * 0.4), 2 * scale, lightPaint);
      canvas.drawCircle(Offset(carX + carW * 0.35, carY + carH * 0.4), 2 * scale, lightPaint);
    }

    // Draw Player Car (Always positioned around y = 0.85)
    final playerT = playerTransitionX / 3.0 + 0.16;
    final playerBottomX = w * (0.15 + playerT * 0.7);
    final playerTopX = w * (0.35 + playerT * 0.3);

    final playerY = h * 0.82;
    final playerX = playerTopX + (playerBottomX - playerTopX) * 0.82;
    const playerW = 45.0;
    const playerH = 30.0;

    final playerPaint = Paint()
      ..shader = const LinearGradient(
        colors: [AppTheme.cyanBlue, Colors.tealAccent],
      ).createShader(Rect.fromCenter(center: Offset(playerX, playerY), width: playerW, height: playerH));

    final playerGlow = Paint()
      ..color = AppTheme.cyanBlue.withOpacity(0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    // Outer glow
    canvas.drawRect(
      Rect.fromCenter(center: Offset(playerX, playerY), width: playerW + 6, height: playerH + 6),
      playerGlow,
    );

    // Base body
    canvas.drawRect(
      Rect.fromCenter(center: Offset(playerX, playerY), width: playerW, height: playerH),
      playerPaint,
    );

    // Front headlights (Cyan)
    final headlightPaint = Paint()..color = AppTheme.cyanBlue;
    canvas.drawCircle(Offset(playerX - playerW * 0.3, playerY - playerH * 0.4), 3, headlightPaint);
    canvas.drawCircle(Offset(playerX + playerW * 0.3, playerY - playerH * 0.4), 3, headlightPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
