import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/discovery_service.dart';
import '../domain/discovered_server.dart';

enum NetworkMode { lan }

final discoveryServiceProvider = Provider<DiscoveryService>((ref) => DiscoveryService());

final discoveryControllerProvider =
StateNotifierProvider<DiscoveryController, DiscoveryState>((ref) {
  return DiscoveryController(ref.read(discoveryServiceProvider));
});

class DiscoveryState {
  final bool scanning;
  final List<DiscoveredServer> servers;
  final String? error;

  final NetworkMode mode;
  final String manualIp; // optional, used for hotspot / restricted networks

  const DiscoveryState({
    required this.scanning,
    required this.servers,
    required this.error,
    required this.mode,
    required this.manualIp,
  });

  factory DiscoveryState.initial() => const DiscoveryState(
    scanning: false,
    servers: [],
    error: null,
    mode: NetworkMode.lan,
    manualIp: '',
  );

  DiscoveryState copyWith({
    bool? scanning,
    List<DiscoveredServer>? servers,
    String? error,
    NetworkMode? mode,
    String? manualIp,
  }) {
    return DiscoveryState(
      scanning: scanning ?? this.scanning,
      servers: servers ?? this.servers,
      error: error,
      mode: mode ?? this.mode,
      manualIp: manualIp ?? this.manualIp,
    );
  }
}

class DiscoveryController extends StateNotifier<DiscoveryState> {
  final DiscoveryService _svc;

  DiscoveryController(this._svc) : super(DiscoveryState.initial());

  void setMode(NetworkMode mode) => state = state.copyWith(mode: mode, error: null);

  void setManualIp(String ip) => state = state.copyWith(manualIp: ip.trim(), error: null);

  Future<void> scan() async {
    if (state.scanning) return;
    state = state.copyWith(scanning: true, error: null);

    try {
      final targets = <InternetAddress>[];

      // LAN broadcast
      targets.add(InternetAddress('255.255.255.255'));

      // Manual IP fallback (hotspot / restricted networks / USB tethering)
      if (state.manualIp.isNotEmpty) {
        final ip = InternetAddress.tryParse(state.manualIp);
        if (ip != null) {
          targets.add(ip);
        } else {
          throw Exception('Manual IP is invalid.');
        }
      }

      final servers = await _svc.scan(targets: targets);

      state = state.copyWith(
        scanning: false,
        servers: servers,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(scanning: false, error: e.toString());
    }
  }

  void clear() => state = state.copyWith(servers: const [], error: null);
}