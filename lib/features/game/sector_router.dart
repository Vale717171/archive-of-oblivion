import '../parser/parser_state.dart';
import 'game_node.dart';
import 'sector_contract.dart';

class SectorCommandContext {
  final ParsedCommand cmd;
  final String nodeId;
  final NodeDef node;
  final SectorRuntimeSnapshot snapshot;

  const SectorCommandContext({
    required this.cmd,
    required this.nodeId,
    required this.node,
    required this.snapshot,
  });
}

class SectorEnterContext {
  final String fromNode;
  final String destNode;
  final SectorRuntimeSnapshot snapshot;

  const SectorEnterContext({
    required this.fromNode,
    required this.destNode,
    required this.snapshot,
  });
}

abstract class SectorHandler {
  EngineResponse? handleCommand(SectorCommandContext context);

  EngineResponse? onEnterNode(SectorEnterContext context) => null;
}

class ContractSectorHandler implements SectorHandler {
  final SectorContract contract;

  const ContractSectorHandler(this.contract);

  @override
  EngineResponse? handleCommand(SectorCommandContext context) {
    if (!contract.handlesNode(context.nodeId)) return null;
    final view = contract.buildStateView(context.nodeId, context.snapshot);
    return contract.handleCommand(context.cmd, context.nodeId, view);
  }

  @override
  EngineResponse? onEnterNode(SectorEnterContext context) {
    if (!contract.handlesNode(context.destNode)) return null;
    final view = contract.buildStateView(context.destNode, context.snapshot);
    return contract.onEnterNode(context.fromNode, context.destNode, view);
  }
}

class SectorRouter {
  final List<SectorHandler> _handlers;

  const SectorRouter(this._handlers);

  EngineResponse? routeCommand(SectorCommandContext context) {
    for (final handler in _handlers) {
      final response = handler.handleCommand(context);
      if (response != null) return response;
    }
    return null;
  }

  EngineResponse? onEnterNode(SectorEnterContext context) {
    for (final handler in _handlers) {
      final response = handler.onEnterNode(context);
      if (response != null) return response;
    }
    return null;
  }
}
