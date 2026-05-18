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

enum GameMode {
  singlePlayer,
  passAndPlay,
  p2pMultiplayer,
}

class TicTacToeScreen extends ConsumerStatefulWidget {
  const TicTacToeScreen({super.key});

  @override
  ConsumerState<TicTacToeScreen> createState() => _TicTacToeScreenState();
}

class _TicTacToeScreenState extends ConsumerState<TicTacToeScreen>
    implements BaseGameController {
  
  GameMode _mode = GameMode.singlePlayer;
  List<String> _board = List.filled(9, '');
  bool _isXTurn = true;
  String _winner = '';
  bool _isGameOver = false;
  bool _isPaused = false;
  int _score = 0;

  // P2P Specific variables
  final P2PNetworkManager _p2p = P2PNetworkManager.instance;
  StreamSubscription? _p2pPacketSub;
  StreamSubscription? _p2pRoomSub;
  bool _isConnecting = false;
  List<MultiplayerRoom> _rooms = [];
  StreamSubscription? _p2pDiscoverySub;

  @override
  void initState() {
    super.initState();
    startGame();
    _setupP2PListeners();
  }

  void _setupP2PListeners() {
    // Listen for incoming game packets
    _p2pPacketSub = _p2p.messageStream.listen((packet) {
      if (packet.game == 'tic_tac_toe') {
        if (packet.type == 'move') {
          final index = packet.payload['index'] as int;
          _executeMove(index);
        } else if (packet.type == 'restart') {
          _restartLocalBoard();
        }
      }
    });

    // Listen for room updates
    _p2pRoomSub = _p2p.roomStream.listen((room) {
      if (room != null && mounted) {
        setState(() {
          _mode = GameMode.p2pMultiplayer;
        });
      }
    });

    // Listen for local network room discoveries
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
      _board = List.filled(9, '');
      _isXTurn = true;
      _winner = '';
      _isGameOver = false;
      _isPaused = false;
      _score = 0;
    });
  }

  void _restartLocalBoard() {
    setState(() {
      _board = List.filled(9, '');
      _isXTurn = true;
      _winner = '';
      _isGameOver = false;
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
    if (_mode == GameMode.p2pMultiplayer) {
      // Send restart signal
      _p2p.sendPacket(P2PPacket(
        type: 'restart',
        game: 'tic_tac_toe',
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
        'game_name': 'Tic Tac Toe',
        'highest_score': _score,
      });

      await supabase.from('game_history').insert({
        'user_id': user.id,
        'game_name': 'Tic Tac Toe',
        'score': _score,
        'duration': 25,
        'win_status': _winner == 'X',
      });
    } catch (_) {}
  }

  // ----------------------------------------------------
  // Game Actions & Turns
  // ----------------------------------------------------

  void _handleTap(int index) {
    if (_board[index] != '' || _isGameOver || _isPaused) return;

    if (_mode == GameMode.p2pMultiplayer) {
      final activeRoom = _p2p.activeRoom;
      if (activeRoom == null || activeRoom.players.length < 2) return;

      // Host is X, Client is O
      final isLocalPlayerHost = _p2p.isHost;
      final isLocalTurn = (_isXTurn && isLocalPlayerHost) || (!_isXTurn && !isLocalPlayerHost);

      if (!isLocalTurn) return; // Prevent illegal moving

      // Dispatch packet to peer
      _p2p.sendPacket(P2PPacket(
        type: 'move',
        game: 'tic_tac_toe',
        payload: {'index': index},
        senderId: _p2p.localPlayerId!,
      ));
    }

    _executeMove(index);
  }

  void _executeMove(int index) {
    setState(() {
      _board[index] = _isXTurn ? 'X' : 'O';
      _isXTurn = !_isXTurn;
      _checkWinner();
    });

    // Make AI moves if in singlePlayer mode
    if (_mode == GameMode.singlePlayer && !_isXTurn && !_isGameOver) {
      Timer(const Duration(milliseconds: 600), _makeAIMove);
    }
  }

  void _makeAIMove() {
    final available = <int>[];
    for (var i = 0; i < 9; i++) {
      if (_board[i] == '') available.add(i);
    }
    if (available.isNotEmpty) {
      final randomIdx = available[DateTime.now().millisecond % available.length];
      _executeMove(randomIdx);
    }
  }

  void _checkWinner() {
    const winPatterns = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8],
      [0, 3, 6], [1, 4, 7], [2, 5, 8],
      [0, 4, 8], [2, 4, 6],
    ];

    for (var pattern in winPatterns) {
      if (_board[pattern[0]] != '' &&
          _board[pattern[0]] == _board[pattern[1]] &&
          _board[pattern[0]] == _board[pattern[2]]) {
        _winner = _board[pattern[0]];
        _score = _winner == 'X' ? 100 : 0;
        endGame();
        return;
      }
    }

    if (!_board.contains('')) {
      _winner = 'Draw';
      _score = 50;
      endGame();
    }
  }

  // ----------------------------------------------------
  // Room Management & UI overlays
  // ----------------------------------------------------

  Future<void> _hostRoom() async {
    final user = ref.read(currentUserProvider);
    final username = user?.email?.split('@').first ?? 'NETRUNNER';
    setState(() => _isConnecting = true);

    try {
      await _p2p.createRoom(username, 'tic_tac_toe');
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
    final username = user?.email?.split('@').first ?? 'PEER';
    setState(() => _isConnecting = true);

    try {
      await _p2p.joinRoom(username, room);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to bridge link: $e')),
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
          'TIC TAC TOE',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2),
        ),
        actions: [
          if (_mode == GameMode.p2pMultiplayer)
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: Center(
                child: DiagnosticsOverlay(
                  latencyMs: _p2p.currentLatency,
                  connectionType: _p2p.activeRoom?.ipAddress == 'Supabase-Relay'
                      ? 'Relay Uplink'
                      : 'P2P Link',
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
              // 1. Selector Lobbies when offline
              if (activeRoom == null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _modeTab('AI BATTLE', GameMode.singlePlayer),
                    const SizedBox(width: 8),
                    _modeTab('PASS & PLAY', GameMode.passAndPlay),
                    const SizedBox(width: 8),
                    _modeTab('P2P BATTLE', GameMode.p2pMultiplayer),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // 2. Interactive Lobby configuration if in P2P mode
              if (_mode == GameMode.p2pMultiplayer && activeRoom == null) ...[
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isConnecting)
                        const CircularProgressIndicator(color: AppTheme.cyanBlue)
                      else ...[
                        CyberButton(
                          text: 'HOST P2P LOBBY',
                          onPressed: _hostRoom,
                        ),
                        const SizedBox(height: 16),
                        CyberButton(
                          text: 'SCAN LOCAL NETWORKS',
                          onPressed: _scanRooms,
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'AVAILABLE ROOMS:',
                          style: TextStyle(
                            color: AppTheme.cyanBlue,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_rooms.isEmpty)
                          const Text(
                            'NO BEACONS SPOTTED. BE FIRST TO HOST!',
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
                // Active Game Room Details
                if (_mode == GameMode.p2pMultiplayer && activeRoom != null) ...[
                  Center(
                    child: Text(
                      'ROOM CODE: ${activeRoom.roomId} | PEERS: ${activeRoom.players.length}/2',
                      style: const TextStyle(
                        color: AppTheme.cyanBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Grid Game Board
                Text(
                  _isGameOver
                      ? (_winner == 'Draw' ? 'DRAW!' : 'WINNER: $_winner')
                      : 'TURN: ${_isXTurn ? "X" : "O"}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                    ),
                    itemCount: 9,
                    itemBuilder: (context, index) {
                      final cell = _board[index];
                      return GestureDetector(
                        onTap: () => _handleTap(index),
                        child: GlassContainer(
                          borderColor: cell == 'X'
                              ? AppTheme.neonPurple
                              : (cell == 'O'
                                    ? AppTheme.cyanBlue
                                    : AppTheme.glassBorder),
                          child: Center(
                            child: Text(
                              cell,
                              style: TextStyle(
                                fontSize: 44,
                                fontWeight: FontWeight.bold,
                                color: cell == 'X'
                                    ? AppTheme.neonPurple
                                    : AppTheme.cyanBlue,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (_isGameOver || _isPaused)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Column(
                      children: [
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
                        if (_mode == GameMode.p2pMultiplayer) ...[
                          const SizedBox(height: 8),
                          CyberButton(
                            text: 'LEAVE LOBBY',
                            onPressed: () {
                              _p2p.leaveRoom();
                              setState(() {
                                _mode = GameMode.singlePlayer;
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

  Widget _modeTab(String label, GameMode md) {
    final active = _mode == md;
    return GestureDetector(
      onTap: () {
        setState(() {
          _mode = md;
          startGame();
        });
      },
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
