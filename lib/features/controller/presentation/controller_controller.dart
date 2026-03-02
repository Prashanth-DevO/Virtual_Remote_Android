import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/control_protocol.dart';
import '../data/udp_control_sender.dart';
import '../domain/controller_state.dart';

final controllerControllerProvider =
StateNotifierProvider.autoDispose<ControllerController, ControllerState>((ref) {
  final c = ControllerController();
  ref.onDispose(() => c.dispose());
  return c;
});

class ControllerController extends StateNotifier<ControllerState> {
  ControllerController() : super(ControllerState.neutral());

  UdpControlSender? _sender;
  int _seq = 0;

  Future<void> connectAndStart({
    required InternetAddress ip,
    required int port,
  }) async {
    // stop old
    _sender?.stop();

    _sender = UdpControlSender(targetIp: ip, targetPort: port);

    await _sender!.start(buildPacket: () {
      final s = state;
      final pkt = ControlProtocol.buildPacket(
        seq: _seq++,
        lx: s.lx,
        ly: s.ly,
        rx: s.rx,
        ry: s.ry,
        l2: s.l2,
        r2: s.r2,
        dpadX: s.dpadX,
        dpadY: s.dpadY,
        buttons: s.buttons,
      );
      return pkt;
    });
  }

  void resetNeutral() {
    state = ControllerState.neutral();
  }

  bool get isConnected => _sender != null && _sender!.isRunning;

  void disconnect() {
    resetNeutral();       // ensures next connect starts neutral
    _sender?.stop();
    _sender = null;
  }

  void dispose() {
    disconnect();
  }

  // minimal setters (we’ll expand)
  void setLeftStick(int lx, int ly) => state = state.copyWith(lx: lx, ly: ly);
  void setRightStick(int rx, int ry) => state = state.copyWith(rx: rx, ry: ry);

  void setTriggerL2(int v) => state = state.copyWith(l2: v);
  void setTriggerR2(int v) => state = state.copyWith(r2: v);

  void setDpad(int x, int y) => state = state.copyWith(dpadX: x, dpadY: y);

  void setButtonBit(int bit, bool pressed) {
    final mask = 1 << bit;
    final next = pressed ? (state.buttons | mask) : (state.buttons & ~mask);
    state = state.copyWith(buttons: next);
  }
}