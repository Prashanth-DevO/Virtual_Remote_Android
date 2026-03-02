import 'dart:io';

class DiscoveredServer {
  final InternetAddress ip;
  final int controlPort;
  final int feedbackPort;
  final int protoVer;
  final int flags;
  final int nonce;
  final BigInt serverId;
  final String name;
  final DateTime seenAt;

  const DiscoveredServer({
    required this.ip,
    required this.controlPort,
    required this.feedbackPort,
    required this.protoVer,
    required this.flags,
    required this.nonce,
    required this.serverId,
    required this.name,
    required this.seenAt,
  });

  bool get pairedLocked => (flags & (1 << 2)) != 0;
  bool get supportsFeedback => (flags & (1 << 0)) != 0;
  bool get supportsRumble => (flags & (1 << 1)) != 0;

  DiscoveredServer copyWith({DateTime? seenAt}) => DiscoveredServer(
        ip: ip,
        controlPort: controlPort,
        feedbackPort: feedbackPort,
        protoVer: protoVer,
        flags: flags,
        nonce: nonce,
        serverId: serverId,
        name: name,
        seenAt: seenAt ?? this.seenAt,
      );
}