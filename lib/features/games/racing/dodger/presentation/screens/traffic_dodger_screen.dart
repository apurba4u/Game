import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/common_widgets/glass_container.dart';
import '../../../../../../core/common_widgets/cyber_button.dart';
import '../../../../core/base_game_controller.dart';
import '../../../../../auth/presentation/providers/auth_provider.dart';

class TrafficCar {
  double x;
  double y;
  final double width;
  final double height;
  final Color color;
  final double speed;

  TrafficCar({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.color,
    required this.speed,
  });
}

class FuelCell {
  double x;
  double y;
  final double radius = 10.0;

  FuelCell({required this.x, required this.y});
}

class TrafficDodgerScreen extends ConsumerStatefulWidget {
  const TrafficDodgerScreen({super.key});

  @override
  ConsumerState<TrafficDodgerScreen> createState() => _TrafficDodgerScreenState();
}

class _HighwayRacerState {} // unused dummy

class _TrafficDodgerScreenState extends ConsumerState<TrafficDodgerScreen> implements BaseGameController {
  late Timer _gameTimer;
  double _playerX = 150.0; // Horizontal coordinate
  double _playerY = 0.0; // Populated in layout
  bool _isGameOver = false;
  bool _isPaused = false;
  int _score = 0;
  double _fuel = 100.0; // Depleting fuel ratio
  List<TrafficCar> _traffic = [];
  List<FuelCell> _fuelCells = [];
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
      _playerX = 150.0;
      _traffic = [];
      _fuelCells = [];
      _isGameOver = false;
      _isPaused = false;
      _score = 0;
      _fuel = 100.0;
    });

    _gameTimer = Timer.periodic(const Duration(milliseconds: 30), _updateLoop);
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
        'game_name': 'Traffic Dodging Racer',
        'highest_score': _score,
      });

      await supabase.from('game_history').insert({
        'user_id': user.id,
        'game_name': 'Traffic Dodging Racer',
        'score': _score,
        'duration': 40,
        'win_status': _score > 1200,
      });
    } catch (_) {}
  }

  void _updateLoop(Timer timer) {
    if (_isPaused || _isGameOver) return;

    setState(() {
      // Deplete fuel
      _fuel -= 0.15;
      if (_fuel <= 0) {
        _fuel = 0.0;
        endGame();
        return;
      }

      // Move incoming traffic
      for (var car in _traffic) {
        car.y += car.speed;
        // Collision checking
        if (car.y + car.height >= _playerY &&
            car.y <= _playerY + 45 &&
            car.x + car.width >= _playerX &&
            car.x <= _playerX + 30) {
          endGame();
          return;
        }
      }

      // Move fuel cells
      for (var fuel in _fuelCells) {
        fuel.y += 4;
        // Collision checking
        final dist = sqrt(pow(fuel.x - (_playerX + 15), 2) + pow(fuel.y - (_playerY + 22), 2));
        if (dist < 25) {
          _fuel = (_fuel + 25.0).clamp(0.0, 100.0);
          _score += 100;
          fuel.y = 1000.0; // Flag to discard
        }
      }

      // Cleanup offscreen objects
      _traffic.removeWhere((c) => c.y > 700);
      _fuelCells.removeWhere((f) => f.y > 700);

      // Spawn traffic cars
      if (_traffic.isEmpty || (_traffic.last.y > 220 && _rand.nextDouble() < 0.05)) {
        final carW = 32.0;
        final carH = 50.0;
        final carX = _rand.nextDouble() * 260.0 + 10.0;
        final speed = _rand.nextDouble() * 4.0 + 3.0;
        _traffic.add(TrafficCar(
          x: carX,
          y: -60.0,
          width: carW,
          height: carH,
          color: _rand.nextBool() ? AppTheme.electricPink : Colors.amber,
          speed: speed,
        ));
      }

      // Spawn fuel cells
      if (_fuelCells.isEmpty && _rand.nextDouble() < 0.015) {
        final cellX = _rand.nextDouble() * 280.0 + 10.0;
        _fuelCells.add(FuelCell(x: cellX, y: -20.0));
      }

      // Score increment
      _score += 1;
    });
  }

  void _dragPlayer(DragUpdateDetails details, double maxWidth) {
    if (_isPaused || _isGameOver) return;
    setState(() {
      _playerX = (_playerX + details.delta.dx).clamp(8.0, maxWidth - 38.0);
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
          'GRID TRAFFIC DODGER',
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
              // Score Board & Fuel indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _hudColumn('DISPATCH XP', '$_score', Colors.greenAccent),
                  SizedBox(
                    width: 140,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'NEURAL ENERGY',
                          style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: _fuel / 100.0,
                            minHeight: 10,
                            backgroundColor: Colors.white12,
                            color: _fuel > 35 ? AppTheme.cyanBlue : AppTheme.electricPink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Game Simulation Area
              Expanded(
                child: GlassContainer(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      _playerY = constraints.maxHeight - 75.0;
                      return GestureDetector(
                        onHorizontalDragUpdate: (details) => _dragPlayer(details, constraints.maxWidth),
                        child: ClipRect(
                          child: CustomPaint(
                            size: Size(constraints.maxWidth, constraints.maxHeight),
                            painter: TrafficPainter(
                              playerX: _playerX,
                              playerY: _playerY,
                              traffic: _traffic,
                              fuelCells: _fuelCells,
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
                'DRAG DRIVER HORIZONTALLY TO AVOID GRID COLLISIONS',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white30, fontSize: 10, letterSpacing: 1),
              ),
              const SizedBox(height: 12),

              if (_isGameOver || _isPaused)
                CyberButton(
                  text: _isPaused ? 'RESUME UPLINK' : 'BOOT SIMULATION AGAIN',
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

class TrafficPainter extends CustomPainter {
  final double playerX;
  final double playerY;
  final List<TrafficCar> traffic;
  final List<FuelCell> fuelCells;

  TrafficPainter({
    required this.playerX,
    required this.playerY,
    required this.traffic,
    required this.fuelCells,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw vertical background neon border channels
    final borderPaint = Paint()
      ..color = AppTheme.cyanBlue.withOpacity(0.15)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    canvas.drawLine(const Offset(4, 0), Offset(4, size.height), borderPaint);
    canvas.drawLine(Offset(size.width - 4, 0), Offset(size.width - 4, size.height), borderPaint);

    // Draw grid scanner background lines
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.02)
      ..strokeWidth = 1;
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Draw fuel cells
    final cellPaint = Paint()
      ..color = Colors.greenAccent
      ..style = PaintingStyle.fill;
    final cellGlow = Paint()
      ..color = Colors.greenAccent.withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    for (var fuel in fuelCells) {
      canvas.drawCircle(Offset(fuel.x, fuel.y), fuel.radius + 2, cellGlow);
      canvas.drawCircle(Offset(fuel.x, fuel.y), fuel.radius, cellPaint);

      // Draws battery icon inside
      final iconPaint = Paint()
        ..color = Colors.black
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(fuel.x, fuel.y - 4), Offset(fuel.x, fuel.y + 4), iconPaint);
    }

    // Draw Traffic Cars
    for (var car in traffic) {
      final rect = Rect.fromLTWH(car.x, car.y, car.width, car.height);
      final carPaint = Paint()
        ..color = car.color
        ..style = PaintingStyle.fill;
      final glowPaint = Paint()
        ..color = car.color.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

      canvas.drawRRect(RRect.fromRectAndRadius(rect.inflate(3), const Radius.circular(6)), glowPaint);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(6)), carPaint);

      // Tail lights
      final lightPaint = Paint()..color = Colors.redAccent;
      canvas.drawCircle(Offset(car.x + 6, car.y + 4), 2, lightPaint);
      canvas.drawCircle(Offset(car.x + car.width - 6, car.y + 4), 2, lightPaint);
    }

    // Draw Player Pod
    final playerRect = Rect.fromLTWH(playerX, playerY, 30, 45);
    final pPaint = Paint()
      ..shader = const LinearGradient(
        colors: [AppTheme.cyanBlue, Colors.tealAccent],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(playerRect);

    final pGlow = Paint()
      ..color = AppTheme.cyanBlue.withOpacity(0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    canvas.drawRRect(RRect.fromRectAndRadius(playerRect.inflate(4), const Radius.circular(8)), pGlow);
    canvas.drawRRect(RRect.fromRectAndRadius(playerRect, const Radius.circular(8)), pPaint);

    // Front glowing light strip
    final stripPaint = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(playerX + 5, playerY + 4, 20, 3), stripPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
