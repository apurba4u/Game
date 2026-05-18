import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/common_widgets/glass_container.dart';
import '../../../../../../core/common_widgets/cyber_button.dart';
import '../../../../core/base_game_controller.dart';
import '../../../../../auth/presentation/providers/auth_provider.dart';

class SpaceLaser {
  double x;
  double y;

  SpaceLaser({required this.x, required this.y});
}

class SpaceEnemy {
  double x;
  double y;
  final double speed;
  final int hp;

  SpaceEnemy({required this.x, required this.y, required this.speed, this.hp = 1});
}

class ShootParticle {
  double x;
  double y;
  double vx;
  double vy;
  double alpha;
  final Color color;

  ShootParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.alpha,
    required this.color,
  });
}

class SpaceShooterScreen extends ConsumerStatefulWidget {
  const SpaceShooterScreen({super.key});

  @override
  ConsumerState<SpaceShooterScreen> createState() => _SpaceShooterScreenState();
}

class _SpaceShooterScreenState extends ConsumerState<SpaceShooterScreen> implements BaseGameController {
  late Timer _gameLoop;
  double _playerX = 150.0;
  double _playerY = 0.0; // Dynamic on constraints
  bool _isGameOver = false;
  bool _isPaused = false;
  int _score = 0;
  int _lives = 3;

  List<SpaceLaser> _lasers = [];
  List<SpaceEnemy> _enemies = [];
  List<ShootParticle> _particles = [];
  final Random _rand = Random();
  int _laserCooldown = 0;

  @override
  void initState() {
    super.initState();
    startGame();
  }

  @override
  void dispose() {
    _gameLoop.cancel();
    super.dispose();
  }

  @override
  void startGame() {
    setState(() {
      _playerX = 150.0;
      _isGameOver = false;
      _isPaused = false;
      _score = 0;
      _lives = 3;
      _lasers = [];
      _enemies = [];
      _particles = [];
    });

    _gameLoop = Timer.periodic(const Duration(milliseconds: 30), _updateEngine);
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
    _gameLoop.cancel();
    startGame();
  }

