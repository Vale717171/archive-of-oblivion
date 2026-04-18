import '../../parser/parser_state.dart';
import 'nucleus_adjudication.dart';

class NucleusContent {
  static EngineResponse outcomeResponse(FinalOutcomeKey outcome) {
    switch (outcome) {
      case FinalOutcomeKey.acceptance:
        return const EngineResponse(
          narrativeText:
              '''You do not claim victory.
You assent to what is already true.

The Antagonist is silent for a long time.

Then:

"Not every attempt opened a door. But nothing honestly traversed was null."

"Even what did not lead onward left a form."

"You do not erase the missed turns.
You carry them without kneeling before them."

Nothing is erased.
Nothing is dismissed.
Yet something in the Archive loosens into presence.

A light, not dramatic, not final:
the light of an ordinary room at dusk.''',
          needsDemiurge: true,
          newNode: 'finale_acceptance',
          lucidityDelta: 20,
          audioTrigger: 'aria_goldberg',
          completePuzzle: 'boss_resolved',
        );
      case FinalOutcomeKey.oblivion:
        return const EngineResponse(
          narrativeText: '''You do not refuse meaning.
You refuse to remain for it.

The Antagonist does not triumph.
It relinquishes jurisdiction.

...

...

"Meaning was present.
You ask that it leave no witness.
You ask for peace without a keeper."
''',
          newNode: 'finale_oblivion',
          audioTrigger: 'silence',
          oblivionDelta: 30,
        );
      case FinalOutcomeKey.eternalZone:
        return const EngineResponse(
          narrativeText: '''You remain inside interpretation.

You perceived variation, fracture, and signal.
You did not fully incarnate them.

Every form opens.
None consents to be final.
Every form points beyond itself.
No form is inhabited to the end.

This is not emptiness.
It is abundance without dwelling.

The Zone does not end.
Neither do you.''',
          needsDemiurge: true,
          newNode: 'finale_eternal_zone',
          audioTrigger: 'oblivion',
        );
      case FinalOutcomeKey.testimony:
        return const EngineResponse(
          narrativeText: '''You do not ask for purity.
You testify.

You bear witness to fragments, wrong turns, costs, and unfinished form.
You do not call them success.
You refuse to call them void.

The Antagonist does not vanish.
It recedes into a smaller authority.

The Archive keeps one chamber open for future truth,
and one door open to the world.

What is incomplete remains incomplete.
What is living remains accountable.''',
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

"The value is no longer in question.
Only your relation to it remains in question.

The claim is near.
It has not yet learned how to remain.

Speak again."''',
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
        'You invoke acceptance. The words arrive, but they do not yet keep their shape.',
      NucleusStance.oblivion =>
        'You invoke oblivion. Silence answers, but not as erasure.',
      NucleusStance.eternalZone =>
        'You invoke continuation. This passage has not yet become a dwelling for endless variation.',
      NucleusStance.testimony =>
        'You invoke testimony. Witness is spoken, but the burden has not fully taken root.',
      NucleusStance.none =>
        'No claim is yet standing long enough to be judged.',
    };

    final contour = attempts <= 1
        ? 'The sentence reaches the threshold and disperses before it can remain.'
        : 'The sentence returns altered. Closer, but still unable to endure.';

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
        ? 'What has been traversed has already taken form. How will you stand before it?'
        : arguments[index];
    final window = windows.isEmpty ? '' : '\n\n${windows.first}';

    return EngineResponse(
      narrativeText: '"$core"$window',
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
