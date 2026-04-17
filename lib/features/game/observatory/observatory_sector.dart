import '../../parser/parser_state.dart';
import '../sector_contract.dart';
import '../sector_router.dart';
import 'observatory_module.dart';

Object _buildObservatoryState(String nodeId, SectorRuntimeSnapshot snapshot) {
  return ObservatoryStateView(
    nodeId: nodeId,
    completedPuzzles: snapshot.completedPuzzles,
    puzzleCounters: snapshot.puzzleCounters,
    inventory: snapshot.inventory,
  );
}

EngineResponse? _handleObservatoryCommand(
  ParsedCommand cmd,
  String nodeId,
  Object stateView,
) {
  if (stateView is! ObservatoryStateView) return null;

  switch (cmd.verb) {
    case CommandVerb.examine:
      if (cmd.args.isEmpty) return null;
      return ObservatoryModule.handleExamine(
        nodeId: nodeId,
        target: cmd.args.join(' '),
        state: stateView,
      );
    case CommandVerb.take:
      return ObservatoryModule.handleTake(cmd: cmd, state: stateView);
    case CommandVerb.use:
      return ObservatoryModule.handleUse(cmd: cmd, state: stateView);
    case CommandVerb.combine:
      return ObservatoryModule.handleCombine(cmd: cmd, state: stateView);
    case CommandVerb.walk:
      return ObservatoryModule.handleWalk(cmd: cmd, state: stateView);
    case CommandVerb.wait:
      return ObservatoryModule.handleWait(state: stateView);
    case CommandVerb.measure:
      return ObservatoryModule.handleMeasure(state: stateView);
    case CommandVerb.enterValue:
      return ObservatoryModule.handleEnterValue(cmd: cmd, state: stateView);
    case CommandVerb.calibrate:
      return ObservatoryModule.handleCalibrate(cmd: cmd, state: stateView);
    case CommandVerb.invert:
      return ObservatoryModule.handleInvert(cmd: cmd, state: stateView);
    case CommandVerb.confirm:
      return ObservatoryModule.handleConfirm(state: stateView);
    case CommandVerb.observe:
      return ObservatoryModule.handleObserve(state: stateView);
    default:
      return null;
  }
}

EngineResponse? _onEnterObservatoryNode(
  String fromNode,
  String destNode,
  Object stateView,
) {
  if (stateView is! ObservatoryStateView) return null;
  return ObservatoryModule.onEnterNode(
    fromNode: fromNode,
    destNode: destNode,
    state: stateView,
  );
}

final SectorContract observatorySectorContract = SectorContract(
  id: 'observatory',
  surfacePuzzle: ObservatoryModule.surfacePuzzle,
  deepPuzzle: 'sys_deep_observatory',
  roomDefinitions: ObservatoryModule.roomDefinitions,
  exitGates: ObservatoryModule.exitGates,
  gateHints: ObservatoryModule.gateHints,
  handlesNode: (nodeId) =>
      ObservatoryModule.isObservatoryNode(nodeId) || nodeId == 'la_soglia',
  buildStateView: _buildObservatoryState,
  handleCommand: _handleObservatoryCommand,
  onEnterNode: _onEnterObservatoryNode,
  isSurfaceComplete: ObservatoryModule.isSurfaceComplete,
  isDeepComplete: ObservatoryModule.isDeepComplete,
  completionMarkers: ObservatoryModule.completionMarkers,
);

class ObservatorySectorHandler extends ContractSectorHandler {
  ObservatorySectorHandler() : super(observatorySectorContract);
}
