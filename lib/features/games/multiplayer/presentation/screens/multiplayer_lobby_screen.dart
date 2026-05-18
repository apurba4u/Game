import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/common_widgets/glass_container.dart';
import '../../../../../../core/common_widgets/cyber_button.dart';
import 'package:go_router/go_router.dart';

class MultiplayerLobbyScreen extends ConsumerStatefulWidget {
  const MultiplayerLobbyScreen({super.key});

  @override
  ConsumerState<MultiplayerLobbyScreen> createState() =>
      _MultiplayerLobbyScreenState();
}

class _MultiplayerLobbyScreenState
    extends ConsumerState<MultiplayerLobbyScreen> {
  final TextEditingController _roomCodeController = TextEditingController();
  final TextEditingController _chatController = TextEditingController();

  bool _isInRoom = false;
  String _activeRoomCode = '';

  final List<String> _lobbyUsers = ['Apurba_Ovi (Host)', 'V_Cybercore'];
  final List<Map<String, String>> _chatMessages = [
    {
      'sender': 'System',
      'msg': 'Neural uplink connection established in Room #GH-9018',
    },
    {'sender': 'V_Cybercore', 'msg': 'Yo! Ready to initiate Tic Tac Toe?'},
  ];

  @override
  void dispose() {
    _roomCodeController.dispose();
    _chatController.dispose();
    super.dispose();
  }

  void _createRoom() {
    setState(() {
      _isInRoom = true;
      _activeRoomCode = 'GH-9018';
    });
  }

  void _joinRoom() {
    if (_roomCodeController.text.trim().isNotEmpty) {
      setState(() {
        _isInRoom = true;
        _activeRoomCode = _roomCodeController.text.toUpperCase();
      });
    }
  }

  void _sendMessage() {
    if (_chatController.text.trim().isNotEmpty) {
      setState(() {
        _chatMessages.add({
          'sender': 'Apurba_Ovi',
          'msg': _chatController.text.trim(),
        });
        _chatController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.cyanBlue),
          onPressed: () => context.pop(),
        ),
        title: Text(
          _isInRoom
              ? 'MULTIPLAYER LOBBY : $_activeRoomCode'
              : 'MULTIPLAYER ARCHIVE',
          style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: _isInRoom ? _buildLobbyConsole() : _buildRoomSetupForm(),
        ),
      ),
    );
  }

  Widget _buildRoomSetupForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'INITIATE MULTIPLAYER BROADCAST',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Host a private gaming room or join an existing channel.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white54, fontSize: 13),
        ),
        const SizedBox(height: 36),

        CyberButton(
          text: 'SPAWN NEURAL ROOM',
          icon: Icons.add_box,
          onPressed: _createRoom,
        ),
        const SizedBox(height: 24),

        const Row(
          children: [
            Expanded(child: Divider(color: Colors.white10)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'OR',
                style: TextStyle(
                  color: Colors.white30,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(child: Divider(color: Colors.white10)),
          ],
        ),
        const SizedBox(height: 24),

        TextField(
          controller: _roomCodeController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'ENTER ROOM CODE (e.g. GH-9018)',
            hintStyle: const TextStyle(color: Colors.white30),
            filled: true,
            fillColor: AppTheme.glassBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.glassBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.glassBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.cyanBlue),
            ),
          ),
        ),
        const SizedBox(height: 16),
        CyberButton(
          text: 'JOIN CHANNELS',
          icon: Icons.login,
          isSecondary: true,
          onPressed: _joinRoom,
        ),
      ],
    );
  }

  Widget _buildLobbyConsole() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Lobby Info and Members
        const Text(
          'CONNECTED COMMUNICATORS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 12),
        GlassContainer(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: _lobbyUsers.map((user) {
              final isHost = user.contains('Host');
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      user,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isHost ? AppTheme.cyanBlue : Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 24),

        // Live Chat Terminal
        const Text(
          'LOBBY COMMUNICATIONS FEED',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: GlassContainer(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: _chatMessages.length,
                    itemBuilder: (context, index) {
                      final chat = _chatMessages[index];
                      final isSystem = chat['sender'] == 'System';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${chat['sender']}: ',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isSystem
                                    ? AppTheme.cyanBlue
                                    : AppTheme.neonPurple,
                                fontSize: 12,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                chat['msg']!,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _chatController,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter broadcast query...',
                          hintStyle: const TextStyle(color: Colors.white30),
                          filled: true,
                          fillColor: Colors.black38,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.white10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.send, color: AppTheme.cyanBlue),
                      onPressed: _sendMessage,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        CyberButton(
          text: 'LAUNCH CORE ENGINE',
          icon: Icons.play_arrow,
          onPressed: () {
            context.push('/game/tic-tac-toe');
          },
        ),
      ],
    );
  }
}
