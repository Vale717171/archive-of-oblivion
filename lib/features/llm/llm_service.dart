// lib/features/llm/llm_service.dart
// Fase 0-omega — Tentativo 1: flutter_llama + Qwen 2.5 0.5B Q4_K_M
// LEGACY — superseded by DemiurgeService ("All That Is"). Do not import. Do not delete.
// flutter_llama dependency removed from pubspec.yaml; stubs left for reference.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'llm_context_service.dart';

const String _kDefaultModelPath =
    '/sdcard/Download/qwen2.5-0.5b-instruct-q4_k_m.gguf';

/// Legacy singleton — non-functional stub kept for historical reference.
/// The game engine now uses DemiurgeService instead.
class LlmService {
  LlmService._();
  static final LlmService instance = LlmService._();

  bool get isLoaded => false;

  Future<bool> ensureLoaded({String modelPath = _kDefaultModelPath}) async =>
      false;

  Future<void> unload() async {}

  Future<String> generate(
    String fallbackText, {
    LlmContextService? context,
  }) async =>
      fallbackText;
}

final llmServiceProvider = Provider<LlmService>((_) => LlmService.instance);
