import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/discovery/presentation/discovery_screen.dart';

void main() {
  runApp(const ProviderScope(child: App()));
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Linux Joystick Client',
      theme: ThemeData(useMaterial3: true),
      home: const DiscoveryScreen(),
    );
  }
}