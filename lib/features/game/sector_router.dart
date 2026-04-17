import '../parser/parser_state.dart';
import 'game_node.dart';

class SectorCommandContext {
  final ParsedCommand cmd;
  final String nodeId;
  final NodeDef node;
  final Object gameState;

  const SectorCommandContext({
    required this.cmd,
    required this.nodeId,
    required this.node,
    required this.gameState,
  });
}

class SectorEnterContext {
  final String fromNode;
  final String destNode;
  final Object gameState;

  const SectorEnterContext({
    required this.fromNode,
    required this.destNode,
    required this.gameState,
  });
}

abstract class SectorHandler {
  EngineResponse? handleCommand(SectorCommandContext context);

  EngineResponse? onEnterNode(SectorEnterContext context) => null;
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
