import 'package:archive_of_oblivion/features/game/game_engine_provider.dart';
import 'package:archive_of_oblivion/features/parser/parser_state.dart';
import 'package:archive_of_oblivion/features/settings/app_settings_provider.dart';
import 'package:archive_of_oblivion/features/state/game_state_provider.dart';
import 'package:archive_of_oblivion/features/state/psycho_provider.dart';
import 'package:archive_of_oblivion/features/ui/game_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordingGameEngineNotifier extends GameEngineNotifier {
  _RecordingGameEngineNotifier(this.commands);

  final List<String> commands;

  @override
  Future<GameEngineState> build() async {
    return const GameEngineState(
      messages: [
        GameMessage(
          text: 'Silence. Then awareness. A path forms ahead.',
          role: MessageRole.narrative,
        ),
      ],
      phase: ParserPhase.idle,
      inventory: ['notebook'],
    );
  }

  @override
  Future<void> processInput(String raw) async {
    commands.add(raw);
  }
}

class _StaticGameStateNotifier extends GameStateNotifier {
  @override
  Future<GameState> build() async => GameState(currentNode: 'intro_void');

  @override
  Future<void> saveEngineState({
    required String currentNode,
    required Set<String> completedPuzzles,
    required Map<String, int> puzzleCounters,
    required List<String> inventory,
    required int psychoWeight,
  }) async {}

  @override
  Future<void> updateNode(String newNode) async {}

  @override
  Future<void> resetGameState() async {}
}

class _StaticPsychoProfileNotifier extends PsychoProfileNotifier {
  @override
  Future<PsychoProfile> build() async => PsychoProfile(
        lucidity: 50,
        oblivionLevel: 0,
        anxiety: 0,
      );

  @override
  Future<void> updateParameter({int? lucidity, int? oblivionLevel, int? anxiety}) async {}

  @override
  Future<void> resetProfile() async {}
}

class _StaticAppSettingsNotifier extends AppSettingsNotifier {
  @override
  Future<AppSettings> build() async => const AppSettings(
        instantText: false,
        reduceMotion: true,
        highContrast: false,
        commandAssist: true,
        musicEnabled: false,
        musicVolume: 0,
        sfxEnabled: false,
        sfxVolume: 0,
        textScale: 1,
        typewriterMillis: 40,
        muteInBackground: false,
        enableHaptics: false,
      );

  @override
  Future<void> saveSettings({
    bool? instantText,
    bool? reduceMotion,
    bool? highContrast,
    bool? commandAssist,
    bool? musicEnabled,
    double? musicVolume,
    bool? sfxEnabled,
    double? sfxVolume,
    double? textScale,
    int? typewriterMillis,
    bool? muteInBackground,
    bool? enableHaptics,
  }) async {}

  @override
  Future<void> reset() async {}
}

void main() {
  testWidgets('submitting while typewriter is active still sends the command', (tester) async {
    final commands = <String>[];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gameEngineProvider.overrideWith(() => _RecordingGameEngineNotifier(commands)),
          gameStateProvider.overrideWith(_StaticGameStateNotifier.new),
          psychoProfileProvider.overrideWith(_StaticPsychoProfileNotifier.new),
          appSettingsProvider.overrideWith(_StaticAppSettingsNotifier.new),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: GameScreen(),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));

    final input = find.byType(TextField);
    expect(input, findsOneWidget);

    await tester.tap(input);
    await tester.enterText(input, 'go north');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pump();

    expect(commands, ['go north']);
  });
}