  @override
  void endGame() {
    _gameLoop.cancel();
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
        'game_name': 'Space Shooter',
        'highest_score': _score,
      });

      await supabase.from('game_history').insert({
        'user_id': user.id,
        'game_name': 'Space Shooter',
        'score': _score,
        'duration': 45,
        'win_status': _score > 1500,
      });
    } catch (_) {}
  }

  void _updateEngine(Timer timer) {
    if (_isPaused || _isGameOver) return;

    setState(() {
      // 1. Particle physics
      for (var p in _particles) {
        p.x += p.vx;
        p.y += p.vy;
        p.alpha -= 0.04;
      }
      _particles.removeWhere((p) => p.alpha <= 0);

      // 2. Fire Laser automatically
      if (_laserCooldown <= 0) {
        _lasers.add(SpaceLaser(x: _playerX + 13, y: _playerY - 5));
        _laserCooldown = 8; // Tick cooldown
      } else {
        _laserCooldown--;
      }

      // Move Lasers
      for (var laser in _lasers) {
        laser.y -= 12;
      }
      _lasers.removeWhere((l) => l.y < -10);

      // 3. Move Enemies
      for (var enemy in _enemies) {
        enemy.y += enemy.speed;

        // Player Collision check
        if (enemy.y >= _playerY - 10 &&
            enemy.y <= _playerY + 30 &&
            enemy.x >= _playerX - 10 &&
            enemy.x <= _playerX + 35) {
          _triggerExplosion(enemy.x, enemy.y, AppTheme.electricPink);
          enemy.y = 1000; // Trash
          _lives--;
          if (_lives <= 0) {
            endGame();
            return;
          }
        }
      }

      // 4. Laser hit enemy collisions
      for (var laser in _lasers) {
        for (var enemy in _enemies) {
          final distance = sqrt(pow(laser.x - (enemy.x + 15), 2) + pow(laser.y - (enemy.y + 15), 2));
          if (distance < 25) {
            _triggerExplosion(enemy.x + 15, enemy.y + 15, Colors.amber);
            enemy.y = 1000.0; // Trash
            laser.y = -100.0; // Discard
            _score += 100;
          }
        }
      }

      _enemies.removeWhere((e) => e.y > 800);

      // 5. Spawn enemies
      if (_enemies.isEmpty || (_enemies.last.y > 180 && _rand.nextDouble() < 0.06)) {
        final spawnX = _rand.nextDouble() * 270.0 + 10.0;
        final speed = _rand.nextDouble() * 3.0 + 2.5;
        _enemies.add(SpaceEnemy(x: spawnX, y: -40.0, speed: speed));
      }
    });
  }

  void _triggerExplosion(double x, double y, Color color) {
    for (int i = 0; i < 15; i++) {
      final angle = _rand.nextDouble() * 2 * pi;
      final speed = _rand.nextDouble() * 5 + 2;
      _particles.add(ShootParticle(
        x: x,
        y: y,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed,
        alpha: 1.0,
        color: color,
      ));
    }
  }

  void _dragSpaceship(DragUpdateDetails details, double maxWidth) {
    if (_isPaused || _isGameOver) return;
    setState(() {
      _playerX = (_playerX + details.delta.dx).clamp(10.0, maxWidth - 40.0);
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
          'SPACE GRID SHOOTER',
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
              // HUD lives and score
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _hudColumn('DISPATCH XP', '$_score', Colors.amber),
                  Row(
                    children: List.generate(3, (idx) {
                      final hasLife = idx < _lives;
                      return Icon(
                        hasLife ? Icons.favorite : Icons.favorite_border,
                        color: hasLife ? AppTheme.electricPink : Colors.white24,
                        size: 20,
                      );
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Shooting Simulator Area
              Expanded(
                child: GlassContainer(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      _playerY = constraints.maxHeight - 80.0;
                      return GestureDetector(
                        onHorizontalDragUpdate: (details) => _dragSpaceship(details, constraints.maxWidth),
                        child: ClipRect(
                          child: CustomPaint(
                            size: Size(constraints.maxWidth, constraints.maxHeight),
                            painter: SpacePainter(
                              playerX: _playerX,
                              playerY: _playerY,
                              lasers: _lasers,
                              enemies: _enemies,
                              particles: _particles,
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
                'DRAG DEFENDER HORIZONTALLY TO ERADICATE ALIEN HOSTILES',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white30, fontSize: 10, letterSpacing: 1),
              ),
              const SizedBox(height: 12),

              if (_isGameOver || _isPaused)
                CyberButton(
                  text: _isPaused ? 'RESUME FIRE' : 'RESTART GALACTIC UPLINK',
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

class SpacePainter extends CustomPainter {
  final double playerX;
  final double playerY;
  final List<SpaceLaser> lasers;
  final List<SpaceEnemy> enemies;
  final List<ShootParticle> particles;

  SpacePainter({
    required this.playerX,
    required this.playerY,
    required this.lasers,
    required this.enemies,
    required this.particles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Starfield background
    final starPaint = Paint()..color = Colors.white.withOpacity(0.3);
    final rand = Random(42); // Seeded so stars don't bounce
    for (int i = 0; i < 40; i++) {
      final sx = rand.nextDouble() * size.width;
      final sy = rand.nextDouble() * size.height;
      canvas.drawCircle(Offset(sx, sy), rand.nextDouble() * 1.5, starPaint);
    }

    // Draw Particles
    for (var p in particles) {
      final pPaint = Paint()
        ..color = p.color.withOpacity(p.alpha)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(p.x, p.y), 3.0, pPaint);
    }

    // Draw Lasers
    final laserPaint = Paint()
      ..color = AppTheme.cyanBlue
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final laserGlow = Paint()
      ..color = AppTheme.cyanBlue.withOpacity(0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    for (var laser in lasers) {
      canvas.drawLine(Offset(laser.x, laser.y), Offset(laser.x, laser.y - 12), laserGlow);
      canvas.drawLine(Offset(laser.x, laser.y), Offset(laser.x, laser.y - 12), laserPaint);
    }

    // Draw Enemies
    for (var enemy in enemies) {
      final rect = Rect.fromLTWH(enemy.x, enemy.y, 30, 30);
      final enemyPaint = Paint()
        ..color = AppTheme.electricPink
        ..style = PaintingStyle.fill;
      final enemyGlow = Paint()
        ..color = AppTheme.electricPink.withOpacity(0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawPath(
        _trianglePath(enemy.x, enemy.y, 30, false),
        enemyGlow,
      );
      canvas.drawPath(
        _trianglePath(enemy.x, enemy.y, 30, false),
        enemyPaint,
      );
    }

    // Draw Player Spaceship
    final playerRect = Rect.fromLTWH(playerX, playerY, 30, 35);
    final shipPaint = Paint()
      ..shader = const LinearGradient(
        colors: [AppTheme.cyanBlue, Colors.blueAccent],
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
      ).createShader(playerRect);

    final shipGlow = Paint()
      ..color = AppTheme.cyanBlue.withOpacity(0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    canvas.drawPath(_trianglePath(playerX, playerY, 30, true), shipGlow);
    canvas.drawPath(_trianglePath(playerX, playerY, 30, true), shipPaint);
  }

  Path _trianglePath(double x, double y, double size, bool pointsUp) {
    final path = Path();
    if (pointsUp) {
      path.moveTo(x + size / 2, y);
      path.lineTo(x + size, y + size);
      path.lineTo(x, y + size);
    } else {
      path.moveTo(x + size / 2, y + size);
      path.lineTo(x + size, y);
      path.lineTo(x, y);
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
