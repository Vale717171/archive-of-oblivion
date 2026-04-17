import '../../parser/parser_state.dart';
import '../sector_contract.dart';
import '../sector_router.dart';
import 'gallery_module.dart';

Object _buildGalleryState(String nodeId, SectorRuntimeSnapshot snapshot) {
  return GalleryStateView(
    nodeId: nodeId,
    completedPuzzles: snapshot.completedPuzzles,
    puzzleCounters: snapshot.puzzleCounters,
    inventory: snapshot.inventory,
    psychoWeight: snapshot.psychoWeight,
  );
}

EngineResponse? _handleGalleryCommand(
  ParsedCommand cmd,
  String nodeId,
  Object stateView,
) {
  if (stateView is! GalleryStateView) return null;

  switch (cmd.verb) {
    case CommandVerb.examine:
      if (cmd.args.isEmpty) return null;
      return GalleryModule.handleExamine(
        nodeId: nodeId,
        target: cmd.args.join(' '),
        state: stateView,
      );
    case CommandVerb.walk:
      return GalleryModule.handleWalk(cmd: cmd, state: stateView);
    case CommandVerb.press:
      return GalleryModule.handlePress(cmd: cmd, state: stateView);
    case CommandVerb.write:
      return GalleryModule.handleWrite(cmd: cmd, state: stateView);
    case CommandVerb.drop:
      return GalleryModule.handleDrop(cmd: cmd, state: stateView);
    case CommandVerb.observe:
      return GalleryModule.handleObserve(state: stateView);
    case CommandVerb.breakObj:
      return GalleryModule.handleBreak(cmd: cmd, state: stateView);
    default:
      return null;
  }
}

EngineResponse? _onEnterGalleryNode(
  String fromNode,
  String destNode,
  Object stateView,
) {
  if (stateView is! GalleryStateView) return null;
  return GalleryModule.onEnterNode(
    fromNode: fromNode,
    destNode: destNode,
    state: stateView,
  );
}

final SectorContract gallerySectorContract = SectorContract(
  id: 'gallery',
  surfacePuzzle: GalleryModule.surfacePuzzle,
  deepPuzzle: 'sys_deep_gallery',
  roomDefinitions: GalleryModule.roomDefinitions,
  exitGates: GalleryModule.exitGates,
  gateHints: GalleryModule.gateHints,
  handlesNode: (nodeId) =>
      GalleryModule.isGalleryNode(nodeId) || nodeId == 'la_soglia',
  buildStateView: _buildGalleryState,
  handleCommand: _handleGalleryCommand,
  onEnterNode: _onEnterGalleryNode,
  isSurfaceComplete: GalleryModule.isSurfaceComplete,
  isDeepComplete: GalleryModule.isDeepComplete,
  completionMarkers: GalleryModule.completionMarkers,
);

class GallerySectorHandler extends ContractSectorHandler {
  GallerySectorHandler() : super(gallerySectorContract);
}
