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
import 'dart:collection';
import 'dart:convert';
import 'dart:math' show min;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/game_engine_provider.dart';
import '../parser/parser_state.dart';
import '../settings/app_settings_provider.dart';
import '../state/game_state_provider.dart';
import '../state/psycho_provider.dart';
import 'archive_panels.dart';
import '../audio/audio_service.dart';
import 'background_service.dart';
import 'ritual_style.dart';

// PsychoProfile thresholds that drive the UI colour palette (mirror GDD section 6)
const int _panicAnxietyThreshold = 70; // anxiety > this → reddish text
const int _lowLucidityThreshold = 30; // lucidity < this → grey text
const int _highOblivionThreshold = 60; // oblivionLevel > this → blue-grey text
const double _backgroundImageOpacity = 0.28;
const double _minimumReadableTextScale = 1.08;
const Duration _backgroundFlashHoldDuration = Duration(milliseconds: 180);
const Duration _backgroundFadeDuration = Duration(milliseconds: 900);
const Duration _puzzleCueHoldDuration = Duration(milliseconds: 1300);
const Duration _simulacrumBannerDuration = Duration(milliseconds: 2200);
// Secret command that activates walkthrough mode (QA only, never persisted).
const String _walkthroughUnlockCommand = 'Stalker4598!TarkoS?';

// ── Finale helpers ────────────────────────────────────────────────────────────
enum _FinaleType { acceptance, oblivion, eternalZone, testimony }

bool _isFinaleNode(String nodeId) =>
    nodeId == 'finale_acceptance' ||
    nodeId == 'finale_oblivion' ||
    nodeId == 'finale_eternal_zone' ||
    nodeId == 'finale_testimony';

_FinaleType? _finaleTypeFor(String nodeId) {
  switch (nodeId) {
    case 'finale_acceptance':
      return _FinaleType.acceptance;
    case 'finale_oblivion':
      return _FinaleType.oblivion;
    case 'finale_eternal_zone':
      return _FinaleType.eternalZone;
    case 'finale_testimony':
      return _FinaleType.testimony;
    default:
      return null;
  }
}

