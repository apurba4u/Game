import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/common_widgets/glass_container.dart';
import '../../../../../../core/common_widgets/cyber_button.dart';
import '../../../../core/base_game_controller.dart';
import '../../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../../../core/audio/audio_manager.dart';
import '../../../../multiplayer/data/services/p2p/sockets/p2p_network_manager.dart';
import '../../../../multiplayer/data/services/p2p/protocol/p2p_packet.dart';
import '../../../../multiplayer/data/services/p2p/protocol/p2p_session_models.dart';
import '../../../../multiplayer/data/services/p2p/diagnostics/diagnostics_overlay.dart';

enum PongGameMode {
  soloAI,
  p2pBattle,
}

class PongScreen extends ConsumerStatefulWidget {
  const PongScreen({super.key});

  @override
  ConsumerState<PongScreen> createState() => _PongScreenState();
}

class _PongScreenState extends ConsumerState<PongScreen>
    with SingleTickerProviderStateMixin
    implements BaseGameController {
  
  late AnimationController _ticker;

  PongGameMode _mode = PongGameMode.soloAI;

  // Game coordinates (-1.0 to 1.0)
  double _ballX = 0;
  double _ballY = 0;
  double _ballDX = 0.02;
  double _ballDY = 0.01;

  double _playerY = 0; // Left paddle (Local Player when Host or Solo)
  double _opponentY = 0; // Right paddle (AI or Client Player)

  final double _paddleHeight = 0.4;
  final double _paddleWidth = 0.04;
  final double _paddleSpeed = 0.08;

  int _playerScore = 0;
  int _opponentScore = 0;
  bool _isPaused = false;
  bool _isGameOver = false;

  // P2P Specific Variables
  final P2PNetworkManager _p2p = P2PNetworkManager.instance;
  StreamSubscription? _p2pPacketSub;
  StreamSubscription? _p2pRoomSub;
  StreamSubscription? _p2pDiscoverySub;
  bool _isConnecting = false;
  List<MultiplayerRoom> _rooms = [];
  String _opponentUsername = 'OPPONENT';

  // Client Interpolation Targets
  double _targetBallX = 0;
  double _targetBallY = 0;
  double _targetOpponentY = 0;

  Timer? _stateBroadcastTimer;

  @override
  void initState() {
    super.initState();
    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _ticker.addListener(_gameTick);
    startGame();
    _setupP2PListeners();
  }

  void _setupP2PListeners() {
    _p2pPacketSub = _p2p.messageStream.listen((packet) {
      if (packet.game == 'pong') {
        if (packet.type == 'paddle_move') {
          // If we are Host, we receive Client paddle coordinate update
          if (_p2p.isHost) {
            setState(() {
              _opponentY = (packet.payload['paddleY'] as num).toDouble();
            });
          }
        } else if (packet.type == 'state_sync') {
          // If we are Client, we receive authoritative coordinates from Host
          if (!_p2p.isHost) {
            final payload = packet.payload;
            setState(() {
              _targetBallX = (payload['ballX'] as num).toDouble();
              _targetBallY = (payload['ballY'] as num).toDouble();
              _targetOpponentY = (payload['hostPaddleY'] as num).toDouble();
              _playerScore = payload['hostScore'] as int;
              _opponentScore = payload['clientScore'] as int;
              
              if (_playerScore >= 3 || _opponentScore >= 3) {
                endGame();
              }
            });
          }
        } else if (packet.type == 'restart') {
          _restartLocalBoard();
        }
      }
    });

    _p2pRoomSub = _p2p.roomStream.listen((room) {
      if (room != null && mounted) {
        setState(() {
          _mode = PongGameMode.p2pBattle;
          final opp = room.players.firstWhere(
            (p) => p.id != _p2p.localPlayerId,
            orElse: () => const PlayerState(id: '', username: 'PEER'),
          );
          _opponentUsername = opp.username;
        });

        // Start broadcasting state at 30Hz if Host
        if (_p2p.isHost) {
          _stateBroadcastTimer?.cancel();
          _stateBroadcastTimer = Timer.periodic(const Duration(milliseconds: 33), (timer) {
            if (!_isPaused && !_isGameOver) {
              _p2p.sendPacket(P2PPacket(
                type: 'state_sync',
                game: 'pong',
                payload: {
                  'ballX': _ballX,
                  'ballY': _ballY,
                  'hostPaddleY': _playerY,
                  'hostScore': _playerScore,
                  'clientScore': _opponentScore,
                },
                senderId: _p2p.localPlayerId!,
              ));
            }
          });
        }
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
    _ticker.dispose();
    _p2pPacketSub?.cancel();
    _p2pRoomSub?.cancel();
    _p2pDiscoverySub?.cancel();
    _p2p.stopDiscovery();
    _stateBroadcastTimer?.cancel();
    super.dispose();
  }

  @override
  void startGame() {
    setState(() {
      _ballX = 0;
      _ballY = 0;
      _targetBallX = 0;
      _targetBallY = 0;
      _ballDX = 0.018;
      _ballDY = 0.009;
      _playerY = 0;
      _opponentY = 0;
      _targetOpponentY = 0;
      _playerScore = 0;
      _opponentScore = 0;
      _isPaused = false;
      _isGameOver = false;
    });
    _ticker.repeat();
  }

  void _restartLocalBoard() {
    setState(() {
      _ballX = 0;
      _ballY = 0;
      _playerY = 0;
      _opponentY = 0;
      _playerScore = 0;
      _opponentScore = 0;
      _isPaused = false;
      _isGameOver = false;
    });
    _ticker.repeat();
  }

  // ----------------------------------------------------
  // Authoritative Game Loop Physics & Interpolation
  // ----------------------------------------------------

  void _gameTick() {
    if (_isPaused || _isGameOver) return;

    if (_mode == PongGameMode.p2pBattle && !_p2p.isHost) {
      // CLIENT-SIDE INTERPOLATION: Interpolate smoothly to authoritative target coordinates
      setState(() {
        _ballX = lerpDouble(_ballX, _targetBallX, 0.3) ?? _targetBallX;
        _ballY = lerpDouble(_ballY, _targetBallY, 0.3) ?? _targetBallY;
        _opponentY = lerpDouble(_opponentY, _targetOpponentY, 0.25) ?? _targetOpponentY;
      });
      return;
    }

    // HOST OR SOLO AI PHYSICS
    setState(() {
      // 1. Move ball
      _ballX += _ballDX;
      _ballY += _ballDY;

      // 2. Bounce ceiling/floor
      if (_ballY > 0.95 || _ballY < -0.95) {
        _ballDY = -_ballDY;
        AudioManager.instance.playSFX('sfx/bounce.mp3');
      }

      // 3. AI logic if in soloAI mode
      if (_mode == PongGameMode.soloAI) {
        if (_ballX > 0) {
          if (_ballY > _opponentY + 0.05) {
            _opponentY += 0.012;
          } else if (_ballY < _opponentY - 0.05) {
            _opponentY -= 0.012;
          }
        }
        _opponentY = _opponentY.clamp(-1.0 + _paddleHeight / 2, 1.0 - _paddleHeight / 2);
      }

      // 4. Player paddle collisions (left side x = -0.9)
      if (_ballX < -0.88 && _ballX > -0.92) {
        if (_ballY > _playerY - _paddleHeight / 2 &&
            _ballY < _playerY + _paddleHeight / 2) {
          _ballDX = -_ballDX * 1.05;
          _ballDY += (_ballY - _playerY) * 0.05;
          AudioManager.instance.playSFX('sfx/hit.mp3');
        }
      }

      // 5. Opponent paddle collisions (right side x = 0.9)
      if (_ballX > 0.88 && _ballX < 0.92) {
        if (_ballY > _opponentY - _paddleHeight / 2 &&
            _ballY < _opponentY + _paddleHeight / 2) {
          _ballDX = -_ballDX * 1.05;
          _ballDY += (_ballY - _opponentY) * 0.05;
          AudioManager.instance.playSFX('sfx/hit.mp3');
        }
      }

      // 6. Scoring rules
      if (_ballX < -1.0) {
        _opponentScore++;
        _resetBall();
        if (_opponentScore >= 3) {
          endGame();
        }
      } else if (_ballX > 1.0) {
        _playerScore++;
        _resetBall();
        if (_playerScore >= 3) {
          endGame();
        }
      }
    });
  }

  void _resetBall() {
    _ballX = 0;
    _ballY = 0;
    _ballDX = -_ballDX.sign * 0.018;
    _ballDY = 0.009;
  }

  void _movePlayer(double delta) {
    if (_isPaused || _isGameOver) return;
    
    setState(() {
      _playerY = (_playerY + delta).clamp(
        -1.0 + _paddleHeight / 2,
        1.0 - _paddleHeight / 2,
      );
    });

    // If client, notify Host of our paddle move
    if (_mode == PongGameMode.p2pBattle && !_p2p.isHost) {
      _p2p.sendPacket(P2PPacket(
        type: 'paddle_move',
        game: 'pong',
        payload: {'paddleY': _playerY},
        senderId: _p2p.localPlayerId!,
      ));
    }
  }

  @override
  void pauseGame() {
    setState(() => _isPaused = true);
    _ticker.stop();
  }

  @override
  void resumeGame() {
    setState(() => _isPaused = false);
    _ticker.repeat();
  }

  @override
  void restartGame() {
    if (_mode == PongGameMode.p2pBattle) {
      _p2p.sendPacket(P2PPacket(
        type: 'restart',
        game: 'pong',
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
    _ticker.stop();
    AudioManager.instance.playSFX('sfx/fail.mp3');
    saveScore();
  }

  @override
  Future<void> saveScore() async {
    final user = ref.read(currentUserProvider);
    if (user == null || _playerScore == 0) return;

    try {
      final supabase = ref.read(supabaseProvider);
      await supabase.from('game_scores').insert({
        'user_id': user.id,
        'game_name': 'Pong',
        'highest_score': _playerScore,
      });

      await supabase.from('game_history').insert({
        'user_id': user.id,
        'game_name': 'Pong',
        'score': _playerScore,
        'duration': 30,
        'win_status': _playerScore >= 3,
      });
    } catch (_) {}
  }

  // ----------------------------------------------------
  // Room Lobbies operations
  // ----------------------------------------------------

  Future<void> _hostRoom() async {
    final user = ref.read(currentUserProvider);
    final username = user?.email?.split('@').first ?? 'HOST_PONG';
    setState(() => _isConnecting = true);

    try {
      await _p2p.createRoom(username, 'pong');
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
    final username = user?.email?.split('@').first ?? 'PEER_PONG';
    setState(() => _isConnecting = true);

    try {
      await _p2p.joinRoom(username, room);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Uplink failed: $e')),
      );
    } finally {
      setState(() => _isConnecting = false);
    }
  }

  // ----------------------------------------------------
  // UI Builds
  // ----------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final activeRoom = _p2p.activeRoom;

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'NEON PONG',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2),
        ),
        actions: [
          if (_mode == PongGameMode.p2pBattle)
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
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Selector Tab when offline
              if (activeRoom == null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _modeTab('VERSUS BOT AI', PongGameMode.soloAI),
                    const SizedBox(width: 12),
                    _modeTab('P2P MULTIPLAYER', PongGameMode.p2pBattle),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // 2. Room discovery/lobbies
              if (_mode == PongGameMode.p2pBattle && activeRoom == null) ...[
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isConnecting)
                        const CircularProgressIndicator(color: AppTheme.cyanBlue)
                      else ...[
                        CyberButton(
                          text: 'HOST LOBBY HUB',
                          onPressed: _hostRoom,
                        ),
                        const SizedBox(height: 16),
                        CyberButton(
                          text: 'SCAN LOBBY BEACONS',
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
                // Scores HUD overlay
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(
                      _mode == PongGameMode.p2pBattle ? 'YOU: $_playerScore' : 'PLAYER: $_playerScore',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.cyanBlue,
                      ),
                    ),
                    const Text(
                      ':',
                      style: TextStyle(fontSize: 18, color: Colors.white30),
                    ),
                    Text(
                      _mode == PongGameMode.p2pBattle ? '$_opponentUsername: $_opponentScore' : 'BOT AI: $_opponentScore',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.electricPink,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Game Window Paint Canvas
                Expanded(
                  child: GlassContainer(
                    padding: EdgeInsets.zero,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return CustomPaint(
                          size: Size(constraints.maxWidth, constraints.maxHeight),
                          painter: PongPainter(
                            ballX: _ballX,
                            ballY: _ballY,
                            playerY: _playerY,
                            aiY: _opponentY,
                            paddleHeight: _paddleHeight,
                            paddleWidth: _paddleWidth,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Paddle move controls
                if (!_isGameOver && !_isPaused)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_upward,
                          size: 44,
                          color: AppTheme.cyanBlue,
                        ),
                        onPressed: () => _movePlayer(-_paddleSpeed),
                      ),
                      const SizedBox(width: 48),
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_downward,
                          size: 44,
                          color: AppTheme.cyanBlue,
                        ),
                        onPressed: () => _movePlayer(_paddleSpeed),
                      ),
                    ],
                  ),

                if (_isGameOver || _isPaused)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Column(
                      children: [
                        CyberButton(
                          text: _isPaused ? 'RESUME SIGNAL' : 'RESTART CORE',
                          onPressed: () {
                            if (_isPaused) {
                              resumeGame();
                            } else {
                              restartGame();
                            }
                          },
                        ),
                        if (_mode == PongGameMode.p2pBattle) ...[
                          const SizedBox(height: 8),
                          CyberButton(
                            text: 'DISCONNECT LINK',
                            onPressed: () {
                              _p2p.leaveRoom();
                              setState(() {
                                _mode = PongGameMode.soloAI;
                                startGame();
                              });
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _modeTab(String label, PongGameMode md) {
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

class PongPainter extends CustomPainter {
  final double ballX;
  final double ballY;
  final double playerY;
  final double aiY;
  final double paddleHeight;
  final double paddleWidth;

  PongPainter({
    required this.ballX,
    required this.ballY,
    required this.playerY,
    required this.aiY,
    required this.paddleHeight,
    required this.paddleWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Convert coordinates from (-1, 1) to canvas limits
    final bX = ((ballX + 1) / 2) * w;
    final bY = ((ballY + 1) / 2) * h;

    final pY = ((playerY + 1) / 2) * h;
    final aY = ((aiY + 1) / 2) * h;

    final pHeight = paddleHeight * h / 2;
    final pWidth = paddleWidth * w / 2;

    // Draw ball
    final ballPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(bX, bY), 10, ballPaint);

    // Ball glow
    final glowPaint = Paint()
      ..color = AppTheme.cyanBlue.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(Offset(bX, bY), 16, glowPaint);

    // Left Paddle (Player 1 / Host)
    final playerPaint = Paint()..color = AppTheme.cyanBlue;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.05 - pWidth / 2, pY - pHeight / 2, pWidth, pHeight),
        const Radius.circular(4),
      ),
      playerPaint,
    );

    // Right Paddle (Player 2 / Client)
    final aiPaint = Paint()..color = AppTheme.electricPink;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.95 - pWidth / 2, aY - pHeight / 2, pWidth, pHeight),
        const Radius.circular(4),
      ),
      aiPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
