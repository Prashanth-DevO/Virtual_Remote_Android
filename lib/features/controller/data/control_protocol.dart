import 'dart:typed_data';

class ControlProtocol {
  // Must match C++ protocol.h
  static const int unioMagic = 0x4F494E55; // 'UNIO'
  static const int version = 1;
  static const int size = 36;

  static int timestampUs() {
    final now = DateTime.now().microsecondsSinceEpoch;
    return now; // fits in uint64
  }

  static Uint8List buildPacket({
    required int seq,
    required int lx,
    required int ly,
    required int rx,
    required int ry,
    required int l2,
    required int r2,
    required int dpadX,
    required int dpadY,
    required int buttons,
  }) {
    // clamp hard
    int clamp16(int v) => v < -32768 ? -32768 : (v > 32767 ? 32767 : v);
    int clampU8(int v) => v < 0 ? 0 : (v > 255 ? 255 : v);
    int clampI8(int v) => v < -1 ? -1 : (v > 1 ? 1 : v);

    final bd = ByteData(size);

    bd.setUint32(0, unioMagic, Endian.little);
    bd.setUint16(4, version, Endian.little);
    bd.setUint16(6, size, Endian.little);

    bd.setUint32(8, seq, Endian.little);
    bd.setUint64(12, timestampUs(), Endian.little);

    bd.setInt16(20, clamp16(lx), Endian.little);
    bd.setInt16(22, clamp16(ly), Endian.little);
    bd.setInt16(24, clamp16(rx), Endian.little);
    bd.setInt16(26, clamp16(ry), Endian.little);

    bd.setUint8(28, clampU8(l2));
    bd.setUint8(29, clampU8(r2));
    bd.setInt8(30, clampI8(dpadX));
    bd.setInt8(31, clampI8(dpadY));

    bd.setUint32(32, buttons, Endian.little);

    return bd.buffer.asUint8List();
  }
}