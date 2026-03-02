import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../discovery/domain/discovered_server.dart';
import 'controller_controller.dart';

class ControllerScreen extends ConsumerStatefulWidget {
  final DiscoveredServer server;
  const ControllerScreen({super.key, required this.server});

  @override
  ConsumerState<ControllerScreen> createState() => _ControllerScreenState();
}

class _ControllerScreenState extends ConsumerState<ControllerScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Start sending immediately
    Future.microtask(() {
      ref.read(controllerControllerProvider.notifier).connectAndStart(
        ip: widget.server.ip,
        port: widget.server.controlPort,
      );
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ref.read(controllerControllerProvider.notifier).disconnect();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final ctl = ref.read(controllerControllerProvider.notifier);
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      ctl.disconnect();
    } else if (state == AppLifecycleState.resumed) {
      ctl.connectAndStart(ip: widget.server.ip, port: widget.server.controlPort);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(controllerControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text('Controller • ${widget.server.name}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Sending @60Hz to ${widget.server.ip.address}:${widget.server.controlPort}'),
            const SizedBox(height: 16),

            // For speed: two sliders to prove control works (we’ll replace with joysticks next)
            const Text('Left Stick X/Y'),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: (s.lx + 32768) / 65535.0,
                    onChanged: (v) {
                      final lx = (v * 65535).round() - 32768;
                      ref.read(controllerControllerProvider.notifier).setLeftStick(lx, s.ly);
                    },
                  ),
                ),
                Expanded(
                  child: Slider(
                    value: (s.ly + 32768) / 65535.0,
                    onChanged: (v) {
                      final ly = (v * 65535).round() - 32768;
                      ref.read(controllerControllerProvider.notifier).setLeftStick(s.lx, ly);
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Text('A Button'),
            Switch(
              value: (s.buttons & 1) != 0,
              onChanged: (on) => ref.read(controllerControllerProvider.notifier).setButtonBit(0, on),
            ),
          ],
        ),
      ),
    );
  }
}