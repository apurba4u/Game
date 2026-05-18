import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/common_widgets/glass_container.dart';
import '../../../../../../core/common_widgets/cyber_button.dart';
import '../../../../core/base_game_controller.dart';
import '../../../../../auth/presentation/providers/auth_provider.dart';

enum PlayerColor { red, white }

class CheckersPiece {
  final PlayerColor color;
  bool isKing;

  CheckersPiece({required this.color, this.isKing = false});
}

class CheckersScreen extends ConsumerStatefulWidget {
  const CheckersScreen({super.key});

  @override
  ConsumerState<CheckersScreen> createState() => _CheckersScreenState();
}

class _CheckersScreenState extends ConsumerState<CheckersScreen> implements BaseGameController {
  late List<List<CheckersPiece?>> _board;
  PlayerColor _turn = PlayerColor.red; // Red is Player, White is AI
  int? _selectedRow;
  int? _selectedCol;
  List<List<int>> _validMoves = [];
  bool _isGameOver = false;
  String _winner = '';
  int _score = 0;
  bool _isPaused = false;
  bool _isVsAI = true;

  @override
  void initState() {
    super.initState();
    startGame();
  }

  @override
  void startGame() {
    setState(() {
      _board = List.generate(8, (r) {
        return List.generate(8, (c) {
          if ((r + c) % 2 == 1) {
            if (r < 3) return CheckersPiece(color: PlayerColor.white);
            if (r > 4) return CheckersPiece(color: PlayerColor.red);
          }
          return null;
        });
      });
      _turn = PlayerColor.red;
      _selectedRow = null;
      _selectedCol = null;
      _validMoves = [];
      _isGameOver = false;
      _winner = '';
      _score = 0;
      _isPaused = false;
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
        'game_name': 'Checkers',
        'highest_score': _score,
      });

      await supabase.from('game_history').insert({
        'user_id': user.id,
        'game_name': 'Checkers',
        'score': _score,
        'duration': 45,
        'win_status': _winner == 'RED',
      });
    } catch (_) {}
  }

  void _onCellTap(int r, int c) {
    if (_isGameOver || _isPaused || (_isVsAI && _turn == PlayerColor.white)) return;

    final piece = _board[r][c];

    // If selecting own piece
    if (piece != null && piece.color == _turn) {
      setState(() {
        _selectedRow = r;
        _selectedCol = c;
        _calculateValidMoves(r, c);
      });
      return;
    }

    // If tapping a valid move cell
    if (_selectedRow != null && _selectedCol != null) {
      final isMoveValid = _validMoves.any((m) => m[0] == r && m[1] == c);
      if (isMoveValid) {
        _makeMove(_selectedRow!, _selectedCol!, r, c);
        return;
      }
    }

    // Clear selection if tap is invalid
    setState(() {
      _selectedRow = null;
      _selectedCol = null;
      _validMoves = [];
    });
  }

  void _calculateValidMoves(int r, int c) {
    _validMoves = [];
    final piece = _board[r][c];
    if (piece == null) return;

    final directions = <List<int>>[];
    if (piece.isKing) {
      directions.addAll([[-1, -1], [-1, 1], [1, -1], [1, 1]]);
    } else {
      if (piece.color == PlayerColor.red) {
        directions.addAll([[-1, -1], [-1, 1]]);
      } else {
        directions.addAll([[1, -1], [1, 1]]);
      }
    }

    for (var dir in directions) {
      final targetR = r + dir[0];
      final targetC = c + dir[1];

      if (_inBounds(targetR, targetC)) {
        final targetPiece = _board[targetR][targetC];
        if (targetPiece == null) {
          _validMoves.add([targetR, targetC, 0]); // 0 means normal move
        } else if (targetPiece.color != piece.color) {
          // Jump attempt
          final jumpR = targetR + dir[0];
          final jumpC = targetC + dir[1];
          if (_inBounds(jumpR, jumpC) && _board[jumpR][jumpC] == null) {
            _validMoves.add([jumpR, jumpC, 1]); // 1 means capture jump
          }
        }
      }
    }
  }

  bool _inBounds(int r, int c) => r >= 0 && r < 8 && c >= 0 && c < 8;

  void _makeMove(int fromR, int fromC, int toR, int toC) {
    setState(() {
      final piece = _board[fromR][fromC]!;
      _board[toR][toC] = piece;
      _board[fromR][fromC] = null;

      // Handle captures
      final isJump = (toR - fromR).abs() == 2;
      if (isJump) {
        final midR = (fromR + toR) ~/ 2;
        final midC = (fromC + toC) ~/ 2;
        _board[midR][midC] = null;
        _score += 20; // 20 points per capture
      }

      // Promote to king
      if (piece.color == PlayerColor.red && toR == 0) {
        piece.isKing = true;
        _score += 50;
      } else if (piece.color == PlayerColor.white && toR == 7) {
        piece.isKing = true;
      }

      _selectedRow = null;
      _selectedCol = null;
      _validMoves = [];

      _checkGameStatus();

      if (!_isGameOver) {
        _turn = _turn == PlayerColor.red ? PlayerColor.white : PlayerColor.red;
        if (_isVsAI && _turn == PlayerColor.white) {
          Timer(const Duration(milliseconds: 800), _makeAIMove);
        }
      }
    });
  }

  void _makeAIMove() {
    if (_isGameOver || _isPaused) return;

    // AI logic: Find all pieces of color white, get their valid moves, select best one
    final aiPieces = <List<int>>[];
    for (var r = 0; r < 8; r++) {
      for (var c = 0; c < 8; c++) {
        if (_board[r][c]?.color == PlayerColor.white) {
          aiPieces.add([r, c]);
        }
      }
    }

    final allMoves = <Map<String, dynamic>>[];
    for (var pos in aiPieces) {
      _calculateValidMoves(pos[0], pos[1]);
      for (var move in _validMoves) {
        allMoves.add({
          'fromR': pos[0],
          'fromC': pos[1],
          'toR': move[0],
          'toC': move[1],
          'isCapture': move[2] == 1,
        });
      }
    }

    if (allMoves.isEmpty) {
      _winner = 'RED';
      _score += 200; // Bonus for clear win
      endGame();
      return;
    }

    // Prioritize captures
    final captures = allMoves.where((m) => m['isCapture']).toList();
    final chosenMove = captures.isNotEmpty
        ? captures[DateTime.now().millisecond % captures.length]
        : allMoves[DateTime.now().millisecond % allMoves.length];

    _makeMove(chosenMove['fromR'], chosenMove['fromC'], chosenMove['toR'], chosenMove['toC']);
  }

  void _checkGameStatus() {
    int redCount = 0;
    int whiteCount = 0;

    for (var r = 0; r < 8; r++) {
      for (var c = 0; c < 8; c++) {
        final p = _board[r][c];
        if (p != null) {
          if (p.color == PlayerColor.red) redCount++;
          if (p.color == PlayerColor.white) whiteCount++;
        }
      }
    }

    if (redCount == 0) {
      _winner = 'WHITE';
      endGame();
    } else if (whiteCount == 0) {
      _winner = 'RED';
      _score += 500; // Grand win bonus
      endGame();
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
          'NEON CHECKERS',
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
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // HUD bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _hudText('SCORE', '$_score', Colors.amber),
                  _hudText(
                    'TURN',
                    _turn == PlayerColor.red ? 'RED (YOU)' : 'WHITE (AI)',
                    _turn == PlayerColor.red ? AppTheme.electricPink : AppTheme.cyanBlue,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Game mode tabs
              if (_board.every((row) => row.every((c) => c == null || c.color == PlayerColor.red || c.color == PlayerColor.white))) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _modeTab('VS INTEL AI', true),
                    const SizedBox(width: 12),
                    _modeTab('PASS & PLAY', false),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // Main checkers grid
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.cyanBlue.withOpacity(0.3), width: 2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 8,
                      ),
                      itemCount: 64,
                      itemBuilder: (context, idx) {
                        final r = idx ~/ 8;
                        final c = idx % 8;
                        final isDarkCell = (r + c) % 2 == 1;
                        final piece = _board[r][c];
                        final isSelected = _selectedRow == r && _selectedCol == c;
                        final isValidDest = _validMoves.any((m) => m[0] == r && m[1] == c);

                        return GestureDetector(
                          onTap: () => _onCellTap(r, c),
                          child: Container(
                            color: isDarkCell
                                ? Colors.black87
                                : AppTheme.glassBackground.withOpacity(0.1),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                if (isValidDest)
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: const BoxDecoration(
                                      color: Colors.greenAccent,
                                      shape: BoxShape.circle,
                                    ),
                                  ).animate(onPlay: (c) => c.repeat(reverse: true))
                                   .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2)),
                                if (piece != null)
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: piece.color == PlayerColor.red
                                            ? [AppTheme.electricPink, Colors.red]
                                            : [AppTheme.cyanBlue, Colors.blue],
                                      ),
                                      border: Border.all(
                                        color: isSelected ? Colors.white : Colors.transparent,
                                        width: 2.0,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: piece.color == PlayerColor.red
                                              ? AppTheme.electricPink.withOpacity(0.4)
                                              : AppTheme.cyanBlue.withOpacity(0.4),
                                          blurRadius: isSelected ? 8 : 4,
                                        )
                                      ],
                                    ),
                                    child: piece.isKing
                                        ? const Icon(Icons.star, color: Colors.white, size: 14)
                                        : null,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Control panel
              if (_isGameOver || _isPaused)
                Column(
                  children: [
                    CyberButton(
                      text: _isPaused ? 'RESUME LINK' : 'RESTART SIMULATOR',
                      onPressed: () => _isPaused ? resumeGame() : restartGame(),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),

              // Game over label
              if (_isGameOver)
                Text(
                  'SIMULATION ENDED. WINNER: $_winner',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.electricPink,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: 2,
                  ),
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

  Widget _modeTab(String label, bool vsAI) {
    final active = _isVsAI == vsAI;
    return GestureDetector(
      onTap: () {
        setState(() {
          _isVsAI = vsAI;
          startGame();
        });
      },
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        borderColor: active ? AppTheme.cyanBlue : AppTheme.glassBorder,
        child: Text(
          label,
          style: TextStyle(
            color: active ? AppTheme.cyanBlue : Colors.white60,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