// 5×4 color matrix: +18% RGB gain plus a small +18 luminance lift keeps the
// mandated 0.15-opacity artwork readable on dimmer screens without making it loud.
const List<double> _backgroundImageBrightnessMatrix = [
  1.18,
  0,
  0,
  0,
  18,
  0,
  1.18,
  0,
  0,
  18,
  0,
  0,
  1.18,
  0,
  18,
  0,
  0,
  0,
  1,
  0,
];

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen>
    with WidgetsBindingObserver {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  // Typewriter state for the last narrative message
  String _typewriterBuffer = '';
  int _typewriterIndex = 0;
  bool _typewriterRunning = false;
  String? _typewriterTarget;
  Timer? _typewriterTimer;
  Timer? _backgroundFlashTimer;
  Timer? _puzzleCueTimer;
  Timer? _simulacrumBannerTimer;
  bool _backgroundFlashActive = false;
  bool _puzzleCueActive = false;
  String? _simulacrumBannerText;
  bool _lastObservedPuzzleSolved = false;
  String? _lastObservedSimulacrum;
  int _lastObservedPsychoShiftCount = 0;
  int _lastObservedMessageCount = 0;
  String _lastObservedSectorLabel = '';
  // -1 = "not yet observed" so the very first build never fires a threshold haptic.
  int _lastObservedOblivionLevel = -1;
  String? _lastSubmittedCommand;
  int _submittedTurnCount = 0;

  // Assist tray (quick commands + reuse) — hidden by default so the text
  // area gets maximum space; toggled by the lightbulb icon in the input row.
  bool _assistVisible = false;

  // Finale state — white-screen fade triggered by "— FINE —" in acceptance.
  bool _wakeUpFading = false;

  // Walkthrough mode — activated by the secret unlock command.
  // Never persisted; resets to false on every app restart.
  bool _walkthroughUnlocked = false;
  int _walkthroughStep = 0;
  List<Map<String, dynamic>>? _walkthroughSteps;

  // Command history — up/down arrow navigation (classic text-adventure UX).
  final List<String> _commandHistory = [];
  int _historyIndex = -1; // -1 = not browsing history
  String _historyDraft = ''; // text typed before entering history mode
  int _processedScreenResetCount = 0;
  int _queuedScreenResetCount = 0;
  // The engine emits monotonically increasing reset counts, so queue order
  // preserves the order of successful commands when several land in one frame.
  final Queue<int> _pendingScreenResetCounts = Queue<int>();
  bool _screenResetCallbackScheduled = false;
  bool _resumeRecapArmed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _focusNode.onKeyEvent = (_, event) {
      if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
        return KeyEventResult.ignored;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        _navigateHistory(-1);
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        _navigateHistory(1);
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    };
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
    WidgetsBinding.instance.removeObserver(this);
    _typewriterTimer?.cancel();
    _backgroundFlashTimer?.cancel();
    _puzzleCueTimer?.cancel();
    _simulacrumBannerTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _resumeRecapArmed = true;
      return;
    }
    if (state == AppLifecycleState.resumed && _resumeRecapArmed) {
      _resumeRecapArmed = false;
      // ignore: discarded_futures
      ref.read(gameEngineProvider.notifier).appendSessionRecap();
    }
  }

  // ── Palette ─────────────────────────────────────────────────────────────

  /// Text colour for narrative messages — shifts with psychological state.
  Color _narrativeColor(
    PsychoProfile? profile, {
    required String nodeId,
    required bool highContrast,
  }) {
    Color base = Colors.white;
    if (profile != null) {
      if (profile.anxiety > _panicAnxietyThreshold) {
        base = const Color(0xFFFFD8D8);
      } else if (profile.lucidity < _lowLucidityThreshold) {
        base = const Color(0xFFCCCCCC);
      } else if (profile.oblivionLevel > _highOblivionThreshold) {
        base = const Color(0xFFCCDDEE);
      }
    }

    final sector = gameSectorLabel(nodeId);
    final tint = switch (sector) {
      'Threshold' => const Color(0xFFF4EBD8),
      'Garden' => const Color(0xFFE9F4DF),
      'Observatory' => const Color(0xFFE5F0FF),
      'Gallery' => const Color(0xFFF3E8D7),
      'Laboratory' => const Color(0xFFE9F1E1),
      'Memory' => const Color(0xFFF2E6D8),
      'Finale' => const Color(0xFFF6EFE2),
      'Zone' => const Color(0xFFE3F5FF),
      _ => const Color(0xFFF2EEE4),
    };
    final blend = highContrast ? 0.06 : 0.18;
    return Color.lerp(base, tint, blend) ?? base;
  }

  /// Subtle background tint — deepens as oblivion rises.
  Color _backgroundColor(PsychoProfile? profile) {
    const baseColor = Color(0xFF080A0F);
    const deepColor = Color(0xFF101726);
    if (profile == null) return baseColor;
    final t = (profile.oblivionLevel / 100).clamp(0.0, 0.35);
    return Color.lerp(baseColor, deepColor, t)!;
  }

  // ── Typewriter ──────────────────────────────────────────────────────────

  void _startTypewriter(String text) {
    final settings = ref.read(appSettingsProvider).valueOrNull;
    final currentNode =
        ref.read(gameStateProvider).valueOrNull?.currentNode ?? '';
    final onboardingBoost = _shouldBoostOnboardingTypewriter(currentNode);
    if (settings?.instantText ?? false) {
      setState(() {
        _typewriterTarget = text;
        _typewriterBuffer = text;
        _typewriterIndex = text.length;
        _typewriterRunning = false;
      });
      return;
    }
    if (_typewriterTarget == text && _typewriterRunning) return;
    _typewriterTarget = text;
    if (onboardingBoost && text.length > 24) {
      final seedChars = min(22, text.length);
      _typewriterBuffer = text.substring(0, seedChars);
      _typewriterIndex = seedChars;
    } else {
      _typewriterBuffer = '';
      _typewriterIndex = 0;
    }
    _typewriterRunning = true;
    _tickTypewriter();
  }

  void _tickTypewriter() {
    if (!_typewriterRunning || _typewriterTarget == null) return;
    if (_typewriterIndex >= _typewriterTarget!.length) {
      setState(() => _typewriterRunning = false);
      return;
    }
    // Variable speed: faster for spaces/punctuation, slower for letters.
    // Finale nodes use a much slower pace so each word carries weight.
    final ch = _typewriterTarget![_typewriterIndex];
    final settings = ref.read(appSettingsProvider).valueOrNull;
    final currentNode =
        ref.read(gameStateProvider).valueOrNull?.currentNode ?? '';
    final onboardingBoost = _shouldBoostOnboardingTypewriter(currentNode);
    final tunedDelay =
        (((settings?.typewriterMillis ?? 30) * 1.25).round()).clamp(12, 60);
    final baseDelay = _isFinaleNode(currentNode)
        ? 170
        : onboardingBoost
            ? (tunedDelay * 0.62).round().clamp(8, 28)
            : tunedDelay;
    final delay = (ch == ' ' || ch == '\n')
        ? onboardingBoost
            ? (baseDelay ~/ 3).clamp(3, 14)
            : (baseDelay ~/ 2).clamp(4, 20)
        : baseDelay;

    _typewriterTimer?.cancel();
    _typewriterTimer = Timer(Duration(milliseconds: delay), () {
      if (!mounted || _typewriterTarget == null) return;
      setState(() {
        _typewriterBuffer += ch;
        _typewriterIndex++;
      });
      // Rhythmic haptic: every 3rd character only (post-increment index divisible
      // by 3) so it feels like a physical keystroke rhythm, not a buzz.
      // Speed scaling: slow pace (≥28 ms/char) → mediumImpact; faster → lightImpact.
      // Skipped entirely when reduceMotion is on.
      if (_typewriterIndex % 3 == 0 &&
          (settings?.enableHaptics ?? true) &&
          !(settings?.reduceMotion ?? false)) {
        (baseDelay >= 28
            ? HapticFeedback.mediumImpact
            : HapticFeedback.lightImpact)();
      }
      // Typewriter click — fire-and-forget, very low volume (0.08×sfxScale).
      // Uses a single cached AudioPlayer (seek+play), not a new instance per char.
      // ignore: discarded_futures
      AudioService().playTypewriterTick();
      _scrollToBottom();
      _tickTypewriter();
    });
  }

  bool _shouldBoostOnboardingTypewriter(String nodeId) {
    if (_isFinaleNode(nodeId)) return false;
    final engine = ref.read(gameEngineProvider).valueOrNull;
    if (engine == null) return false;
    final playerTurns =
        engine.messages.where((m) => m.role == MessageRole.player).length;
    return playerTurns <= 8;
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

  void _scrollToTop() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });
  }

  bool _hapticsOn() {
    final s = ref.read(appSettingsProvider).valueOrNull;
    return (s?.enableHaptics ?? true) && !(s?.reduceMotion ?? false);
  }

  void _triggerSuccessVisualCue() {
    _backgroundFlashTimer?.cancel();
    // "Confirmed" — heavier than the submit tap so the player feels the command land.
    if (_hapticsOn()) HapticFeedback.heavyImpact();
    final settings = ref.read(appSettingsProvider).valueOrNull;
    if (settings?.reduceMotion ?? false) {
      _scrollToTop();
      return;
    }
    setState(() {
      _backgroundFlashActive = true;
    });
    _scrollToTop();
    _backgroundFlashTimer = Timer(_backgroundFlashHoldDuration, () {
      if (!mounted) return;
      setState(() => _backgroundFlashActive = false);
    });
  }

  /// Double light-tap haptic for parser errors — two short pulses 80 ms apart
  /// feel like a dry "no" without being jarring.
  void _triggerErrorHaptic() {
    if (!_hapticsOn()) return;
    HapticFeedback.lightImpact();
    Timer(const Duration(milliseconds: 80), () {
      if (!mounted) return;
      HapticFeedback.lightImpact();
    });
  }

  /// Double medium-impact haptic 50 ms apart — a distinct "threshold crossed"
  /// signature, heavier than the error double-tap (light/80ms) and different
  /// from the single heavy used for scene changes.
  void _triggerSectorChangeHaptic() {
    if (!_hapticsOn()) return;
    HapticFeedback.mediumImpact();
    Timer(const Duration(milliseconds: 50), () {
      if (!mounted) return;
      HapticFeedback.mediumImpact();
    });
  }

  /// Fires haptic cues when oblivionLevel crosses key thresholds upward.
  ///
  /// Fires only on threshold crossings — not on every profile update —
  /// so the sensation marks narrative milestones rather than routine updates.
  ///
  ///   ≥ 70 → single heavyImpact   ("something is wrong")
  ///   ≥ 90 → double heavyImpact 120 ms apart   ("the Archive is consuming you")
  void _consumeOblivionHaptic(int oblivionLevel) {
    if (_lastObservedOblivionLevel == -1) {
      // First build: just record the baseline, never fire.
      _lastObservedOblivionLevel = oblivionLevel;
      return;
    }
    final prev = _lastObservedOblivionLevel;
    _lastObservedOblivionLevel = oblivionLevel;

    final crossed90 = oblivionLevel >= 90 && prev < 90;
    final crossed70 = oblivionLevel >= 70 && prev < 70;

    if (crossed90) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_hapticsOn()) return;
        HapticFeedback.heavyImpact();
        Timer(const Duration(milliseconds: 120), () {
          if (!mounted) return;
          HapticFeedback.heavyImpact();
        });
      });
    } else if (crossed70) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _hapticsOn()) HapticFeedback.heavyImpact();
      });
    }
  }

  /// Detects sector changes between builds and schedules the haptic cue.
  /// [currentNode] is the node ID already resolved in the build() frame.
  void _consumeSectorChange(String currentNode) {
    final sector = gameSectorLabel(currentNode);
    if (_lastObservedSectorLabel.isNotEmpty &&
        sector != _lastObservedSectorLabel) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _triggerSectorChangeHaptic();
      });
    }
    _lastObservedSectorLabel = sector;
  }

  void _triggerPuzzleSolvedCue() {
    _puzzleCueTimer?.cancel();
    if (_hapticsOn()) HapticFeedback.mediumImpact();
    // ignore: discarded_futures
    AudioService().handleTrigger('sfx:command_accepted');
    setState(() => _puzzleCueActive = true);
    _puzzleCueTimer = Timer(_puzzleCueHoldDuration, () {
      if (!mounted) return;
      setState(() => _puzzleCueActive = false);
    });
  }

  void _showSimulacrumBanner(String itemName) {
    final words = <String>[];
    for (final part in itemName.split(' ')) {
      if (part.isEmpty) continue;
      words.add('${part[0].toUpperCase()}${part.substring(1)}');
    }
    final label = words.join(' ');
    _simulacrumBannerTimer?.cancel();
    if (_hapticsOn()) HapticFeedback.mediumImpact();
    setState(() => _simulacrumBannerText = '✦ $label recovered');
    _simulacrumBannerTimer = Timer(_simulacrumBannerDuration, () {
      if (!mounted) return;
      setState(() => _simulacrumBannerText = null);
    });
  }

  void _triggerPsychoShiftCue({required bool phaseChanged}) {
    if (_hapticsOn()) {
      HapticFeedback.mediumImpact();
      if (phaseChanged) {
        Timer(const Duration(milliseconds: 70), () {
          if (!mounted) return;
          HapticFeedback.mediumImpact();
        });
      }
    }
    // ignore: discarded_futures
    AudioService().handleTrigger('sfx:command_accepted');
  }

  void _consumeFeedbackSignals(GameEngineState engine) {
    if (engine.isPuzzleSolved && !_lastObservedPuzzleSolved) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _triggerPuzzleSolvedCue();
      });
    }
    _lastObservedPuzzleSolved = engine.isPuzzleSolved;

    final latestSimulacrum = engine.latestSimulacrum;
    if (latestSimulacrum != null &&
        _lastObservedSimulacrum != latestSimulacrum) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showSimulacrumBanner(latestSimulacrum);
      });
    }
    _lastObservedSimulacrum = latestSimulacrum;

    if (engine.psychoShiftCount > _lastObservedPsychoShiftCount) {
      final phaseChanged = engine.latestPsychoShiftIsPhase;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _triggerPsychoShiftCue(phaseChanged: phaseChanged);
        }
      });
    }
    _lastObservedPsychoShiftCount = engine.psychoShiftCount;

    // Detect new error messages and play pitched-down rejection SFX.
    final msgCount = engine.messages.length;
    if (msgCount > _lastObservedMessageCount) {
      final lastMsg = engine.messages.lastOrNull;
      if (lastMsg?.role == MessageRole.error) {
        // ignore: discarded_futures
        AudioService().playCommandRejected();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _triggerErrorHaptic();
        });
      }
    }
    _lastObservedMessageCount = msgCount;
  }

  void _scheduleScreenResetCue(int screenResetCount) {
    // Preserve the reset counts so rapid successive successes can still be
    // flashed in order instead of collapsing into a single generic flag.
    // Counts are monotonic and only increase inside the engine.
    if (screenResetCount <= _queuedScreenResetCount) return;
    _pendingScreenResetCounts.addLast(screenResetCount);
    _queuedScreenResetCount = screenResetCount;
    if (_screenResetCallbackScheduled) return;
    _screenResetCallbackScheduled = true;
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _consumeScreenResetCue());
  }

  void _clearScheduledScreenResetCue() {
    _screenResetCallbackScheduled = false;
  }

  void _consumeScreenResetCue() {
    if (!mounted) {
      _pendingScreenResetCounts.clear();
      _clearScheduledScreenResetCue();
      return;
    }
    if (_pendingScreenResetCounts.isEmpty) {
      _clearScheduledScreenResetCue();
      return;
    }
    _processedScreenResetCount = _pendingScreenResetCounts.removeFirst();
    _triggerSuccessVisualCue();
    if (_pendingScreenResetCounts.isEmpty) {
      _clearScheduledScreenResetCue();
      return;
    }
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _consumeScreenResetCue());
  }

  // ── Input ────────────────────────────────────────────────────────────────

  /// Navigate command history. [direction] = -1 (older) or +1 (newer).
  void _navigateHistory(int direction) {
    if (_commandHistory.isEmpty) return;
    if (_historyIndex == -1 && direction == 1) return; // nothing newer

    if (_historyIndex == -1) {
      // Entering history: save whatever the user was typing
      _historyDraft = _controller.text;
      _historyIndex = _commandHistory.length - 1;
    } else if (direction == -1 && _historyIndex > 0) {
      _historyIndex--;
    } else if (direction == 1 && _historyIndex < _commandHistory.length - 1) {
      _historyIndex++;
    } else if (direction == 1 && _historyIndex == _commandHistory.length - 1) {
      // Past the end → restore draft
      _historyIndex = -1;
      _controller
        ..text = _historyDraft
        ..selection = TextSelection.collapsed(offset: _historyDraft.length);
      return;
    }

    final entry = _commandHistory[_historyIndex];
    _controller
      ..text = entry
      ..selection = TextSelection.collapsed(offset: entry.length);
  }

  void _submit() {
    final text = _controller.text.trim();
    if (_typewriterRunning) {
      _skipTypewriter();
      if (text.isEmpty) return;
    }
    if (text.isEmpty) return;
    // Secret walkthrough unlock command — consumed here, never forwarded to engine.
    if (text == _walkthroughUnlockCommand) {
      _controller.clear();
      setState(() => _walkthroughUnlocked = true);
      _focusNode.requestFocus();
      return;
    }
    // Immediate "key press" feedback — fires before the engine processes the command.
    if (_hapticsOn()) HapticFeedback.mediumImpact();
    _controller.clear();
    _lastSubmittedCommand = text;
    _submittedTurnCount += 1;
    // Add to history (skip duplicates of the most recent entry; cap at 30).
    if (_commandHistory.isEmpty || _commandHistory.last != text) {
      _commandHistory.add(text);
      if (_commandHistory.length > 30) _commandHistory.removeAt(0);
    }
    _historyIndex = -1;
    _historyDraft = '';
    ref.read(gameEngineProvider.notifier).processInput(text);
    _focusNode.requestFocus();
    SystemChannels.textInput.invokeMethod('TextInput.show');
  }

  void _queueQuickCommand(String command, {bool submit = true}) {
    if (_typewriterRunning) {
      _skipTypewriter();
    }
    _controller
      ..text = command
      ..selection = TextSelection.collapsed(offset: command.length);
    if (submit) {
      _submit();
    } else {
      _focusNode.requestFocus();
    }
  }

  Future<void> _walkthroughNext() async {
    if (_walkthroughSteps == null) {
      try {
        final raw =
            await rootBundle.loadString('assets/texts/walkthrough.json');
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        _walkthroughSteps =
            (decoded['steps'] as List).cast<Map<String, dynamic>>();
      } catch (e) {
        // Fail silently in production; print in debug for QA diagnostics.
        assert(() {
          // ignore: avoid_print
          print('[Walkthrough] Failed to load walkthrough.json: $e');
          return true;
        }());
        return;
      }
    }
    final steps = _walkthroughSteps!;
    if (_walkthroughStep >= steps.length) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Walkthrough complete')),
        );
      }
      return;
    }
    final command = steps[_walkthroughStep]['command'] as String;
    setState(() => _walkthroughStep++);
    _queueQuickCommand(command);
  }

  Future<void> _startNewGame() async {
    _skipTypewriter();
    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF111111),
        title: const Text('New game'),
        content: const Text(
          'Start over from the beginning? Your current progress will be replaced.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Start over'),
          ),
        ],
      ),
    );

    if (shouldReset != true || !mounted) return;

    FocusScope.of(context).unfocus();
    await ref.read(gameEngineProvider.notifier).startNewGame();
    if (!mounted) return;
    _focusNode.requestFocus();
  }

  Future<void> _handleMenuAction(
    _GameMenuAction action,
    GameEngineState? engine,
  ) async {
    switch (action) {
      case _GameMenuAction.newGame:
        return _startNewGame();
      case _GameMenuAction.archiveStatus:
        if (engine != null) {
          return ArchivePanels.showArchiveStatus(context, engine);
        }
        return;
      case _GameMenuAction.saveLoad:
        return ArchivePanels.showSaveLoad(context);
      case _GameMenuAction.memories:
        return ArchivePanels.showPlayerMemories(context);
      case _GameMenuAction.howToPlay:
        return ArchivePanels.showHowToPlay(context);
      case _GameMenuAction.settings:
        return ArchivePanels.showSettings(context);
      case _GameMenuAction.credits:
        return ArchivePanels.showCredits(context);
      case _GameMenuAction.title:
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        return;
    }
  }

  String? _findLastPlayerCommand(List<GameMessage> messages) {
    for (final message in messages.reversed) {
      if (message.role == MessageRole.player) {
        return message.text.replaceFirst(RegExp(r'^>\s*'), '');
      }
    }
    return _lastSubmittedCommand;
  }

  String _inputHintForNode(String nodeId) {
    if (nodeId == 'intro_void') return 'try: go north';
    if (nodeId == 'la_soglia') return 'try: go north / east / south / west';
    if (nodeId == 'garden_cypress') return 'try: examine leaves';
    if (nodeId == 'garden_fountain') return 'try: examine fountain';
    if (nodeId == 'obs_antechamber') return 'try: examine lenses and mount';
    if (nodeId == 'gallery_hall') return 'try: study the reflections';
    if (nodeId == 'lab_substances') return 'try: examine symbols';
    if (nodeId == 'quinto_ritual_chamber') return 'try: examine cup';
    if (nodeId == 'il_nucleo') return 'try: answer, observe, or unburden';
    return 'type a command';
  }

  List<_QuickCommand> _quickCommandsForNode(
      String nodeId, GameEngineState engine) {
    final commands = <_QuickCommand>[
      const _QuickCommand('Look', 'look'),
      const _QuickCommand('Inventory', 'inventory'),
      const _QuickCommand('Hint', 'hint'),
      const _QuickCommand('Help', 'help'),
    ];

    if (nodeId == 'intro_void') {
      commands.insert(0, const _QuickCommand('Go north', 'go north'));
    } else if (nodeId == 'la_soglia') {
      commands.insertAll(0, const [
        _QuickCommand('North', 'go north'),
        _QuickCommand('East', 'go east'),
        _QuickCommand('South', 'go south'),
        _QuickCommand('West', 'go west'),
      ]);
    } else if (nodeId == 'garden_cypress') {
      commands.insertAll(0, const [
        _QuickCommand('Examine leaves', 'examine leaves'),
        _QuickCommand('Hint', 'hint'),
      ]);
    } else if (nodeId == 'garden_fountain') {
      commands.insertAll(0, const [
        _QuickCommand('Examine fountain', 'examine fountain'),
        _QuickCommand('Hint', 'hint'),
      ]);
    } else if (nodeId == 'garden_grove') {
      commands.insertAll(0, const [
        _QuickCommand('Examine statue', 'examine statue'),
        _QuickCommand('Go east', 'go east'),
        _QuickCommand('Go west', 'go west'),
      ]);
    } else if (nodeId == 'obs_antechamber') {
      commands.insertAll(0, const [
        _QuickCommand('Examine lenses', 'examine lenses'),
        _QuickCommand('Examine mount', 'examine mount'),
        _QuickCommand('Go north', 'go north'),
      ]);
    } else if (nodeId == 'obs_void') {
      commands.insertAll(0, const [
        _QuickCommand('Wait', 'wait'),
        _QuickCommand('Examine panel', 'examine panel'),
      ]);
    } else if (nodeId == 'obs_dome') {
      commands.insertAll(0, const [
        _QuickCommand('Examine telescope', 'examine telescope'),
        _QuickCommand('Examine mirror', 'examine mirror'),
        _QuickCommand('Hint', 'hint'),
      ]);
    } else if (nodeId == 'gallery_hall') {
      commands.insertAll(0, const [
        _QuickCommand('Examine mirrors', 'examine mirrors'),
        _QuickCommand('Hint', 'hint'),
      ]);
    } else if (nodeId == 'gallery_corridor') {
      commands.insertAll(0, const [
        _QuickCommand('Examine mosaic', 'examine mosaic'),
        _QuickCommand('Hint', 'hint'),
      ]);
    } else if (nodeId == 'gallery_central') {
      commands.insertAll(0, const [
        _QuickCommand('Examine mirror', 'examine mirror'),
        _QuickCommand('Hint', 'hint'),
      ]);
    } else if (nodeId == 'lab_substances') {
      commands.insertAll(0, const [
        _QuickCommand('Examine symbols', 'examine symbols'),
        _QuickCommand('Hint', 'hint'),
      ]);
    } else if (nodeId == 'lab_furnace') {
      commands.insertAll(0, const [
        _QuickCommand('Examine furnace', 'examine furnace'),
        _QuickCommand('Wait', 'wait'),
      ]);
    } else if (nodeId == 'quinto_maturity') {
      commands.insertAll(0, const [
        _QuickCommand('Say …', 'say ', submit: false),
        _QuickCommand('Write …', 'write ', submit: false),
      ]);
    } else if (nodeId == 'quinto_ritual_chamber') {
      commands.insertAll(0, const [
        _QuickCommand('Examine cup', 'examine cup'),
        _QuickCommand('Inventory', 'inventory'),
        _QuickCommand('Hint', 'hint'),
      ]);
    } else if (nodeId == 'il_nucleo' &&
        engine.inventory.any(
          (item) => !simulacraItemNames.contains(item),
        )) {
      commands.insertAll(0, const [
        _QuickCommand('Examine antagonist', 'examine antagonist'),
        _QuickCommand('Hint', 'hint'),
      ]);
    }

    return commands.take(6).toList(growable: false);
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final engineAsync = ref.watch(gameEngineProvider);
    final psychoAsync = ref.watch(psychoProfileProvider);
    final gameStateAsync = ref.watch(gameStateProvider);
    final settingsAsync = ref.watch(appSettingsProvider);
    final profile = psychoAsync.valueOrNull;
    final settings = settingsAsync.valueOrNull;
    final textScale =
        (settings?.textScale ?? 1.0).clamp(_minimumReadableTextScale, 1.8);
    final highContrast = settings?.highContrast ?? false;
    final currentNode = gameStateAsync.valueOrNull?.currentNode ?? 'intro_void';

    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    final bgColor = _backgroundColor(profile);
    final narrativeColor = highContrast
        ? const Color(0xFFF6F2E8)
        : _narrativeColor(
            profile,
            nodeId: currentNode,
            highContrast: highContrast,
          );
    final visualProfile = visualProfileForNode(currentNode);

    // Resolve background image from current node
    final backgroundPath = BackgroundService.getBackgroundForNodeOrDefault(
      currentNode,
    );

    // Finale state
    final finaleType = _finaleTypeFor(currentNode);
    final isFinale = finaleType != null;

    // Oblivion threshold haptic — fires once when crossing 70 and again at 90.
    _consumeOblivionHaptic(profile?.oblivionLevel ?? 0);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Stack(
          children: [
            _BackgroundLayer(
              backgroundPath: backgroundPath,
              flashActive: _backgroundFlashActive,
              opacity: isFinale ? 0.52 : null,
            ),
            IgnorePointer(
              child: _SectorAtmosphereLayer(
                profile: visualProfile,
                reduceMotion: settings?.reduceMotion ?? false,
              ),
            ),
            // Vignette: radial gradient that darkens toward the edges.
            // Intensity scales with oblivionLevel (0→100) so the world
            // grows cinematically darker as the player sinks into oblivion.
            _VignetteLayer(oblivionLevel: profile?.oblivionLevel ?? 0),
            // Finale atmospheric backdrop — tint/darkening per ending type.
            if (isFinale)
              _FinaleBackdrop(
                type: finaleType,
                reduceMotion: settings?.reduceMotion ?? false,
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
                  style: const TextStyle(
                      color: Colors.red, fontFamily: 'monospace'),
                  textAlign: TextAlign.center,
                ),
              ),
              data: (engine) {
                _consumeFeedbackSignals(engine);
                _consumeSectorChange(currentNode);
                // Detect the WAKE UP epilogue text to trigger white-screen fade.
                final lastMsg = engine.messages.lastOrNull;
                if (lastMsg != null &&
                    lastMsg.role == MessageRole.narrative &&
                    lastMsg.text.contains('— FINE —') &&
                    !_wakeUpFading) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() => _wakeUpFading = true);
                  });
                }
                if (engine.screenResetCount != _processedScreenResetCount) {
                  _scheduleScreenResetCue(engine.screenResetCount);
                }
                final quickCommands = (settings?.commandAssist ?? true)
                    ? _quickCommandsForNode(currentNode, engine)
                    : const <_QuickCommand>[];
                final showSessionAssist = (settings?.commandAssist ?? true) &&
                    (_typewriterRunning || _submittedTurnCount <= 14);
                final lastCommand = _findLastPlayerCommand(engine.messages);

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
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: _TopHud(
                        sectorLabel: gameSectorLabel(currentNode),
                        nodeTitle: gameNodeTitle(currentNode),
                        narrativeColor: narrativeColor,
                        visualProfile: visualProfile,
                        textScale: textScale,
                        onMenuSelected: (action) =>
                            _handleMenuAction(action, engine),
                        canReturnToTitle: Navigator.of(context).canPop(),
                      ),
                    ),
                    if (!keyboardOpen && !isFinale)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: _SessionCard(
                          sectorLabel: gameSectorLabel(currentNode),
                          nodeTitle: gameNodeTitle(currentNode),
                          itemCount: engine.inventory.length,
                          weight: engine.psychoWeight,
                          narrativeColor: narrativeColor,
                          visualProfile: visualProfile,
                          textScale: textScale,
                          showAssist: showSessionAssist,
                          typewriterRunning: _typewriterRunning,
                        ),
                      ),
                    // ── Message history ──────────────────────────────────────
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.33),
                            border: Border.all(
                              color: visualProfile.frame.withValues(alpha: 0.8),
                              width: 1.1,
                            ),
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    visualProfile.glow.withValues(alpha: 0.12),
                                blurRadius: 30,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: GestureDetector(
                              onTap: _skipTypewriter,
                              child: ListView.builder(
                                controller: _scrollController,
                                padding:
                                    const EdgeInsets.fromLTRB(22, 28, 22, 12),
                                itemCount: engine.messages.length,
                                itemBuilder: (context, index) {
                                  final msg = engine.messages[index];
                                  final isLast =
                                      index == engine.messages.length - 1;
                                  final isLastNarrative = isLast &&
                                      msg.role == MessageRole.narrative;

                                  // Display typewriter buffer for the last narrative message
                                  final displayText = isLastNarrative
                                      ? _typewriterBuffer
                                      : msg.text;

                                  return _MessageTile(
                                    text: displayText,
                                    role: msg.role,
                                    narrativeColor: narrativeColor,
                                    visualProfile: visualProfile,
                                    showCursor:
                                        isLastNarrative && _typewriterRunning,
                                    textScale: textScale,
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // ── Assist tray (quick commands) — visible on demand ─────
                    if (_assistVisible)
                      AnimatedSize(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (quickCommands.isNotEmpty)
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(12, 6, 12, 0),
                                child: _QuickCommandBar(
                                  commands: quickCommands,
                                  onCommand: _queueQuickCommand,
                                  narrativeColor: narrativeColor,
                                  visualProfile: visualProfile,
                                ),
                              ),
                            if (lastCommand != null)
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(12, 4, 12, 0),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: ActionChip(
                                    label: Text(
                                      '↑ $lastCommand',
                                      style: RitualTypography.command(
                                        12.4,
                                        color: narrativeColor.withValues(
                                            alpha: 0.9),
                                      ),
                                    ),
                                    onPressed: () => _queueQuickCommand(
                                        lastCommand,
                                        submit: false),
                                    backgroundColor:
                                        Colors.white.withValues(alpha: 0.03),
                                    side: BorderSide(
                                      color: visualProfile.frame
                                          .withValues(alpha: 0.55),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                    // ── Status bar ───────────────────────────────────────────
                    _StatusBar(
                      weight: engine.psychoWeight,
                      itemCount: engine.inventory.length,
                      profile: profile,
                      color: narrativeColor.withValues(alpha: 0.72),
                      visualProfile: visualProfile,
                      textScale: textScale,
                      lastCommand: _lastSubmittedCommand,
                    ),

                    // ── Input field ──────────────────────────────────────────
                    _InputRow(
                      controller: _controller,
                      focusNode: _focusNode,
                      onSubmit: _submit,
                      enabled: engine.phase == ParserPhase.idle,
                      narrativeColor: narrativeColor,
                      visualProfile: visualProfile,
                      textScale: textScale,
                      hintText: _inputHintForNode(currentNode),
                      onRecallLast: lastCommand == null
                          ? null
                          : () =>
                              _queueQuickCommand(lastCommand, submit: false),
                      onWalkthroughNext:
                          _walkthroughUnlocked ? _walkthroughNext : null,
                      assistVisible: _assistVisible,
                      onToggleAssist: (quickCommands.isNotEmpty ||
                              lastCommand != null)
                          ? () =>
                              setState(() => _assistVisible = !_assistVisible)
                          : null,
                    ),

                    const SizedBox(height: 8),
                  ],
                );
              },
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: _PuzzleSolvedOverlay(
                  active: _puzzleCueActive,
                  visualProfile: visualProfile,
                  reduceMotion: settings?.reduceMotion ?? false,
                ),
              ),
            ),
            Positioned(
              top: 18,
              left: 20,
              right: 20,
              child: IgnorePointer(
                child: _SimulacrumBanner(
                  text: _simulacrumBannerText,
                  visualProfile: visualProfile,
                  reduceMotion: settings?.reduceMotion ?? false,
                ),
              ),
            ),
            // White-screen fade that plays after "WAKE UP" in finale_acceptance.
            _WakeUpFade(
              active: _wakeUpFading,
              reduceMotion: settings?.reduceMotion ?? false,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _BackgroundLayer extends StatelessWidget {
  final String backgroundPath;
  final bool flashActive;

  /// Override opacity — defaults to [_backgroundImageOpacity] (0.15).
  final double? opacity;

  const _BackgroundLayer({
    required this.backgroundPath,
    required this.flashActive,
    this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      backgroundPath,
      fit: BoxFit.cover,
      gaplessPlayback: true,
    );
    final child = flashActive
        ? image
        : ColorFiltered(
            colorFilter: const ColorFilter.matrix(
              _backgroundImageBrightnessMatrix,
            ),
            child: image,
          );

    return Positioned.fill(
      child: AnimatedOpacity(
        opacity: flashActive ? 1.0 : (opacity ?? _backgroundImageOpacity),
        duration: flashActive ? Duration.zero : _backgroundFadeDuration,
        curve: Curves.easeOut,
        child: child,
      ),
    );
  }
}

class _VignetteLayer extends StatelessWidget {
  final int oblivionLevel; // 0–100

  const _VignetteLayer({required this.oblivionLevel});

  @override
  Widget build(BuildContext context) {
    // Base alpha 0.55, rises to 0.82 at full oblivion.
    final alpha = 0.55 + (oblivionLevel / 100) * 0.27;
    return Positioned.fill(
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.6,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: alpha),
              ],
              stops: const [0.35, 1.0],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectorAtmosphereLayer extends StatefulWidget {
  final SectorVisualProfile profile;
  final bool reduceMotion;

  const _SectorAtmosphereLayer({
    required this.profile,
    required this.reduceMotion,
  });

  @override
  State<_SectorAtmosphereLayer> createState() => _SectorAtmosphereLayerState();
}

class _SectorAtmosphereLayerState extends State<_SectorAtmosphereLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    if (!widget.reduceMotion) {
      _ctrl.repeat(reverse: true);
    } else {
      _ctrl.value = 0.5;
    }
  }

  @override
  void didUpdateWidget(covariant _SectorAtmosphereLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reduceMotion != oldWidget.reduceMotion) {
      if (widget.reduceMotion) {
        _ctrl.stop();
        _ctrl.value = 0.5;
      } else {
        _ctrl.repeat(reverse: true);
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final drift = widget.reduceMotion ? 0.0 : (_ctrl.value - 0.5) * 0.08;
        return Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: widget.profile.veilGradient,
                ),
              ),
            ),
            Transform.translate(
              offset: Offset(0, drift * 20),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, -0.45 + drift),
                    radius: 1.15,
                    colors: [
                      widget.profile.glow.withValues(alpha: 0.18),
                      widget.profile.glow.withValues(alpha: 0.05),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.26, 0.7],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

enum _GameMenuAction {
  newGame,
  saveLoad,
  archiveStatus,
  memories,
  howToPlay,
  settings,
  credits,
  title,
}

class _QuickCommand {
  final String label;
  final String command;
  final bool submit;

  const _QuickCommand(this.label, this.command, {this.submit = true});
}

class _TopHud extends StatelessWidget {
  final String sectorLabel;
  final String nodeTitle;
  final Color narrativeColor;
  final SectorVisualProfile visualProfile;
  final double textScale;
  final ValueChanged<_GameMenuAction> onMenuSelected;
  final bool canReturnToTitle;

  const _TopHud({
    required this.sectorLabel,
    required this.nodeTitle,
    required this.narrativeColor,
    required this.visualProfile,
    required this.textScale,
    required this.onMenuSelected,
    required this.canReturnToTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                sectorLabel.toUpperCase(),
                style: RitualTypography.command(
                  11 * textScale,
                  color: visualProfile.accent.withValues(alpha: 0.92),
                ).copyWith(letterSpacing: 1.5),
              ),
              const SizedBox(height: 4),
              Text(
                nodeTitle,
                style: RitualTypography.display(
                  24 * textScale,
                  color: narrativeColor,
                ),
              ),
            ],
          ),
        ),
        PopupMenuButton<_GameMenuAction>(
          tooltip: 'Game menu',
          color: const Color(0xFF111216),
          onSelected: onMenuSelected,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: _GameMenuAction.newGame,
              child: Text('New game'),
            ),
            const PopupMenuItem(
              value: _GameMenuAction.saveLoad,
              child: Text('Save / Load'),
            ),
            const PopupMenuItem(
              value: _GameMenuAction.archiveStatus,
              child: Text('Archive status'),
            ),
            const PopupMenuItem(
              value: _GameMenuAction.memories,
              child: Text('Your memories'),
            ),
            const PopupMenuItem(
              value: _GameMenuAction.howToPlay,
              child: Text('How to play'),
            ),
            const PopupMenuItem(
              value: _GameMenuAction.settings,
              child: Text('Settings'),
            ),
            const PopupMenuItem(
              value: _GameMenuAction.credits,
              child: Text('Credits'),
            ),
            if (canReturnToTitle)
              const PopupMenuItem(
                value: _GameMenuAction.title,
                child: Text('Return to title'),
              ),
          ],
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.28),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: visualProfile.frame.withValues(alpha: 0.88),
              ),
            ),
            child: Icon(
              Icons.more_horiz,
              color: visualProfile.accent.withValues(alpha: 0.95),
            ),
          ),
        ),
      ],
    );
  }
}

