import 'dart:async';

class P2PSocketHelper {
  static Future<dynamic> bindUdpDiscovery(int port, Function(String message) onMessage) async {
    return null;
  }

  static Future<dynamic> bindTcpServer(int port) async {
    return null;
  }

  static Future<dynamic> connectTcpClient(String ip, int port) async {
    return null;
  }

  static Future<void> sendUdpBeacon(List<int> data, int port) async {}

  static void sendTcpData(dynamic socket, List<int> data) {}

  static void setupTcpServerListener(dynamic serverSocket, Function(dynamic client) onClientConnected) {}

  static void setupTcpClientListener(
    dynamic clientSocket,
    Function(List<int> data) onData,
    Function() onDone,
    Function(dynamic error) onError,
  ) {}

  static void closeSocket(dynamic socket) {}
}
