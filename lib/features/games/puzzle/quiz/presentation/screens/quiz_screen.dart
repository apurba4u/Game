import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/common_widgets/glass_container.dart';
import '../../../../../../core/common_widgets/cyber_button.dart';
import '../../../../core/base_game_controller.dart';
import '../../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../multiplayer/data/services/p2p/sockets/p2p_network_manager.dart';
import '../../../../multiplayer/data/services/p2p/protocol/p2p_packet.dart';
import '../../../../multiplayer/data/services/p2p/protocol/p2p_session_models.dart';
import '../../../../multiplayer/data/services/p2p/diagnostics/diagnostics_overlay.dart';

enum QuizGameMode {
  singlePlayer,
  p2pMultiplayer,
}

class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({super.key});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen>
    implements BaseGameController {
  
  final List<Map<String, dynamic>> _questions = const [
    {
      'question': 'Which database is natively integrated as the core backend of GameHub?',
      'options': ['MongoDB', 'Supabase', 'Firebase', 'SQLite'],
      'answerIndex': 1,
    },
    {
      'question': 'What is the main state management framework deployed in this application?',
      'options': ['BLoC', 'Redux', 'Riverpod', 'Provider'],
      'answerIndex': 2,
    },
    {
      'question': 'What engine powers Flame complex games inside Flutter?',
      'options': ['Unity', 'Flame', 'Unreal', 'Godot'],
      'answerIndex': 1,
    },
    {
      'question': 'Which protocol is utilized for dynamic real-time P2P peer discovery?',
      'options': ['HTTP POST', 'FTP Uplink', 'UDP Multicast & Broadcast', 'SMTP SSL'],
      'answerIndex': 2,
    },
  ];

  QuizGameMode _mode = QuizGameMode.singlePlayer;
  int _currentQuestionIndex = 0;
  int _score = 0;
  bool _isPaused = false;
  bool _isGameOver = false;
  int? _selectedAnswerIndex;

  // P2P Specific Variables
  final P2PNetworkManager _p2p = P2PNetworkManager.instance;
  StreamSubscription? _p2pPacketSub;
  StreamSubscription? _p2pRoomSub;
  StreamSubscription? _p2pDiscoverySub;
  bool _isConnecting = false;
  List<MultiplayerRoom> _rooms = [];
  
  // Real-time opponent tracking
  int _opponentScore = 0;
  int _opponentQuestionIdx = 0;
  String _opponentUsername = 'OPPONENT';

  @override
  void initState() {
    super.initState();
    startGame();
    _setupP2PListeners();
  }

  void _setupP2PListeners() {
    _p2pPacketSub = _p2p.messageStream.listen((packet) {
      if (packet.game == 'quiz') {
        if (packet.type == 'answer') {
          setState(() {
            _opponentScore = packet.payload['score'] as int;
            _opponentQuestionIdx = packet.payload['questionIdx'] as int;
            
            // If opponent finished and we finished, trigger end game
            if (_opponentQuestionIdx >= _questions.length - 1 && _currentQuestionIndex >= _questions.length - 1) {
              endGame();
            }
          });
        } else if (packet.type == 'restart') {
          _restartLocalBoard();
        }
      }
    });

    _p2pRoomSub = _p2p.roomStream.listen((room) {
      if (room != null && mounted) {
        setState(() {
          _mode = QuizGameMode.p2pMultiplayer;
          final opp = room.players.firstWhere(
            (p) => p.id != _p2p.localPlayerId,
            orElse: () => const PlayerState(id: '', username: 'PEER'),
          );
          _opponentUsername = opp.username;
        });
      }
    });

    _p2pDiscoverySub = _p2p.discoveryStream.listen((roomList) {
      if (mounted) {
        setState(() {
          _rooms = roomList;
        });
      }
    });
  }

  @override
  void dispose() {
    _p2pPacketSub?.cancel();
    _p2pRoomSub?.cancel();
    _p2pDiscoverySub?.cancel();
    _p2p.stopDiscovery();
    super.dispose();
  }

  @override
  void startGame() {
    setState(() {
      _currentQuestionIndex = 0;
      _score = 0;
      _opponentScore = 0;
      _opponentQuestionIdx = 0;
      _isPaused = false;
      _isGameOver = false;
      _selectedAnswerIndex = null;
    });
  }

  void _restartLocalBoard() {
    setState(() {
      _currentQuestionIndex = 0;
      _score = 0;
      _opponentScore = 0;
      _opponentQuestionIdx = 0;
      _isPaused = false;
      _isGameOver = false;
      _selectedAnswerIndex = null;
    });
  }

  @override
  void pauseGame() {
    setState(() => _isPaused = true);
  }

  @override
  void resumeGame() {
    setState(() => _isPaused = false);
  }

  @override
  void restartGame() {
    if (_mode == QuizGameMode.p2pMultiplayer) {
      _p2p.sendPacket(P2PPacket(
        type: 'restart',
        game: 'quiz',
        payload: {},
        senderId: _p2p.localPlayerId!,
      ));
      _restartLocalBoard();
    } else {
      startGame();
    }
  }

  @override
  void endGame() {
    setState(() => _isGameOver = true);
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
        'game_name': 'Quiz Game',
        'highest_score': _score,
      });

      await supabase.from('game_history').insert({
        'user_id': user.id,
        'game_name': 'Quiz Game',
        'score': _score,
        'duration': 30,
        'win_status': _mode == QuizGameMode.p2pMultiplayer ? (_score > _opponentScore) : (_score == _questions.length * 10),
      });
    } catch (_) {}
  }

  // ----------------------------------------------------
  // Answering Logic
  // ----------------------------------------------------

  void _submitAnswer(int optionIndex) {
    if (_isPaused || _isGameOver || _selectedAnswerIndex != null) return;

    setState(() {
      _selectedAnswerIndex = optionIndex;
      final correctIndex = _questions[_currentQuestionIndex]['answerIndex'];
      if (optionIndex == correctIndex) {
        _score += 10;
      }
    });

    // Send updated stats to opponent
    if (_mode == QuizGameMode.p2pMultiplayer) {
      _p2p.sendPacket(P2PPacket(
        type: 'answer',
        game: 'quiz',
        payload: {
          'score': _score,
          'questionIdx': _currentQuestionIndex,
        },
        senderId: _p2p.localPlayerId!,
      ));
    }

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _selectedAnswerIndex = null;
          if (_currentQuestionIndex < _questions.length - 1) {
            _currentQuestionIndex++;
          } else {
            // Wait for opponent if in P2P mode
            if (_mode == QuizGameMode.p2pMultiplayer) {
              if (_opponentQuestionIdx >= _questions.length - 1) {
                endGame();
              }
            } else {
              endGame();
            }
          }
        });
      }
    });
  }

  // ----------------------------------------------------
  // Room lobbies handlers
  // ----------------------------------------------------

  Future<void> _hostRoom() async {
    final user = ref.read(currentUserProvider);
    final username = user?.email?.split('@').first ?? 'HOST_QUIZ';
    setState(() => _isConnecting = true);

    try {
      await _p2p.createRoom(username, 'quiz');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lobby failure: $e')),
      );
    } finally {
      setState(() => _isConnecting = false);
    }
  }

  void _scanRooms() {
    _p2p.startDiscovery();
  }

  Future<void> _joinRoom(MultiplayerRoom room) async {
    final user = ref.read(currentUserProvider);
    final username = user?.email?.split('@').first ?? 'PEER_QUIZ';
    setState(() => _isConnecting = true);

    try {
      await _p2p.joinRoom(username, room);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed linking socket: $e')),
      );
    } finally {
      setState(() => _isConnecting = false);
    }
  }

  // ----------------------------------------------------
  // Builds UI
  // ----------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final currentQuestion = _questions[_currentQuestionIndex];
    final activeRoom = _p2p.activeRoom;

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'TRIVIA TERMINAL',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2),
        ),
        actions: [
          if (_mode == QuizGameMode.p2pMultiplayer)
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: Center(
                child: DiagnosticsOverlay(
                  latencyMs: _p2p.currentLatency,
                  connectionType: _p2p.activeRoom?.ipAddress == 'Supabase-Relay'
                      ? 'Relay Server'
                      : 'P2P Net',
                ),
              ),
            ),
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
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Selector Tab when offline
              if (activeRoom == null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _modeTab('SINGLE PLAYER', QuizGameMode.singlePlayer),
                    const SizedBox(width: 12),
                    _modeTab('P2P QUIZ BATTLE', QuizGameMode.p2pMultiplayer),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // 2. Room signallers / scan UI
              if (_mode == QuizGameMode.p2pMultiplayer && activeRoom == null) ...[
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isConnecting)
                        const CircularProgressIndicator(color: AppTheme.cyanBlue)
                      else ...[
                        CyberButton(
                          text: 'HOST BATTLE LOBBY',
                          onPressed: _hostRoom,
                        ),
                        const SizedBox(height: 16),
                        CyberButton(
                          text: 'SCAN LOCAL NETWORKS',
                          onPressed: _scanRooms,
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'SPOTTED HOSTS:',
                          style: TextStyle(
                            color: AppTheme.cyanBlue,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_rooms.isEmpty)
                          const Text(
                            'NO LIVE LOBBY SIGNALS DETECTED. ENCRYPT ONE!',
                            style: TextStyle(color: Colors.white30, fontSize: 11),
                          )
                        else
                          Expanded(
                            child: ListView.builder(
                              itemCount: _rooms.length,
                              itemBuilder: (context, idx) {
                                final rm = _rooms[idx];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: GestureDetector(
                                    onTap: () => _joinRoom(rm),
                                    child: GlassContainer(
                                      child: ListTile(
                                        title: Text(
                                          'ROOM ${rm.roomId}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        subtitle: Text(
                                          'Host: ${rm.players.first.username} | Port: ${rm.port}',
                                          style: const TextStyle(color: Colors.white54, fontSize: 11),
                                        ),
                                        trailing: const Icon(
                                          Icons.wifi,
                                          color: AppTheme.cyanBlue,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ] else ...[
                // Concurrent scoreboard in P2P Battle mode
                if (_mode == QuizGameMode.p2pMultiplayer && activeRoom != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('YOU', style: TextStyle(color: AppTheme.neonPurple, fontSize: 9, fontWeight: FontWeight.bold)),
                          Text('SCORE: $_score', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          Text('Q: ${_currentQuestionIndex + 1}/${_questions.length}', style: const TextStyle(color: Colors.white54, fontSize: 10)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(_opponentUsername.toUpperCase(), style: const TextStyle(color: AppTheme.cyanBlue, fontSize: 9, fontWeight: FontWeight.bold)),
                          Text('SCORE: $_opponentScore', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          Text('Q: ${_mathMin(_opponentQuestionIdx + 1, _questions.length)}/${_questions.length}', style: const TextStyle(color: Colors.white54, fontSize: 10)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ] else ...[
                  Text(
                    'QUESTION ${_currentQuestionIndex + 1}/${_questions.length}',
                    style: const TextStyle(
                      color: AppTheme.cyanBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'SCORE: $_score',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                ],

                // Question card panel
                Expanded(
                  child: GlassContainer(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Text(
                        currentQuestion['question'],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Option Choice columns
                if (!_isGameOver && !_isPaused)
                  Column(
                    children: List.generate(4, (index) {
                      final option = currentQuestion['options'][index];
                      final isSelected = _selectedAnswerIndex == index;
                      final correctIndex = currentQuestion['answerIndex'];

                      Color borderColor = AppTheme.glassBorder;
                      if (_selectedAnswerIndex != null) {
                        if (index == correctIndex) {
                          borderColor = Colors.greenAccent;
                        } else if (isSelected) {
                          borderColor = AppTheme.electricPink;
                        }
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        width: double.infinity,
                        child: GestureDetector(
                          onTap: () => _submitAnswer(index),
                          child: GlassContainer(
                            borderColor: borderColor,
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 18,
                            ),
                            child: Text(
                              option,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),

                if (_isGameOver || _isPaused)
                  Column(
                    children: [
                      CyberButton(
                        text: _isPaused ? 'RESUME LINK' : 'PLAY AGAIN',
                        onPressed: () {
                          if (_isPaused) {
                            resumeGame();
                          } else {
                            restartGame();
                          }
                        },
                      ),
                      if (_mode == QuizGameMode.p2pMultiplayer) ...[
                        const SizedBox(height: 8),
                        CyberButton(
                          text: 'LEAVE ROOM',
                          onPressed: () {
                            _p2p.leaveRoom();
                            setState(() {
                              _mode = QuizGameMode.singlePlayer;
                              startGame();
                            });
                          },
                        ),
                      ],
                    ],
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  int _mathMin(int a, int b) => a < b ? a : b;

  Widget _modeTab(String label, QuizGameMode md) {
    final active = _mode == md;
    return GestureDetector(
      onTap: () {
        setState(() {
          _mode = md;
          startGame();
        });
      },
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        borderColor: active ? AppTheme.cyanBlue : AppTheme.glassBorder,
        child: Text(
          label,
          style: TextStyle(
            color: active ? AppTheme.cyanBlue : Colors.white54,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}
