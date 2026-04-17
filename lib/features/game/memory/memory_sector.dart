import '../../parser/parser_state.dart';
import '../sector_contract.dart';
import '../sector_router.dart';
import 'memory_module.dart';

Object _buildMemoryState(String nodeId, SectorRuntimeSnapshot snapshot) {
  return MemoryStateView(
    nodeId: nodeId,
    completedPuzzles: snapshot.completedPuzzles,
    puzzleCounters: snapshot.puzzleCounters,
    inventory: snapshot.inventory,
    psychoWeight: snapshot.psychoWeight,
    runtime: MemoryModule.deriveRuntime(
      puzzles: snapshot.completedPuzzles,
      counters: snapshot.puzzleCounters,
      inventory: snapshot.inventory,
      psychoWeight: snapshot.psychoWeight,
    ),
  );
}

EngineResponse? _handleMemoryCommand(
  ParsedCommand cmd,
  String nodeId,
  Object stateView,
) {
  if (stateView is! MemoryStateView) return null;

  switch (cmd.verb) {
    case CommandVerb.examine:
      if (cmd.args.isEmpty) return null;
      return MemoryModule.handleExamine(
        nodeId: nodeId,
        target: cmd.args.join(' '),
        state: stateView,
      );
    case CommandVerb.write:
      return MemoryModule.handleWrite(cmd: cmd, state: stateView);
    case CommandVerb.say:
      return MemoryModule.handleSay(cmd: cmd, state: stateView);
    case CommandVerb.drop:
      return MemoryModule.handleDrop(cmd: cmd, state: stateView);
    case CommandVerb.stir:
      return MemoryModule.handleStir(state: stateView);
    case CommandVerb.drink:
      return MemoryModule.handleDrink(state: stateView);
    case CommandVerb.unknown:
      return MemoryModule.handleUnknown(cmd: cmd, state: stateView);
    default:
      return null;
  }
}

EngineResponse? _onEnterMemoryNode(
  String fromNode,
  String destNode,
  Object stateView,
) {
  if (stateView is! MemoryStateView) return null;
  return MemoryModule.onEnterNode(
    fromNode: fromNode,
    destNode: destNode,
    state: stateView,
  );
}

final SectorContract memorySectorContract = SectorContract(
  id: 'memory',
  surfacePuzzle: MemoryModule.surfacePuzzle,
  deepPuzzle: 'sys_deep_memory',
  roomDefinitions: MemoryModule.roomDefinitions,
  exitGates: MemoryModule.exitGates,
  gateHints: MemoryModule.gateHints,
  handlesNode: (nodeId) =>
      MemoryModule.isMemoryNode(nodeId) || nodeId == 'la_soglia',
  buildStateView: _buildMemoryState,
  handleCommand: _handleMemoryCommand,
  onEnterNode: _onEnterMemoryNode,
  isSurfaceComplete: MemoryModule.isSurfaceComplete,
  isDeepComplete: MemoryModule.isDeepComplete,
  completionMarkers: MemoryModule.completionMarkers,
);

class MemorySectorHandler extends ContractSectorHandler {
  MemorySectorHandler() : super(memorySectorContract);
}
