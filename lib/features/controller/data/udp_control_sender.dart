import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

class UdpControlSender {
  final InternetAddress targetIp;
  final int targetPort;

  RawDatagramSocket? _socket;
  Timer? _timer;
  Uint8List Function()? _buildPacket;

  UdpControlSender({required this.targetIp, required this.targetPort});

  Future<void> start({
    required Uint8List Function() buildPacket,
    int localPort = 0,
  }) async {
    if (_socket != null) return;

    RawDatagramSocket socket;
    try {
      socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, localPort);
    } on SocketException {
      // If requested source port is unavailable, fall back to an ephemeral port.
      socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    }
    _socket = socket;
    _buildPacket = buildPacket;

    sendNow();

    // 60Hz
    _timer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      sendNow();
    });
  }

  void sendNow() {
    final socket = _socket;
    final buildPacket = _buildPacket;
    if (socket == null || buildPacket == null) return;
    final pkt = buildPacket();
    socket.send(pkt, targetIp, targetPort);
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _socket?.close();
    _socket = null;
    _buildPacket = null;
  }

  bool get isRunning => _socket != null;
}
