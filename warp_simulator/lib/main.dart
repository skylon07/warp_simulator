import 'package:flutter/material.dart';
import 'package:warp_simulator/src/simulation.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Warp Wake Simulator',
      home: const SafeArea(child: WarpWakeSimulation()),
    );
  }
}
