import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/audio/audio_service.dart';
import 'features/demiurge/demiurge_service.dart';
import 'features/ui/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Global error handlers — catch unhandled exceptions that would otherwise
  // silently crash the app and trigger Android's crash-restart loop.
  FlutterError.onError = (FlutterErrorDetails details) {
    // ignore: avoid_print
    print('[FlutterError] ${details.exceptionAsString()}\n${details.stack}');
  };
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    // ignore: avoid_print
    print('[PlatformError] $error\n$stack');
    return true; // mark as handled so the app does not terminate
  };

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
      title: 'The Archive of Oblivion',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.black,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        brightness: Brightness.dark,
        fontFamily: 'Georgia',
      ),
      home: const HomeScreen(),
    );
  }
}
