import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../../core/storage/database_service.dart';
import '../demiurge/demiurge_service.dart';

// Modello dati
class PsychoProfile {
  final int lucidity;
  final int oblivionLevel;
  final int anxiety;
  // Phase system (Option A overlay — non-destructive on top of existing sectors)
  final int phase;           // 1-5: current narrative phase
  final int awarenessLevel;  // 0-100: grows with exploration and insight
  final int proustAffinity;  // 0-100: affinity with Proust Echo
  final int tarkovskijAffinity; // 0-100: affinity with Tarkovskij Echo
  final int sethAffinity;    // 0-100: affinity with Seth Echo

  PsychoProfile({
    required this.lucidity,
    required this.oblivionLevel,
    required this.anxiety,
    this.phase = 1,
    this.awarenessLevel = 0,
    this.proustAffinity = 0,
    this.tarkovskijAffinity = 0,
    this.sethAffinity = 0,
  });

  factory PsychoProfile.fromMap(Map<String, dynamic> map) {
    return PsychoProfile(
      lucidity: map['lucidity'] as int,
      oblivionLevel: map['oblivion_level'] as int,
      anxiety: map['anxiety'] as int,
      phase: map['phase'] as int? ?? 1,
      awarenessLevel: map['awareness_level'] as int? ?? 0,
      proustAffinity: map['proust_affinity'] as int? ?? 0,
      tarkovskijAffinity: map['tarkovskij_affinity'] as int? ?? 0,
      sethAffinity: map['seth_affinity'] as int? ?? 0,
    );
  }
}

// Il Notifier che gestisce lo stato asincrono
class PsychoProfileNotifier extends AsyncNotifier<PsychoProfile> {
  final _dbService = DatabaseService.instance;

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
      // Reload state without an intermediate loading() to avoid UI flicker.
      state = AsyncValue.data(await _fetchProfile());
    }
  }

  /// Updates the phase-system metrics (awareness, affinities).
  /// Deltas are clamped to [0, 100]. Automatically advances the phase
  /// when awarenessLevel crosses a threshold.
  Future<void> updateAwareness({
    int? awarenessDelta,
    int? proustDelta,
    int? tarkovskijDelta,
    int? sethDelta,
  }) async {
    final current = state.valueOrNull ?? await _fetchProfile();
    final Map<String, dynamic> updates = {};

    if (awarenessDelta != null) {
      updates['awareness_level'] =
          (current.awarenessLevel + awarenessDelta).clamp(0, 100);
    }
    if (proustDelta != null) {
      updates['proust_affinity'] =
          (current.proustAffinity + proustDelta).clamp(0, 100);
    }
    if (tarkovskijDelta != null) {
      updates['tarkovskij_affinity'] =
          (current.tarkovskijAffinity + tarkovskijDelta).clamp(0, 100);
    }
    if (sethDelta != null) {
      updates['seth_affinity'] =
          (current.sethAffinity + sethDelta).clamp(0, 100);
    }

    if (updates.isEmpty) return;

    // Phase transition: advance phase if awarenessLevel crosses a threshold.
    final newAwareness =
        (updates['awareness_level'] as int?) ?? current.awarenessLevel;
    final newPhase = _phaseForAwareness(newAwareness, current.phase);
    if (newPhase != current.phase) {
      updates['phase'] = newPhase;
      DemiurgeService.instance.switchPhase(newPhase);
    }

    final db = await _dbService.database;
    await db.update('psycho_profile', updates, where: 'id = 1');
    state = AsyncValue.data(await _fetchProfile());
  }

  /// Returns the phase that corresponds to [awarenessLevel], never going below
  /// [currentPhase] (phases only advance, never regress).
  static int _phaseForAwareness(int awarenessLevel, int currentPhase) {
    // Thresholds: 20 → 2, 40 → 3, 60 → 4, 80 → 5
    int earned = 1;
    if (awarenessLevel >= 80) {
      earned = 5;
    } else if (awarenessLevel >= 60) {
      earned = 4;
    } else if (awarenessLevel >= 40) {
      earned = 3;
    } else if (awarenessLevel >= 20) {
      earned = 2;
    }
    return earned > currentPhase ? earned : currentPhase;
  }

  Future<void> resetProfile() async {
    final db = await _dbService.database;
    await db.insert(
      'psycho_profile',
      DatabaseService.defaultPsychoProfileRow,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    DemiurgeService.instance.switchPhase(1);
    state = AsyncValue.data(await _fetchProfile());
  }
}

// Il provider globale da usare nell'app
final psychoProfileProvider =
    AsyncNotifierProvider<PsychoProfileNotifier, PsychoProfile>(() {
  return PsychoProfileNotifier();
});
