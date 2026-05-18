import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../protocol/p2p_session_models.dart';
import '../protocol/p2p_packet.dart';
import '../heartbeat/heartbeat_manager.dart';
import 'platform/p2p_socket_helper_stub.dart'
    if (dart.library.io) 'platform/p2p_socket_helper_native.dart';

// Ei class ta multiplayer networking er heart and soul (main controller).
// Web platforms (Chrome) er jonno Supabase Realtime Channels logic use kore signals pass kore,
// ar Android/iOS/Desktop native connection er jonno local TCP sockets dynamic scanning ar UDP discovery handle kore.
class P2PNetworkManager {
  static final P2PNetworkManager instance = P2PNetworkManager._internal();

  factory P2PNetworkManager() => instance;

  P2PNetworkManager._internal() {
    _initHeartbeat();
  }

  // Network State Variables
  bool isHost = false; // Player ki room host naki client, ta check kore.
  String? localPlayerId;
  String? localUsername;
  MultiplayerRoom? activeRoom; // Ekhon active thaka game room logic meta.
  int currentLatency = 0; // Host-client ping latency millisecond stats tracker.
  String reconnectToken = '';

  // Heartbeat & Latency Manager
  late HeartbeatManager heartbeatManager;

  // Sockets / Channels references (Agnostic Dynamic Types)
  dynamic _serverSocket;
  dynamic _clientSocket;
  dynamic _udpDiscoverSocket;
  final List<dynamic> _connectedClients = [];

  RealtimeChannel? _webChannel;

  // Broadcasters/Listeners
  final _messageController = StreamController<P2PPacket>.broadcast();
  Stream<P2PPacket> get messageStream => _messageController.stream;

  final _roomController = StreamController<MultiplayerRoom?>.broadcast();
  Stream<MultiplayerRoom?> get roomStream => _roomController.stream;

  final _latencyController = StreamController<int>.broadcast();
  Stream<int> get latencyStream => _latencyController.stream;

  final List<MultiplayerRoom> discoveredRooms = [];
  final _discoveryController = StreamController<List<MultiplayerRoom>>.broadcast();
  Stream<List<MultiplayerRoom>> get discoveryStream => _discoveryController.stream;

  // Connection initiate er shuruতেই local unique IDs generate kore connection active monitoring start kore.
  void _initHeartbeat() {
    localPlayerId = const Uuid().v4();
    reconnectToken = const Uuid().v4();

    heartbeatManager = HeartbeatManager(
      localPlayerId: localPlayerId!,
      onPeerStale: (peerId) {
        debugPrint('Peer $peerId went stale!');
        _handlePeerStale(peerId);
      },
      onLatencyUpdated: (peerId, pingMs) {
        currentLatency = pingMs;
        _latencyController.add(currentLatency);
      },
    );
  }

  // ----------------------------------------------------
  // Discovery: Multicast, Broadcast & Web signaling
  // ----------------------------------------------------

  // Local private WiFi networks e automatic lobby lists scan korar main mechanism
  Future<void> startDiscovery() async {
    discoveredRooms.clear();
    _discoveryController.add(discoveredRooms);

    if (kIsWeb) {
      // Chrome/Web browser local UDP packets check korte pare na. Tai Supabase global channel subscribe kora hoy.
      final supabase = Supabase.instance.client;
      _webChannel = supabase.channel('global_lobby_signaling');
      _webChannel!.onBroadcast(
        event: 'room_beacon',
        callback: (payload) {
          try {
            final roomJson = payload['room'] as Map<String, dynamic>;
            final room = MultiplayerRoom.fromJson(roomJson);
            _addDiscoveredRoom(room);
          } catch (e) {
            debugPrint('Error parsing web discovery: $e');
          }
        },
      ).subscribe();
    } else {
      // Android/iOS/Native setup: local UDP broadcast ar multicast ports scan kore auto discover support pathay.
      try {
        _udpDiscoverSocket = await P2PSocketHelper.bindUdpDiscovery(9019, (message) {
          try {
            final roomMap = json.decode(message) as Map<String, dynamic>;
            final room = MultiplayerRoom.fromJson(roomMap);
            _addDiscoveredRoom(room);
          } catch (_) {}
        });
      } catch (e) {
        debugPrint('UDP Discovery Bind Error: $e');
      }
    }
  }

  void _addDiscoveredRoom(MultiplayerRoom room) {
    if (!discoveredRooms.any((r) => r.roomId == room.roomId)) {
      discoveredRooms.add(room);
      _discoveryController.add(List.from(discoveredRooms));
    }
  }

  void stopDiscovery() {
    _discoveryController.add([]);
    if (kIsWeb) {
      _webChannel = null;
    } else {
      try {
        P2PSocketHelper.closeSocket(_udpDiscoverSocket);
        _udpDiscoverSocket = null;
      } catch (_) {}
    }
  }

  // ----------------------------------------------------
  // Room Creation / Hosting (Dynamic Sockets / Web Channels)
  // ----------------------------------------------------

