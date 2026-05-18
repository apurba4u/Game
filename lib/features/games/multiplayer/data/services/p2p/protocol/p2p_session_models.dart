import 'package:uuid/uuid.dart';

enum MatchState {
  lobby,
  countdown,
  playing,
  paused,
  finished,
  results,
}

class PlayerState {
  final String id;
  final String username;
  final bool isReady;
  final double progress; // For Typing Battle / Quiz
  final int latencyMs;
  final int score;

  const PlayerState({
    required this.id,
    required this.username,
    this.isReady = false,
    this.progress = 0.0,
    this.latencyMs = 0,
    this.score = 0,
  });

  PlayerState copyWith({
    String? id,
    String? username,
    bool? isReady,
    double? progress,
    int? latencyMs,
    int? score,
  }) {
    return PlayerState(
      id: id ?? this.id,
      username: username ?? this.username,
      isReady: isReady ?? this.isReady,
      progress: progress ?? this.progress,
      latencyMs: latencyMs ?? this.latencyMs,
      score: score ?? this.score,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'isReady': isReady,
        'progress': progress,
        'latencyMs': latencyMs,
        'score': score,
      };

  factory PlayerState.fromJson(Map<String, dynamic> json) => PlayerState(
        id: json['id'] as String,
        username: json['username'] as String,
        isReady: json['isReady'] as bool? ?? false,
        progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
        latencyMs: json['latencyMs'] as int? ?? 0,
        score: json['score'] as int? ?? 0,
      );
}

class MultiplayerRoom {
  final String roomId;
  final String hostId;
  final int port;
  final String ipAddress;
  final List<PlayerState> players;
  final String activeGame;
  final MatchState matchState;

  const MultiplayerRoom({
    required this.roomId,
    required this.hostId,
    required this.port,
    required this.ipAddress,
    required this.players,
    required this.activeGame,
    this.matchState = MatchState.lobby,
  });

  MultiplayerRoom copyWith({
    String? roomId,
    String? hostId,
    int? port,
    String? ipAddress,
    List<PlayerState>? players,
    String? activeGame,
    MatchState? matchState,
  }) {
    return MultiplayerRoom(
      roomId: roomId ?? this.roomId,
      hostId: hostId ?? this.hostId,
      port: port ?? this.port,
      ipAddress: ipAddress ?? this.ipAddress,
      players: players ?? this.players,
      activeGame: activeGame ?? this.activeGame,
      matchState: matchState ?? this.matchState,
    );
  }

  Map<String, dynamic> toJson() => {
        'roomId': roomId,
        'hostId': hostId,
        'port': port,
        'ipAddress': ipAddress,
        'players': players.map((p) => p.toJson()).toList(),
        'activeGame': activeGame,
        'matchState': matchState.name,
      };

  factory MultiplayerRoom.fromJson(Map<String, dynamic> json) => MultiplayerRoom(
        roomId: json['roomId'] as String,
        hostId: json['hostId'] as String,
        port: json['port'] as int? ?? 9018,
        ipAddress: json['ipAddress'] as String? ?? '127.0.0.1',
        players: (json['players'] as List<dynamic>?)
                ?.map((e) => PlayerState.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        activeGame: json['activeGame'] as String? ?? 'tic_tac_toe',
        matchState: MatchState.values.firstWhere(
          (e) => e.name == json['matchState'],
          orElse: () => MatchState.lobby,
        ),
      );
}

class GameSession {
  final String sessionId;
  final String gameType;
  final MatchState matchState;
  final int startTimestamp;

  GameSession({
    String? sessionId,
    required this.gameType,
    this.matchState = MatchState.lobby,
    int? startTimestamp,
  })  : sessionId = sessionId ?? const Uuid().v4(),
        startTimestamp = startTimestamp ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'gameType': gameType,
        'matchState': matchState.name,
        'startTimestamp': startTimestamp,
      };
}
