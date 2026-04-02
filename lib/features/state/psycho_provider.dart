import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/storage/database_service.dart';

// Modello dati
class PsychoProfile {
  final int lucidity;
  final int oblivionLevel;
  final int anxiety;

  PsychoProfile({
    required this.lucidity,
    required this.oblivionLevel,
    required this.anxiety,
  });

  factory PsychoProfile.fromMap(Map<String, dynamic> map) {
    return PsychoProfile(
      lucidity: map['lucidity'] as int,
      oblivionLevel: map['oblivion_level'] as int,
      anxiety: map['anxiety'] as int,
    );
  }
}

// Il Notifier che gestisce lo stato asincrono
class PsychoProfileNotifier extends AsyncNotifier<PsychoProfile> {
  final _dbService = DatabaseService.instance;

  @override
  Future<PsychoProfile> build() async {
    return await _loadProfile();
  }

  Future<PsychoProfile> _loadProfile() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> rows = await db.query(
      'psycho_profile',
      where: 'id = 1',
    );

    if (rows.isNotEmpty) {
      return PsychoProfile.fromMap(rows.first);
    }

    // Fallback di sicurezza, non dovrebbe mai accadere data l'inizializzazione del DB
    return PsychoProfile(lucidity: 100, oblivionLevel: 0, anxiety: 0);
  }

  // Metodo per aggiornare un parametro dinamicamente (es. quando l'utente scrive frasi senza senso)
  Future<void> updateProfile({
    int? lucidity,
    int? oblivionLevel,
    int? anxiety,
  }) async {
    final db = await _dbService.database;

    // Aggiorna solo i campi passati
    final Map<String, dynamic> values = {};
    if (lucidity != null) values['lucidity'] = lucidity;
    if (oblivionLevel != null) values['oblivion_level'] = oblivionLevel;
    if (anxiety != null) values['anxiety'] = anxiety;

    if (values.isEmpty) return;

    await db.update('psycho_profile', values, where: 'id = 1');

    // Ricarica lo stato per notificare i listener (UI, Audio, LLM System Prompt)
    state = const AsyncValue.loading();
    state = AsyncValue.data(await _loadProfile());
  }
}

// Il provider globale da usare nell'app
final psychoProfileProvider =
    AsyncNotifierProvider<PsychoProfileNotifier, PsychoProfile>(
  () => PsychoProfileNotifier(),
);
