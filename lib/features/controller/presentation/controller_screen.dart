import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../discovery/domain/discovered_server.dart';
import '../domain/controller_state.dart';
import 'controller_controller.dart';

class ControllerScreen extends ConsumerStatefulWidget {
  final DiscoveredServer server;
  const ControllerScreen({super.key, required this.server});

  @override
  ConsumerState<ControllerScreen> createState() => _ControllerScreenState();
}

class _ControllerScreenState extends ConsumerState<ControllerScreen>
    with WidgetsBindingObserver {
  Future<void> _lockLandscape() async {
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  Future<void> _restoreOrientations() async {
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lockLandscape();

    Future.microtask(() {
      ref
          .read(controllerControllerProvider.notifier)
          .connectAndStart(
            ip: widget.server.ip,
            port: widget.server.controlPort,
          );
    });
  }

  @override
  void dispose() {
    _restoreOrientations();
    WidgetsBinding.instance.removeObserver(this);
    ref.read(controllerControllerProvider.notifier).disconnect();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final ctl = ref.read(controllerControllerProvider.notifier);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      ctl.disconnect();
    } else if (state == AppLifecycleState.resumed) {
      ctl.connectAndStart(
        ip: widget.server.ip,
        port: widget.server.controlPort,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(controllerControllerProvider);
    final ctl = ref.read(controllerControllerProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFE8E2EC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1300),
              child: _XboxControllerSurface(
                state: s,
                onLeftStick: ctl.setLeftStick,
                onRightStick: ctl.setRightStick,
                onL2Changed: ctl.setTriggerL2,
                onR2Changed: ctl.setTriggerR2,
                onButton: ctl.setButtonBit,
                onDpad: ctl.setDpad,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _XboxControllerSurface extends StatelessWidget {
  final ControllerState state;
  final void Function(int x, int y) onLeftStick;
  final void Function(int x, int y) onRightStick;
  final ValueChanged<int> onL2Changed;
  final ValueChanged<int> onR2Changed;
  final void Function(int bit, bool pressed) onButton;
  final void Function(int x, int y) onDpad;

  const _XboxControllerSurface({
    required this.state,
    required this.onLeftStick,
    required this.onRightStick,
    required this.onL2Changed,
    required this.onR2Changed,
    required this.onButton,
    required this.onDpad,
  });

  bool _isOn(int bit) => (state.buttons & (1 << bit)) != 0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        double lf(double f) => w * f;
        double tf(double f) => h * f;

        final stickSize = math.min(w * 0.24, h * 0.39);
        final l3r3Size = stickSize * 1.5;
        final dpadSize = math.min(w * 0.17, h * 0.3);
        final faceSize = math.min(w * 0.21, h * 0.34);
        final centerControlWidth = (w * 0.38).clamp(250.0, 430.0);
        final compactWidth = (centerControlWidth * 0.3).clamp(70.0, 112.0);
        final compactHeight = (h * 0.08).clamp(38.0, 54.0);
        final compactFontSize = (compactHeight * 0.34).clamp(14.0, 18.0);
        final homeButtonSize = (h * 0.14).clamp(56.0, 84.0);

        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF151922),
            borderRadius: BorderRadius.circular(48),
            border: Border.all(color: const Color(0xFF414652), width: 4),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFEAE5EE),
                borderRadius: BorderRadius.circular(34),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: lf(0.06),
                    top: tf(0.07),
                    width: w * 0.18,
                    height: h * 0.10,
                    child: _PressButton(
                      label: 'LB',
                      active: _isOn(GamepadButton.l1),
                      onChanged: (v) => onButton(GamepadButton.l1, v),
                    ),
                  ),
                  Positioned(
                    left: lf(0.06),
                    top: tf(0.20),
                    width: w * 0.05,
                    height: h * 0.34,
                    child: _TriggerSlider(
                      label: 'LT',
                      value: state.l2,
                      onChanged: onL2Changed,
                    ),
                  ),
                  Positioned(
                    right: lf(0.06),
                    top: tf(0.07),
                    width: w * 0.18,
                    height: h * 0.10,
                    child: _PressButton(
                      label: 'RB',
                      active: _isOn(GamepadButton.r1),
                      onChanged: (v) => onButton(GamepadButton.r1, v),
                    ),
                  ),
                  Positioned(
                    right: lf(0.06),
                    top: tf(0.20),
                    width: w * 0.05,
                    height: h * 0.34,
                    child: _TriggerSlider(
                      label: 'RT',
                      value: state.r2,
                      onChanged: onR2Changed,
                    ),
                  ),
                  Positioned(
                    left: (w - centerControlWidth) / 2,
                    top: tf(0.12),
                    width: centerControlWidth,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _PressButton(
                          label: 'Back',
                          active: _isOn(GamepadButton.select),
                          onChanged: (v) => onButton(GamepadButton.select, v),
                          compact: true,
                          width: compactWidth,
                          height: compactHeight,
                          fontSize: compactFontSize,
                        ),
                        _MiniCenterButton(
                          icon: Icons.close,
                          active: _isOn(GamepadButton.home),
                          onChanged: (v) => onButton(GamepadButton.home, v),
                          size: homeButtonSize,
                          iconSize: homeButtonSize * 0.62,
                        ),
                        _PressButton(
                          label: 'Start',
                          active: _isOn(GamepadButton.start),
                          onChanged: (v) => onButton(GamepadButton.start, v),
                          compact: true,
                          width: compactWidth,
                          height: compactHeight,
                          fontSize: compactFontSize,
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: lf(0.07),
                    bottom: tf(0.07),
                    width: l3r3Size,
                    height: l3r3Size,
                    child: _AnalogStick(
                      x: state.lx,
                      y: state.ly,
                      onChanged: onLeftStick,
                      onReset: () => onLeftStick(0, 0),
                      ringColor: const Color(0xFF2D323E),
                      label: 'L3',
                    ),
                  ),
                  Positioned(
                    left: lf(0.28),
                    bottom: tf(0.24),
                    width: dpadSize,
                    height: dpadSize,
                    child: _Dpad(x: state.dpadX, y: state.dpadY, onChanged: onDpad),
                  ),
                  Positioned(
                    right: lf(0.07),
                    bottom: tf(0.07),
                    width: l3r3Size,
                    height: l3r3Size,
                    child: _AnalogStick(
                      x: state.rx,
                      y: state.ry,
                      onChanged: onRightStick,
                      onReset: () => onRightStick(0, 0),
                      ringColor: const Color(0xFF2D323E),
                      label: 'R3',
                    ),
                  ),
                  Positioned(
                    right: lf(0.28),
                    bottom: tf(0.24),
                    width: faceSize,
                    height: faceSize,
                    child: _FaceButtons(
                      a: _isOn(GamepadButton.a),
                      b: _isOn(GamepadButton.b),
                      x: _isOn(GamepadButton.x),
                      y: _isOn(GamepadButton.y),
                      onButton: onButton,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PressButton extends StatelessWidget {
  final String label;
  final bool active;
  final ValueChanged<bool> onChanged;
  final bool compact;
  final double? width;
  final double? height;
  final double? fontSize;

  const _PressButton({
    required this.label,
    required this.active,
    required this.onChanged,
    this.compact = false,
    this.width,
    this.height,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => onChanged(true),
      onTapUp: (_) => onChanged(false),
      onTapCancel: () => onChanged(false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 70),
        width: width ?? (compact ? 120 : null),
        height: height ?? (compact ? 56 : null),
        decoration: BoxDecoration(
          color: active
              ? Theme.of(context).colorScheme.primaryContainer
              : const Color(0xFF2D313B),
          borderRadius: BorderRadius.circular(compact ? 28 : 16),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: fontSize ?? (compact ? 18 : 16),
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _MiniCenterButton extends StatelessWidget {
  final IconData icon;
  final bool active;
  final ValueChanged<bool> onChanged;
  final double size;
  final double iconSize;

  const _MiniCenterButton({
    required this.icon,
    required this.active,
    required this.onChanged,
    this.size = 92,
    this.iconSize = 58,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => onChanged(true),
      onTapUp: (_) => onChanged(false),
      onTapCancel: () => onChanged(false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 70),
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active
              ? Theme.of(context).colorScheme.primary
              : const Color(0xFF2A2E38),
        ),
        child: Icon(icon, size: iconSize, color: Colors.white),
      ),
    );
  }
}

class _TriggerSlider extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  const _TriggerSlider({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    void updateValue(Offset local, double height) {
      final normalized = (1 - (local.dy / height)).clamp(0.0, 1.0);
      onChanged((normalized * 255).round());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final dragHeight = constraints.maxHeight;

        return GestureDetector(
          onVerticalDragStart: (d) => updateValue(d.localPosition, dragHeight),
          onVerticalDragUpdate: (d) => updateValue(d.localPosition, dragHeight),
          onVerticalDragEnd: (_) => onChanged(0),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF2D313B),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                FractionallySizedBox(
                  heightFactor: value / 255,
                  widthFactor: 1,
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF464C58),
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
                    ),
                  ),
                ),
                Center(
                  child: RotatedBox(
                    quarterTurns: 3,
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FaceButtons extends StatelessWidget {
  final bool a;
  final bool b;
  final bool x;
  final bool y;
  final void Function(int bit, bool pressed) onButton;

  const _FaceButtons({
    required this.a,
    required this.b,
    required this.x,
    required this.y,
    required this.onButton,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.biggest.shortestSide;
        final buttonSize = (side * 0.34).clamp(38.0, 50.0);
        final spread = side * 0.32;

        Widget place({
          required double dx,
          required double dy,
          required String label,
          required bool active,
          required Color tint,
          required int bit,
        }) {
          return Positioned(
            left: (side / 2) + dx - (buttonSize / 2),
            top: (side / 2) + dy - (buttonSize / 2),
            child: SizedBox(
              width: buttonSize,
              height: buttonSize,
              child: _RoundGameButton(
                label: label,
                active: active,
                tint: tint,
                onChanged: (v) => onButton(bit, v),
              ),
            ),
          );
        }

        return Stack(
          children: [
            place(
              dx: -spread,
              dy: 0,
              label: 'X',
              active: x,
              tint: const Color(0xFF2AA2FF),
              bit: GamepadButton.x,
            ),
            place(
              dx: spread,
              dy: 0,
              label: 'B',
              active: b,
              tint: const Color(0xFFFF5A5F),
              bit: GamepadButton.b,
            ),
            place(
              dx: 0,
              dy: -spread,
              label: 'Y',
              active: y,
              tint: const Color(0xFFF9CE3D),
              bit: GamepadButton.y,
            ),
            place(
              dx: 0,
              dy: spread,
              label: 'A',
              active: a,
              tint: const Color(0xFF5CD65C),
              bit: GamepadButton.a,
            ),
          ],
        );
      },
    );
  }
}

class _RoundGameButton extends StatelessWidget {
  final String label;
  final bool active;
  final Color tint;
  final ValueChanged<bool> onChanged;

  const _RoundGameButton({
    required this.label,
    required this.active,
    required this.tint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => onChanged(true),
      onTapUp: (_) => onChanged(false),
      onTapCancel: () => onChanged(false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 65),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? tint : const Color(0xFF232831),
          border: Border.all(color: const Color(0xFF525A68)),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: tint.withValues(alpha: 0.6),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _Dpad extends StatelessWidget {
  final int x;
  final int y;
  final void Function(int x, int y) onChanged;

  const _Dpad({required this.x, required this.y, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget arm({
      required Alignment align,
      required String label,
      required bool active,
      required VoidCallback onPress,
    }) {
      return Align(
        alignment: align,
        child: GestureDetector(
          onTapDown: (_) => onPress(),
          onTapUp: (_) => onChanged(0, 0),
          onTapCancel: () => onChanged(0, 0),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: active ? const Color(0xFF3A414D) : const Color(0xFF262C35),
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
      );
    }

    return Stack(
      children: [
        arm(
          align: Alignment.topCenter,
          label: '↑',
          active: y == 1,
          onPress: () => onChanged(0, 1),
        ),
        arm(
          align: Alignment.bottomCenter,
          label: '↓',
          active: y == -1,
          onPress: () => onChanged(0, -1),
        ),
        arm(
          align: Alignment.centerLeft,
          label: '←',
          active: x == -1,
          onPress: () => onChanged(-1, 0),
        ),
        arm(
          align: Alignment.centerRight,
          label: '→',
          active: x == 1,
          onPress: () => onChanged(1, 0),
        ),
        Align(
          alignment: Alignment.center,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFF1D2229),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
      ],
    );
  }
}

class _AnalogStick extends StatelessWidget {
  final int x;
  final int y;
  final void Function(int x, int y) onChanged;
  final VoidCallback onReset;
  final Color ringColor;
  final String label;

  const _AnalogStick({
    required this.x,
    required this.y,
    required this.onChanged,
    required this.onReset,
    required this.ringColor,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest.shortestSide;
        final radius = size / 2;
        final normX = x / 32767.0;
        final normY = y / 32767.0;

        void updateFromLocal(Offset local) {
          final cx = local.dx - radius;
          final cy = local.dy - radius;
          final maxR = radius - 12;

          var nx = cx / maxR;
          var ny = cy / maxR;
          final len = math.sqrt(nx * nx + ny * ny);
          if (len > 1) {
            nx /= len;
            ny /= len;
          }

          onChanged((nx * 32767).round(), (ny * 32767).round());
        }

        return GestureDetector(
          onPanDown: (d) => updateFromLocal(d.localPosition),
          onPanUpdate: (d) => updateFromLocal(d.localPosition),
          onPanEnd: (_) => onReset(),
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF2C313B),
              border: Border.all(color: ringColor, width: 2.5),
            ),
            child: Stack(
              children: [
                Center(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Positioned(
                  left: radius + (normX * (radius - 17)) - 17,
                  top: radius + (normY * (radius - 17)) - 17,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xAA7A808A),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
