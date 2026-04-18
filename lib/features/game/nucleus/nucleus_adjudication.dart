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
        s.contradictionCount <= 2 &&
        s.unresolvedProtections <= 2 &&
        s.memoryCostlyCount >= 2 &&
        s.zoneResolvedContradictions >= s.zoneIntensifiedContradictions;

    final oblivion = s.contradictionCount >= 5 ||
        (s.zoneIntensifiedContradictions >= 2 &&
            (s.notebookHabitation < 8 || s.unresolvedProtections >= 4)) ||
        (!s.memoryReady && s.unresolvedProtections >= 6 && s.quoteReady);

    final eternalZone = !acceptance &&
        !oblivion &&
        s.quoteReady &&
        s.notebookHabitation >= 8 &&
        s.zoneSubstantialCount >= 2 &&
        s.unresolvedProtections >= 2 &&
        s.contradictionCount >= 2 &&
        s.contradictionCount <= 4;

    final testimony = acceptance &&
        s.deepSectorCount >= 4 &&
        s.zoneSubstantialCount >= 3 &&
        s.memoryCostlyCount >= 3 &&
        s.contradictionCount <= 1 &&
        s.unresolvedProtections <= 1 &&
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

    if (snapshot.contradictionCount >= 4) {
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

    if (snapshot.memoryCostlyCount < 2) {
      arguments.add(
        'Memory answered, but not at full cost. You narrated; you did not fully confess.',
      );
    } else {
      arguments.add(
        'Memory paid a price. The question is whether you can keep paying outside the room.',
      );
    }

    if (snapshot.zoneSubstantialCount >
        snapshot.zoneIntensifiedContradictions) {
      arguments.add(
        'The Zone registered ownership more than evasion. That matters here.',
      );
    } else {
      arguments.add(
        'The Zone still records evasions as coordinates. It can route you back there.',
      );
    }

    if (snapshot.unresolvedProtections >= 4) {
      windows.add('A protection remains primary. Name it or surrender to it.');
    }
    if (snapshot.quoteReady && snapshot.habitationReady) {
      windows
          .add('You have listened and inhabited language enough to testify.');
    }
    if (snapshot.sectorDepthReady) {
      windows.add('Depth exists in the run. Integration is still contested.');
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
