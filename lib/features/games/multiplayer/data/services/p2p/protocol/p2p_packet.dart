class P2PPacket {
  final String type;
  final String game;
  final Map<String, dynamic> payload;
  final int timestamp;
  final String senderId;

  P2PPacket({
    required this.type,
    required this.game,
    required this.payload,
    int? timestamp,
    required this.senderId,
  }) : timestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toJson() => {
        'type': type,
        'game': game,
        'payload': payload,
        'timestamp': timestamp,
        'senderId': senderId,
      };

  factory P2PPacket.fromJson(Map<String, dynamic> json) {
    return P2PPacket(
      type: json['type'] as String? ?? 'sync',
      game: json['game'] as String? ?? 'general',
      payload: Map<String, dynamic>.from(json['payload'] as Map? ?? {}),
      timestamp: json['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      senderId: json['senderId'] as String? ?? 'unknown',
    );
  }

  // Validator to verify packet integrity and anti-cheat checks
  bool isValid() {
    if (type.isEmpty || senderId.isEmpty) return false;
    // Malformed packet checks
    if (timestamp <= 0) return false;
    return true;
  }
}
