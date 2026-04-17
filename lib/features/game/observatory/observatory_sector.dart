import '../../parser/parser_state.dart';
import '../sector_router.dart';

/// Prepared sector adapter for Observatory extraction.
///
/// Intentionally returns null for now so existing notifier-owned
/// Observatory behavior remains unchanged until migration.
class ObservatorySectorHandler implements SectorHandler {
  const ObservatorySectorHandler();

  @override
  EngineResponse? handleCommand(SectorCommandContext context) {
    if (!context.nodeId.startsWith('obs_')) return null;
    return null;
  }

  @override
  EngineResponse? onEnterNode(SectorEnterContext context) => null;
}
