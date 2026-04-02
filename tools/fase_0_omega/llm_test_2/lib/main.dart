// Fase 0-omega — Tentativo 2: mediapipe_genai
// Archive of Oblivion — LLM Validation Suite (GDD §17)
//
// PURPOSE: Validate that mediapipe_genai + Gemma 2B can run on a physical Android
// device within the success criteria defined in GDD §17.
//
// KEY DIFFERENCE FROM TEST 1:
// - Gemma prompt format: <start_of_turn>user / <end_of_turn> / <start_of_turn>model
//   (NOT Qwen's <|system|> / <|user|> format)
// - If this test passes, ALL prompt templates in GDD §20 must be adapted.
// - Model is ~1.3 GB — too large for APK assets, loaded from external storage.
//
// USAGE:
// 1. adb push gemma-2b-it-gpu-int8.bin /sdcard/Download/
// 2. flutter run --release (physical device only)
// 3. Verify model path in the app, tap START TESTS

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mediapipe_genai/mediapipe_genai.dart';

void main() => runApp(const LlmTestApp());

class LlmTestApp extends StatelessWidget {
  const LlmTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fase 0-omega — Test 2',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        colorScheme:
            const ColorScheme.dark(primary: Colors.tealAccent),
      ),
      home: const TestScreen(),
    );
  }
}

// ---------------------------------------------------------------------------
// Test prompts — Gemma format (start_of_turn / end_of_turn)
// These mirror the game templates from GDD §20, adapted for Gemma.
// If this test passes, the main project must use this format throughout.
// ---------------------------------------------------------------------------

String _gemmaPrompt(String systemInstruction, String userMessage) {
  // Gemma doesn't have a dedicated system turn — prepend to user turn.
  return '<start_of_turn>user\n'
      '$systemInstruction\n\n'
      '$userMessage\n'
      '<end_of_turn>\n'
      '<start_of_turn>model\n';
}

final List<_Prompt> _kTestPrompts = [
  _Prompt(
    label: '1. Zone Narrative',
    content: _gemmaPrompt(
      'You are the narrator of an oneiric text adventure. '
      'Max 60 words, poetic, impossible geometries, one unexpected sensory detail. Only describe.',
      'Simulacra collected: 2/4. '
      'Tarkovsky verse: "I dreamed my childhood was returning". Mood: burdened.',
    ),
  ),
  _Prompt(
    label: '2. Proustian Trigger',
    content: _gemmaPrompt(
      'Generate a Proustian reminiscence. Max 50 words. '
      'Triggered by smell of linden. Precise sensory detail, sensation preceding the memory. Then ONE question.',
      'Proust reference: "the smell and taste of things remain poised a long while, like souls". '
      'Sector: garden.',
    ),
  ),
  _Prompt(
    label: '3. Narrator — Weight 0 (lucid)',
    content: _gemmaPrompt(
      'Describe with lucid, minimal, airy style. The player is at peace.',
      'Describe: a circular rotunda of black marble veined with silver. Four colored doors.',
    ),
  ),
  _Prompt(
    label: '4. Narrator — Weight 3+ (oppressed)',
    content: _gemmaPrompt(
      'Describe as oppressive, claustrophobic, anxious. Mind clouded.',
      'Describe: a circular rotunda of black marble veined with silver. Four colored doors.',
    ),
  ),
  _Prompt(
    label: '5. Antagonist Argument',
    content: _gemmaPrompt(
      'You are the Antagonist. Argue calmly that oblivion is mercy. '
      'Logical, never hostile. Max 80 words. If the player makes a valid point, concede elegantly.',
      'Phase: 1. Player input: "I want to remember." Inventory: gold coin, ancient book.',
    ),
  ),
];

// ---------------------------------------------------------------------------
// Data models
// ---------------------------------------------------------------------------
class _Prompt {
  final String label;
  final String content;
  const _Prompt({required this.label, required this.content});
}

class _TestResult {
  final String label;
  final int durationMs;
  final int approxTokens;
  final String output;
  final String? error;

  const _TestResult({
    required this.label,
    required this.durationMs,
    required this.approxTokens,
    required this.output,
    this.error,
  });

  double get tokensPerSecond =>
      approxTokens / ((durationMs > 0 ? durationMs : 1) / 1000);

  // GDD §17: generation < 15s for MediaPipe (stricter than test 1)
  bool get passed =>
      error == null && durationMs < 15000 && output.trim().length > 10;
}

enum _Phase { idle, loading, testing, done, error }

