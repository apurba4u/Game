import 'dart:async';
import 'dart:convert';
import 'dart:io';

class P2PSocketHelper {
  static Future<RawDatagramSocket?> bindUdpDiscovery(int port, Function(String message) onMessage) async {
    try {
      final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, port);
      socket.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final datagram = socket.receive();
          if (datagram != null) {
            try {
              onMessage(utf8.decode(datagram.data));
            } catch (_) {}
          }
        }
      });
      return socket;
    } catch (_) {
      return null;
    }
  }

  static Future<ServerSocket?> bindTcpServer(int port) async {
    try {
      return await ServerSocket.bind(InternetAddress.anyIPv4, port);
    } catch (_) {
      return null;
    }
  }

  static Future<Socket?> connectTcpClient(String ip, int port) async {
    try {
      return await Socket.connect(ip, port);
    } catch (_) {
      return null;
    }
  }

  static Future<void> sendUdpBeacon(List<int> data, int port) async {
    try {
      final udp = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      udp.broadcastEnabled = true;
      udp.send(data, InternetAddress('255.255.255.255'), port);
      udp.send(data, InternetAddress('224.0.0.1'), port);
      udp.close();
    } catch (_) {}
  }

  static void sendTcpData(dynamic socket, List<int> data) {
    if (socket is Socket) {
      try {
        socket.add(data);
      } catch (_) {}
    }
  }

  static void setupTcpServerListener(dynamic serverSocket, Function(dynamic client) onClientConnected) {
    if (serverSocket is ServerSocket) {
      serverSocket.listen((client) {
        onClientConnected(client);
      });
    }
  }

  static void setupTcpClientListener(
    dynamic clientSocket,
    Function(List<int> data) onData,
    Function() onDone,
    Function(dynamic error) onError,
  ) {
    if (clientSocket is Socket) {
      clientSocket.listen(
        onData,
        onDone: onDone,
        onError: onError,
      );
    }
  }

  static void closeSocket(dynamic socket) {
    try {
      if (socket is Socket) {
        socket.close();
      } else if (socket is ServerSocket) {
        socket.close();
      } else if (socket is RawDatagramSocket) {
        socket.close();
      }
    } catch (_) {}
  }
}
