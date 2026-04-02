import 'package:flutter_riverpod/flutter_riverpod.dart';
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

    return "$basePrompt $locationContext $psychoContext";
  }
}

// Provider per ottenere il servizio sempre aggiornato con gli ultimi stati
final llmContextServiceProvider = Provider<LlmContextService?>((ref) {
  final psychoState = ref.watch(psychoProfileProvider).valueOrNull;
  final gameState = ref.watch(gameStateProvider).valueOrNull;

  if (psychoState == null || gameState == null) return null;

  return LlmContextService(psychoState, gameState);
});
