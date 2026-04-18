import '../../parser/parser_state.dart';
import 'nucleus_adjudication.dart';

class NucleusContent {
  static EngineResponse outcomeResponse(FinalOutcomeKey outcome) {
    switch (outcome) {
      case FinalOutcomeKey.acceptance:
        return const EngineResponse(
          narrativeText: '''You speak it, and this time the words remain.

The Antagonist is silent for a long time.

Then:

"You are correct. I have no argument against that."

Something in the Archive loosens from necessity into presence.

A light — not dramatic, not final — the light of an ordinary room at dusk.''',
          needsDemiurge: true,
          newNode: 'finale_acceptance',
          lucidityDelta: 20,
          audioTrigger: 'aria_goldberg',
          completePuzzle: 'boss_resolved',
        );
      case FinalOutcomeKey.oblivion:
        return const EngineResponse(
          narrativeText: '''You choose erasure.

The Antagonist does not triumph. It only stops resisting you.

...

...

"Lived. Died. No one will remember."

— Arseny Tarkovsky''',
          newNode: 'finale_oblivion',
          audioTrigger: 'silence',
          oblivionDelta: 30,
        );
      case FinalOutcomeKey.eternalZone:
        return const EngineResponse(
          narrativeText: '''You remain inside interpretation.

The argument does not close. It multiplies.

The variations are infinite. The Zone does not end. Neither do you.''',
          needsDemiurge: true,
          newNode: 'finale_eternal_zone',
          audioTrigger: 'oblivion',
        );
      case FinalOutcomeKey.testimony:
        return const EngineResponse(
          narrativeText: '''You do not ask for acquittal. You testify.

You speak as witness to what was paid, what remains, and what must still be carried consciously.

The Antagonist does not vanish. It accepts jurisdiction limits.

The Archive keeps one chamber open for future truth, and one door open to the world.''',
          needsDemiurge: true,
          newNode: 'finale_testimony',
          lucidityDelta: 24,
          anxietyDelta: -12,
          audioTrigger: 'aria_goldberg',
          completePuzzle: 'boss_testimony',
        );
      case FinalOutcomeKey.unresolved:
        return const EngineResponse(
          narrativeText: '''The Antagonist listens.

"You are near a claim. Not yet inside one."''',
          needsDemiurge: true,
          anxietyDelta: 3,
          incrementCounter: 'boss_attempts',
        );
    }
  }

  static EngineResponse unavailableStanceResponse({
    required NucleusStance stance,
    required int attempts,
    required Iterable<String> mundaneInventory,
  }) {
    final inv = mundaneInventory.join(', ');
    final invBlock = inv.isEmpty ? '' : '\n\n[INVENTORY: $inv]';

    final base = switch (stance) {
      NucleusStance.acceptance =>
        'You invoke acceptance, but the run has not integrated enough to hold it.',
      NucleusStance.oblivion =>
        'You invoke oblivion, but your run still resists total erasure.',
      NucleusStance.eternalZone =>
        'You invoke continuation, but the Zone does not fully claim this trajectory yet.',
      NucleusStance.testimony =>
        'You invoke testimony, but testimony requires a rarer balance than this run currently holds.',
      NucleusStance.none =>
        'The Antagonist waits for a claim with consequence.',
    };

    final contour = attempts <= 1
        ? 'The sentence reaches the threshold and dissolves.'
        : 'The sentence returns altered, still unratified.';

    return EngineResponse(
      narrativeText: '$base\n\n$contour$invBlock',
      needsDemiurge: attempts < 2,
      anxietyDelta: attempts * 2,
      incrementCounter: 'boss_attempts',
    );
  }

  static EngineResponse antagonistPrompt({
    required List<String> arguments,
    required List<String> windows,
    required int attempts,
  }) {
    final index = attempts % (arguments.isEmpty ? 1 : arguments.length);
    final core = arguments.isEmpty
        ? 'The Antagonist asks what remains unresolved.'
        : arguments[index];
    final window = windows.isEmpty ? '' : '\n\n${windows.first}';

    return EngineResponse(
      narrativeText: 'The Antagonist says:\n\n"$core"$window',
      needsDemiurge: true,
      anxietyDelta: attempts == 0 ? 5 : 2,
    );
  }

  static EngineResponse finaleAmbient(String nodeId) {
    if (nodeId == 'finale_acceptance') {
      return const EngineResponse(
        narrativeText: 'The Archive is still. Type WAKE UP when you are ready.',
      );
    }
    if (nodeId == 'finale_oblivion') {
      return const EngineResponse(narrativeText: '...');
    }
    if (nodeId == 'finale_testimony') {
      return const EngineResponse(
        narrativeText:
            'The testimony remains open. You may WAKE UP, or stay and revise one line more.',
      );
    }
    return const EngineResponse(
      narrativeText:
          'The variations continue. There is no command that ends this.',
    );
  }

  static const EngineResponse wakeUpEpilogue = EngineResponse(
    narrativeText: '''"The Archive is empty.

Time has started flowing again.

Outside it is cold, but you are no longer alone."

— FINE —''',
    audioTrigger: 'calm',
    lucidityDelta: 20,
  );
}
