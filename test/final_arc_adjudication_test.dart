import 'package:flutter_test/flutter_test.dart';

import 'package:archive_of_oblivion/features/game/final_arc_adjudication.dart';

void main() {
  group('FinalArcAdjudication', () {
    test('aggregates multi-axis run state consistently', () {
      final snapshot = FinalArcAdjudication.aggregate(
        puzzles: const {
          'garden_complete',
          'obs_complete',
          'gallery_complete',
          'lab_complete',
          'ritual_complete',
          'memory_epitaph_ready',
          'sys_deep_garden',
          'sys_deep_observatory',
        },
        counters: const {
          'quote_exposure_seen': 21,
          'sys_notebook_habitation': 9,
          'sys_contradictions': 2,
          'sys_weight_verbal': 7,
          'sys_weight_symbolic': 3,
          'memory_meta_quality_sum': 8,
          'memory_meta_specific_count': 4,
          'memory_meta_costly_count': 2,
          'zone_meta_responses': 3,
          'zone_meta_quality_tier_2': 2,
          'zone_meta_contradiction_resolved_count': 1,
          'zone_meta_contradiction_intensified_count': 0,
        },
        inventory: const ['notebook', 'ataraxia', 'the constant'],
        psychoWeight: 4,
      );

      expect(snapshot.surfaceSectorCount, 5);
      expect(snapshot.deepSectorCount, 2);
      expect(snapshot.sectorDepthReady, isTrue);
      expect(snapshot.quoteReady, isTrue);
      expect(snapshot.habitationReady, isTrue);
      expect(snapshot.coherenceBand, 'strained');
      expect(snapshot.dominantWeightAxis, 'verbal');
      expect(snapshot.memoryReady, isTrue);
      expect(snapshot.zoneSubstantialCount, 2);
      expect(snapshot.traversalValueEvident, isTrue);
      expect(snapshot.livedTraversalValue, greaterThanOrEqualTo(6));
      expect(snapshot.sterileTraversalPressure, lessThanOrEqualTo(3));
      expect(snapshot.nucleusEligibilityInput, isTrue);
    });

    test('legacy-like state without metadata degrades safely', () {
      final snapshot = FinalArcAdjudication.aggregate(
        puzzles: const {'garden_complete'},
        counters: const {
          'quote_exposure_seen': 2,
        },
        inventory: const ['notebook'],
        psychoWeight: 0,
      );

      expect(snapshot.memoryQualityScore, 0);
      expect(snapshot.memorySpecificCount, 0);
      expect(snapshot.memoryCostlyCount, 0);
      expect(snapshot.zoneResponses, 0);
      expect(snapshot.zoneSubstantialCount, 0);
      expect(snapshot.traversalValueEvident, isFalse);
      expect(snapshot.sterileTraversalPressure, greaterThanOrEqualTo(1));
      expect(snapshot.nucleusEligibilityInput, isFalse);
    });
  });
}
