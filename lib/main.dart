import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/audio/audio_service.dart';
import 'features/demiurge/demiurge_service.dart';
import 'features/ui/game_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ProviderContainer necessario per inizializzare AudioService
  // prima di runApp (audio_service usa container.listen, non WidgetRef)
  final container = ProviderContainer();

  // Inizializza audio + sessione Android
  final audioService = AudioService();
  try {
    await audioService.initialize(container);
  } catch (e) {
    // Audio failure must not prevent the game from starting (GDD: text-only is valid)
    // ignore: avoid_print
    print('AudioService init failed: $e');
  }

  // Pre-load Demiurge citation bundles (deterministic narrator — GDD §5).
  try {
    await DemiurgeService.instance.loadAll();
  } catch (e) {
    // Bundle failure must not prevent the game from starting; fallback text is used.
    // ignore: avoid_print
    print('DemiurgeService loadAll failed: $e');
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "L'Archivio dell'Oblio",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
        useMaterial3: true,
      ),
      home: const GameScreen(),
    );
  }
}
