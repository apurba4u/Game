import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/common_widgets/glass_container.dart';
import '../../../../../../core/common_widgets/cyber_button.dart';
import '../../../../core/base_game_controller.dart';
import '../../../../../auth/presentation/providers/auth_provider.dart';

class RockPaperScissorsScreen extends ConsumerStatefulWidget {
  const RockPaperScissorsScreen({super.key});

  @override
  ConsumerState<RockPaperScissorsScreen> createState() =>
      _RockPaperScissorsScreenState();
}

class _RockPaperScissorsScreenState
    extends ConsumerState<RockPaperScissorsScreen>
    implements BaseGameController {
  final List<String> _choices = ['Rock', 'Paper', 'Scissors'];
  final List<IconData> _icons = [
    Icons.back_hand,
    Icons.description,
    Icons.content_cut,
  ];

  String _playerChoice = '';
  String _computerChoice = '';
  String _result = 'CHOOSE YOUR WEAPON';
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
      _playerChoice = '';
      _computerChoice = '';
      _result = 'CHOOSE YOUR WEAPON';
      _score = 0;
      _isPaused = false;
      _isGameOver = false;
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
        'game_name': 'Rock Paper Scissors',
        'highest_score': _score,
      });

      await supabase.from('game_history').insert({
        'user_id': user.id,
        'game_name': 'Rock Paper Scissors',
        'score': _score,
        'duration': 15,
        'win_status': _score > 0,
      });
    } catch (e) {
      // Handle offline or errors
    }
  }

  void _play(String playerChoice) {
    if (_isPaused || _isGameOver) return;

    final random = Random();
    final computerChoice = _choices[random.nextInt(3)];

    setState(() {
      _playerChoice = playerChoice;
      _computerChoice = computerChoice;

      if (playerChoice == computerChoice) {
        _result = "IT'S A DRAW";
      } else if ((playerChoice == 'Rock' && computerChoice == 'Scissors') ||
          (playerChoice == 'Paper' && computerChoice == 'Rock') ||
          (playerChoice == 'Scissors' && computerChoice == 'Paper')) {
        _result = 'YOU WON!';
        _score += 50;
      } else {
        _result = 'YOU LOST!';
        endGame();
      }
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
          'ROCK PAPER SCISSORS',
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
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
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
              Text(
                _result,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _result == 'YOU WON!'
                      ? Colors.greenAccent
                      : (_result == 'YOU LOST!'
                            ? AppTheme.electricPink
                            : Colors.white),
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 40),
              if (_playerChoice.isNotEmpty)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        const Text(
                          'YOU',
                          style: TextStyle(
                            color: Colors.white60,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Icon(
                          _icons[_choices.indexOf(_playerChoice)],
                          size: 64,
                          color: AppTheme.cyanBlue,
                        ),
                      ],
                    ),
                    const Text(
                      'VS',
                      style: TextStyle(
                        color: Colors.white30,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Column(
                      children: [
                        const Text(
                          'COMPUTER',
                          style: TextStyle(
                            color: Colors.white60,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Icon(
                          _icons[_choices.indexOf(_computerChoice)],
                          size: 64,
                          color: AppTheme.electricPink,
                        ),
                      ],
                    ),
                  ],
                ),
              const Spacer(),
              if (!_isGameOver && !_isPaused)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(3, (index) {
                    final choice = _choices[index];
                    final icon = _icons[index];
                    return GestureDetector(
                      onTap: () => _play(choice),
                      child: GlassContainer(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Icon(icon, size: 36, color: AppTheme.cyanBlue),
                            const SizedBox(height: 8),
                            Text(
                              choice.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              if (_isGameOver || _isPaused)
                CyberButton(
                  text: _isPaused ? 'RESUME GAME' : 'PLAY AGAIN',
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
