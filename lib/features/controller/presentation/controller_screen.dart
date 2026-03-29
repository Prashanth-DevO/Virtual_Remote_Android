import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../discovery/domain/discovered_server.dart';
import '../domain/controller_state.dart';
import 'controller_controller.dart';

enum _ControlMode { character, vehicle }

class ControllerScreen extends ConsumerStatefulWidget {
  final DiscoveredServer server;
  const ControllerScreen({super.key, required this.server});

  @override
  ConsumerState<ControllerScreen> createState() => _ControllerScreenState();
}

class _ControllerScreenState extends ConsumerState<ControllerScreen>
    with WidgetsBindingObserver {
  _ControlMode _mode = _ControlMode.character;

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
      _startControl();
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
      _startControl();
    }
  }

  Future<void> _startControl() async {
    final ctl = ref.read(controllerControllerProvider.notifier);
    await ctl.connectAndStart(
      ip: widget.server.ip,
      port: widget.server.controlPort,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(controllerControllerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFE8E2EC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1300),
              child: _mode == _ControlMode.character
                  ? _CharacterControllerSurface(
                      state: s,
                      onModeChanged: _setMode,
                      onLeftStick: _onLeftStick,
                      onRightStick: _onRightStick,
                      onL2Changed: _onL2Changed,
                      onR2Changed: _onR2Changed,
                      onButton: _onButton,
                      onDpad: _onDpad,
                    )
                  : _VehicleControllerSurface(
                      state: s,
                      onModeChanged: _setMode,
                      onL2Changed: _onL2Changed,
                      onR2Changed: _onR2Changed,
                      onButton: _onButton,
                      onSteerChanged: _onVehicleSteerChanged,
                    ),
            ),
          ),
        ),
      ),
    );
  }

  void _setMode(_ControlMode mode) {
    if (_mode == mode) return;
    setState(() => _mode = mode);
    ref.read(controllerControllerProvider.notifier).resetNeutralAndSend();
  }

  void _onLeftStick(int x, int y) {
    ref.read(controllerControllerProvider.notifier).setLeftStick(x, y);
  }

  void _onRightStick(int x, int y) {
    ref.read(controllerControllerProvider.notifier).setRightStick(x, y);
  }

  void _onL2Changed(int value) {
    ref.read(controllerControllerProvider.notifier).setTriggerL2(value);
  }

  void _onR2Changed(int value) {
    ref.read(controllerControllerProvider.notifier).setTriggerR2(value);
  }

  void _onButton(int bit, bool pressed) {
    ref.read(controllerControllerProvider.notifier).setButtonBit(bit, pressed);
  }

  void _onDpad(int x, int y) {
    ref.read(controllerControllerProvider.notifier).setDpad(x, y);
  }

  void _onVehicleSteerChanged(int dirX) {
    final ctl = ref.read(controllerControllerProvider.notifier);
    // Keep D-pad neutral in vehicle mode to avoid triggering linked
    // left/right D-pad actions while steering.
    ctl.setDpad(0, 0);
    ctl.setLeftStick(dirX * 32767, 0);
  }
}

class _CharacterControllerSurface extends StatelessWidget {
  final ControllerState state;
  final ValueChanged<_ControlMode> onModeChanged;
  final void Function(int x, int y) onLeftStick;
  final void Function(int x, int y) onRightStick;
  final ValueChanged<int> onL2Changed;
  final ValueChanged<int> onR2Changed;
  final void Function(int bit, bool pressed) onButton;
  final void Function(int x, int y) onDpad;

