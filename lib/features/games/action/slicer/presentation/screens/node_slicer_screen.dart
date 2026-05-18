import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/common_widgets/glass_container.dart';
import '../../../../../../core/common_widgets/cyber_button.dart';
import '../../../../core/base_game_controller.dart';
import '../../../../../auth/presentation/providers/auth_provider.dart';

// Ei data class ta sliceable data nodes (targets) ar fatal bombs er state record rakhe.
// Fruit Ninja game ar concept logical grid node slice theme e convert kora hoyeche.
class DataNode {
  double x;
  double y;
  double vx; // Horizontal velocity (direction and speed)
  double vy; // Vertical velocity (gravity bounce path)
  final double radius = 24.0;
  final bool isBomb; // Target ki bomb naki point element, check logic
  bool isSliced = false;
  final Color color;

  DataNode({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.isBomb,
    required this.color,
  });
}

// Slice korle je neon sparks trigger hoy, tar physical particles behavior configuration
class SlicerParticle {
  double x;
  double y;
  double vx;
  double vy;
  double alpha;
  final Color color;

  SlicerParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.alpha,
    required this.color,
  });
}

// Node Slicer: Premium touch blade game widget controller.
// User finger track motion calculation ar collision intersection detect kore.
class NodeSlicerScreen extends ConsumerStatefulWidget {
  const NodeSlicerScreen({super.key});

  @override
  ConsumerState<NodeSlicerScreen> createState() => _NodeSlicerScreenState();
}

class _NodeSlicerScreenState extends ConsumerState<NodeSlicerScreen> implements BaseGameController {
  late Timer _slicerTimer;
  List<DataNode> _nodes = [];
  List<SlicerParticle> _particles = [];
  List<Offset> _slashPath = []; // Trail of player's finger slash (swipe gesture tracker)
  bool _isGameOver = false;
  bool _isPaused = false;
  int _score = 0;
  int _lives = 3;
  final Random _rand = Random();

  @override
  void initState() {
    super.initState();
    startGame();
  }

  @override
  void dispose() {
    _slicerTimer.cancel();
    super.dispose();
  }

  @override
  void startGame() {
    setState(() {
      _nodes = [];
      _particles = [];
      _slashPath = [];
      _isGameOver = false;
      _isPaused = false;
      _score = 0;
      _lives = 3;
    });

    _slicerTimer = Timer.periodic(const Duration(milliseconds: 30), _updateNodes);
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
    _slicerTimer.cancel();
    startGame();
  }

