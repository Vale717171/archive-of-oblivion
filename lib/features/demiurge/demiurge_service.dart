// lib/features/demiurge/demiurge_service.dart
// "All That Is" (Tutto Ciò Che È) — deterministic narrator replacing the LLM.
// Responds to unrecognized commands with enigmatic sentences, cultural citations,
// and ambiguous closing lines. The player never knows if they made a mistake
// or discovered something. Error is part of the existential journey.

import 'dart:convert';
import 'dart:math' show Random;

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A single response entry from the Demiurge JSON bundles.
class DemiurgeEntry {
  final String opening;
  final String citation;
  final String author;
  final String closing;

  const DemiurgeEntry({
    required this.opening,
    required this.citation,
    required this.author,
    required this.closing,
  });

  factory DemiurgeEntry.fromJson(Map<String, dynamic> json) => DemiurgeEntry(
        opening: json['opening'] as String,
        citation: json['citation'] as String,
        author: json['author'] as String,
        closing: json['closing'] as String,
      );

  /// Formats the entry as display text for the player.
  String format() => '$opening\n\n"$citation"\n— $author\n\n$closing';
}

/// Deterministic narrator service — replaces the on-device LLM.
///
/// Loads curated citation bundles from `assets/texts/demiurge/` and serves
/// responses that blend enigmatic openings, public-domain citations, and
/// ambiguous closings. An anti-repetition buffer ensures the last
/// [_antiRepeatWindow] entries are never repeated.
class DemiurgeService {
  DemiurgeService._();
  static final DemiurgeService instance = DemiurgeService._();

  final Random _rng = Random();

  /// Current narrative phase (1-5). Influences the tone framing of responses.
  int _currentPhase = 1;

  /// Advances the Demiurge to the given narrative phase.
  /// Phase only ever moves forward; calling with a lower value is a no-op.
  void switchPhase(int phase) {
    if (phase > _currentPhase) _currentPhase = phase.clamp(1, 5);
  }

  int get currentPhase => _currentPhase;

  /// Sector → list of loaded entries.
  final Map<String, List<DemiurgeEntry>> _pools = {};

  /// Recently shown indices per sector (anti-repetition ring buffer).
  final Map<String, List<int>> _recentIndices = {};

  static const int _antiRepeatWindow = 20;

  // Sector keys matching JSON file names in assets/texts/demiurge/.
  static const List<String> sectorKeys = [
    'giardino',
    'osservatorio',
    'galleria',
    'laboratorio',
    'universale',
  ];

  // ── Loading ──────────────────────────────────────────────────────────────

  /// Loads all sector bundles from assets. Safe to call multiple times.
  Future<void> loadAll() async {
    for (final sector in sectorKeys) {
      if (_pools.containsKey(sector)) continue;
      await _loadSector(sector);
    }
  }

  Future<void> _loadSector(String sector) async {
    try {
      final raw = await rootBundle
          .loadString('assets/texts/demiurge/$sector.json');
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final responses = (data['responses'] as List<dynamic>)
          .map((e) => DemiurgeEntry.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
      _pools[sector] = responses;
      _recentIndices[sector] = [];
    } catch (e) {
      // Bundle missing or malformed — pool stays empty; log for debugging.
      // ignore: avoid_print
      assert(() { print('DemiurgeService: failed to load $sector — $e'); return true; }());
      _pools[sector] = [];
      _recentIndices[sector] = [];
    }
  }

  // ── Response generation ──────────────────────────────────────────────────

  /// Returns a formatted Demiurge response for the given [sector].
  /// Falls back to the [universale] pool when the sector pool is empty,
  /// and to [fallbackText] when no entries are available at all.
  String respond({required String sector, required String fallbackText}) {
    final entry = _pickEntry(sector) ??
        _pickEntry('universale');
    return entry?.format() ?? fallbackText;
  }

  DemiurgeEntry? _pickEntry(String sector) {
    final pool = _pools[sector];
    if (pool == null || pool.isEmpty) return null;

    final recent = _recentIndices[sector] ?? [];
    final recentSet = recent.toSet();
    final available = List<int>.generate(pool.length, (i) => i)
      ..removeWhere(recentSet.contains);

    // If all indices were recently shown, reset the buffer and re-compute
    // available without recursion to avoid any risk of infinite call chains
    // (e.g. a corrupt pool with length 0 that somehow passed the guard above).
    if (available.isEmpty) {
      _recentIndices[sector] = [];
      final refreshed = List<int>.generate(pool.length, (i) => i);
      if (refreshed.isEmpty) return null;
      available.addAll(refreshed);
    }

    final chosen = available[_rng.nextInt(available.length)];

    // Update anti-repetition buffer.
    final buffer = _recentIndices[sector] ?? [];
    buffer.add(chosen);
    if (buffer.length > _antiRepeatWindow) {
      buffer.removeAt(0);
    }
    _recentIndices[sector] = buffer;

    return pool[chosen];
  }

  // ── Mapping helpers ──────────────────────────────────────────────────────

  /// Maps a game node ID to its Demiurge sector key.
  static String sectorForNode(String nodeId) {
    if (nodeId.startsWith('garden') || nodeId == 'la_soglia') {
      return 'giardino';
    }
    if (nodeId.startsWith('obs_')) return 'osservatorio';
    if (nodeId.startsWith('gal_')) return 'galleria';
    if (nodeId.startsWith('lab_')) return 'laboratorio';
    return 'universale';
  }
}

// ── Riverpod provider ───────────────────────────────────────────────────────

final demiurgeServiceProvider =
    Provider<DemiurgeService>((_) => DemiurgeService.instance);
