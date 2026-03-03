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
      backgroundColor: const Color(0xFF0F131A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Center(
            child: AspectRatio(
              aspectRatio: 16 / 9,
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

        final stickSize = w * 0.19;
        final dpadSize  = w * 0.16;
        final faceSize  = w * 0.20;

        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(38),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF35383D), Color(0xFF171A1F)],
            ),
            boxShadow: const [
              BoxShadow(blurRadius: 18, offset: Offset(0, 10), color: Color(0x36000000)),
            ],
          ),
          child: Stack(
            children: [

              // ── Decorative grip bars ─────────────────────────────────
              Positioned(
                left: lf(0.02), top: tf(0.30),
                child: Container(
                  width: w * 0.018, height: h * 0.55,
                  decoration: BoxDecoration(color: const Color(0xFF2AA2FF), borderRadius: BorderRadius.circular(99)),
                ),
              ),
              Positioned(
                right: lf(0.02), top: tf(0.30),
                child: Container(
                  width: w * 0.018, height: h * 0.55,
                  decoration: BoxDecoration(color: const Color(0xFFFF3B4D), borderRadius: BorderRadius.circular(99)),
                ),
              ),

              // ── LB — far left, top ───────────────────────────────────
              Positioned(
                left: lf(0.04), top: tf(0.04),
                width: w * 0.18, height: h * 0.14,
                child: _PressButton(
                  label: 'LB',
                  active: _isOn(GamepadButton.l1),
                  onChanged: (v) => onButton(GamepadButton.l1, v),
                ),
              ),

              // ── LT — far left, below LB ──────────────────────────────
              Positioned(
                left: lf(0.04), top: tf(0.22),
                width: w * 0.18, height: h * 0.14,
                child: _TriggerSlider(label: 'LT', value: state.l2, onChanged: onL2Changed),
              ),

              // ── RB — far right, top ──────────────────────────────────
              Positioned(
                right: lf(0.04), top: tf(0.04),
                width: w * 0.18, height: h * 0.14,
                child: _PressButton(
                  label: 'RB',
                  active: _isOn(GamepadButton.r1),
                  onChanged: (v) => onButton(GamepadButton.r1, v),
                ),
              ),

              // ── RT — far right, below RB ─────────────────────────────
              Positioned(
                right: lf(0.04), top: tf(0.22),
                width: w * 0.18, height: h * 0.14,
                child: _TriggerSlider(label: 'RT', value: state.r2, onChanged: onR2Changed),
              ),

              // ── Xbox Home — centered, very top ───────────────────────
              Positioned(
                left: lf(0.5) - 18, top: tf(0.06),
                width: 36, height: 36,
                child: _MiniCenterButton(
                  icon: Icons.radio_button_checked,
                  active: _isOn(GamepadButton.home),
                  onChanged: (v) => onButton(GamepadButton.home, v),
                ),
              ),

              // ── Select / Start — center, upper-mid ───────────────────
              Positioned(
                left: lf(0.5) - w * 0.09, top: tf(0.30),
                width: w * 0.18,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _MiniCenterButton(
                      icon: Icons.content_copy,
                      active: _isOn(GamepadButton.select),
                      onChanged: (v) => onButton(GamepadButton.select, v),
                    ),
                    _MiniCenterButton(
                      icon: Icons.menu,
                      active: _isOn(GamepadButton.start),
                      onChanged: (v) => onButton(GamepadButton.start, v),
                    ),
                  ],
                ),
              ),

              // ── Left Analog Stick — center-left, vertically centered ──
              Positioned(
                left: lf(0.24),
                top: tf(0.5) - stickSize / 2,
                width: stickSize, height: stickSize,
                child: _AnalogStick(
                  x: state.lx, y: state.ly,
                  onChanged: onLeftStick,
                  onReset: () => onLeftStick(0, 0),
                  ringColor: const Color(0xFF2AA2FF),
                ),
              ),

              // ── D-pad — bottom-left ──────────────────────────────────
              Positioned(
                left: lf(0.06), bottom: tf(0.08),
                width: dpadSize, height: dpadSize,
                child: _Dpad(x: state.dpadX, y: state.dpadY, onChanged: onDpad),
              ),

              // ── Right Analog Stick — center-right, vertically centered ─
              Positioned(
                right: lf(0.24),
                top: tf(0.5) - stickSize / 2,
                width: stickSize, height: stickSize,
                child: _AnalogStick(
                  x: state.rx, y: state.ry,
                  onChanged: onRightStick,
                  onReset: () => onRightStick(0, 0),
                  ringColor: const Color(0xFFFF3B4D),
                ),
              ),

              // ── Face Buttons — far right, vertically centered ─────────
              Positioned(
                right: lf(0.04),
                top: tf(0.5) - faceSize / 2,
                width: faceSize, height: faceSize,
                child: _FaceButtons(
                  a: _isOn(GamepadButton.a),
                  b: _isOn(GamepadButton.b),
                  x: _isOn(GamepadButton.x),
                  y: _isOn(GamepadButton.y),
                  onButton: onButton,
                ),
              ),

              // ── L3 — below left stick ────────────────────────────────
              Positioned(
                left: lf(0.24) + stickSize / 2 - 28,
                bottom: tf(0.05),
                child: _PressButton(
                  label: 'L3',
                  active: _isOn(GamepadButton.l3),
                  onChanged: (v) => onButton(GamepadButton.l3, v),
                  compact: true,
                ),
              ),

              // ── R3 — below right stick ───────────────────────────────
              Positioned(
                right: lf(0.24) + stickSize / 2 - 28,
                bottom: tf(0.05),
                child: _PressButton(
                  label: 'R3',
                  active: _isOn(GamepadButton.r3),
                  onChanged: (v) => onButton(GamepadButton.r3, v),
                  compact: true,
                ),
              ),

            ],
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
        width: compact ? 56 : null,
        height: compact ? 30 : null,
        decoration: BoxDecoration(
          color: active
              ? Theme.of(context).colorScheme.primaryContainer
              : const Color(0xFF232831),
          borderRadius: BorderRadius.circular(compact ? 16 : 12),
          border: Border.all(color: const Color(0xFF4C5360)),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: compact ? 11 : 12,
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
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active
              ? Theme.of(context).colorScheme.primary
              : const Color(0xFF20252D),
          border: Border.all(color: const Color(0xFF4C5360)),
        ),
        child: Icon(icon, size: 15, color: Colors.white),
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF232831),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF4C5360)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(trackHeight: 3),
                child: Slider(
                  value: value / 255,
                  onChanged: (v) => onChanged((v * 255).round()),
                ),
              ),
            ),
          ],
        ),
      ),
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
          border: Border.all(
            color: active ? Colors.white : const Color(0xFF525A68),
          ),
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
              border: Border.all(color: const Color(0xFF555D6D)),
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
              border: Border.all(color: const Color(0xFF555D6D)),
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

  const _AnalogStick({
    required this.x,
    required this.y,
    required this.onChanged,
    required this.onReset,
    required this.ringColor,
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
              color: const Color(0xFF20252D),
              border: Border.all(color: ringColor, width: 2),
            ),
            child: Stack(
              children: [
                Center(
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white38,
                    ),
                  ),
                ),
                Positioned(
                  left: radius + (normX * (radius - 17)) - 17,
                  top: radius + (normY * (radius - 17)) - 17,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF7A808A),
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
