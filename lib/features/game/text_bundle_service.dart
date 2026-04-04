// lib/features/game/text_bundle_service.dart
// Loads and caches JSON text bundles and prompt templates from assets.
// Bundles are used by the LLM context service (post Fase 0-omega).
// The game engine uses hardcoded fallback text; bundles enrich LLM prompts.

import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

class TextBundleService {
  static final TextBundleService instance = TextBundleService._();
  TextBundleService._();

  final Map<String, Map<String, dynamic>> _cache = {};

  // ── Bundle loaders ─────────────────────────────────────────────────────────

  /// Load a named bundle from `assets/texts/<name>.json`.
  /// Caches the result; subsequent calls are synchronous.
  Future<Map<String, dynamic>> loadBundle(String name) async {
    final key = 'texts/$name';
    if (_cache.containsKey(key)) return _cache[key]!;
    final raw = await rootBundle.loadString('assets/texts/$name.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;
    _cache[key] = data;
    return data;
  }

  /// Load a named prompt template from `assets/prompts/<name>.json`.
  Future<Map<String, dynamic>> loadPrompt(String name) async {
    final key = 'prompts/$name';
    if (_cache.containsKey(key)) return _cache[key]!;
    final raw = await rootBundle.loadString('assets/prompts/$name.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;
    _cache[key] = data;
    return data;
  }

  // ── Convenience accessors ─────────────────────────────────────────────────

  /// Pre-load all bundles into the cache. Call once at app startup.
  Future<void> preloadAll() async {
    const bundles = [
      'epicuro_bundle', 'proust_bundle', 'tarkovsky_bundle',
      'newton_bundle',  'alchimia_bundle', 'arte_bundle',
    ];
    const prompts = ['zona_templates', 'antagonist_templates', 'proust_triggers'];
    await Future.wait([
      for (final b in bundles) loadBundle(b),
      for (final p in prompts)  loadPrompt(p),
    ]);
  }

  /// Returns the [n]th Zone question (0-indexed, wraps around).
  /// Returns an empty map if the bundle is not yet loaded.
  Map<String, dynamic> zoneQuestion(int n) {
    final templates = _cache['prompts/zona_templates'];
    if (templates == null) return const {};
    final questions = templates['questions'] as List<dynamic>?;
    if (questions == null || questions.isEmpty) return const {};
    return questions[n % questions.length] as Map<String, dynamic>;
  }

  /// Returns all Resolution keywords from antagonist_templates.json.
  List<String> get resolutionKeywords {
    final t = _cache['prompts/antagonist_templates'];
    if (t == null) return const [];
    return List<String>.from(t['resolution_keywords'] as List<dynamic>? ?? []);
  }

  /// Returns all Surrender keywords from antagonist_templates.json.
  List<String> get surrenderKeywords {
    final t = _cache['prompts/antagonist_templates'];
    if (t == null) return const [];
    return List<String>.from(t['surrender_keywords'] as List<dynamic>? ?? []);
  }

  /// Returns Tarkovsky verse for zone entry at encounter [n].
  String? tarkovskyVerse(int n) {
    final t = _cache['texts/tarkovsky_bundle'];
    if (t == null) return null;
    final verses = t['zone_verses'] as List<dynamic>?;
    if (verses == null || verses.isEmpty) return null;
    final v = verses[n % verses.length] as Map<String, dynamic>;
    return v['text'] as String?;
  }

  /// Returns a zone environment fragment for encounter [n].
  String? zoneEnvironment(int n) {
    final t = _cache['texts/tarkovsky_bundle'];
    if (t == null) return null;
    final envs = t['zone_environment_fragments'] as List<dynamic>?;
    if (envs == null || envs.isEmpty) return null;
    return envs[n % envs.length] as String?;
  }
}
