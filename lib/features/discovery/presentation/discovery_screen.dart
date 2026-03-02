import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/discovered_server.dart';
import 'discovery_controller.dart';

import '../../controller/presentation/controller_screen.dart';

class DiscoveryScreen extends ConsumerWidget {
  const DiscoveryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final st = ref.watch(discoveryControllerProvider);
    final ctl = ref.read(discoveryControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Servers'),
        actions: [
          IconButton(
            onPressed: st.scanning ? null : () => ctl.scan(),
            icon: st.scanning
                ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          if (st.error != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.red.withOpacity(0.1),
              child: Text(st.error!, style: const TextStyle(color: Colors.red)),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<NetworkMode>(
                  segments: const [
                    ButtonSegment(value: NetworkMode.lan, label: Text('LAN')),
                  ],
                  selected: {st.mode},
                  onSelectionChanged: (s) => ctl.setMode(s.first),
                ),
                const SizedBox(height: 10),

                // ✅ Manual IP is the real-world fallback (hotspot/restricted networks)
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Manual IP (hotspot / restricted networks)',
                    hintText: 'e.g. 10.42.0.1',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: ctl.setManualIp,
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: st.scanning ? null : () => ctl.scan(),
                        icon: const Icon(Icons.wifi_tethering),
                        label: Text(st.scanning ? 'Scanning...' : 'Scan'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: st.scanning ? null : () => ctl.clear(),
                      child: const Text('Clear'),
                    )
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: st.servers.isEmpty
                ? const Center(
              child: Text(
                'No servers found.\n\nLAN: Wi-Fi broadcast.\nHotspot/USB tethering: use Manual IP.',
                textAlign: TextAlign.center,
              ),
            )
                : ListView.separated(
              itemCount: st.servers.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) => _ServerTile(server: st.servers[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServerTile extends StatelessWidget {
  final DiscoveredServer server;
  const _ServerTile({required this.server});

  @override
  Widget build(BuildContext context) {
    final lockText = server.pairedLocked ? 'Locked' : 'Available';
    final lockColor = server.pairedLocked ? Colors.orange : Colors.green;

    return ListTile(
      title: Text(server.name),
      subtitle: Text('${server.ip.address}  •  control:${server.controlPort}'),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: lockColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: lockColor.withOpacity(0.5)),
        ),
        child: Text(
          lockText,
          style: TextStyle(color: lockColor, fontWeight: FontWeight.w600),
        ),
      ),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ControllerScreen(server: server),
          ),
        );
      },
    );
  }
}