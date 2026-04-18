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

  /// Derived signal: how much the run appears genuinely inhabited even when
  /// not fully resolved.
  final int livedTraversalValue;

  /// Derived signal: accumulation of evasive/sterile participation patterns.
  final int sterileTraversalPressure;

  final bool traversalValueEvident;
  final bool livingIncompletionEvident;

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
    required this.livedTraversalValue,
    required this.sterileTraversalPressure,
    required this.traversalValueEvident,
    required this.livingIncompletionEvident,
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

    final livedTraversalValue = _deriveLivedTraversalValue(
      surfaceCount: surfaceCount,
      deepCount: deepCount,
      quoteReady: quote >= MemoryModule.quoteExposureThresholdToNucleo,
      habitationReady: habitation >= 8,
      memorySpecific: memorySpecific,
      memoryCostly: memoryCostly,
      zoneSubstantial: zoneSubstantial,
      zoneResponses: zoneResponses,
      contradictions: contradictions,
      zoneIntensified: zoneIntensified,
    );

    final sterileTraversalPressure = _deriveSterileTraversalPressure(
      contradictions: contradictions,
      memorySpecific: memorySpecific,
      memoryCostly: memoryCostly,
      zoneResponses: zoneResponses,
      zoneSubstantial: zoneSubstantial,
      zoneIntensified: zoneIntensified,
      notebookHabitation: habitation,
    );

    final livingIncompletionEvident = contradictions >= 1 &&
        contradictions <= 4 &&
        memorySpecific >= 2 &&
        memoryCostly >= 1 &&
        (zoneSubstantial >= 1 || zoneResponses >= 2) &&
        zoneSubstantial >= zoneIntensified;

    final traversalValueEvident = livedTraversalValue >= 4;

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
      livedTraversalValue: livedTraversalValue,
      sterileTraversalPressure: sterileTraversalPressure,
      traversalValueEvident: traversalValueEvident,
      livingIncompletionEvident: livingIncompletionEvident,
      nucleusEligibilityInput: nucleusEligibilityInput,
    );
  }

  static int _deriveLivedTraversalValue({
    required int surfaceCount,
    required int deepCount,
    required bool quoteReady,
    required bool habitationReady,
    required int memorySpecific,
    required int memoryCostly,
    required int zoneSubstantial,
    required int zoneResponses,
    required int contradictions,
    required int zoneIntensified,
  }) {
    var score = 0;
    score += surfaceCount >= 3 ? 1 : 0;
    score += deepCount >= 1 ? 1 : 0;
    score += deepCount >= 3 ? 1 : 0;
    score += quoteReady ? 1 : 0;
    score += habitationReady ? 1 : 0;
    score += memorySpecific.clamp(0, 3);
    score += memoryCostly.clamp(0, 2);
    score += zoneSubstantial.clamp(0, 3);

    // Incomplete but inhabited: participation exceeds clean resolution
    // without collapsing into pure intensification.
    if (zoneResponses > zoneSubstantial &&
        zoneSubstantial > 0 &&
        zoneIntensified <= zoneSubstantial + 1) {
      score += 1;
    }
    if (contradictions >= 1 &&
        contradictions <= 4 &&
        memorySpecific >= 2 &&
        zoneSubstantial >= 1) {
      score += 1;
    }

    return score;
  }

  static int _deriveSterileTraversalPressure({
    required int contradictions,
    required int memorySpecific,
    required int memoryCostly,
    required int zoneResponses,
    required int zoneSubstantial,
    required int zoneIntensified,
    required int notebookHabitation,
  }) {
    var score = 0;
    score += zoneIntensified.clamp(0, 3);
    score += contradictions >= 5
        ? 2
        : contradictions >= 3
            ? 1
            : 0;
    if (zoneResponses >= 3 && zoneSubstantial == 0) score += 2;
    if (memorySpecific == 0 && memoryCostly == 0) score += 1;
    if (notebookHabitation < 5) score += 1;
    return score;
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
