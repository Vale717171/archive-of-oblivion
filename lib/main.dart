import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/audio/audio_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ProviderContainer necessario per inizializzare AudioService
  // prima di runApp (audio_service usa container.listen, non WidgetRef)
  final container = ProviderContainer();

  // Inizializza audio + sessione Android
  final audioService = AudioService();
  await audioService.initialize(container);

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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
        useMaterial3: true,
      ),
      home: const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'L\'Archivio dell\'Oblio',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
