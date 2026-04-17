import '../../parser/parser_state.dart';
import '../sector_router.dart';
import 'observatory_module.dart';

class ObservatorySectorHandler implements SectorHandler {
  const ObservatorySectorHandler();

  ObservatoryStateView? _view(SectorCommandContext context) {
    final state = context.gameState;
    if (state is! ObservatoryStateView) return null;
    return state;
  }

  ObservatoryStateView? _enterView(SectorEnterContext context) {
    final state = context.gameState;
    if (state is! ObservatoryStateView) return null;
    return state;
  }

  @override
  EngineResponse? handleCommand(SectorCommandContext context) {
    if (!ObservatoryModule.isObservatoryNode(context.nodeId) &&
        context.nodeId != 'la_soglia') {
      return null;
    }

    final view = _view(context);
    if (view == null) return null;

    switch (context.cmd.verb) {
      case CommandVerb.examine:
        if (context.cmd.args.isEmpty) return null;
        return ObservatoryModule.handleExamine(
          nodeId: context.nodeId,
          target: context.cmd.args.join(' '),
          state: view,
        );
      case CommandVerb.take:
        return ObservatoryModule.handleTake(cmd: context.cmd, state: view);
      case CommandVerb.use:
        return ObservatoryModule.handleUse(cmd: context.cmd, state: view);
      case CommandVerb.combine:
        return ObservatoryModule.handleCombine(cmd: context.cmd, state: view);
      case CommandVerb.walk:
        return ObservatoryModule.handleWalk(cmd: context.cmd, state: view);
      case CommandVerb.wait:
        return ObservatoryModule.handleWait(state: view);
      case CommandVerb.measure:
        return ObservatoryModule.handleMeasure(state: view);
      case CommandVerb.enterValue:
        return ObservatoryModule.handleEnterValue(
            cmd: context.cmd, state: view);
      case CommandVerb.calibrate:
        return ObservatoryModule.handleCalibrate(cmd: context.cmd, state: view);
      case CommandVerb.invert:
        return ObservatoryModule.handleInvert(cmd: context.cmd, state: view);
      case CommandVerb.confirm:
        return ObservatoryModule.handleConfirm(state: view);
      case CommandVerb.observe:
        return ObservatoryModule.handleObserve(state: view);
      default:
        return null;
    }
  }

  @override
  EngineResponse? onEnterNode(SectorEnterContext context) {
    if (!ObservatoryModule.isObservatoryNode(context.destNode)) {
      return null;
    }

    final view = _enterView(context);
    if (view == null) return null;
    return ObservatoryModule.onEnterNode(
      fromNode: context.fromNode,
      destNode: context.destNode,
      state: view,
    );
  }
}
