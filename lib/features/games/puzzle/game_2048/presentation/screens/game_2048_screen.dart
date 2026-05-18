import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/common_widgets/glass_container.dart';
import '../../../../../../core/common_widgets/cyber_button.dart';
import '../../../../core/base_game_controller.dart';
import '../../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../../../core/audio/audio_manager.dart';

class Game2048Screen extends ConsumerStatefulWidget {
  const Game2048Screen({super.key});

  @override
  ConsumerState<Game2048Screen> createState() => _Game2048ScreenState();
}

class _Game2048ScreenState extends ConsumerState<Game2048Screen>
    implements BaseGameController {
  List<List<int>> _grid = List.generate(4, (_) => List.filled(4, 0));
  int _score = 0;
  bool _isPaused = false;
  bool _isGameOver = false;

  @override
  void initState() {
    super.initState();
    startGame();
  }

  @override
  void startGame() {
    setState(() {
      _grid = List.generate(4, (_) => List.filled(4, 0));
      _score = 0;
      _isPaused = false;
      _isGameOver = false;
      _addNewTile();
      _addNewTile();
    });
  }

  void _addNewTile() {
    final emptyCells = <Point<int>>[];
    for (var r = 0; r < 4; r++) {
      for (var c = 0; c < 4; c++) {
        if (_grid[r][c] == 0) emptyCells.add(Point(r, c));
      }
    }
    if (emptyCells.isEmpty) return;

    final random = Random();
    final cell = emptyCells[random.nextInt(emptyCells.length)];
    _grid[cell.x][cell.y] = random.nextDouble() < 0.9 ? 2 : 4;
  }

  void _handleSwipe(DragEndDetails details) {
    if (_isPaused || _isGameOver) return;

    final dx = details.velocity.pixelsPerSecond.dx;
    final dy = details.velocity.pixelsPerSecond.dy;

    if (dx.abs() > dy.abs()) {
      if (dx > 0) {
        _slideRight();
      } else {
        _slideLeft();
      }
    } else {
      if (dy > 0) {
        _slideDown();
      } else {
        _slideUp();
      }
    }

    _checkGameOver();
  }

  void _slideLeft() {
    bool moved = false;
    for (var r = 0; r < 4; r++) {
      final original = List<int>.from(_grid[r]);
      final row = _grid[r].where((val) => val != 0).toList();
      final newRow = <int>[];

      int i = 0;
      while (i < row.length) {
        if (i + 1 < row.length && row[i] == row[i + 1]) {
          newRow.add(row[i] * 2);
          _score += row[i] * 2;
          i += 2;
        } else {
          newRow.add(row[i]);
          i++;
        }
      }
      while (newRow.length < 4) {
        newRow.add(0);
      }
      _grid[r] = newRow;
      if (original.toString() != newRow.toString()) moved = true;
    }
    if (moved) {
      setState(() {
        _addNewTile();
        AudioManager.instance.playSFX('sfx/slide.mp3');
      });
    }
  }

  void _slideRight() {
    bool moved = false;
    for (var r = 0; r < 4; r++) {
      final original = List<int>.from(_grid[r]);
      final row = _grid[r].where((val) => val != 0).toList().reversed.toList();
      final newRow = <int>[];

      int i = 0;
      while (i < row.length) {
        if (i + 1 < row.length && row[i] == row[i + 1]) {
          newRow.add(row[i] * 2);
          _score += row[i] * 2;
          i += 2;
        } else {
          newRow.add(row[i]);
          i++;
        }
      }
      while (newRow.length < 4) {
        newRow.add(0);
      }
      _grid[r] = newRow.reversed.toList();
      if (original.toString() != _grid[r].toString()) moved = true;
    }
    if (moved) {
      setState(() {
        _addNewTile();
        AudioManager.instance.playSFX('sfx/slide.mp3');
      });
    }
  }

  void _slideUp() {
    bool moved = false;
    for (var c = 0; c < 4; c++) {
      final col = <int>[];
      for (var r = 0; r < 4; r++) {
        if (_grid[r][c] != 0) col.add(_grid[r][c]);
      }

      final newCol = <int>[];
      int i = 0;
      while (i < col.length) {
        if (i + 1 < col.length && col[i] == col[i + 1]) {
          newCol.add(col[i] * 2);
          _score += col[i] * 2;
          i += 2;
        } else {
          newCol.add(col[i]);
          i++;
        }
      }
      while (newCol.length < 4) {
        newCol.add(0);
      }

      for (var r = 0; r < 4; r++) {
        if (_grid[r][c] != newCol[r]) moved = true;
        _grid[r][c] = newCol[r];
      }
    }
    if (moved) {
      setState(() {
        _addNewTile();
        AudioManager.instance.playSFX('sfx/slide.mp3');
      });
    }
  }

  void _slideDown() {
    bool moved = false;
    for (var c = 0; c < 4; c++) {
      final col = <int>[];
      for (var r = 3; r >= 0; r--) {
        if (_grid[r][c] != 0) col.add(_grid[r][c]);
      }

      final newCol = <int>[];
      int i = 0;
      while (i < col.length) {
        if (i + 1 < col.length && col[i] == col[i + 1]) {
          newCol.add(col[i] * 2);
          _score += col[i] * 2;
          i += 2;
        } else {
          newCol.add(col[i]);
          i++;
        }
      }
      while (newCol.length < 4) {
        newCol.add(0);
      }

      final reversedCol = newCol.reversed.toList();
      for (var r = 0; r < 4; r++) {
        if (_grid[r][c] != reversedCol[r]) moved = true;
        _grid[r][c] = reversedCol[r];
      }
    }
    if (moved) {
      setState(() {
        _addNewTile();
        AudioManager.instance.playSFX('sfx/slide.mp3');
      });
    }
  }

  void _checkGameOver() {
    for (var r = 0; r < 4; r++) {
      for (var c = 0; c < 4; c++) {
        if (_grid[r][c] == 0) return;
        if (r + 1 < 4 && _grid[r][c] == _grid[r + 1][c]) return;
        if (c + 1 < 4 && _grid[r][c] == _grid[r][c + 1]) return;
      }
    }
    endGame();
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
    setState(() {
      _isGameOver = true;
    });
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
        'game_name': '2048 Game',
        'highest_score': _score,
      });

      await supabase.from('game_history').insert({
        'user_id': user.id,
        'game_name': '2048 Game',
        'score': _score,
        'duration': 60,
        'win_status': _score > 2048,
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
          '2048 MATRIX',
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
              const SizedBox(height: 20),

              // 2048 Swipe Board
              Expanded(
                child: GestureDetector(
                  onHorizontalDragEnd: _handleSwipe,
                  onVerticalDragEnd: _handleSwipe,
                  child: GlassContainer(
                    padding: const EdgeInsets.all(8),
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                          ),
                      itemCount: 16,
                      itemBuilder: (context, index) {
                        final r = index ~/ 4;
                        final c = index % 4;
                        final value = _grid[r][c];

                        Color cellColor = AppTheme.glassBackground;
                        Color textColor = Colors.white70;
                        if (value > 0) {
                          cellColor = AppTheme.neonPurple.withOpacity(
                            (log(value) / log(2048)).clamp(0.1, 0.9),
                          );
                          textColor = Colors.white;
                        }

                        return Container(
                          decoration: BoxDecoration(
                            color: cellColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: value > 0
                                  ? AppTheme.cyanBlue
                                  : AppTheme.glassBorder,
                              width: value > 0 ? 1.5 : 1.0,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              value > 0 ? '$value' : '',
                              style: TextStyle(
                                fontSize: value > 999 ? 16 : 22,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              if (_isGameOver || _isPaused)
                CyberButton(
                  text: _isPaused ? 'RESUME MATRIX' : 'PLAY AGAIN',
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