  Future<MultiplayerRoom> createRoom(String username, String gameType) async {
    isHost = true;
    localUsername = username;
    final roomId = const Uuid().v4().substring(0, 6).toUpperCase();

    if (kIsWeb) {
      // Web Room Hosting (WebSocket / Supabase Relay)
      final selfState = PlayerState(
        id: localPlayerId!,
        username: localUsername!,
        isReady: true,
      );

      activeRoom = MultiplayerRoom(
        roomId: roomId,
        hostId: localPlayerId!,
        port: 0,
        ipAddress: 'Supabase-Relay',
        players: [selfState],
        activeGame: gameType,
      );

      // Join room signaling channel
      final supabase = Supabase.instance.client;
      _webChannel = supabase.channel('room_$roomId');
      _webChannel!.onBroadcast(
        event: 'message',
        callback: (payload) {
          final packet = P2PPacket.fromJson(payload);
          _onPacketReceived(packet);
        },
      ).subscribe();

      // Broadcast periodic beacon for web discovery
      Timer.periodic(const Duration(seconds: 3), (timer) {
        if (activeRoom == null || !isHost) {
          timer.cancel();
          return;
        }
        final globalLobby = supabase.channel('global_lobby_signaling');
        globalLobby.sendBroadcastMessage(
          event: 'room_beacon',
          payload: {'room': activeRoom!.toJson()},
        );
      });

      _roomController.add(activeRoom);
      heartbeatManager.start();
      return activeRoom!;
    } else {
      // Native P2P Sockets with Dynamic Port Selection
      int port = 9018;
      bool bound = false;

      while (!bound && port < 9030) {
        try {
          final server = await P2PSocketHelper.bindTcpServer(port);
          if (server != null) {
            _serverSocket = server;
            bound = true;
            debugPrint('Successfully bound Host Server to Port: $port');
          } else {
            port++;
          }
        } catch (_) {
          port++;
        }
      }

      if (!bound) {
        throw Exception('UNABLE TO ALLOCATE MULTIPLAYER SOCKET');
      }

      final selfState = PlayerState(
        id: localPlayerId!,
        username: localUsername!,
        isReady: true,
      );

      activeRoom = MultiplayerRoom(
        roomId: roomId,
        hostId: localPlayerId!,
        port: port,
        ipAddress: '127.0.0.1',
        players: [selfState],
        activeGame: gameType,
      );

      // Listen for client TCP connections
      P2PSocketHelper.setupTcpServerListener(_serverSocket, (client) {
        _connectedClients.add(client);
        _setupNativeClientListener(client);
      });

      // Broadcast UDP Discovery beacon
      Timer.periodic(const Duration(seconds: 3), (timer) async {
        if (activeRoom == null || !isHost) {
          timer.cancel();
          return;
        }
        try {
          final roomData = utf8.encode(json.encode(activeRoom!.toJson()));
          await P2PSocketHelper.sendUdpBeacon(roomData, 9019);
        } catch (_) {}
      });

      _roomController.add(activeRoom);
      heartbeatManager.start();
      return activeRoom!;
    }
  }

  void _setupNativeClientListener(dynamic client) {
    P2PSocketHelper.setupTcpClientListener(
      client,
      (data) {
        try {
          final message = utf8.decode(data);
          final packetMap = json.decode(message) as Map<String, dynamic>;
          final packet = P2PPacket.fromJson(packetMap);
          _onPacketReceived(packet);
        } catch (_) {}
      },
      () {
        _connectedClients.remove(client);
        P2PSocketHelper.closeSocket(client);
      },
      (e) {
        _connectedClients.remove(client);
        P2PSocketHelper.closeSocket(client);
      },
    );
  }

  // ----------------------------------------------------
  // Joining Rooms
  // ----------------------------------------------------

  Future<void> joinRoom(String username, MultiplayerRoom room) async {
    isHost = false;
    localUsername = username;

    final selfState = PlayerState(
      id: localPlayerId!,
      username: localUsername!,
      isReady: false,
    );

    if (kIsWeb) {
      // Join Web Room via Supabase Channels
      activeRoom = room.copyWith(
        players: [...room.players, selfState],
      );

      final supabase = Supabase.instance.client;
      _webChannel = supabase.channel('room_${room.roomId}');
      _webChannel!.onBroadcast(
        event: 'message',
        callback: (payload) {
          final packet = P2PPacket.fromJson(payload);
          _onPacketReceived(packet);
        },
      ).subscribe();

      // Dispatch join packet
      Timer(const Duration(milliseconds: 500), () {
        sendPacket(P2PPacket(
          type: 'join',
          game: room.activeGame,
          payload: {'player': selfState.toJson()},
          senderId: localPlayerId!,
        ));
      });

      _roomController.add(activeRoom);
      heartbeatManager.start();
    } else {
      // Join Native Room via TCP Socket
      try {
        final client = await P2PSocketHelper.connectTcpClient(
          room.ipAddress == 'Supabase-Relay' ? '127.0.0.1' : room.ipAddress,
          room.port,
        );
        if (client == null) throw Exception('Uplink failed');
        _clientSocket = client;

        activeRoom = room.copyWith(
          players: [...room.players, selfState],
        );

        P2PSocketHelper.setupTcpClientListener(
          client,
          (data) {
            try {
              final message = utf8.decode(data);
              final packetMap = json.decode(message) as Map<String, dynamic>;
              final packet = P2PPacket.fromJson(packetMap);
              _onPacketReceived(packet);
            } catch (_) {}
          },
          () => _handleHostDisconnected(),
          (_) => _handleHostDisconnected(),
        );

        // Send join packet
        sendPacket(P2PPacket(
          type: 'join',
          game: room.activeGame,
          payload: {'player': selfState.toJson()},
          senderId: localPlayerId!,
        ));

        _roomController.add(activeRoom);
        heartbeatManager.start();
      } catch (e) {
        throw Exception('UNABLE TO ESTABLISH TCP UPLINK');
      }
    }
  }