  @override
  void endGame() {
    _slicerTimer.cancel();
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
        'game_name': 'Node Slicer',
        'highest_score': _score,
      });

      await supabase.from('game_history').insert({
        'user_id': user.id,
        'game_name': 'Node Slicer',
        'score': _score,
        'duration': 50,
        'win_status': _score > 2000,
      });
    } catch (_) {}
  }

  void _updateNodes(Timer timer) {
    if (_isPaused || _isGameOver) return;

    setState(() {
      // 1. Slash decay (remove old trail segments)
      if (_slashPath.isNotEmpty) {
        _slashPath.removeAt(0);
      }

      // 2. Physics for floating particles
      for (var p in _particles) {
        p.x += p.vx;
        p.y += p.vy;
        p.alpha -= 0.04;
      }
      _particles.removeWhere((p) => p.alpha <= 0);

      // 3. Physics for floating data nodes
      for (var node in _nodes) {
        node.x += node.vx;
        node.y += node.vy;
        node.vy += 0.15; // Gravity pull

        // Check if finger trail intersects the node (slicing)
        if (!node.isSliced && _slashPath.isNotEmpty) {
          for (var pt in _slashPath) {
            final dist = sqrt(pow(node.x - pt.dx, 2) + pow(node.y - pt.dy, 2));
            if (dist < node.radius) {
              node.isSliced = true;
              _triggerSlashExplosion(node.x, node.y, node.color);

              if (node.isBomb) {
                _lives--;
                _score = max(0, _score - 500);
                if (_lives <= 0) {
                  endGame();
                  return;
                }
              } else {
                _score += 150;
              }
              break;
            }
          }
        }
      }

      // Lose life if a normal node falls below the screen without being sliced
      for (var node in _nodes) {
        if (node.y > 600 && !node.isSliced && !node.isBomb) {
          _lives--;
          node.isSliced = true; // flag to avoid duplicate penalty
          if (_lives <= 0) {
            endGame();
            return;
          }
        }
      }

      // Clear offscreen nodes
      _nodes.removeWhere((n) => n.y > 650);

      // 4. Launch new data node packages
      if (_nodes.isEmpty || (_nodes.last.y > 350 && _rand.nextDouble() < 0.04)) {
        final startX = _rand.nextDouble() * 260.0 + 30.0;
        final vx = (_rand.nextDouble() * 4.0 - 2.0); // angle drift
        final vy = -(_rand.nextDouble() * 5.0 + 8.5); // shoot strength
        final isBomb = _rand.nextDouble() < 0.20; // 20% bomb rate

        _nodes.add(DataNode(
          x: startX,
          y: 600.0,
          vx: vx,
          vy: vy,
          isBomb: isBomb,
          color: isBomb ? AppTheme.electricPink : AppTheme.cyanBlue,
        ));
      }
    });
  }

  void _triggerSlashExplosion(double x, double y, Color color) {
    for (int i = 0; i < 18; i++) {
      final angle = _rand.nextDouble() * 2 * pi;
      final speed = _rand.nextDouble() * 6 + 2;
      _particles.add(SlicerParticle(
        x: x,
        y: y,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed,
        alpha: 1.0,
        color: color,
      ));
    }
  }

  void _onPanStart(DragStartDetails details, RenderBox box) {
    if (_isPaused || _isGameOver) return;
    final pos = box.globalToLocal(details.globalPosition);
    setState(() {
      _slashPath = [pos];
    });
  }

  void _onPanUpdate(DragUpdateDetails details, RenderBox box) {
    if (_isPaused || _isGameOver) return;
    final pos = box.globalToLocal(details.globalPosition);
    setState(() {
      _slashPath.add(pos);
      if (_slashPath.length > 8) {
        _slashPath.removeAt(0); // keep short trailing segments
      }
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _slashPath = [];
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
          'GRID NODE SLICER',
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
                  _hudColumn('DISPATCH DECRYPTED', '$_score', Colors.amber),
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

              // Slash Simulation Area
              Expanded(
                child: GlassContainer(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return GestureDetector(
                        onPanStart: (det) => _onPanStart(det, context.findRenderObject() as RenderBox),
                        onPanUpdate: (det) => _onPanUpdate(det, context.findRenderObject() as RenderBox),
                        onPanEnd: _onPanEnd,
                        child: ClipRect(
                          child: CustomPaint(
                            size: Size(constraints.maxWidth, constraints.maxHeight),
                            painter: SlicerPainter(
                              nodes: _nodes,
                              particles: _particles,
                              slashPath: _slashPath,
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
                'SLASH SWIPE DIAGONALLY ACROSS FLOATING GREEN NODES. AVOID RED BOMB CORES!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white30, fontSize: 10, letterSpacing: 1),
              ),
              const SizedBox(height: 12),

              if (_isGameOver || _isPaused)
                CyberButton(
                  text: _isPaused ? 'RESUME DECRYPTION' : 'BOOT SIMULATION CORE AGAIN',
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

class SlicerPainter extends CustomPainter {
  final List<DataNode> nodes;
  final List<SlicerParticle> particles;
  final List<Offset> slashPath;

  SlicerPainter({
    required this.nodes,
    required this.particles,
    required this.slashPath,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw grid scans background
    final gridFloor = Paint()
      ..color = Colors.white.withOpacity(0.015)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridFloor);
    }
    for (double y = 0; y < size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridFloor);
    }

    // Draw Sliced Spark Particles
    for (var p in particles) {
      final pPaint = Paint()
        ..color = p.color.withOpacity(p.alpha)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(p.x, p.y), 3.0, pPaint);
    }

    // Draw Data Nodes
    for (var node in nodes) {
      if (node.isSliced) continue;

      final nPaint = Paint()
        ..color = node.color
        ..style = PaintingStyle.fill;
      final glowPaint = Paint()
        ..color = node.color.withOpacity(0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

      // Draw cyber circuit nodes
      canvas.drawCircle(Offset(node.x, node.y), node.radius + 3, glowPaint);
      canvas.drawCircle(Offset(node.x, node.y), node.radius, nPaint);

      // Draw inside details
      final detailPaint = Paint()
        ..color = Colors.black87
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(Offset(node.x, node.y), node.radius * 0.5, detailPaint);
    }

    // Draw Slash Path Trail (Slick glow line!)
    if (slashPath.length >= 2) {
      final trailPaint = Paint()
        ..color = AppTheme.cyanBlue
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      final trailGlow = Paint()
        ..color = AppTheme.cyanBlue.withOpacity(0.6)
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
        ..style = PaintingStyle.stroke;

      final path = Path();
      path.moveTo(slashPath.first.dx, slashPath.first.dy);
      for (int i = 1; i < slashPath.length; i++) {
        path.lineTo(slashPath[i].dx, slashPath[i].dy);
      }

      canvas.drawPath(path, trailGlow);
      canvas.drawPath(path, trailPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
