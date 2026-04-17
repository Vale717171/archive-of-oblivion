import '../../parser/parser_state.dart';
import '../sector_contract.dart';
import '../sector_router.dart';
import 'garden_module.dart';

Object _buildGardenState(String nodeId, SectorRuntimeSnapshot snapshot) {
  return GardenStateView(
    nodeId: nodeId,
    completedPuzzles: snapshot.completedPuzzles,
    puzzleCounters: snapshot.puzzleCounters,
    inventory: snapshot.inventory,
    psychoWeight: snapshot.psychoWeight,
  );
}

EngineResponse? _handleGardenCommand(
  ParsedCommand cmd,
  String nodeId,
  Object stateView,
) {
  if (stateView is! GardenStateView) return null;

  switch (cmd.verb) {
    case CommandVerb.examine:
      if (cmd.args.isEmpty) return null;
      return GardenModule.handleExamine(
        nodeId: nodeId,
        target: cmd.args.join(' '),
        state: stateView,
      );
    case CommandVerb.arrange:
      return GardenModule.handleArrange(cmd: cmd, state: stateView);
    case CommandVerb.wait:
      return GardenModule.handleWait(state: stateView);
    case CommandVerb.write:
      return GardenModule.handleWrite(cmd: cmd, state: stateView);
    case CommandVerb.walk:
      return GardenModule.handleWalk(cmd: cmd, state: stateView);
    case CommandVerb.offer:
      return GardenModule.handleOffer(cmd: cmd, state: stateView);
    case CommandVerb.deposit:
      return GardenModule.handleDeposit(state: stateView);
    default:
      return null;
  }
}

EngineResponse? _onEnterGardenNode(
  String fromNode,
  String destNode,
  Object stateView,
) {
  if (stateView is! GardenStateView) return null;
  return GardenModule.onEnterNode(
    fromNode: fromNode,
    destNode: destNode,
    state: stateView,
  );
}

final SectorContract gardenSectorContract = SectorContract(
  id: 'garden',
  surfacePuzzle: GardenModule.surfacePuzzle,
  deepPuzzle: 'sys_deep_garden',
  roomDefinitions: GardenModule.roomDefinitions,
  exitGates: GardenModule.exitGates,
  gateHints: GardenModule.gateHints,
  handlesNode: (nodeId) =>
      GardenModule.isGardenNode(nodeId) || nodeId == 'la_soglia',
  buildStateView: _buildGardenState,
  handleCommand: _handleGardenCommand,
  onEnterNode: _onEnterGardenNode,
  isSurfaceComplete: GardenModule.isSurfaceComplete,
  isDeepComplete: GardenModule.isDeepComplete,
  completionMarkers: GardenModule.completionMarkers,
);

class GardenSectorHandler extends ContractSectorHandler {
  GardenSectorHandler() : super(gardenSectorContract);
}
