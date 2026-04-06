// lib/features/ui/game_screen.dart
// Author: GitHub Copilot — 2026-04-02
// Main text UI for L'Archivio dell'Oblio.
// Features:
//   - Scrollable message history (player input + narrative responses)
//   - Text input at the bottom
//   - Typewriter effect for incoming narrative messages
//   - Colour palette that shifts subtly with PsychoProfile
//   - Subtle sector background image (opacity 0.15) behind the text

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/game_engine_provider.dart';
import '../parser/parser_state.dart';
import '../state/game_state_provider.dart';
import '../state/psycho_provider.dart';
import 'background_service.dart';

// PsychoProfile thresholds that drive the UI colour palette (mirror GDD section 6)
const int _panicAnxietyThreshold = 70; // anxiety > this → reddish text
const int _lowLucidityThreshold = 30; // lucidity < this → grey text
const int _highOblivionThreshold = 60; // oblivionLevel > this → blue-grey text

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  // Typewriter state for the last narrative message
  String _typewriterBuffer = '';
  int _typewriterIndex = 0;
  bool _typewriterRunning = false;
  String? _typewriterTarget;
  Timer? _typewriterTimer;

  @override
  void initState() {
    super.initState();
    // Request input focus after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focusNode.requestFocus();
      for (final assetPath in BackgroundService.allBackgroundAssets) {
        precacheImage(AssetImage(assetPath), context);
      }
    });
  }

  @override
  void dispose() {
    _typewriterTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ── Palette ─────────────────────────────────────────────────────────────

  /// Text colour for narrative messages — shifts with psychological state.
  Color _narrativeColor(PsychoProfile? profile) {
    if (profile == null) return Colors.white;
    if (profile.anxiety > _panicAnxietyThreshold) return const Color(0xFFFFD8D8);
    if (profile.lucidity < _lowLucidityThreshold) return const Color(0xFFCCCCCC);
    if (profile.oblivionLevel > _highOblivionThreshold) return const Color(0xFFCCDDEE);
    return Colors.white;
  }

  /// Subtle background tint — deepens as oblivion rises.
  Color _backgroundColor(PsychoProfile? profile) {
    if (profile == null) return Colors.black;
    final t = (profile.oblivionLevel / 100).clamp(0.0, 0.3);
    return Color.lerp(Colors.black, const Color(0xFF050A14), t)!;
  }

  // ── Typewriter ──────────────────────────────────────────────────────────

  void _startTypewriter(String text) {
    if (_typewriterTarget == text && _typewriterRunning) return;
    _typewriterTarget = text;
    _typewriterBuffer = '';
    _typewriterIndex = 0;
    _typewriterRunning = true;
    _tickTypewriter();
  }

  void _tickTypewriter() {
    if (!_typewriterRunning || _typewriterTarget == null) return;
    if (_typewriterIndex >= _typewriterTarget!.length) {
      setState(() => _typewriterRunning = false);
      return;
    }
    // Variable speed: faster for spaces/punctuation, slower for letters
    final ch = _typewriterTarget![_typewriterIndex];
    final delay = (ch == ' ' || ch == '\n') ? 10 : 22;

    _typewriterTimer?.cancel();
    _typewriterTimer = Timer(Duration(milliseconds: delay), () {
      if (!mounted || _typewriterTarget == null) return;
      setState(() {
        _typewriterBuffer += ch;
        _typewriterIndex++;
      });
      _scrollToBottom();
      _tickTypewriter();
    });
  }

  void _skipTypewriter() {
    if (_typewriterRunning && _typewriterTarget != null) {
      _typewriterTimer?.cancel();
      setState(() {
        _typewriterBuffer = _typewriterTarget!;
        _typewriterIndex = _typewriterTarget!.length;
        _typewriterRunning = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Input ────────────────────────────────────────────────────────────────

  void _submit() {
    if (_typewriterRunning) {
      _skipTypewriter();
      return;
    }
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    ref.read(gameEngineProvider.notifier).processInput(text);
    _focusNode.requestFocus();
    SystemChannels.textInput.invokeMethod('TextInput.show');
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final engineAsync = ref.watch(gameEngineProvider);
    final psychoAsync = ref.watch(psychoProfileProvider);
    final gameStateAsync = ref.watch(gameStateProvider);
    final profile = psychoAsync.valueOrNull;

    final bgColor = _backgroundColor(profile);
    final narrativeColor = _narrativeColor(profile);

    // Resolve background image from current node
    final backgroundPath = BackgroundService.getBackgroundForNodeOrDefault(
      gameStateAsync.valueOrNull?.currentNode,
    );

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Background image — subtle sector atmosphere
            Positioned.fill(
              child: Opacity(
                opacity: 0.15,
                child: Image.asset(
                  backgroundPath,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                ),
              ),
            ),
            // Game content on top — unchanged
            engineAsync.when(
              loading: () => Center(
                child: Text(
                  '…',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 24,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              error: (e, _) => Center(
                child: Text(
                  'The Archive is inaccessible.\n$e',
                  style: const TextStyle(color: Colors.red, fontFamily: 'monospace'),
                  textAlign: TextAlign.center,
                ),
              ),
              data: (engine) {
                // Start typewriter for the latest narrative message when it arrives
                final lastNarrative = engine.messages.lastOrNull;
                if (lastNarrative != null &&
                    lastNarrative.role == MessageRole.narrative &&
                    _typewriterTarget != lastNarrative.text) {
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) => _startTypewriter(lastNarrative.text),
                  );
                }

                return Column(
                  children: [
                    // ── Message history ──────────────────────────────────────
                    Expanded(
                      child: GestureDetector(
                        onTap: _skipTypewriter,
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(20, 32, 20, 8),
                          itemCount: engine.messages.length,
                          itemBuilder: (context, index) {
                            final msg = engine.messages[index];
                            final isLast = index == engine.messages.length - 1;
                            final isLastNarrative =
                                isLast && msg.role == MessageRole.narrative;

                            // Display typewriter buffer for the last narrative message
                            final displayText =
                                isLastNarrative ? _typewriterBuffer : msg.text;

                            return _MessageTile(
                              text: displayText,
                              role: msg.role,
                              narrativeColor: narrativeColor,
                              showCursor: isLastNarrative && _typewriterRunning,
                            );
                          },
                        ),
                      ),
                    ),

                    // ── Status bar ───────────────────────────────────────────
                    if (engine.inventory.isNotEmpty || engine.psychoWeight > 0)
                      _StatusBar(
                        weight: engine.psychoWeight,
                        itemCount: engine.inventory.length,
                        color: narrativeColor.withValues(alpha: 0.4),
                      ),

                    // ── Input field ──────────────────────────────────────────
                    _InputRow(
                      controller: _controller,
                      focusNode: _focusNode,
                      onSubmit: _submit,
                      enabled: engine.phase == ParserPhase.idle,
                      narrativeColor: narrativeColor,
                    ),

                    const SizedBox(height: 8),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _MessageTile extends StatelessWidget {
  final String text;
  final MessageRole role;
  final Color narrativeColor;
  final bool showCursor;

  const _MessageTile({
    required this.text,
    required this.role,
    required this.narrativeColor,
    this.showCursor = false,
  });

  @override
  Widget build(BuildContext context) {
    switch (role) {
      case MessageRole.player:
        return Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 4),
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontFamily: 'monospace',
              fontSize: 14,
              letterSpacing: 0.5,
            ),
          ),
        );

      case MessageRole.narrative:
        return Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 12),
          child: RichText(
            text: TextSpan(
              text: text,
              style: TextStyle(
                color: narrativeColor,
                fontFamily: 'Georgia',
                fontSize: 16,
                height: 1.65,
                letterSpacing: 0.2,
              ),
              children: showCursor
                  ? [
                      TextSpan(
                        text: '▌',
                        style: TextStyle(
                          color: narrativeColor.withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                      )
                    ]
                  : null,
            ),
          ),
        );

      case MessageRole.error:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            text,
            style: TextStyle(
              color: Colors.red.shade300,
              fontFamily: 'monospace',
              fontSize: 13,
              fontStyle: FontStyle.italic,
            ),
          ),
        );
    }
  }
}

class _StatusBar extends StatelessWidget {
  final int weight;
  final int itemCount;
  final Color color;

  const _StatusBar({
    required this.weight,
    required this.itemCount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
      child: Row(
        children: [
          Text(
            'Carrying: $itemCount  ·  Weight: $weight',
            style: TextStyle(
              color: color,
              fontFamily: 'monospace',
              fontSize: 11,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _InputRow extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSubmit;
  final bool enabled;
  final Color narrativeColor;

  const _InputRow({
    required this.controller,
    required this.focusNode,
    required this.onSubmit,
    required this.enabled,
    required this.narrativeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        children: [
          Text(
            '>',
            style: TextStyle(
              color: narrativeColor.withValues(alpha: enabled ? 0.8 : 0.3),
              fontFamily: 'monospace',
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              enabled: enabled,
              autofocus: true,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSubmit(),
              style: TextStyle(
                color: narrativeColor,
                fontFamily: 'monospace',
                fontSize: 15,
              ),
              cursorColor: narrativeColor,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: enabled ? '' : '…',
                hintStyle: TextStyle(
                  color: narrativeColor.withValues(alpha: 0.25),
                  fontFamily: 'monospace',
                ),
              ),
              textCapitalization: TextCapitalization.none,
              autocorrect: false,
              enableSuggestions: false,
            ),
          ),
        ],
      ),
    );
  }
}
