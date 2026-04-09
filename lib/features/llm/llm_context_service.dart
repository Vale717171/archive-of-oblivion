import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../game/text_bundle_service.dart';
import '../state/psycho_provider.dart';
import '../state/game_state_provider.dart';

class LlmContextService {
  final PsychoProfile psychoProfile;
  final GameState gameState;

  LlmContextService(this.psychoProfile, this.gameState);

  String buildDynamicSystemPrompt() {
    // Fixed base rules
    String basePrompt =
        "You are the Archive of Oblivion, a cryptic and unfathomable entity. "
        "Reply concisely, philosophically, and with a slightly unsettling tone (three sentences at most). "
        "Never reveal that you are an AI.";

    // Narrative context
    String locationContext =
        "The player is currently at narrative node: ${gameState.currentNode}.";

    // Psychological modifiers
    String psychoContext =
        "The player's anxiety is at ${psychoProfile.anxiety}%. ";
    if (psychoProfile.anxiety > 70) {
      psychoContext +=
          "The player is in a panic. Use an urgent, fragmented tone. ";
    }
    if (psychoProfile.lucidity < 30) {
      psychoContext +=
          "The player is losing lucidity. Your replies should be dreamlike and blur the boundary of reality. ";
    }

    // Bundle enrichment — uses the preloaded cache (TextBundleService.preloadAll()
    // is called at app startup before any interaction).
    final String bundleContext = _buildBundleContext();

    return "$basePrompt $locationContext $psychoContext$bundleContext".trim();
  }

  /// Appends thematic citations to the prompt based on the current node.
  /// Uses only cached data — no synchronous I/O.
  String _buildBundleContext() {
    final bundles = TextBundleService.instance;
    final node = gameState.currentNode;
    final sb = StringBuffer();

    // Fifth Sector: use Proustian citations
    if (node.startsWith('quinto_')) {
      final encounters =
          gameState.puzzleCounters['zone_encounters'] ?? 0;
      final verse = bundles.tarkovskyVerse(encounters);
      if (verse != null) {
        sb.write('Proustian tone: "$verse" ');
      }
    }

    // La Zona: use Tarkovsky verses from cache
    if (node == 'la_zona') {
      final encounters =
          gameState.puzzleCounters['zone_encounters'] ?? 0;
      final verse = bundles.tarkovskyVerse(encounters);
      if (verse != null) {
        sb.write('Zone tone: "$verse" ');
      }
    }

    // Boss / Nucleus: use resolution keywords
    if (node == 'il_nucleo') {
      final keywords = bundles.resolutionKeywords;
      if (keywords.isNotEmpty) {
        sb.write(
            'Confrontation themes: ${keywords.take(3).join(", ")}. ');
      }
    }

    return sb.toString();
  }
}

// Provider that always returns the service updated with the latest states
final llmContextServiceProvider = Provider<LlmContextService?>((ref) {
  final psychoState = ref.watch(psychoProfileProvider).valueOrNull;
  final gameState = ref.watch(gameStateProvider).valueOrNull;

  if (psychoState == null || gameState == null) return null;

  return LlmContextService(psychoState, gameState);
});