  // ----------------------------------------------------
  // Dispatch / Send Packets
  // ----------------------------------------------------

  void sendPacket(P2PPacket packet) {
    if (!packet.isValid()) return;

    if (kIsWeb) {
      // Send Web channel package
      _webChannel?.sendBroadcastMessage(
        event: 'message',
        payload: packet.toJson(),
      );
    } else {
      // Send Native TCP sockets
      final raw = json.encode(packet.toJson());
      final data = utf8.encode(raw);

      if (isHost) {
        // Host broadcasts to all clients
        for (final client in _connectedClients) {
          P2PSocketHelper.sendTcpData(client, data);
        }
      } else {
        // Client sends directly to Host
        P2PSocketHelper.sendTcpData(_clientSocket, data);
      }
    }
  }

  // ----------------------------------------------------
  // Packet Received Pipeline
  // ----------------------------------------------------

  void _onPacketReceived(P2PPacket packet) {
    // Record heartbeat immediately
    heartbeatManager.registerHeartbeat(packet.senderId);

    // Filter by type
    switch (packet.type) {
      case 'ping':
        // Return pong immediately
        sendPacket(P2PPacket(
          type: 'pong',
          game: packet.game,
          payload: packet.payload,
          senderId: localPlayerId!,
        ));
        break;

      case 'pong':
        heartbeatManager.registerPong(packet.senderId, packet.payload);
        break;

      case 'join':
        if (isHost && activeRoom != null) {
          final newPlayer = PlayerState.fromJson(packet.payload['player'] as Map<String, dynamic>);
          if (!activeRoom!.players.any((p) => p.id == newPlayer.id)) {
            activeRoom = activeRoom!.copyWith(
              players: [...activeRoom!.players, newPlayer],
            );
            _roomController.add(activeRoom);
            // Broadcast room update
            sendPacket(P2PPacket(
              type: 'room_sync',
              game: packet.game,
              payload: {'room': activeRoom!.toJson()},
              senderId: localPlayerId!,
            ));
          }
        }
        break;

      case 'room_sync':
        if (!isHost) {
          activeRoom = MultiplayerRoom.fromJson(packet.payload['room'] as Map<String, dynamic>);
          _roomController.add(activeRoom);
        }
        break;

      case 'ready':
        if (isHost && activeRoom != null) {
          final pid = packet.senderId;
          final updatedList = activeRoom!.players.map((p) {
            return p.id == pid ? p.copyWith(isReady: packet.payload['isReady'] as bool) : p;
          }).toList();
          activeRoom = activeRoom!.copyWith(players: updatedList);
          _roomController.add(activeRoom);
          sendPacket(P2PPacket(
            type: 'room_sync',
            game: packet.game,
            payload: {'room': activeRoom!.toJson()},
            senderId: localPlayerId!,
          ));
        }
        break;

      default:
        // Forward custom game packets to subscriber screens
        _messageController.add(packet);
        break;
    }
  }

  // ----------------------------------------------------
  // Cleanups, Disconnects & Session Restores
  // ----------------------------------------------------

  void _handlePeerStale(String peerId) {
    if (activeRoom != null) {
      final updatedList = activeRoom!.players.where((p) => p.id != peerId).toList();
      activeRoom = activeRoom!.copyWith(players: updatedList);
      _roomController.add(activeRoom);
    }
  }

  void _handleHostDisconnected() {
    debugPrint('HOST NETWORK DISCONNECTED! Triggering session restore...');
    leaveRoom();
  }

  void leaveRoom() {
    stopDiscovery();
    heartbeatManager.stop();

    if (kIsWeb) {
      _webChannel = null;
    } else {
      try {
        P2PSocketHelper.closeSocket(_clientSocket);
        _clientSocket = null;
        P2PSocketHelper.closeSocket(_serverSocket);
        _serverSocket = null;
        for (final client in _connectedClients) {
          P2PSocketHelper.closeSocket(client);
        }
        _connectedClients.clear();
      } catch (_) {}
    }

    activeRoom = null;
    _roomController.add(null);
  }
}
