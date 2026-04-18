import '../../parser/parser_state.dart';
import '../final_arc_adjudication.dart';
import 'nucleus_adjudication.dart';
import 'nucleus_content.dart';

class NucleusTurnResolution {
  final EngineResponse response;
  final Set<String> puzzleAdds;
  final Map<String, int> counterUpdates;

  const NucleusTurnResolution({
    required this.response,
    this.puzzleAdds = const {},
    this.counterUpdates = const {},
  });
}

class NucleusModule {
  static const Set<String> _simulacra = {
    'ataraxia',
    'the constant',
    'the proportion',
    'the catalyst',
  };

  static bool isFinalArcNode(String nodeId) =>
      nodeId == 'il_nucleo' || nodeId.startsWith('finale_');

  static NucleusTurnResolution resolveTurn({
    required ParsedCommand cmd,
    required String nodeId,
    required EngineResponse evaluationResponse,
    required Set<String> puzzles,
    required Map<String, int> counters,
    required List<String> inventory,
    required int psychoWeight,
  }) {
    if (nodeId == 'il_nucleo') {
      return _resolveNucleusCommand(
        cmd: cmd,
        evaluationResponse: evaluationResponse,
        puzzles: puzzles,
        counters: counters,
        inventory: inventory,
        psychoWeight: psychoWeight,
      );
    }

    if (!nodeId.startsWith('finale_')) {
      return NucleusTurnResolution(response: evaluationResponse);
    }

    return _resolveFinaleCommand(
      cmd: cmd,
      nodeId: nodeId,
      evaluationResponse: evaluationResponse,
    );
  }

  static NucleusTurnResolution _resolveNucleusCommand({
    required ParsedCommand cmd,
    required EngineResponse evaluationResponse,
    required Set<String> puzzles,
    required Map<String, int> counters,
    required List<String> inventory,
    required int psychoWeight,
  }) {
    if (cmd.verb == CommandVerb.inventory ||
        cmd.verb == CommandVerb.examine ||
        cmd.verb == CommandVerb.help) {
      return NucleusTurnResolution(response: evaluationResponse);
    }

    if (cmd.verb == CommandVerb.drop) {
      return _resolveBossDrop(cmd: cmd, inventory: inventory);
    }

    if (cmd.verb == CommandVerb.deposit) {
      return _resolveBossDeposit(inventory: inventory);
    }

    final snapshot = FinalArcAdjudication.aggregate(
      puzzles: puzzles,
      counters: counters,
      inventory: inventory,
      psychoWeight: psychoWeight,
    );
    final eligibility = NucleusAdjudication.evaluate(snapshot);
    final arguments = NucleusAdjudication.buildArguments(
      snapshot: snapshot,
      eligibility: eligibility,
    );

    final stance = NucleusAdjudication.classifyStance(cmd.rawInput);
    if (stance == NucleusStance.none) {
      final attempts = counters['boss_attempts'] ?? 0;
      return NucleusTurnResolution(
        response: NucleusContent.antagonistPrompt(
          arguments: arguments.antagonistArguments,
          windows: arguments.counterWindows,
          attempts: attempts,
        ),
      );
    }

    final outcome = _eligibleOutcomeForStance(stance, eligibility);
    if (outcome == null) {
      final attempts = (counters['boss_attempts'] ?? 0) + 1;
      final mundane = inventory.where((i) => !_simulacra.contains(i));
      return NucleusTurnResolution(
        response: NucleusContent.unavailableStanceResponse(
          stance: stance,
          attempts: attempts,
          mundaneInventory: mundane,
        ),
      );
    }

    final outcomeCounters = <String, int>{
      'final_arc_outcome_${outcome.name}_count':
          (counters['final_arc_outcome_${outcome.name}_count'] ?? 0) + 1,
      'final_arc_stance_${stance.name}_count':
          (counters['final_arc_stance_${stance.name}_count'] ?? 0) + 1,
    };
    final outcomePuzzles = <String>{'final_arc_outcome_${outcome.name}'};

    return NucleusTurnResolution(
      response: NucleusContent.outcomeResponse(outcome),
      counterUpdates: outcomeCounters,
      puzzleAdds: outcomePuzzles,
    );
  }

