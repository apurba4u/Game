import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/common_widgets/cyber_button.dart';
import '../../../../core/base_game_controller.dart';
import '../../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../../../core/audio/audio_manager.dart';

class MemoryGameScreen extends ConsumerStatefulWidget {
  const MemoryGameScreen({super.key});

  @override
  ConsumerState<MemoryGameScreen> createState() => _MemoryGameScreenState();
}

class _MemoryGameScreenState extends ConsumerState<MemoryGameScreen>
    implements BaseGameController {
  final List<String> _cardSymbols = [
    '⚡',
    '⚡',
    '🛸',
    '🛸',
    '👾',
    '👾',
    '💾',
    '💾',
    '🔌',
    '🔌',
    '🔋',
    '🔋',
    '🛡️',
    '🛡️',
    '🛰️',
    '🛰️',
  ];

  List<String> _shuffledCards = [];
  List<bool> _cardFlips = [];
  List<int> _selectedIndices = [];
  int _score = 0;
  int _pairsFound = 0;
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
      _shuffledCards = List.from(_cardSymbols)..shuffle();
      _cardFlips = List.filled(16, false);
      _selectedIndices = [];
      _score = 0;
      _pairsFound = 0;
      _isPaused = false;
      _isGameOver = false;
    });
  }

  void _onCardTap(int index) {
    if (_isPaused ||
        _isGameOver ||
        _cardFlips[index] ||
        _selectedIndices.length >= 2) {
      return;
    }

    setState(() {
      _cardFlips[index] = true;
      _selectedIndices.add(index);
    });

    AudioManager.instance.playSFX('sfx/card_flip.mp3');

    if (_selectedIndices.length == 2) {
      final index1 = _selectedIndices[0];
      final index2 = _selectedIndices[1];

      if (_shuffledCards[index1] == _shuffledCards[index2]) {
        // Match!
        setState(() {
          _score += 150;
          _pairsFound++;
          _selectedIndices = [];
          if (_pairsFound == 8) {
            endGame();
          }
        });
        AudioManager.instance.playSFX('sfx/match.mp3');
      } else {
        // Mis-match! Flip back down after 1s
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted) {
            setState(() {
              _cardFlips[index1] = false;
              _cardFlips[index2] = false;
              _selectedIndices = [];
              _score = (_score - 20).clamp(0, 999999);
            });
          }
        });
      }
    }
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
    AudioManager.instance.playSFX('sfx/complete.mp3');
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
        'game_name': 'Memory Cards',
        'highest_score': _score,
      });

      await supabase.from('game_history').insert({
        'user_id': user.id,
        'game_name': 'Memory Cards',
        'score': _score,
        'duration': 50,
        'win_status': true,
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
          'MEMORY MATRIX',
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

              // Cards Grid
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                  itemCount: 16,
                  itemBuilder: (context, index) {
                    final flipped = _cardFlips[index];
                    return GestureDetector(
                      onTap: () => _onCardTap(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: flipped
                                ? AppTheme.cyanBlue
                                : AppTheme.glassBorder,
                            width: 1.5,
                          ),
                          color: flipped
                              ? AppTheme.cyanBlue.withOpacity(0.1)
                              : AppTheme.glassBackground,
                        ),
                        child: Center(
                          child: Text(
                            flipped ? _shuffledCards[index] : '?',
                            style: TextStyle(
                              fontSize: flipped ? 28 : 22,
                              fontWeight: FontWeight.bold,
                              color: flipped ? Colors.white : Colors.white24,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              if (_isGameOver || _isPaused)
                CyberButton(
                  text: _isPaused ? 'RESUME MATRIX' : 'REBOOT SYSTEM',
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