  const _CharacterControllerSurface({
    required this.state,
    required this.onModeChanged,
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

        final stickSize = math.min(w * 0.29, h * 0.60);
        final dpadSize = math.min(w * 0.17, h * 0.3);
        final faceSize = math.min(w * 0.21, h * 0.34);
        final shoulderTop = tf(0.10);
        final triggerTop = tf(0.18);
        final triggerHeight = h * 0.22;

        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF151922),
            borderRadius: BorderRadius.circular(48),
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
                    left: lf(0.5) - (w * 0.11),
                    top: tf(0.03),
                    width: w * 0.22,
                    height: h * 0.08,
                    child: _ModeToggle(
                      mode: _ControlMode.character,
                      onChanged: onModeChanged,
                    ),
                  ),
                  Positioned(
                    left: lf(0.06),
                    top: shoulderTop,
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
                    top: triggerTop,
                    width: w * 0.05,
                    height: triggerHeight,
                    child: _TriggerSlider(
                      label: 'LT',
                      value: state.l2,
                      onChanged: onL2Changed,
                    ),
                  ),
                  Positioned(
                    right: lf(0.06),
                    top: shoulderTop,
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
                    top: triggerTop,
                    width: w * 0.05,
                    height: triggerHeight,
                    child: _TriggerSlider(
                      label: 'RT',
                      value: state.r2,
                      onChanged: onR2Changed,
                    ),
                  ),
                  Positioned(
                    left: lf(0.5) - (w * 0.20),
                    top: tf(0.19),
                    width: w * 0.40,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _PressButton(
                          label: 'Back',
                          active: _isOn(GamepadButton.select),
                          onChanged: (v) => onButton(GamepadButton.select, v),
                          compact: true,
                        ),
                        _MiniCenterButton(
                          icon: Icons.close,
                          active: _isOn(GamepadButton.home),
                          onChanged: (v) => onButton(GamepadButton.home, v),
                        ),
                        _PressButton(
                          label: 'Start',
                          active: _isOn(GamepadButton.start),
                          onChanged: (v) => onButton(GamepadButton.start, v),
                          compact: true,
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: lf(0.05),
                    bottom: tf(0.02),
                    width: stickSize,
                    height: stickSize,
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
                    left: lf(0.345),
                    bottom: tf(0.23),
                    width: dpadSize,
                    height: dpadSize,
                    child: _Dpad(
                      x: state.dpadX,
                      y: state.dpadY,
                      onChanged: onDpad,
                    ),
                  ),
                  Positioned(
                    right: lf(0.05),
                    bottom: tf(0.02),
                    width: stickSize,
                    height: stickSize,
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
                    right: lf(0.34),
                    top: tf(0.40),
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

class _VehicleControllerSurface extends StatelessWidget {
  final ControllerState state;
  final ValueChanged<_ControlMode> onModeChanged;
  final ValueChanged<int> onL2Changed;
  final ValueChanged<int> onR2Changed;
  final void Function(int bit, bool pressed) onButton;
  final ValueChanged<int> onSteerChanged;

  const _VehicleControllerSurface({
    required this.state,
    required this.onModeChanged,
    required this.onL2Changed,
    required this.onR2Changed,
    required this.onButton,
    required this.onSteerChanged,
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
        final steeringStickSize = math.min(w * 0.36, h * 0.62);
        final pedalRowWidth = (w * 0.30).clamp(280.0, 420.0).toDouble();
        final pedalRowHeight = (h * 0.25).clamp(120.0, 210.0).toDouble();

        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF151922),
            borderRadius: BorderRadius.circular(48),
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
                    left: lf(0.5) - (w * 0.11),
                    top: tf(0.03),
                    width: w * 0.22,
                    height: h * 0.08,
                    child: _ModeToggle(
                      mode: _ControlMode.vehicle,
                      onChanged: onModeChanged,
                    ),
                  ),
                  Positioned(
                    left: lf(0.06),
                    top: tf(0.10),
                    width: w * 0.22,
                    height: h * 0.10,
                    child: _PressButton(
                      label: 'LB',
                      active: _isOn(GamepadButton.l1),
                      onChanged: (v) => onButton(GamepadButton.l1, v),
                    ),
                  ),
                  Positioned(
                    right: lf(0.06),
                    top: tf(0.10),
                    width: w * 0.22,
                    height: h * 0.10,
                    child: _PressButton(
                      label: 'RB',
                      active: _isOn(GamepadButton.r1),
                      onChanged: (v) => onButton(GamepadButton.r1, v),
                    ),
                  ),
                  Positioned(
                    left: lf(0.5) - (w * 0.20),
                    top: tf(0.20),
                    width: w * 0.40,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _PressButton(
                          label: 'Back',
                          active: _isOn(GamepadButton.select),
                          onChanged: (v) => onButton(GamepadButton.select, v),
                          compact: true,
                        ),
                        _MiniCenterButton(
                          icon: Icons.close,
                          active: _isOn(GamepadButton.home),
                          onChanged: (v) => onButton(GamepadButton.home, v),
                        ),
                        _PressButton(
                          label: 'Start',
                          active: _isOn(GamepadButton.start),
                          onChanged: (v) => onButton(GamepadButton.start, v),
                          compact: true,
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: lf(0.05),
                    bottom: tf(0.03),
                    width: steeringStickSize,
                    height: steeringStickSize,
                    child: _AnalogStick(
                      x: state.lx,
                      y: 0,
                      onChanged: (x, _) => onSteerChanged(x.sign),
                      onReset: () => onSteerChanged(0),
                      ringColor: const Color(0xFF2D323E),
                      label: 'L3',
                    ),
                  ),
                  Positioned(
                    right: lf(0.05),
                    bottom: tf(0.05),
                    width: pedalRowWidth,
                    height: pedalRowHeight,
                    child: Row(
                      children: [
                        Expanded(
                          child: _PedalButton(
                            label: 'LT',
                            value: state.l2,
                            onChanged: onL2Changed,
                          ),
                        ),
                        const SizedBox(width: 22),
                        Expanded(
                          child: _PedalButton(
                            label: 'RT',
                            value: state.r2,
                            onChanged: onR2Changed,
                          ),
                        ),
                      ],
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

class _ModeToggle extends StatelessWidget {
  final _ControlMode mode;
  final ValueChanged<_ControlMode> onChanged;

  const _ModeToggle({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFDDD7E2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            Expanded(
              child: _ModeToggleChip(
                label: 'Character',
                active: mode == _ControlMode.character,
                onTap: () => onChanged(_ControlMode.character),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _ModeToggleChip(
                label: 'Vehicle',
                active: mode == _ControlMode.vehicle,
                onTap: () => onChanged(_ControlMode.vehicle),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeToggleChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ModeToggleChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF0F8D85) : const Color(0xFF2D313B),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _PedalButton extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  const _PedalButton({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final active = value > 0;
    return GestureDetector(
      onTapDown: (_) => onChanged(255),
      onTapUp: (_) => onChanged(0),
      onTapCancel: () => onChanged(0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFC8C8CB) : const Color(0xFFE0E0E3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF8B8C90), width: 1.5),
        ),
        child: CustomPaint(
          painter: _PedalLinePainter(),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF2D313B),
                fontWeight: FontWeight.w800,
                fontSize: 22,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PedalLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFF3D4047)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 5; i++) {
      final x = size.width * (0.16 + (i * 0.17));
      canvas.drawLine(
        Offset(x, size.height * 0.14),
        Offset(x, size.height * 0.86),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PressButton extends StatelessWidget {
  final String label;
  final bool active;
  final ValueChanged<bool> onChanged;
  final bool compact;

  const _PressButton({
    required this.label,
    required this.active,
    required this.onChanged,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => onChanged(true),
      onTapUp: (_) => onChanged(false),
      onTapCancel: () => onChanged(false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 70),
        width: compact ? 120 : null,
        height: compact ? 56 : null,
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
            fontSize: compact ? 18 : 16,
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

  const _MiniCenterButton({
    required this.icon,
    required this.active,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => onChanged(true),
      onTapUp: (_) => onChanged(false),
      onTapCancel: () => onChanged(false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 70),
        width: 92,
        height: 92,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active
              ? Theme.of(context).colorScheme.primary
              : const Color(0xFF2A2E38),
        ),
        child: Icon(icon, size: 58, color: Colors.white),
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
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(28),
                      ),
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
        final labelFontSize = (size * 0.24).clamp(26.0, 38.0);
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
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: labelFontSize,
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
