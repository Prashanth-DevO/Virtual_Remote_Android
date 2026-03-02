import 'dart:typed_data';

class DiscoveryProtocol {
  static const int discoveryPort = 9002;

  // Matches C++: 0x53444A4C ('L''J''D''S') little-endian.
  static const int magic = 0x53444A4C;
  static const int version = 1;

  static const int msgDiscoverReq = 1;
  static const int msgDiscoverResp = 2;

  static const int maxNameLen = 64;

  // Struct sizes (packed)
  static const int reqSize = 4 + 1 + 1 + 2 + 4; // 12
  static const int respHeaderSize =
      4 + 1 + 1 + 2 + 4 + 8 + 2 + 2 + 2 + 2 + 4; // 34

  static Uint8List buildDiscoverReq(int nonce) {
    final bd = ByteData(reqSize);
    bd.setUint32(0, magic, Endian.little);
    bd.setUint8(4, version);
    bd.setUint8(5, msgDiscoverReq);
    bd.setUint16(6, 0, Endian.little); // reserved
    bd.setUint32(8, nonce, Endian.little);
    return bd.buffer.asUint8List();
  }

  static DiscoverRespParsed? tryParseDiscoverResp(Uint8List bytes, int expectedNonce) {
    if (bytes.length < respHeaderSize) return null;

    final bd = ByteData.sublistView(bytes);

    final m = bd.getUint32(0, Endian.little);
    if (m != magic) return null;

    final v = bd.getUint8(4);
    if (v != version) return null;

    final msgType = bd.getUint8(5);
    if (msgType != msgDiscoverResp) return null;

    // reserved at 6..7 ignored
    final nonce = bd.getUint32(8, Endian.little);
    if (nonce != expectedNonce) return null;

    final serverId = bd.getUint64(12, Endian.little);
    final controlPort = bd.getUint16(20, Endian.little);
    final feedbackPort = bd.getUint16(22, Endian.little);
    final protoVer = bd.getUint16(24, Endian.little);
    final nameLen = bd.getUint16(26, Endian.little);
    final flags = bd.getUint32(28, Endian.little);

    if (nameLen > maxNameLen) return null;
    final expectedTotal = respHeaderSize + nameLen;
    if (bytes.length < expectedTotal) return null;

    final nameBytes = bytes.sublist(respHeaderSize, respHeaderSize + nameLen);
    final name = _decodeUtf8Loose(nameBytes);

    return DiscoverRespParsed(
      nonce: nonce,
      serverId: serverId,
      controlPort: controlPort,
      feedbackPort: feedbackPort,
      protoVer: protoVer,
      flags: flags,
      name: name,
    );
  }

  static String _decodeUtf8Loose(List<int> bytes) {
    // Discovery name should be ASCII/UTF-8. If it's garbage, drop invalids.
    try {
      return String.fromCharCodes(bytes).trim();
    } catch (_) {
      return 'linux-joystick';
    }
  }
}

class DiscoverRespParsed {
  final int nonce;
  final int serverId; // uint64 -> fits in Dart int on 64-bit, but keep safe when storing
  final int controlPort;
  final int feedbackPort;
  final int protoVer;
  final int flags;
  final String name;

  const DiscoverRespParsed({
    required this.nonce,
    required this.serverId,
    required this.controlPort,
    required this.feedbackPort,
    required this.protoVer,
    required this.flags,
    required this.name,
  });
}