class _SessionCard extends StatelessWidget {
  final String sectorLabel;
  final String nodeTitle;
  final int itemCount;
  final int weight;
  final Color narrativeColor;
  final SectorVisualProfile visualProfile;
  final double textScale;
  final bool showAssist;
  final bool typewriterRunning;

  const _SessionCard({
    required this.sectorLabel,
    required this.nodeTitle,
    required this.itemCount,
    required this.weight,
    required this.narrativeColor,
    required this.visualProfile,
    required this.textScale,
    required this.showAssist,
    required this.typewriterRunning,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.31),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: visualProfile.frame.withValues(alpha: 0.82)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$sectorLabel · $nodeTitle',
            style: RitualTypography.command(
              11.5 * textScale,
              color: visualProfile.accent.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$itemCount carried  ·  weight $weight  ·  autosave active',
            style: RitualTypography.ritualSans(
              13.2 * textScale,
              color: narrativeColor.withValues(alpha: 0.84),
            ),
          ),
          if (showAssist) ...[
            const SizedBox(height: 8),
            Text(
              typewriterRunning
                  ? 'Tap the narrative to reveal the full line instantly.'
                  : 'Short commands work best. Some mistakes still change the atmosphere; others pass without opening anything yet.',
              style: TextStyle(
                color: narrativeColor.withValues(alpha: 0.68),
                fontSize: 12.2 * textScale,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuickCommandBar extends StatelessWidget {
  final List<_QuickCommand> commands;
  final void Function(String command, {bool submit}) onCommand;
  final Color narrativeColor;
  final SectorVisualProfile visualProfile;

  const _QuickCommandBar({
    required this.commands,
    required this.onCommand,
    required this.narrativeColor,
    required this.visualProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final command in commands)
          ActionChip(
            label: Text(
              command.label,
              style: RitualTypography.command(
                12.2,
                color: narrativeColor.withValues(alpha: 0.9),
              ),
            ),
            onPressed: () => onCommand(command.command, submit: command.submit),
            backgroundColor: Colors.black.withValues(alpha: 0.2),
            side:
                BorderSide(color: visualProfile.frame.withValues(alpha: 0.76)),
          ),
      ],
    );
  }
}

class _MessageTile extends StatelessWidget {
  final String text;
  final MessageRole role;
  final Color narrativeColor;
  final SectorVisualProfile visualProfile;
  final bool showCursor;
  final double textScale;

  const _MessageTile({
    required this.text,
    required this.role,
    required this.narrativeColor,
    required this.visualProfile,
    this.showCursor = false,
    required this.textScale,
  });

  @override
  Widget build(BuildContext context) {
    switch (role) {
      case MessageRole.player:
        // Split `> command` so the prompt glyph stays muted and the
        // command itself is rendered in the archive gold.
        final promptMatch = RegExp(r'^(>\s*)(.*)$').firstMatch(text);
        final promptGlyph = promptMatch?.group(1) ?? '';
        final commandText = promptMatch?.group(2) ?? text;
        return Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 4),
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: promptGlyph,
                  style: RitualTypography.command(
                    14 * textScale,
                    color: Colors.white.withValues(alpha: 0.42),
                  ),
                ),
                TextSpan(
                  text: commandText,
                  style: RitualTypography.command(
                    14 * textScale,
                    color: visualProfile.accent,
                  ),
                ),
              ],
            ),
          ),
        );

      case MessageRole.narrative:
        return Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 12),
          child: RichText(
            text: TextSpan(
              text: text,
              style: RitualTypography.narrative(
                17 * textScale,
                color: narrativeColor,
              ),
              children: showCursor
                  ? [
                      TextSpan(
                        text: '▌',
                        style: TextStyle(
                          color: narrativeColor.withValues(alpha: 0.7),
                          fontSize: 14 * textScale,
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
              fontFamily: RitualTypography.command(12).fontFamily,
              fontSize: 13 * textScale,
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
  final PsychoProfile? profile;
  final Color color;
  final SectorVisualProfile visualProfile;
  final double textScale;
  final String? lastCommand;

  const _StatusBar({
    required this.weight,
    required this.itemCount,
    required this.profile,
    required this.color,
    required this.visualProfile,
    required this.textScale,
    this.lastCommand,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
      child: Tooltip(
        message:
            'Lucidity · Anxiety · Oblivion — these shape the Archive’s response.',
        preferBelow: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    lastCommand == null
                        ? 'Carrying: $itemCount  ·  Weight: $weight'
                        : 'Carrying: $itemCount  ·  Weight: $weight  ·  Last: $lastCommand',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontFamily: RitualTypography.command(11).fontFamily,
                      fontSize: 11.3 * textScale,
                      letterSpacing: 0.58,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _PsycheMiniBar(
              label: 'Lucidity',
              value: profile?.lucidity ?? 50,
              color: const Color(0xFFDCC58A),
              visualProfile: visualProfile,
            ),
            const SizedBox(height: 4),
            _PsycheMiniBar(
              label: 'Anxiety',
              value: profile?.anxiety ?? 10,
              color: const Color(0xFFC97C7C),
              visualProfile: visualProfile,
            ),
            const SizedBox(height: 4),
            _PsycheMiniBar(
              label: 'Oblivion',
              value: profile?.oblivionLevel ?? 0,
              color: const Color(0xFF879EC4),
              visualProfile: visualProfile,
            ),
          ],
        ),
      ),
    );
  }
}

class _PsycheMiniBar extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final SectorVisualProfile visualProfile;

  const _PsycheMiniBar({
    required this.label,
    required this.value,
    required this.color,
    required this.visualProfile,
  });

  @override
  Widget build(BuildContext context) {
    final clampedValue = value.clamp(0, 100).toDouble();
    return Row(
      children: [
        SizedBox(
          width: 62,
          child: Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.82),
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.55,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: clampedValue / 100,
              minHeight: 6,
              backgroundColor: visualProfile.frame.withValues(alpha: 0.18),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
      ],
    );
  }
}

class _PuzzleSolvedOverlay extends StatelessWidget {
  final bool active;
  final SectorVisualProfile visualProfile;
  final bool reduceMotion;

  const _PuzzleSolvedOverlay({
    required this.active,
    required this.visualProfile,
    required this.reduceMotion,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: active ? 1 : 0,
      duration:
          reduceMotion ? Duration.zero : const Duration(milliseconds: 220),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.44),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: visualProfile.accent, width: 1.2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '✦',
                style: TextStyle(
                  color: visualProfile.accent,
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Puzzle resolved',
                style: TextStyle(
                  color: Color(0xFFF3E8CF),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SimulacrumBanner extends StatelessWidget {
  final String? text;
  final SectorVisualProfile visualProfile;
  final bool reduceMotion;

  const _SimulacrumBanner({
    required this.text,
    required this.visualProfile,
    required this.reduceMotion,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration:
          reduceMotion ? Duration.zero : const Duration(milliseconds: 260),
      offset: text == null ? const Offset(0, -1.1) : Offset.zero,
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: text == null ? 0 : 1,
        duration:
            reduceMotion ? Duration.zero : const Duration(milliseconds: 220),
        child: Align(
          alignment: Alignment.topCenter,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF17120A).withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: visualProfile.accent),
              boxShadow: [
                BoxShadow(
                  color: visualProfile.glow.withValues(alpha: 0.28),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Text(
              text ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFFF1E5C9),
                fontWeight: FontWeight.w600,
                fontFamily: RitualTypography.ritualSans(12).fontFamily,
                letterSpacing: 0.45,
              ),
            ),
          ),
        ),
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
  final SectorVisualProfile visualProfile;
  final double textScale;
  final String hintText;
  final VoidCallback? onRecallLast;
  final VoidCallback? onWalkthroughNext;
  // Assist tray toggle — null when there is nothing to show.
  final VoidCallback? onToggleAssist;
  final bool assistVisible;

  const _InputRow({
    required this.controller,
    required this.focusNode,
    required this.onSubmit,
    required this.enabled,
    required this.narrativeColor,
    required this.visualProfile,
    required this.textScale,
    required this.hintText,
    this.onRecallLast,
    this.onWalkthroughNext,
    this.onToggleAssist,
    this.assistVisible = false,
  });

  @override
  Widget build(BuildContext context) {
    // ListenableBuilder lets the border glow react to focus without a
    // StatefulWidget — FocusNode already extends ChangeNotifier.
    return ListenableBuilder(
      listenable: focusNode,
      builder: (context, _) {
        final hasFocus = focusNode.hasFocus && enabled;
        final borderColor = hasFocus
            ? visualProfile.accent.withValues(alpha: 0.82)
            : visualProfile.frame.withValues(alpha: 0.62);

        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.48),
                  border: Border.all(color: borderColor),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: hasFocus
                          ? visualProfile.glow.withValues(alpha: 0.24)
                          : Colors.black.withValues(alpha: 0.06),
                      blurRadius: 28,
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                child: Row(
                  children: [
                    if (onToggleAssist != null)
                      IconButton(
                        tooltip: assistVisible
                            ? 'Hide suggestions'
                            : 'Show suggestions',
                        onPressed: onToggleAssist,
                        icon: Icon(
                          assistVisible
                              ? Icons.lightbulb
                              : Icons.lightbulb_outline,
                          size: 20,
                          color: assistVisible
                              ? visualProfile.accent
                              : narrativeColor.withValues(alpha: 0.40),
                        ),
                      ),
                    if (onRecallLast != null)
                      IconButton(
                        tooltip: 'Reuse last command',
                        onPressed: onRecallLast,
                        icon: Icon(
                          Icons.history,
                          color: narrativeColor.withValues(
                              alpha: enabled ? 0.65 : 0.25),
                        ),
                      ),
                    if (onWalkthroughNext != null)
                      IconButton(
                        tooltip: 'Next walkthrough step',
                        onPressed: onWalkthroughNext,
                        icon: Icon(
                          Icons.arrow_forward,
                          color: narrativeColor.withValues(
                              alpha: enabled ? 0.65 : 0.25),
                        ),
                      ),
                    Text(
                      '>',
                      style: TextStyle(
                        color: narrativeColor.withValues(
                            alpha: enabled ? 0.8 : 0.3),
                        fontFamily: RitualTypography.command(16).fontFamily,
                        fontSize: 16 * textScale,
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
                          fontFamily: RitualTypography.command(15).fontFamily,
                          fontSize: 15.8 * textScale,
                        ),
                        cursorColor: narrativeColor,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: enabled ? hintText : '…',
                          hintStyle: TextStyle(
                            color: narrativeColor.withValues(alpha: 0.25),
                            fontFamily: RitualTypography.command(14).fontFamily,
                            fontSize: 14 * textScale,
                          ),
                          suffixIcon: IconButton(
                            tooltip: 'Send',
                            onPressed: enabled ? onSubmit : null,
                            icon: Icon(
                              Icons.send_rounded,
                              size: 20,
                              color: enabled
                                  ? visualProfile.accent
                                  : Colors.white.withValues(alpha: 0.15),
                            ),
                          ),
                        ),
                        textCapitalization: TextCapitalization.none,
                        autocorrect: false,
                        enableSuggestions: false,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Finale widgets ────────────────────────────────────────────────────────────

/// Atmospheric backdrop overlay shown when the player is in a finale node.
/// - Acceptance  : warm, faint golden wash — the Archive grows luminous.
/// - Oblivion    : progressive black overlay that darkens over 8 seconds.
/// - Eternal Zone: cold blue-grey tint — the Zone has claimed you.
class _FinaleBackdrop extends StatefulWidget {
  final _FinaleType type;
  final bool reduceMotion;

  const _FinaleBackdrop({required this.type, this.reduceMotion = false});

  @override
  State<_FinaleBackdrop> createState() => _FinaleBackdropState();
}

class _FinaleBackdropState extends State<_FinaleBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );
    if (widget.type == _FinaleType.oblivion) {
      if (widget.reduceMotion) {
        _ctrl.value = 1.0;
      } else {
        _ctrl.forward();
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: switch (widget.type) {
          _FinaleType.acceptance => Container(
              color: const Color(0xFFD4A017).withValues(alpha: 0.07),
            ),
          _FinaleType.oblivion => AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) => Container(
                color: Colors.black.withValues(alpha: _ctrl.value * 0.68),
              ),
            ),
          _FinaleType.eternalZone => Container(
              color: const Color(0xFF1A3A5C).withValues(alpha: 0.14),
            ),
          _FinaleType.testimony => Container(
              color: const Color(0xFF8B6A3F).withValues(alpha: 0.11),
            ),
        },
      ),
    );
  }
}

/// White-screen fade triggered by the "WAKE UP" epilogue in finale_acceptance.
/// Fades from transparent to fully white over 4 seconds.
class _WakeUpFade extends StatelessWidget {
  final bool active;
  final bool reduceMotion;

  const _WakeUpFade({required this.active, this.reduceMotion = false});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedOpacity(
          opacity: active ? 1.0 : 0.0,
          duration: reduceMotion ? Duration.zero : const Duration(seconds: 4),
          curve: Curves.easeInOut,
          child: Container(color: Colors.white),
        ),
      ),
    );
  }
}
