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

enum ConnectFourMode {
  singlePlayer,
  passAndPlay,
  p2pMultiplayer,
}

class ConnectFourScreen extends ConsumerStatefulWidget {
  const ConnectFourScreen({super.key});

  @override
  ConsumerState<ConnectFourScreen> createState() => _ConnectFourScreenState();
}

class _ConnectFourScreenState extends ConsumerState<ConnectFourScreen>
    implements BaseGameController {
  
  static const int rows = 6;
  static const int cols = 7;
  
  ConnectFourMode _mode = ConnectFourMode.singlePlayer;
  
  // Grid represented as list of lists (row major: 6 rows, 7 columns)
  // empty = '', P1 = 'X' (Purple), P2 = 'O' (Cyan)
  List<List<String>> _grid = List.generate(rows, (_) => List.filled(cols, ''));
  bool _isP1Turn = true;
  String _winner = '';
  bool _isGameOver = false;
  bool _isPaused = false;
  int _score = 0;

  // P2P variables
  final P2PNetworkManager _p2p = P2PNetworkManager.instance;
  StreamSubscription? _p2pPacketSub;
  StreamSubscription? _p2pRoomSub;
  StreamSubscription? _p2pDiscoverySub;
  bool _isConnecting = false;
  List<MultiplayerRoom> _rooms = [];

  @override
  void initState() {
    super.initState();
    startGame();
    _setupP2PListeners();
  }

  void _setupP2PListeners() {
    _p2pPacketSub = _p2p.messageStream.listen((packet) {
      if (packet.game == 'connect_four') {
        if (packet.type == 'move') {
          final colIdx = packet.payload['col'] as int;
          _dropToken(colIdx);
        } else if (packet.type == 'restart') {
          _restartLocalBoard();
        }
      }
    });

    _p2pRoomSub = _p2p.roomStream.listen((room) {
      if (room != null && mounted) {
        setState(() {
          _mode = ConnectFourMode.p2pMultiplayer;
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
      _grid = List.generate(rows, (_) => List.filled(cols, ''));
      _isP1Turn = true;
      _winner = '';
      _isGameOver = false;
      _isPaused = false;
      _score = 0;
    });
  }

  void _restartLocalBoard() {
    setState(() {
      _grid = List.generate(rows, (_) => List.filled(cols, ''));
      _isP1Turn = true;
      _winner = '';
      _isGameOver = false;
      _isPaused = false;
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
    if (_mode == ConnectFourMode.p2pMultiplayer) {
      _p2p.sendPacket(P2PPacket(
        type: 'restart',
        game: 'connect_four',
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
        'game_name': 'Connect Four',
        'highest_score': _score,
      });

      await supabase.from('game_history').insert({
        'user_id': user.id,
        'game_name': 'Connect Four',
        'score': _score,
        'duration': 35,
        'win_status': _winner == 'X',
      });
    } catch (_) {}
  }

  // ----------------------------------------------------
  // Drop Token & Win Condition Validations
  // ----------------------------------------------------

  void _selectColumn(int colIdx) {
    if (_isGameOver || _isPaused) return;

    if (_mode == ConnectFourMode.p2pMultiplayer) {
      final activeRoom = _p2p.activeRoom;
      if (activeRoom == null || activeRoom.players.length < 2) return;

      // Host is P1 ('X'), Client is P2 ('O')
      final isLocalHost = _p2p.isHost;
      final isLocalTurn = (_isP1Turn && isLocalHost) || (!_isP1Turn && !isLocalHost);

      if (!isLocalTurn) return; // Prevent out-of-turn play

      // Dispatch column pick
      _p2p.sendPacket(P2PPacket(
        type: 'move',
        game: 'connect_four',
        payload: {'col': colIdx},
        senderId: _p2p.localPlayerId!,
      ));
    }

    _dropToken(colIdx);
  }

  void _dropToken(int colIdx) {
    // Find lowest available row index in this column
    int targetRow = -1;
    for (int r = rows - 1; r >= 0; r--) {
      if (_grid[r][colIdx] == '') {
        targetRow = r;
        break;
      }
    }

    if (targetRow == -1) return; // Column is full!

    setState(() {
      _grid[targetRow][colIdx] = _isP1Turn ? 'X' : 'O';
      _isP1Turn = !_isP1Turn;
      _checkWinner();
    });

    // Make AI move in singlePlayer
    if (_mode == ConnectFourMode.singlePlayer && !_isP1Turn && !_isGameOver) {
      Timer(const Duration(milliseconds: 700), _makeAIMove);
    }
  }

  void _makeAIMove() {
    final availableCols = <int>[];
    for (int c = 0; c < cols; c++) {
      if (_grid[0][c] == '') availableCols.add(c);
    }
    if (availableCols.isNotEmpty) {
      final randomCol = availableCols[DateTime.now().millisecond % availableCols.length];
      _dropToken(randomCol);
    }
  }

  void _checkWinner() {
    // Horizontal Check
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c <= cols - 4; c++) {
        final val = _grid[r][c];
        if (val != '' &&
            val == _grid[r][c + 1] &&
            val == _grid[r][c + 2] &&
            val == _grid[r][c + 3]) {
          _winner = val;
          _score = _winner == 'X' ? 120 : 0;
          endGame();
          return;
        }
      }
    }

    // Vertical Check
    for (int r = 0; r <= rows - 4; r++) {
      for (int c = 0; c < cols; c++) {
        final val = _grid[r][c];
        if (val != '' &&
            val == _grid[r + 1][c] &&
            val == _grid[r + 2][c] &&
            val == _grid[r + 3][c]) {
          _winner = val;
          _score = _winner == 'X' ? 120 : 0;
          endGame();
          return;
        }
      }
    }

    // Diagonal Checks (Bottom-Left to Top-Right)
    for (int r = 3; r < rows; r++) {
      for (int c = 0; c <= cols - 4; c++) {
        final val = _grid[r][c];
        if (val != '' &&
            val == _grid[r - 1][c + 1] &&
            val == _grid[r - 2][c + 2] &&
            val == _grid[r - 3][c + 3]) {
          _winner = val;
          _score = _winner == 'X' ? 120 : 0;
          endGame();
          return;
        }
      }
    }

    // Diagonal Checks (Top-Left to Bottom-Right)
    for (int r = 0; r <= rows - 4; r++) {
      for (int c = 0; c <= cols - 4; c++) {
        final val = _grid[r][c];
        if (val != '' &&
            val == _grid[r + 1][c + 1] &&
            val == _grid[r + 2][c + 2] &&
            val == _grid[r + 3][c + 3]) {
          _winner = val;
          _score = _winner == 'X' ? 120 : 0;
          endGame();
          return;
        }
      }
    }

    // Check for draw
    bool isFull = true;
    for (int c = 0; c < cols; c++) {
      if (_grid[0][c] == '') {
        isFull = false;
        break;
      }
    }

    if (isFull) {
      _winner = 'Draw';
      _score = 60;
      endGame();
    }
  }

  // ----------------------------------------------------
  // Room Control triggers
  // ----------------------------------------------------

  Future<void> _hostRoom() async {
    final user = ref.read(currentUserProvider);
    final username = user?.email?.split('@').first ?? 'HOST_4';
    setState(() => _isConnecting = true);

    try {
      await _p2p.createRoom(username, 'connect_four');
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
    final username = user?.email?.split('@').first ?? 'PEER_4';
    setState(() => _isConnecting = true);

    try {
      await _p2p.joinRoom(username, room);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed connection: $e')),
      );
    } finally {
      setState(() => _isConnecting = false);
    }
  }

  // ----------------------------------------------------
  // UI rendering
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
          'CONNECT FOUR',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2),
        ),
        actions: [
          if (_mode == ConnectFourMode.p2pMultiplayer)
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
              // 1. Selector Tab
              if (activeRoom == null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _modeTab('AI BOT', ConnectFourMode.singlePlayer),
                    const SizedBox(width: 8),
                    _modeTab('PASS & PLAY', ConnectFourMode.passAndPlay),
                    const SizedBox(width: 8),
                    _modeTab('P2P NETWORK', ConnectFourMode.p2pMultiplayer),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // 2. Room listings and lobbies
              if (_mode == ConnectFourMode.p2pMultiplayer && activeRoom == null) ...[
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isConnecting)
                        const CircularProgressIndicator(color: AppTheme.cyanBlue)
                      else ...[
                        CyberButton(
                          text: 'HOST LOBBY BEACON',
                          onPressed: _hostRoom,
                        ),
                        const SizedBox(height: 16),
                        CyberButton(
                          text: 'SCAN LOCAL NETWORKS',
                          onPressed: _scanRooms,
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'SPOTTED SIGNALS:',
                          style: TextStyle(
                            color: AppTheme.cyanBlue,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_rooms.isEmpty)
                          const Text(
                            'NO LIVE ROOM BEACONS FOUND. HOST ONE!',
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
                // Active game indicators
                if (_mode == ConnectFourMode.p2pMultiplayer && activeRoom != null) ...[
                  Center(
                    child: Text(
                      'ROOM ENCRYPTED: ${activeRoom.roomId} | PEERS: ${activeRoom.players.length}/2',
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

                Text(
                  _isGameOver
                      ? (_winner == 'Draw' ? 'NEURAL DRAW!' : 'WINNER: ${_winner == "X" ? "PURPLE" : "CYAN"}')
                      : 'TURN: ${_isP1Turn ? "PURPLE" : "CYAN"}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 20),

                // Matrix Slots UI
                Expanded(
                  child: GlassContainer(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        // Column Drop click triggers
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: List.generate(cols, (colIdx) {
                            return IconButton(
                              icon: const Icon(
                                Icons.arrow_downward,
                                color: AppTheme.cyanBlue,
                                size: 20,
                              ),
                              onPressed: () => _selectColumn(colIdx),
                            );
                          }),
                        ),
                        const Divider(color: AppTheme.glassBorder, height: 12),
                        // 6x7 Circular Grid Nodes
                        Expanded(
                          child: GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: cols,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                            ),
                            itemCount: rows * cols,
                            itemBuilder: (context, index) {
                              final r = index ~/ cols;
                              final c = index % cols;
                              final cell = _grid[r][c];

                              Color cellColor = Colors.transparent;
                              BoxShadow? neonGlow;

                              if (cell == 'X') {
                                cellColor = AppTheme.neonPurple;
                                neonGlow = BoxShadow(
                                  color: AppTheme.neonPurple.withOpacity(0.8),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                );
                              } else if (cell == 'O') {
                                cellColor = AppTheme.cyanBlue;
                                neonGlow = BoxShadow(
                                  color: AppTheme.cyanBlue.withOpacity(0.8),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                );
                              }

                              return Container(
                                decoration: BoxDecoration(
                                  color: cellColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: cell == '' ? AppTheme.glassBorder : cellColor,
                                    width: 1.5,
                                  ),
                                  boxShadow: neonGlow != null ? [neonGlow] : null,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (_isGameOver || _isPaused)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Column(
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
                        if (_mode == ConnectFourMode.p2pMultiplayer) ...[
                          const SizedBox(height: 8),
                          CyberButton(
                            text: 'DISCONNECT LOBBY',
                            onPressed: () {
                              _p2p.leaveRoom();
                              setState(() {
                                _mode = ConnectFourMode.singlePlayer;
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

  Widget _modeTab(String label, ConnectFourMode md) {
    final active = _mode == md;
    return GestureDetector(
      onTap: () {
        setState(() {
          _mode = md;
          startGame();
        });
      },
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        borderColor: active ? AppTheme.cyanBlue : AppTheme.glassBorder,
        child: Text(
          label,
          style: TextStyle(
            color: active ? AppTheme.cyanBlue : Colors.white54,
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
      ),
    );
  }
}
