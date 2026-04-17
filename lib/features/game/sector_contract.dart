import '../parser/parser_state.dart';
import 'game_node.dart';

class SectorRuntimeSnapshot {
  final Set<String> completedPuzzles;
  final Map<String, int> puzzleCounters;
  final List<String> inventory;
  final int psychoWeight;

  const SectorRuntimeSnapshot({
    required this.completedPuzzles,
    required this.puzzleCounters,
    required this.inventory,
    required this.psychoWeight,
  });
}

class SectorContract {
  final String id;
  final String surfacePuzzle;
  final String deepPuzzle;
  final Map<String, NodeDef> roomDefinitions;
  final Map<String, Map<String, String>> exitGates;
  final Map<String, String> gateHints;
  final bool Function(String nodeId) handlesNode;
  final Object Function(String nodeId, SectorRuntimeSnapshot snapshot)
      buildStateView;
  final EngineResponse? Function(
    ParsedCommand cmd,
    String nodeId,
    Object stateView,
  ) handleCommand;
  final EngineResponse? Function(
    String fromNode,
    String destNode,
    Object stateView,
  ) onEnterNode;
  final bool Function(Set<String> puzzles) isSurfaceComplete;
  final bool Function({
    required Set<String> puzzles,
    required Map<String, int> counters,
  }) isDeepComplete;
  final Set<String> Function({
    required Set<String> puzzles,
    required Map<String, int> counters,
  }) completionMarkers;

  const SectorContract({
    required this.id,
    required this.surfacePuzzle,
    required this.deepPuzzle,
    required this.roomDefinitions,
    required this.exitGates,
    required this.gateHints,
    required this.handlesNode,
    required this.buildStateView,
    required this.handleCommand,
    required this.onEnterNode,
    required this.isSurfaceComplete,
    required this.isDeepComplete,
    required this.completionMarkers,
  });
}
