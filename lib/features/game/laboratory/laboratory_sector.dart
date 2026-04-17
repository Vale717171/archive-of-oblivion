import '../../parser/parser_state.dart';
import '../sector_contract.dart';
import '../sector_router.dart';
import 'laboratory_module.dart';

Object _buildLaboratoryState(String nodeId, SectorRuntimeSnapshot snapshot) {
  return LaboratoryStateView(
    nodeId: nodeId,
    completedPuzzles: snapshot.completedPuzzles,
    puzzleCounters: snapshot.puzzleCounters,
    inventory: snapshot.inventory,
    psychoWeight: snapshot.psychoWeight,
    runtime: LaboratoryModule.deriveRuntime(
      puzzles: snapshot.completedPuzzles,
      counters: snapshot.puzzleCounters,
    ),
  );
}

EngineResponse? _handleLaboratoryCommand(
  ParsedCommand cmd,
  String nodeId,
  Object stateView,
) {
  if (stateView is! LaboratoryStateView) return null;

  switch (cmd.verb) {
    case CommandVerb.examine:
      if (cmd.args.isEmpty) return null;
      return LaboratoryModule.handleExamine(
        nodeId: nodeId,
        target: cmd.args.join(' '),
        state: stateView,
      );
    case CommandVerb.offer:
      return LaboratoryModule.handleOffer(cmd: cmd, state: stateView);
    case CommandVerb.decipher:
      return LaboratoryModule.handleDecipher(state: stateView);
    case CommandVerb.collect:
      return LaboratoryModule.handleCollect(cmd: cmd, state: stateView);
    case CommandVerb.wait:
      return LaboratoryModule.handleWait(state: stateView);
    case CommandVerb.setParam:
      return LaboratoryModule.handleSetParam(cmd: cmd, state: stateView);
    case CommandVerb.drop:
      return LaboratoryModule.handleDrop(cmd: cmd, state: stateView);
    case CommandVerb.blow:
      return LaboratoryModule.handleBlow(state: stateView);
    case CommandVerb.unknown:
      return LaboratoryModule.handleUnknown(cmd: cmd, state: stateView);
    default:
      return null;
  }
}

EngineResponse? _onEnterLaboratoryNode(
  String fromNode,
  String destNode,
  Object stateView,
) {
  if (stateView is! LaboratoryStateView) return null;
  return LaboratoryModule.onEnterNode(
    fromNode: fromNode,
    destNode: destNode,
    state: stateView,
  );
}

final SectorContract laboratorySectorContract = SectorContract(
  id: 'laboratory',
  surfacePuzzle: LaboratoryModule.surfacePuzzle,
  deepPuzzle: 'sys_deep_laboratory',
  roomDefinitions: LaboratoryModule.roomDefinitions,
  exitGates: LaboratoryModule.exitGates,
  gateHints: LaboratoryModule.gateHints,
  handlesNode: (nodeId) =>
      LaboratoryModule.isLaboratoryNode(nodeId) || nodeId == 'la_soglia',
  buildStateView: _buildLaboratoryState,
  handleCommand: _handleLaboratoryCommand,
  onEnterNode: _onEnterLaboratoryNode,
  isSurfaceComplete: LaboratoryModule.isSurfaceComplete,
  isDeepComplete: LaboratoryModule.isDeepComplete,
  completionMarkers: LaboratoryModule.completionMarkers,
);

class LaboratorySectorHandler extends ContractSectorHandler {
  LaboratorySectorHandler() : super(laboratorySectorContract);
}