// ---------------------------------------------------------------------------
// Main screen
// ---------------------------------------------------------------------------
class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  _Phase _phase = _Phase.idle;
  String _status = 'Ready. Push model to /sdcard/Download/ then tap START TESTS.';
  int _loadMs = 0;
  final List<_TestResult> _results = [];
  bool _modelLoaded = false;
  bool _modelFileFound = false;

  LlmInferenceEngine? _engine;
  late final TextEditingController _pathCtrl;

  static const String _defaultModelPath =
      '/sdcard/Download/gemma-2b-it-gpu-int8.bin';

  @override
  void initState() {
    super.initState();
    _pathCtrl = TextEditingController(text: _defaultModelPath);
    _checkModelFile();
  }

  @override
  void dispose() {
    _pathCtrl.dispose();
    super.dispose();
  }

  void _checkModelFile() {
    final exists = File(_pathCtrl.text).existsSync();
    if (exists != _modelFileFound) {
      setState(() => _modelFileFound = exists);
    }
  }

  Future<void> _loadModel() async {
    setState(() {
      _phase = _Phase.loading;
      _status = 'Initializing MediaPipe LLM engine…';
      _modelLoaded = false;
    });

    final sw = Stopwatch()..start();
    try {
      // Try GPU first; fall back to CPU if GPU not supported
      _engine = LlmInferenceEngine(
        LlmInferenceOptions.gpu(modelPath: _pathCtrl.text),
      );
      sw.stop();
    } catch (gpuError) {
      // GPU not available — try CPU
      setState(() => _status = 'GPU init failed, trying CPU… ($gpuError)');
      try {
        _engine = LlmInferenceEngine(
          LlmInferenceOptions.cpu(modelPath: _pathCtrl.text),
        );
        sw.stop();
      } catch (cpuError) {
        sw.stop();
        setState(() {
          _phase = _Phase.error;
          _status = '❌ Failed to create LlmInferenceEngine.\n'
              'GPU error: $gpuError\n'
              'CPU error: $cpuError';
        });
        return;
      }
    }

    setState(() {
      _loadMs = sw.elapsedMilliseconds;
      _modelLoaded = true;
      _status = '✅ Engine ready in ${(_loadMs / 1000).toStringAsFixed(2)}s';
    });
  }

  Future<void> _runTests() async {
    setState(() {
      _phase = _Phase.testing;
      _results.clear();
    });

    for (final prompt in _kTestPrompts) {
      setState(() => _status = 'Running ${prompt.label}…');

      try {
        final sw = Stopwatch()..start();

        final buffer = StringBuffer();
        await for (final chunk in _engine!.generateResponse(prompt.content)) {
          buffer.write(chunk);
          // Stop after ~100 tokens to keep test duration predictable
          if (buffer.length > 400) break;
        }
        sw.stop();

        final text = buffer.toString().trim();
        final approxTok = (text.length / 4).round().clamp(1, 9999);

        _results.add(_TestResult(
          label: prompt.label,
          durationMs: sw.elapsedMilliseconds,
          approxTokens: approxTok,
          output: text,
        ));
      } catch (e) {
        _results.add(_TestResult(
          label: prompt.label,
          durationMs: 0,
          approxTokens: 0,
          output: '',
          error: e.toString(),
        ));
      }

      setState(() {});
      await Future.delayed(const Duration(milliseconds: 300));
    }

    setState(() {
      _phase = _Phase.done;
      _status = 'All tests complete. Scroll down for verdict.';
    });
  }

  Future<void> _startAll() async {
    try {
      await _loadModel();
      if (_modelLoaded) await _runTests();
    } catch (e) {
      setState(() {
        _phase = _Phase.error;
        _status = '❌ Fatal exception: $e';
      });
    }
  }

  bool get _overallPass {
    if (!_modelLoaded || _results.length < _kTestPrompts.length) return false;
    if (_loadMs > 60000) return false;
    return _results.every((r) => r.passed);
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fase 0-omega — Test 2: mediapipe_genai'),
        backgroundColor: Colors.teal.shade900,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildWarningBanner(),
            const SizedBox(height: 12),
            _buildCriteria(),
            const SizedBox(height: 12),
            _buildModelPathField(),
            const SizedBox(height: 12),
            _buildStatusCard(),
            const SizedBox(height: 12),
            if (_phase == _Phase.idle || _phase == _Phase.error)
              _buildStartButton(),
            if (_phase == _Phase.loading) const LinearProgressIndicator(),
            if (_loadMs > 0) ...[
              const SizedBox(height: 12),
              _buildMetricRow(
                'Engine init time',
                '${(_loadMs / 1000).toStringAsFixed(2)}s',
                _loadMs < 60000,
                threshold: '< 60s',
              ),
            ],
            const SizedBox(height: 8),
            ..._results.map(_buildResultCard),
            if (_phase == _Phase.done) ...[
              const SizedBox(height: 20),
              _buildVerdict(),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningBanner() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.amber.shade900.withOpacity(0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade700),
      ),
      child: const Text(
        '⚠️  TENTATIVO 2 — Only run this if Tentativo 1 (flutter_llama) failed.\n'
        'If this passes, all GDD §20 prompt templates must be adapted to Gemma format.',
        style: TextStyle(color: Colors.amber, fontSize: 11),
      ),
    );
  }

  Widget _buildCriteria() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SUCCESS CRITERIA — GDD §17 (MediaPipe)',
            style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1),
          ),
          const SizedBox(height: 8),
          for (final entry in {
            'Load time': '< 60 s',
            'Generation per prompt': '< 15 s (MediaPipe target)',
            'Output quality': 'non-gibberish English',
            '5 consecutive runs': 'no crash',
            'RAM': '< 2 GB  ← measure with Android Studio Profiler',
          }.entries)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  const Icon(Icons.radio_button_unchecked,
                      color: Colors.white30, size: 14),
                  const SizedBox(width: 8),
                  Text('${entry.key}: ',
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 12)),
                  Text(entry.value,
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontStyle: FontStyle.italic)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModelPathField() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _modelFileFound ? Icons.check_circle : Icons.error_outline,
                color:
                    _modelFileFound ? Colors.green : Colors.orange,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                _modelFileFound ? 'Model file found' : 'Model file not found',
                style: TextStyle(
                  color: _modelFileFound
                      ? Colors.greenAccent
                      : Colors.orangeAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _checkModelFile,
                child:
                    const Text('Refresh', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _pathCtrl,
            onChanged: (_) => _checkModelFile(),
            style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
            decoration: const InputDecoration(
              labelText: 'Model path on device (.bin format)',
              labelStyle: TextStyle(fontSize: 11),
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'adb push gemma-2b-it-gpu-int8.bin /sdcard/Download/',
            style: TextStyle(
                fontFamily: 'monospace',
                color: Colors.white30,
                fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _status,
        style: const TextStyle(
            color: Colors.white, fontFamily: 'monospace', fontSize: 12),
      ),
    );
  }

  Widget _buildStartButton() {
    return ElevatedButton(
      onPressed: _modelFileFound ? _startAll : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.teal.shade700,
        disabledBackgroundColor: Colors.grey[800],
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: Text(
        _modelFileFound
            ? '▶  START TESTS'
            : '▶  START TESTS (model not found)',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildMetricRow(
    String label,
    String value,
    bool pass, {
    String threshold = '',
  }) {
    return Row(
      children: [
        Icon(
          pass ? Icons.check_circle : Icons.cancel,
          color: pass ? Colors.greenAccent : Colors.redAccent,
          size: 16,
        ),
        const SizedBox(width: 8),
        Text('$label: ',
            style: const TextStyle(color: Colors.white54, fontSize: 12)),
        Text(
          value,
          style: TextStyle(
            color: pass ? Colors.greenAccent : Colors.redAccent,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (threshold.isNotEmpty) ...[
          const SizedBox(width: 4),
          Text('($threshold)',
              style: const TextStyle(color: Colors.white30, fontSize: 11)),
        ],
      ],
    );
  }

  Widget _buildResultCard(_TestResult r) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: _card(
        color: r.error != null
            ? Colors.red.shade900.withOpacity(0.5)
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  r.passed ? Icons.check_circle : Icons.cancel,
                  color: r.passed ? Colors.green : Colors.red,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    r.label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                  ),
                ),
                if (r.error == null)
                  Text(
                    '${(r.durationMs / 1000).toStringAsFixed(2)}s  '
                    '~${r.approxTokens}tok  '
                    '${r.tokensPerSecond.toStringAsFixed(1)}tok/s',
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 10),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            if (r.error != null)
              Text(
                'ERROR: ${r.error}',
                style: const TextStyle(
                    color: Colors.redAccent,
                    fontFamily: 'monospace',
                    fontSize: 10),
              )
            else
              Text(
                r.output.length > 300
                    ? '${r.output.substring(0, 300)}…'
                    : r.output,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 11),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerdict() {
    final passCount = _results.where((r) => r.passed).length;
    final avgMs = _results.isEmpty
        ? 0
        : _results.map((r) => r.durationMs).reduce((a, b) => a + b) ~/
            _results.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _overallPass
            ? Colors.green.shade900.withOpacity(0.6)
            : Colors.red.shade900.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _overallPass ? Colors.greenAccent : Colors.redAccent,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Text(
            _overallPass
                ? '✅  TENTATIVO 2 PASSED'
                : '❌  TENTATIVO 2 FAILED',
            style: TextStyle(
              color:
                  _overallPass ? Colors.greenAccent : Colors.redAccent,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            _overallPass
                ? 'mediapipe_genai is viable.\n'
                    'Add mediapipe_genai to main pubspec.yaml.\n'
                    'Adapt all GDD §20 prompt templates to Gemma format.\n'
                    'Replace _llmStub() in game_engine_provider.dart.'
                : 'mediapipe_genai failed.\n'
                    'Proceed to Tentativo 3: FFI custom llama.cpp (8h).',
            style: const TextStyle(color: Colors.white, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Load: ${(_loadMs / 1000).toStringAsFixed(1)}s  |  '
            'Tests: $passCount/${_results.length} passed  |  '
            'Avg gen: ${(avgMs / 1000).toStringAsFixed(1)}s',
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
          const SizedBox(height: 8),
          const Text(
            '⚠️  Check RAM usage in Android Studio Profiler (target: < 2 GB)',
            style: TextStyle(
                color: Colors.amber,
                fontSize: 11,
                fontStyle: FontStyle.italic),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child, Color? color}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color ?? Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );
  }
}
