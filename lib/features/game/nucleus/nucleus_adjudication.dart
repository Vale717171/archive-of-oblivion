import '../final_arc_adjudication.dart';
import '../memory/memory_module.dart';

enum NucleusStance { acceptance, oblivion, eternalZone, testimony, none }

enum FinalOutcomeKey {
  acceptance,
  oblivion,
  eternalZone,
  testimony,
  unresolved,
}

class NucleusEligibility {
  final bool acceptance;
  final bool oblivion;
  final bool eternalZone;
  final bool testimony;

  const NucleusEligibility({
    required this.acceptance,
    required this.oblivion,
    required this.eternalZone,
    required this.testimony,
  });
}

class NucleusArgumentSet {
  final List<String> antagonistArguments;
  final List<String> counterWindows;
  final Set<NucleusStance> availableStances;

  const NucleusArgumentSet({
    required this.antagonistArguments,
    required this.counterWindows,
    required this.availableStances,
  });
}

class NucleusAdjudication {
  static NucleusEligibility evaluate(FinalArcAdjudicationSnapshot s) {
    final acceptance = s.nucleusEligibilityInput &&
        s.traversalValueEvident &&
        s.sterileTraversalPressure <= 4 &&
        s.contradictionCount <= 3 &&
        s.unresolvedProtections <= 4 &&
        (s.memoryCostlyCount >= 1 || s.livingIncompletionEvident) &&
        s.zoneSubstantialCount + s.zoneResolvedContradictions >=
            s.zoneIntensifiedContradictions;

    final oblivion = (s.sterileTraversalPressure >= 5 &&
            (s.unresolvedProtections >= 5 || s.contradictionCount >= 4)) ||
        (s.unresolvedProtections >= 7 && s.quoteReady) ||
        (!s.traversalValueEvident &&
            s.contradictionCount >= 4 &&
            s.memoryCostlyCount == 0);

    final eternalZone = !oblivion &&
        !acceptance &&
        s.traversalValueEvident &&
        s.quoteReady &&
        s.notebookHabitation >= 8 &&
        s.zoneSubstantialCount >= 2 &&
        s.unresolvedProtections >= 2 &&
        s.contradictionCount >= 2 &&
        s.contradictionCount <= 5;

    final testimony = acceptance &&
        s.deepSectorCount >= 4 &&
        s.zoneSubstantialCount >= 3 &&
        s.memoryCostlyCount >= 3 &&
        s.contradictionCount <= 2 &&
        s.unresolvedProtections <= 2 &&
        s.sterileTraversalPressure <= 1 &&
        s.quoteExposureSeen >=
            MemoryModule.quoteExposureThresholdToNucleo + 6 &&
        s.habitationReady;

    return NucleusEligibility(
      acceptance: acceptance,
      oblivion: oblivion,
      eternalZone: eternalZone,
      testimony: testimony,
    );
  }

