import 'dart:async';

class HeartbeatManager {
  final String localPlayerId;
  final Function(String peerId) onPeerStale;
  final Function(String peerId, int pingMs) onLatencyUpdated;

  HeartbeatManager({
    required this.localPlayerId,
    required this.onPeerStale,
    required this.onLatencyUpdated,
  });

  Timer? _heartbeatTimer;
  final Map<String, int> _lastSeenTimestamps = {};
  final Map<String, int> _pingStartTimes = {};
  final Map<String, int> _latencies = {};

  void start() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _checkStalePeers();
    });
  }

  void stop() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _lastSeenTimestamps.clear();
    _pingStartTimes.clear();
    _latencies.clear();
  }

  // Called when a packet is received from a peer
  void registerHeartbeat(String peerId) {
    _lastSeenTimestamps[peerId] = DateTime.now().millisecondsSinceEpoch;
  }

  // Generates ping payloads
  Map<String, dynamic> createPingPayload(String peerId) {
    final now = DateTime.now().millisecondsSinceEpoch;
    _pingStartTimes[peerId] = now;
    return {'pingTime': now};
  }

  // Handles pong return times
  void registerPong(String peerId, Map<String, dynamic> payload) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final pingStart = _pingStartTimes[peerId];
    if (pingStart != null) {
      final elapsed = now - pingStart;
      _latencies[peerId] = elapsed;
      onLatencyUpdated(peerId, elapsed);
    }
    _lastSeenTimestamps[peerId] = now;
  }

  int getLatency(String peerId) => _latencies[peerId] ?? 0;

  void _checkStalePeers() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final threshold = 6000; // 6 seconds without heartbeat is stale

    final stalePeers = <String>[];
    _lastSeenTimestamps.forEach((peerId, lastSeen) {
      if (now - lastSeen > threshold) {
        stalePeers.add(peerId);
      }
    });

    for (final peerId in stalePeers) {
      _lastSeenTimestamps.remove(peerId);
      _pingStartTimes.remove(peerId);
      _latencies.remove(peerId);
      onPeerStale(peerId);
    }
  }
}
