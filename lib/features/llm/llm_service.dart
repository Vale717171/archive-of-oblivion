// lib/features/llm/llm_service.dart
// Fase 0-omega — Tentativo 1: flutter_llama + Qwen 2.5 0.5B Q4_K_M
// Replaces _llmStub() in game_engine_provider.dart (GDD §17).

import 'dart:io';

import 'package:flutter_llama/flutter_llama.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'llm_context_service.dart';

// Default model path — user must push the .gguf file via adb:
//   adb push qwen2.5-0.5b-instruct-q4_k_m.gguf /sdcard/Download/
const String _kDefaultModelPath =
    '/sdcard/Download/qwen2.5-0.5b-instruct-q4_k_m.gguf';

/// Singleton wrapper around [FlutterLlama].
/// Loads the Qwen 2.5 0.5B model once and keeps it in memory for the session.
/// All public methods are safe to call without checking [isLoaded] first;
/// they return the [fallbackText] gracefully on any error.
class LlmService {
  LlmService._();
  static final LlmService instance = LlmService._();

  bool _loaded = false;
  Completer<bool>? _loadCompleter;

  bool get isLoaded => _loaded;

  // ── Model lifecycle ────────────────────────────────────────────────────────

  /// Loads the model if not already loaded.
  /// Concurrent calls wait for the same load operation rather than triggering
  /// duplicate loads, using a [Completer] as a one-shot latch.
  /// Returns `true` on success, `false` if the file is missing or load fails.
  Future<bool> ensureLoaded({String modelPath = _kDefaultModelPath}) async {
    if (_loaded) return true;

    // If a load is already in progress, wait for it to complete.
    if (_loadCompleter != null) {
      return _loadCompleter!.future;
    }

    final file = File(modelPath);
    if (!file.existsSync()) return false;

    _loadCompleter = Completer<bool>();
    try {
      final config = LlamaConfig(
        modelPath: modelPath,
        nThreads: 4,
        // 0 = CPU-only; set nGpuLayers: -1 AND useGpu: true together to enable Vulkan GPU
        nGpuLayers: 0,
        contextSize: 2048,
        batchSize: 512,
        useGpu: false,
        verbose: false,
      );
      _loaded = await FlutterLlama.instance.loadModel(config);
    } catch (_) {
      _loaded = false;
    }
    _loadCompleter!.complete(_loaded);
    _loadCompleter = null;
    return _loaded;
  }

  Future<void> unload() async {
    if (!_loaded) return;
    try {
      await FlutterLlama.instance.unloadModel();
    } finally {
      _loaded = false;
    }
  }

  // ── Text generation ────────────────────────────────────────────────────────

  /// Generates narrative text using the on-device LLM.
  ///
  /// [fallbackText] is the engine-authored text used both as the user prompt
  /// and as the return value when the LLM is unavailable or errors out.
  /// [context] provides the dynamic system prompt (psych profile, node, etc.).
  ///
  /// Prompt format: Qwen `<|system|>/<|user|>/<|assistant|>` (GDD §20).
  Future<String> generate(
    String fallbackText, {
    LlmContextService? context,
  }) async {
    if (!_loaded) {
      final ok = await ensureLoaded();
      if (!ok) return fallbackText;
    }

    final systemPrompt = context?.buildDynamicSystemPrompt() ??
        'You are the narrator of an oneiric text adventure. '
            'Max 60 words, poetic and slightly unsettling. Only describe.';

    final fullPrompt = '<|system|>\n$systemPrompt\n'
        '<|user|>\n$fallbackText\n'
        '<|assistant|>';

    try {
      final params = GenerationParams(
        prompt: fullPrompt,
        temperature: 0.7,
        topP: 0.95,
        topK: 40,
        maxTokens: 100,
        repeatPenalty: 1.1,
      );
      final response = await FlutterLlama.instance.generate(params);
      final text = response.text.trim();
      return text.isNotEmpty ? text : fallbackText;
    } catch (_) {
      return fallbackText;
    }
  }
}

// ── Riverpod provider ─────────────────────────────────────────────────────────

final llmServiceProvider = Provider<LlmService>((_) => LlmService.instance);
