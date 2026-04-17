import '../../parser/parser_state.dart';
import '../sector_router.dart';
import 'garden_module.dart';

class GardenSectorHandler implements SectorHandler {
  const GardenSectorHandler();

  GardenStateView? _view(SectorCommandContext context) {
    final state = context.gameState;
    if (state is! GardenStateView) return null;
    return state;
  }

  GardenStateView? _enterView(SectorEnterContext context) {
    final state = context.gameState;
    if (state is! GardenStateView) return null;
    return state;
  }

  @override
  EngineResponse? handleCommand(SectorCommandContext context) {
    final view = _view(context);
    if (view == null) return null;

    switch (context.cmd.verb) {
      case CommandVerb.examine:
        if (context.cmd.args.isEmpty) return null;
        return GardenModule.handleExamine(
          nodeId: context.nodeId,
          target: context.cmd.args.join(' '),
          state: view,
        );
      case CommandVerb.arrange:
        return GardenModule.handleArrange(cmd: context.cmd, state: view);
      case CommandVerb.wait:
        return GardenModule.handleWait(state: view);
      case CommandVerb.write:
        return GardenModule.handleWrite(cmd: context.cmd, state: view);
      case CommandVerb.walk:
        return GardenModule.handleWalk(cmd: context.cmd, state: view);
      case CommandVerb.offer:
        return GardenModule.handleOffer(cmd: context.cmd, state: view);
      case CommandVerb.deposit:
        return GardenModule.handleDeposit(state: view);
      default:
        return null;
    }
  }

  @override
  EngineResponse? onEnterNode(SectorEnterContext context) {
    final view = _enterView(context);
    if (view == null) return null;
    return GardenModule.onEnterNode(
      fromNode: context.fromNode,
      destNode: context.destNode,
      state: view,
    );
  }
}
