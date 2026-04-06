import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../../core/storage/database_service.dart';

// Modello dati
class PsychoProfile {
  final int lucidity;
  final int oblivionLevel;
  final int anxiety;

  PsychoProfile(
      {required this.lucidity,
      required this.oblivionLevel,
      required this.anxiety});

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
  static const _defaultProfileRow = {
    'id': 1,
    'lucidity': DatabaseService.defaultLucidity,
    'oblivion_level': DatabaseService.defaultOblivionLevel,
    'anxiety': DatabaseService.defaultAnxiety,
  };

  @override
  Future<PsychoProfile> build() async {
    return _fetchProfile();
  }

  Future<PsychoProfile> _fetchProfile() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps =
        await db.query('psycho_profile', where: 'id = 1');
    if (maps.isNotEmpty) {
      return PsychoProfile.fromMap(maps.first);
    }
    // Fallback di sicurezza, non dovrebbe mai accadere data l'inizializzazione del DB
    return PsychoProfile(
      lucidity: DatabaseService.defaultLucidity,
      oblivionLevel: DatabaseService.defaultOblivionLevel,
      anxiety: DatabaseService.defaultAnxiety,
    );
  }

  // Metodo per aggiornare un parametro dinamicamente (es. quando l'utente scrive frasi senza senso)
  Future<void> updateParameter(
      {int? lucidity, int? oblivionLevel, int? anxiety}) async {
    final db = await _dbService.database;

    // Aggiorna solo i campi passati
    final Map<String, dynamic> updates = {};
    if (lucidity != null) updates['lucidity'] = lucidity;
    if (oblivionLevel != null) updates['oblivion_level'] = oblivionLevel;
    if (anxiety != null) updates['anxiety'] = anxiety;

    if (updates.isNotEmpty) {
      await db.update('psycho_profile', updates, where: 'id = 1');
      // Ricarica lo stato per notificare i listener (UI, Audio, LLM System Prompt)
      state = const AsyncValue.loading();
      state = AsyncValue.data(await _fetchProfile());
    }
  }

  Future<void> resetProfile() async {
    final db = await _dbService.database;
    await db.insert(
      'psycho_profile',
      _defaultProfileRow,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    state = AsyncValue.data(await _fetchProfile());
  }
}

// Il provider globale da usare nell'app
final psychoProfileProvider =
    AsyncNotifierProvider<PsychoProfileNotifier, PsychoProfile>(() {
  return PsychoProfileNotifier();
});
