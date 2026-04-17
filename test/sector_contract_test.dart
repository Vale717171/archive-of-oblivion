import 'package:flutter_test/flutter_test.dart';

import 'package:archive_of_oblivion/features/game/gallery/gallery_sector.dart';
import 'package:archive_of_oblivion/features/game/garden/garden_sector.dart';
import 'package:archive_of_oblivion/features/game/laboratory/laboratory_sector.dart';
import 'package:archive_of_oblivion/features/game/observatory/observatory_sector.dart';

void main() {
  final contracts = [
    gardenSectorContract,
    observatorySectorContract,
    gallerySectorContract,
    laboratorySectorContract,
  ];

  test('extracted sectors expose the common contract surface', () {
    for (final contract in contracts) {
      expect(contract.id, isNotEmpty);
      expect(contract.surfacePuzzle, isNotEmpty);
      expect(contract.deepPuzzle, isNotEmpty);
      expect(contract.roomDefinitions, isNotEmpty);
      expect(contract.exitGates, isNotEmpty);
      expect(contract.gateHints, isNotEmpty);
      expect(contract.completionMarkers(puzzles: {}, counters: {}),
          isA<Set<String>>());
    }
  });
}