  static NucleusTurnResolution _resolveFinaleCommand({
    required ParsedCommand cmd,
    required String nodeId,
    required EngineResponse evaluationResponse,
  }) {
    if (cmd.verb == CommandVerb.inventory ||
        cmd.verb == CommandVerb.examine ||
        cmd.verb == CommandVerb.help) {
      return NucleusTurnResolution(
          response: NucleusContent.finaleAmbient(nodeId));
    }

    final raw = cmd.rawInput.toLowerCase().trim();
    if ((raw == 'wake up' || raw == 'wakeup') &&
        (nodeId == 'finale_acceptance' || nodeId == 'finale_testimony')) {
      return const NucleusTurnResolution(
          response: NucleusContent.wakeUpEpilogue);
    }

    return NucleusTurnResolution(
        response: NucleusContent.finaleAmbient(nodeId));
  }

  static FinalOutcomeKey? _eligibleOutcomeForStance(
    NucleusStance stance,
    NucleusEligibility eligibility,
  ) {
    switch (stance) {
      case NucleusStance.acceptance:
        if (eligibility.acceptance) return FinalOutcomeKey.acceptance;
        return null;
      case NucleusStance.oblivion:
        if (eligibility.oblivion) return FinalOutcomeKey.oblivion;
        return null;
      case NucleusStance.eternalZone:
        if (eligibility.eternalZone) return FinalOutcomeKey.eternalZone;
        return null;
      case NucleusStance.testimony:
        if (eligibility.testimony) return FinalOutcomeKey.testimony;
        return null;
      case NucleusStance.none:
        return null;
    }
  }

  static NucleusTurnResolution _resolveBossDrop({
    required ParsedCommand cmd,
    required List<String> inventory,
  }) {
    if (cmd.args.isEmpty) {
      return const NucleusTurnResolution(
        response:
            EngineResponse(narrativeText: 'What do you wish to set down?'),
      );
    }

    final target = cmd.args.join(' ');
    final match = inventory
        .where((i) =>
            !_simulacra.contains(i) &&
            (i.contains(target) || target.contains(i)))
        .firstOrNull;
    if (match == null) {
      return const NucleusTurnResolution(
        response: EngineResponse(
          narrativeText:
              'You do not carry that — or perhaps you carry it in a form that cannot be set down here.',
        ),
      );
    }

    final remaining =
        inventory.where((i) => !_simulacra.contains(i) && i != match).length;

    if (remaining == 0) {
      return NucleusTurnResolution(
        response: EngineResponse(
          narrativeText: 'You set down the $match.\n\n'
              'Your hands are empty. The burden no longer argues for the Antagonist.',
          weightDelta: -1,
          lucidityDelta: 10,
          anxietyDelta: -10,
          needsDemiurge: true,
          audioTrigger: 'calm',
        ),
      );
    }

    return NucleusTurnResolution(
      response: EngineResponse(
        narrativeText: 'You set down the $match.\n\n'
            '$remaining burden${remaining == 1 ? '' : 's'} still remain.',
        weightDelta: -1,
        anxietyDelta: -2,
        lucidityDelta: 3,
      ),
    );
  }

  static NucleusTurnResolution _resolveBossDeposit({
    required List<String> inventory,
  }) {
    final hasMundane = inventory.any((i) => !_simulacra.contains(i));
    if (!hasMundane) {
      return const NucleusTurnResolution(
        response: EngineResponse(
          narrativeText: 'You carry nothing that can be set down here.\n\n'
              'The simulacra are yours; they are not the burden.',
        ),
      );
    }

    return const NucleusTurnResolution(
      response: EngineResponse(
        narrativeText: 'You set everything down.\n\n'
            'Your hands are empty. The burden is gone.\n\n'
            'The Antagonist recalculates.',
        lucidityDelta: 10,
        anxietyDelta: -15,
        needsDemiurge: true,
        audioTrigger: 'calm',
        clearInventoryOnDeposit: true,
      ),
    );
  }
}
