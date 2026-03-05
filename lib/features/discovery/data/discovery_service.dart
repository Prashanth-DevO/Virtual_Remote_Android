import 'dart:async';
import 'dart:io';
import 'dart:math';

import '../domain/discovered_server.dart';
import 'discovery_protocol.dart';

class DiscoveryService {
  final Random _rng = Random.secure();

  int _nextNonce() => _rng.nextInt(0x7fffffff);

  /// targets: where to send discovery packets (unicast/broadcast)
  Future<List<DiscoveredServer>> scan({
    Duration timeout = const Duration(milliseconds: 600),
    required List<InternetAddress> targets,
  }) async {
    final nonce = _nextNonce();
    final req = DiscoveryProtocol.buildDiscoverReq(nonce);

    final resultsByServerId = <BigInt, DiscoveredServer>{};

    RawDatagramSocket socket;
    try {
      socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    } catch (_) {
      return const [];
    }

    socket.broadcastEnabled = true;

    // Send to all targets (broadcast + unicast)
    for (final t in targets) {
      socket.send(req, t, DiscoveryProtocol.discoveryPort);
    }

    final done = Completer<List<DiscoveredServer>>();
    Timer? timer;

    void finish() {
      if (done.isCompleted) return;
      timer?.cancel();
      socket.close();
      done.complete(resultsByServerId.values.toList()
        ..sort((a, b) => b.seenAt.compareTo(a.seenAt)));
    }

    timer = Timer(timeout, finish);

    socket.listen((event) {
      if (event != RawSocketEvent.read) return;
      final dg = socket.receive();
      if (dg == null) return;

      final parsed = DiscoveryProtocol.tryParseDiscoverResp(dg.data, nonce);
      if (parsed == null) return;

      final serverIdBig = BigInt.from(parsed.serverId);

      final server = DiscoveredServer(
        ip: dg.address,
        controlPort: parsed.controlPort,
        feedbackPort: parsed.feedbackPort,
        protoVer: parsed.protoVer,
        flags: parsed.flags,
        nonce: parsed.nonce,
        serverId: serverIdBig,
        name: parsed.name.isEmpty ? 'LINUX_VIRTUAL_BOX 🎮' : parsed.name,
        seenAt: DateTime.now(),
      );

      resultsByServerId[serverIdBig] = server;
    });

    return done.future;
  }
}