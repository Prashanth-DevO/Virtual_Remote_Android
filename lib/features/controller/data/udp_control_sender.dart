import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

class UdpControlSender {
  final InternetAddress targetIp;
  final int targetPort;

  RawDatagramSocket? _socket;
  Timer? _timer;

  UdpControlSender({required this.targetIp, required this.targetPort});

  Future<void> start({required Uint8List Function() buildPacket}) async {
    if (_socket != null) return;

    final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    _socket = socket;

    // 60Hz
    _timer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      final pkt = buildPacket();
      socket.send(pkt, targetIp, targetPort);
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _socket?.close();
    _socket = null;
  }

  bool get isRunning => _socket != null;
}