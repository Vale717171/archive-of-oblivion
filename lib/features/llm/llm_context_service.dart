import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/psycho_provider.dart';
import '../state/game_state_provider.dart';

class LlmContextService {
  final PsychoProfile psychoProfile;
  final GameState gameState;

  LlmContextService({required this.psychoProfile, required this.gameState});

  String buildSystemPrompt() {
    // Regole di base fisse
    const String basePrompt =
        "Sei l'Archivio dell'Oblio, un'entità criptica e insondabile. "
        "Rispondi in modo conciso, filosofico e onirico. "
        "Non spiegare mai direttamente — allude, suggerisci, frammenta. ";

    // Contesto narrativo
    final String locationContext =
        "Il giocatore si trova attualmente nel nodo narrativo: ${gameState.currentNode}. ";

    // Modificatori psicologici
    String psychoContext = "L'ansia del giocatore è a ${psychoProfile.anxiety}%. ";

    if (psychoProfile.anxiety >= 80) {
      psychoContext +=
          "Il giocatore è nel panico. Usa un tono pressante e frammentato. ";
    } else if (psychoProfile.lucidity <= 30) {
      psychoContext +=
          "Il giocatore sta perdendo la lucidità. Le tue risposte devono essere oniriche e confondere la realtà. ";
    }

    return "$basePrompt $locationContext $psychoContext";
  }
}

// Provider per ottenere il servizio sempre aggiornato con gli ultimi stati
final llmContextServiceProvider = Provider<LlmContextService?>((ref) {
  final psychoAsync = ref.watch(psychoProfileProvider);
  final gameAsync = ref.watch(gameStateProvider);

  final psycho = psychoAsync.value;
  final game = gameAsync.value;

  if (psycho == null || game == null) return null;

  return LlmContextService(psychoProfile: psycho, gameState: game);
});
