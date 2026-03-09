import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/control_protocol.dart';
import '../data/udp_control_sender.dart';
import '../domain/controller_state.dart';

final controllerControllerProvider =
    StateNotifierProvider.autoDispose<ControllerController, ControllerState>((
      ref,
    ) {
      final c = ControllerController();
      ref.onDispose(() => c.dispose());
      return c;
    });

class GamepadButton {
  static const int a = 0;
  static const int b = 1;
  static const int x = 2;
  static const int y = 3;
  static const int l1 = 4;
  static const int r1 = 5;
  static const int l3 = 6;
  static const int r3 = 7;
  static const int select = 8;
  static const int start = 9;
  static const int home = 10;
}

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

    await _sender!.start(localPort: port, buildPacket: _buildPacket);
  }

  Uint8List _buildPacket() {
    final s = state;
    final nextSeq = _seq++;
    return ControlProtocol.buildPacket(
      seq: nextSeq,
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
  }

  void _setStateAndSend(ControllerState next) {
    if (_sameControlState(state, next)) return;
    state = next;
    _sender?.sendNow();
  }

  bool _sameControlState(ControllerState a, ControllerState b) {
    return a.lx == b.lx &&
        a.ly == b.ly &&
        a.rx == b.rx &&
        a.ry == b.ry &&
        a.l2 == b.l2 &&
        a.r2 == b.r2 &&
        a.dpadX == b.dpadX &&
        a.dpadY == b.dpadY &&
        a.buttons == b.buttons;
  }

  void resetNeutral() {
    state = ControllerState.neutral();
  }

  void resetNeutralAndSend() {
    _setStateAndSend(ControllerState.neutral());
  }

  bool get isConnected => _sender != null && _sender!.isRunning;

  void disconnect() {
    resetNeutral(); // ensures next connect starts neutral
    _sender?.stop();
    _sender = null;
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }

  // minimal setters (we’ll expand)
  void setLeftStick(int lx, int ly) =>
      _setStateAndSend(state.copyWith(lx: lx, ly: ly));
  void setRightStick(int rx, int ry) =>
      _setStateAndSend(state.copyWith(rx: rx, ry: ry));

  void setTriggerL2(int v) => _setStateAndSend(state.copyWith(l2: v));
  void setTriggerR2(int v) => _setStateAndSend(state.copyWith(r2: v));

  void setDpad(int x, int y) =>
      _setStateAndSend(state.copyWith(dpadX: x, dpadY: y));

  void setButtonBit(int bit, bool pressed) {
    final mask = 1 << bit;
    final next = pressed ? (state.buttons | mask) : (state.buttons & ~mask);
    _setStateAndSend(state.copyWith(buttons: next));
  }
}
