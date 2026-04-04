import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../game/text_bundle_service.dart';
import '../state/psycho_provider.dart';
import '../state/game_state_provider.dart';

class LlmContextService {
  final PsychoProfile psychoProfile;
  final GameState gameState;

  LlmContextService(this.psychoProfile, this.gameState);

  String buildDynamicSystemPrompt() {
    // Regole di base fisse
    String basePrompt =
        "Sei l'Archivio dell'Oblio, un'entità criptica e insondabile. "
        "Rispondi in modo conciso, filosofico e leggermente inquietante (massimo 3 frasi). "
        "Non rivelare mai di essere un'IA.";

    // Contesto narrativo
    String locationContext =
        "Il giocatore si trova attualmente nel nodo narrativo: ${gameState.currentNode}.";

    // Modificatori psicologici
    String psychoContext =
        "L'ansia del giocatore è a ${psychoProfile.anxiety}%. ";
    if (psychoProfile.anxiety > 70) {
      psychoContext +=
          "Il giocatore è nel panico. Usa un tono pressante e frammentato. ";
    }
    if (psychoProfile.lucidity < 30) {
      psychoContext +=
          "Il giocatore sta perdendo la lucidità. Le tue risposte devono essere oniriche e confondere la realtà. ";
    }

    // Bundle enrichment — usa la cache precaricata (TextBundleService.preloadAll()
    // viene chiamato all'avvio dell'app prima di qualsiasi interazione).
    final String bundleContext = _buildBundleContext();

    return "$basePrompt $locationContext $psychoContext$bundleContext".trim();
  }

  /// Aggiunge citazioni tematiche al prompt in base al nodo corrente.
  /// Usa solo dati già in cache — nessuna I/O sincrona.
  String _buildBundleContext() {
    final bundles = TextBundleService.instance;
    final node = gameState.currentNode;
    final sb = StringBuffer();

    // Fifth Sector: usa citazioni proustiane
    if (node.startsWith('quinto_')) {
      final verse = bundles.tarkovskyVerse(0);
      if (verse != null) {
        sb.write('Tonalità proustiana: "$verse" ');
      }
    }

    // La Zona: usa versi Tarkovsky dalla cache
    if (node == 'la_zona') {
      final encounters =
          gameState.puzzleCounters['zone_encounters'] ?? 0;
      final verse = bundles.tarkovskyVerse(encounters);
      if (verse != null) {
        sb.write('Tonalità zona: "$verse" ');
      }
    }

    // Boss / Nucleare: usa keywords di resa/risoluzione
    if (node == 'il_nucleo') {
      final keywords = bundles.resolutionKeywords;
      if (keywords.isNotEmpty) {
        sb.write(
            'Temi di confronto: ${keywords.take(3).join(", ")}. ');
      }
    }

    return sb.toString();
  }
}

// Provider per ottenere il servizio sempre aggiornato con gli ultimi stati
final llmContextServiceProvider = Provider<LlmContextService?>((ref) {
  final psychoState = ref.watch(psychoProfileProvider).valueOrNull;
  final gameState = ref.watch(gameStateProvider).valueOrNull;

  if (psychoState == null || gameState == null) return null;

  return LlmContextService(psychoState, gameState);
});
