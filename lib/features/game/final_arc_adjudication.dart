import 'memory/memory_module.dart';

class FinalArcAdjudicationSnapshot {
  final int surfaceSectorCount;
  final int deepSectorCount;
  final bool sectorDepthReady;

  final int quoteExposureSeen;
  final int notebookHabitation;
  final bool quoteReady;
  final bool habitationReady;

  final int contradictionCount;
  final String coherenceBand;
  final String dominantWeightAxis;

  final bool memoryReady;
  final int memoryQualityScore;
  final int memorySpecificCount;
  final int memoryCostlyCount;
  final Set<String> memoryAnsweredChambers;

  final int zoneResponses;
  final int zoneSubstantialCount;
  final int zoneResolvedContradictions;
  final int zoneIntensifiedContradictions;

  final int unresolvedProtections;

  final bool nucleusEligibilityInput;

  const FinalArcAdjudicationSnapshot({
    required this.surfaceSectorCount,
    required this.deepSectorCount,
    required this.sectorDepthReady,
    required this.quoteExposureSeen,
    required this.notebookHabitation,
    required this.quoteReady,
    required this.habitationReady,
    required this.contradictionCount,
    required this.coherenceBand,
    required this.dominantWeightAxis,
    required this.memoryReady,
    required this.memoryQualityScore,
    required this.memorySpecificCount,
    required this.memoryCostlyCount,
    required this.memoryAnsweredChambers,
    required this.zoneResponses,
    required this.zoneSubstantialCount,
    required this.zoneResolvedContradictions,
    required this.zoneIntensifiedContradictions,
    required this.unresolvedProtections,
    required this.nucleusEligibilityInput,
  });
}

class FinalArcAdjudication {
  static const Set<String> _surfacePuzzles = {
    'garden_complete',
    'obs_complete',
    'gallery_complete',
    'lab_complete',
    'ritual_complete',
  };

  static const Set<String> _deepPuzzles = {
    'sys_deep_garden',
    'sys_deep_observatory',
    'sys_deep_gallery',
    'sys_deep_laboratory',
    'sys_deep_memory',
  };

  static const Set<String> _simulacra = {
    'ataraxia',
    'the constant',
    'the proportion',
    'the catalyst',
  };

  static FinalArcAdjudicationSnapshot aggregate({
    required Set<String> puzzles,
    required Map<String, int> counters,
    required List<String> inventory,
    required int psychoWeight,
  }) {
    final surfaceCount = _surfacePuzzles.where(puzzles.contains).length;
    final deepCount = _deepPuzzles.where(puzzles.contains).length;
    final quote = counters['quote_exposure_seen'] ?? 0;
    final habitation = counters['sys_notebook_habitation'] ?? 0;
    final contradictions = counters['sys_contradictions'] ?? 0;

    final memoryInput = MemoryModule.buildEpitaphInput(
      puzzles: puzzles,
      counters: counters,
      inventory: inventory,
      psychoWeight: psychoWeight,
    );

    final memoryQuality = counters['memory_meta_quality_sum'] ??
        memoryInput.specificAnswers + memoryInput.costlyAnswers;

    final memorySpecific =
        counters['memory_meta_specific_count'] ?? memoryInput.specificAnswers;
    final memoryCostly =
        counters['memory_meta_costly_count'] ?? memoryInput.costlyAnswers;

    final zoneResponses = counters['zone_meta_responses'] ?? 0;
    final zoneSubstantial = counters['zone_meta_quality_tier_2'] ?? 0;
    final zoneResolved =
        counters['zone_meta_contradiction_resolved_count'] ?? 0;
    final zoneIntensified =
        counters['zone_meta_contradiction_intensified_count'] ?? 0;

    final mundaneProtections = inventory
        .where((item) => !_simulacra.contains(item) && item != 'notebook')
        .length;

    final unresolvedProtections =
        contradictions + mundaneProtections + (memoryCostly < 2 ? 1 : 0);

    final dominantAxis = _dominantWeightAxis(counters, psychoWeight);
    final coherenceBand = contradictions >= 5
        ? 'fractured'
        : contradictions >= 2
            ? 'strained'
            : 'stable';

    final memoryReady = puzzles.contains('memory_epitaph_ready') ||
        (memoryInput.answeredChambers.length == 4 &&
            memorySpecific >= 3 &&
            memoryCostly >= 2);

    final sectorDepthReady = deepCount >= 2;
    final quoteReady = quote >= MemoryModule.quoteExposureThresholdToNucleo;
    final habitationReady = habitation >= 8;

    final nucleusEligibilityInput = puzzles.contains('ritual_complete') &&
        memoryReady &&
        sectorDepthReady &&
        quoteReady;

    return FinalArcAdjudicationSnapshot(
      surfaceSectorCount: surfaceCount,
      deepSectorCount: deepCount,
      sectorDepthReady: sectorDepthReady,
      quoteExposureSeen: quote,
      notebookHabitation: habitation,
      quoteReady: quoteReady,
      habitationReady: habitationReady,
      contradictionCount: contradictions,
      coherenceBand: coherenceBand,
      dominantWeightAxis: dominantAxis,
      memoryReady: memoryReady,
      memoryQualityScore: memoryQuality,
      memorySpecificCount: memorySpecific,
      memoryCostlyCount: memoryCostly,
      memoryAnsweredChambers: memoryInput.answeredChambers,
      zoneResponses: zoneResponses,
      zoneSubstantialCount: zoneSubstantial,
      zoneResolvedContradictions: zoneResolved,
      zoneIntensifiedContradictions: zoneIntensified,
      unresolvedProtections: unresolvedProtections,
      nucleusEligibilityInput: nucleusEligibilityInput,
    );
  }

  static String _dominantWeightAxis(
      Map<String, int> counters, int psychoWeight) {
    final verbal = counters['sys_weight_verbal'] ?? 0;
    final symbolic = counters['sys_weight_symbolic'] ?? 0;
    final material = psychoWeight;

    if (material >= verbal && material >= symbolic) return 'material';
    if (symbolic >= verbal) return 'symbolic';
    return 'verbal';
  }
}