  static NucleusArgumentSet buildArguments({
    required FinalArcAdjudicationSnapshot snapshot,
    required NucleusEligibility eligibility,
  }) {
    final arguments = <String>[];
    final windows = <String>[];

    if (snapshot.sterileTraversalPressure >= 5) {
      arguments.add(
        'Many of your turns were evasive. Not every question was alive in the asking.',
      );
    } else if (snapshot.livingIncompletionEvident) {
      arguments.add(
        'Not every attempt opened a door. Still, your hesitations produced time instead of noise.',
      );
    } else if (snapshot.contradictionCount >= 4) {
      arguments.add(
        'You call this coherence, yet your own run records fracture after fracture.',
      );
    } else if (snapshot.contradictionCount == 0) {
      arguments.add(
        'No contradiction left on record. Are you integrated, or merely untested?',
      );
    } else {
      arguments.add(
        'You reduced contradiction, but one seam still speaks. Name it fully.',
      );
    }

    switch (snapshot.dominantWeightAxis) {
      case 'material':
        arguments.add(
          'Your body led the argument. What remains in your hands still governs your speech.',
        );
      case 'symbolic':
        arguments.add(
          'You mastered form and rite. But form can imitate transformation.',
        );
      default:
        arguments.add(
          'You speak with precision. Precision can still hide where cost should be.',
        );
    }

    if (snapshot.traversalValueEvident) {
      arguments.add(
        'The run already holds weight. The unresolved matter is your stance toward what emerged.',
      );
    } else {
      arguments.add(
        'You touched many surfaces lightly. I am still searching for where you were truly present.',
      );
    }

    if (snapshot.memoryCostlyCount < 2) {
      if (snapshot.memorySpecificCount >= 2) {
        arguments.add(
          'Your answers were specific, yet not fully costly. Incompletion is present, not nullity.',
        );
      } else {
        arguments.add(
          'Memory answered, but mostly in decorative form. Description replaced stake.',
        );
      }
    } else {
      arguments.add(
        'Memory paid a price. The question is whether you can keep paying outside the room.',
      );
    }

    if (snapshot.zoneSubstantialCount >=
        snapshot.zoneIntensifiedContradictions) {
      arguments.add(
        'The Zone recorded ownership often enough: failure did not erase witness.',
      );
    } else {
      arguments.add(
        'The Zone still records evasions as coordinates. Some refusals remained empty.',
      );
    }

    if (snapshot.unresolvedProtections >= 4 ||
        snapshot.sterileTraversalPressure >= 4) {
      windows.add(
          'A protection remains primary. Name it, bear it, or let it choose for you.');
    }
    if (snapshot.quoteReady && snapshot.habitationReady) {
      windows
          .add('You have listened and inhabited language enough to testify.');
    }
    if (snapshot.sectorDepthReady) {
      windows.add(
          'Depth exists in the run. The stance now decides embodiment, not value.');
    }
    if (snapshot.livingIncompletionEvident) {
      windows.add(
        'Incomplete attempts are on record as lived matter. They are not acquittal; they are form.',
      );
    }

    final stances = <NucleusStance>{};
    if (eligibility.acceptance) stances.add(NucleusStance.acceptance);
    if (eligibility.oblivion) stances.add(NucleusStance.oblivion);
    if (eligibility.eternalZone) stances.add(NucleusStance.eternalZone);
    if (eligibility.testimony) stances.add(NucleusStance.testimony);

    return NucleusArgumentSet(
      antagonistArguments: arguments,
      counterWindows: windows,
      availableStances: stances,
    );
  }

  static NucleusStance classifyStance(String rawInput) {
    final raw = rawInput.toLowerCase().trim();

    if (raw.isEmpty) return NucleusStance.none;

    const oblivionTerms = {
      'i accept oblivion',
      'i accept the void',
      'nothing matters',
      'surrender',
      'i give up',
      'the void is peace',
      'i want to forget',
      'oblivion',
      'erase me',
    };
    if (oblivionTerms.any(raw.contains)) return NucleusStance.oblivion;

    const eternalTerms = {
      'stay',
      'remain',
      'i remain',
      'i want to stay',
      'eternal zone',
      'continue',
      'keep looping',
    };
    if (eternalTerms.any(raw.contains)) return NucleusStance.eternalZone;

    const testimonyTerms = {
      'testimony',
      'i testify',
      'i bear witness',
      'bear witness',
      'i witness',
      'i will remember and speak',
      'i remember and testify',
    };
    if (testimonyTerms.any(raw.contains)) return NucleusStance.testimony;

    const acceptanceTerms = {
      'human warmth',
      'imperfection',
      'observer',
      'acceptance',
      'i want to remember',
      'i exist',
      'irrepeatable',
      'breath',
      'i choose to live',
    };
    if (acceptanceTerms.any(raw.contains)) return NucleusStance.acceptance;

    return NucleusStance.none;
  }
}
