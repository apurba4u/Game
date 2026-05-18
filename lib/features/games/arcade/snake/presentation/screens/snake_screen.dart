import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/common_widgets/glass_container.dart';
import '../../../../../../core/common_widgets/cyber_button.dart';
import '../../../../core/base_game_controller.dart';
import '../../../../../auth/presentation/providers/auth_provider.dart';

class SnakeScreen extends ConsumerStatefulWidget {
  const SnakeScreen({super.key});

  @override
  ConsumerState<SnakeScreen> createState() => _SnakeScreenState();
}

class _SnakeScreenState extends ConsumerState<SnakeScreen>
    implements BaseGameController {
  // Grid settings
  static const int _gridSize = 20;

  List<Offset> _snake = [];
  Offset _food = const Offset(0, 0);
  String _direction = 'UP';
  Timer? _timer;
  int _score = 0;
  bool _isPaused = false;
  bool _isGameOver = false;

  @override
  void initState() {
    super.initState();
    startGame();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  void startGame() {
    setState(() {
      _snake = [
        const Offset(10, 10),
        const Offset(10, 11),
        const Offset(10, 12),
      ];
      _direction = 'UP';
      _score = 0;
      _isPaused = false;
      _isGameOver = false;
      _generateFood();
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      if (!_isPaused && !_isGameOver) {
        _moveSnake();
      }
    });
  }

  void _generateFood() {
    final random = Random();
    Offset newFood;
    do {
      newFood = Offset(
        random.nextInt(_gridSize).toDouble(),
        random.nextInt(_gridSize).toDouble(),
      );
    } while (_snake.contains(newFood));

    setState(() {
      _food = newFood;
    });
  }

  void _moveSnake() {
    setState(() {
      final head = _snake.first;
      Offset newHead;

      switch (_direction) {
        case 'UP':
          newHead = Offset(head.dx, head.dy - 1);
          break;
        case 'DOWN':
          newHead = Offset(head.dx, head.dy + 1);
          break;
        case 'LEFT':
          newHead = Offset(head.dx - 1, head.dy);
          break;
        case 'RIGHT':
          newHead = Offset(head.dx + 1, head.dy);
          break;
        default:
          newHead = head;
      }

      // Check collision with walls or self
      if (newHead.dx < 0 ||
          newHead.dx >= _gridSize ||
          newHead.dy < 0 ||
          newHead.dy >= _gridSize ||
          _snake.contains(newHead)) {
        endGame();
        return;
      }

      _snake.insert(0, newHead);

      // Check food consumption
      if (newHead == _food) {
        _score += 10;
        _generateFood();
      } else {
        _snake.removeLast();
      }
    });
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
    startGame();
  }

  @override
  void endGame() {
    _timer?.cancel();
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
        'game_name': 'Snake Game',
        'highest_score': _score,
      });

      await supabase.from('game_history').insert({
        'user_id': user.id,
        'game_name': 'Snake Game',
        'score': _score,
        'duration': 45,
        'win_status': _score > 100, // Arbiter win condition
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
          'NEON SNAKE',
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

              // Grid Panel
              Expanded(
                child: GlassContainer(
                  padding: const EdgeInsets.all(4),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: CustomPaint(
                      painter: SnakePainter(
                        snake: _snake,
                        food: _food,
                        gridSize: _gridSize,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Responsive On-screen D-Pad controllers for mobile
              if (!_isGameOver && !_isPaused)
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.keyboard_arrow_up,
                        size: 40,
                        color: AppTheme.cyanBlue,
                      ),
                      onPressed: () => {
                        if (_direction != 'DOWN') _direction = 'UP',
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.keyboard_arrow_left,
                            size: 40,
                            color: AppTheme.cyanBlue,
                          ),
                          onPressed: () => {
                            if (_direction != 'RIGHT') _direction = 'LEFT',
                          },
                        ),
                        const SizedBox(width: 48),
                        IconButton(
                          icon: const Icon(
                            Icons.keyboard_arrow_right,
                            size: 40,
                            color: AppTheme.cyanBlue,
                          ),
                          onPressed: () => {
                            if (_direction != 'LEFT') _direction = 'RIGHT',
                          },
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        size: 40,
                        color: AppTheme.cyanBlue,
                      ),
                      onPressed: () => {
                        if (_direction != 'UP') _direction = 'DOWN',
                      },
                    ),
                  ],
                ),

              if (_isGameOver || _isPaused)
                CyberButton(
                  text: _isPaused ? 'RESUME GAME' : 'RESTART CORE',
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
    );
  }
}

class SnakePainter extends CustomPainter {
  final List<Offset> snake;
  final Offset food;
  final int gridSize;

  SnakePainter({
    required this.snake,
    required this.food,
    required this.gridSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cellSize = size.width / gridSize;

    // Draw snake body
    final bodyPaint = Paint()..color = AppTheme.neonPurple;
    final headPaint = Paint()..color = AppTheme.cyanBlue;

    for (var i = 0; i < snake.length; i++) {
      final node = snake[i];
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            node.dx * cellSize,
            node.dy * cellSize,
            cellSize - 1,
            cellSize - 1,
          ),
          const Radius.circular(4),
        ),
        i == 0 ? headPaint : bodyPaint,
      );
    }

    // Draw food
    final foodPaint = Paint()..color = AppTheme.electricPink;
    canvas.drawCircle(
      Offset(
        (food.dx * cellSize) + (cellSize / 2),
        (food.dy * cellSize) + (cellSize / 2),
      ),
      cellSize / 2 - 1,
      foodPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
