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

enum TypingGameMode {
  soloPractice,
  p2pBattle,
}

class TypingBattleScreen extends ConsumerStatefulWidget {
  const TypingBattleScreen({super.key});

  @override
  ConsumerState<TypingBattleScreen> createState() => _TypingBattleScreenState();
}

class _TypingBattleScreenState extends ConsumerState<TypingBattleScreen>
    implements BaseGameController {
  
  static const String targetText = 
      "neural connection established. accessing root mainframe gateway. bypassing quantum firewall logs. decrypting database keys...";

  TypingGameMode _mode = TypingGameMode.soloPractice;
  
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  int _wpm = 0;
  int _accuracy = 100;
  double _progress = 0.0;
  bool _isGameOver = false;
  bool _isPaused = false;
  int _score = 0;

  DateTime? _startTime;
  Timer? _metricsTimer;

  // P2P Specific Variables
  final P2PNetworkManager _p2p = P2PNetworkManager.instance;
  StreamSubscription? _p2pPacketSub;
  StreamSubscription? _p2pRoomSub;
  StreamSubscription? _p2pDiscoverySub;
  bool _isConnecting = false;
  List<MultiplayerRoom> _rooms = [];

  // Opponent metrics
  double _opponentProgress = 0.0;
  int _opponentWpm = 0;
  String _opponentUsername = 'OPPONENT';

  // Debouncing / Batching typing packets (Send updates every 500ms max)
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    startGame();
    _setupP2PListeners();
  }

  void _setupP2PListeners() {
    _p2pPacketSub = _p2p.messageStream.listen((packet) {
      if (packet.game == 'typing') {
        if (packet.type == 'progress') {
          setState(() {
            _opponentProgress = (packet.payload['progress'] as num).toDouble();
            _opponentWpm = packet.payload['wpm'] as int;
            
            if (_opponentProgress >= 1.0 && _progress >= 1.0) {
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
          _mode = TypingGameMode.p2pBattle;
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
    _metricsTimer?.cancel();
    _debounceTimer?.cancel();
    _inputController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void startGame() {
    setState(() {
      _inputController.clear();
      _wpm = 0;
      _accuracy = 100;
      _progress = 0.0;
      _opponentProgress = 0.0;
      _opponentWpm = 0;
      _isPaused = false;
      _isGameOver = false;
      _score = 0;
      _startTime = null;
    });
    _metricsTimer?.cancel();
    _metricsTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_startTime != null && !_isGameOver && !_isPaused) {
        _calculateMetrics();
      }
    });
  }

  void _restartLocalBoard() {
    setState(() {
      _inputController.clear();
      _wpm = 0;
      _accuracy = 100;
      _progress = 0.0;
      _opponentProgress = 0.0;
      _opponentWpm = 0;
      _isPaused = false;
      _isGameOver = false;
      _startTime = null;
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
    if (_mode == TypingGameMode.p2pBattle) {
      _p2p.sendPacket(P2PPacket(
        type: 'restart',
        game: 'typing',
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
    _metricsTimer?.cancel();
    setState(() => _isGameOver = true);
    saveScore();
  }

  @override
  Future<void> saveScore() async {
    final user = ref.read(currentUserProvider);
    if (user == null || _wpm == 0) return;

    try {
      final supabase = ref.read(supabaseProvider);
      await supabase.from('game_scores').insert({
        'user_id': user.id,
        'game_name': 'Typing Battle',
        'highest_score': _wpm,
      });

      await supabase.from('game_history').insert({
        'user_id': user.id,
        'game_name': 'Typing Battle',
        'score': _wpm,
        'duration': 40,
        'win_status': _mode == TypingGameMode.p2pBattle ? (_progress >= 1.0 && _progress > _opponentProgress) : true,
      });
    } catch (_) {}
  }

  // ----------------------------------------------------
  // Typing mechanics & Debounced Packet dispatcher
  // ----------------------------------------------------

  void _onTypeChanged(String val) {
    if (_isGameOver || _isPaused) return;

    _startTime ??= DateTime.now();

    _calculateMetrics();

    // Check game completed
    if (val.length >= targetText.length && val == targetText) {
      setState(() {
        _progress = 1.0;
      });
      _dispatchProgressDebounced();
      
      if (_mode == TypingGameMode.p2pBattle) {
        if (_opponentProgress >= 1.0) {
          endGame();
        }
      } else {
        endGame();
      }
      return;
    }

    _dispatchProgressDebounced();
  }

  void _calculateMetrics() {
    final val = _inputController.text;
    if (val.isEmpty) return;

    // 1. Calculate accuracy
    int correctChars = 0;
    for (int i = 0; i < val.length; i++) {
      if (i < targetText.length && val[i] == targetText[i]) {
        correctChars++;
      }
    }
    setState(() {
      _accuracy = ((correctChars / val.length) * 100).toInt();
      _progress = (val.length / targetText.length).clamp(0.0, 1.0);
    });

    // 2. Calculate WPM (Words = characters / 5)
    if (_startTime != null) {
      final elapsedSecs = DateTime.now().difference(_startTime!).inSeconds;
      if (elapsedSecs > 0) {
        final words = correctChars / 5.0;
        setState(() {
          _wpm = ((words / elapsedSecs) * 60).toInt();
        });
      }
    }
  }

  void _dispatchProgressDebounced() {
    if (_mode != TypingGameMode.p2pBattle) return;

    // Debounce to prevent socket congestion (max 1 update per 400ms)
    if (_debounceTimer?.isActive ?? false) return;

    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      _p2p.sendPacket(P2PPacket(
        type: 'progress',
        game: 'typing',
        payload: {
          'progress': _progress,
          'wpm': _wpm,
        },
        senderId: _p2p.localPlayerId!,
      ));
    });
  }

  // ----------------------------------------------------
  // Room joins and creations
  // ----------------------------------------------------

  Future<void> _hostRoom() async {
    final user = ref.read(currentUserProvider);
    final username = user?.email?.split('@').first ?? 'HOST_TYPE';
    setState(() => _isConnecting = true);

    try {
      await _p2p.createRoom(username, 'typing');
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
    final username = user?.email?.split('@').first ?? 'PEER_TYPE';
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
  // UI layouts rendering
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
          'TYPING TERMINAL',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2),
        ),
        actions: [
          if (_mode == TypingGameMode.p2pBattle)
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Selector Tab when offline
              if (activeRoom == null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _modeTab('PRACTICE SOLO', TypingGameMode.soloPractice),
                    const SizedBox(width: 12),
                    _modeTab('P2P TYPING BATTLE', TypingGameMode.p2pBattle),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // 2. Room discovery/lobbies
              if (_mode == TypingGameMode.p2pBattle && activeRoom == null) ...[
                Column(
                  children: [
                    if (_isConnecting)
                      const CircularProgressIndicator(color: AppTheme.cyanBlue)
                    else ...[
                      CyberButton(
                        text: 'HOST LOBBY SIGNALLER',
                        onPressed: _hostRoom,
                      ),
                      const SizedBox(height: 16),
                      CyberButton(
                        text: 'SCAN LOBBY BEACONS',
                        onPressed: _scanRooms,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'DISCOVERED BEACONS:',
                        style: TextStyle(
                          color: AppTheme.cyanBlue,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_rooms.isEmpty)
                        const Text(
                          'NO ACTIVE SIGNALS. BE THE FIRST TO HOST!',
                          style: TextStyle(color: Colors.white30, fontSize: 11),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
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
                    ],
                  ],
                ),
              ] else ...[
                // Active game indicators and HUD Progress racer tracks
                if (_mode == TypingGameMode.p2pBattle && activeRoom != null) ...[
                  Center(
                    child: Text(
                      'ROOM CODE: ${activeRoom.roomId} | OPPONENT: $_opponentUsername',
                      style: const TextStyle(
                        color: AppTheme.cyanBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Racer track progress
                  _racerTrack('YOU', _progress, AppTheme.neonPurple),
                  const SizedBox(height: 8),
                  _racerTrack(_opponentUsername.toUpperCase(), _opponentProgress, AppTheme.cyanBlue),
                  const SizedBox(height: 20),
                ],

                // Metrics board row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _metricCard('WPM', '$_wpm'),
                    _metricCard('ACCURACY', '$_accuracy%'),
                  ],
                ),
                const SizedBox(height: 24),

                // Cyberpunk styled text box highlighter
                GlassContainer(
                  padding: const EdgeInsets.all(20),
                  child: RichText(
                    text: TextSpan(
                      children: List.generate(targetText.length, (idx) {
                        final char = targetText[idx];
                        final typed = _inputController.text;

                        Color charColor = Colors.white30;
                        if (idx < typed.length) {
                          charColor = typed[idx] == char
                              ? Colors.greenAccent
                              : AppTheme.electricPink;
                        }

                        return TextSpan(
                          text: char,
                          style: TextStyle(
                            color: charColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Type writing input
                if (!_isGameOver && !_isPaused)
                  TextField(
                    controller: _inputController,
                    focusNode: _focusNode,
                    onChanged: _onTypeChanged,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: 'DECRYPT TEXT HERE',
                      labelStyle: const TextStyle(color: AppTheme.cyanBlue, fontSize: 11, letterSpacing: 1.5),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: AppTheme.glassBorder),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: AppTheme.cyanBlue, width: 2),
                        borderRadius: BorderRadius.circular(12),
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
                        if (_mode == TypingGameMode.p2pBattle) ...[
                          const SizedBox(height: 8),
                          CyberButton(
                            text: 'LEAVE LOBBY',
                            onPressed: () {
                              _p2p.leaveRoom();
                              setState(() {
                                _mode = TypingGameMode.soloPractice;
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

  Widget _racerTrack(String name, double progress, Color glowColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name, style: TextStyle(color: glowColor, fontSize: 8, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Container(
          height: 12,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppTheme.glassBorder),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                color: glowColor,
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(color: glowColor.withOpacity(0.8), blurRadius: 6),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _metricCard(String label, String value) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: AppTheme.cyanBlue, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _modeTab(String label, TypingGameMode md) {
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
