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

// PsychoProfile thresholds that drive the UI colour palette (mirror GDD section 6)
const int _panicAnxietyThreshold = 70; // anxiety > this → reddish text
const int _lowLucidityThreshold = 30; // lucidity < this → grey text
const int _highOblivionThreshold = 60; // oblivionLevel > this → blue-grey text
const double _backgroundImageOpacity = 0.15;
const Duration _backgroundFlashHoldDuration = Duration(milliseconds: 180);
const Duration _backgroundFadeDuration = Duration(milliseconds: 900);
const Duration _puzzleCueHoldDuration = Duration(milliseconds: 1300);
const Duration _simulacrumBannerDuration = Duration(milliseconds: 2200);
// Secret command that activates walkthrough mode (QA only, never persisted).
const String _walkthroughUnlockCommand = 'Stalker4598!TarkoS?';

// ── Finale helpers ────────────────────────────────────────────────────────────
enum _FinaleType { acceptance, oblivion, eternalZone }

bool _isFinaleNode(String nodeId) =>
    nodeId == 'finale_acceptance' ||
    nodeId == 'finale_oblivion' ||
    nodeId == 'finale_eternal_zone';

_FinaleType? _finaleTypeFor(String nodeId) {
  switch (nodeId) {
    case 'finale_acceptance':
      return _FinaleType.acceptance;
    case 'finale_oblivion':
      return _FinaleType.oblivion;
    case 'finale_eternal_zone':
      return _FinaleType.eternalZone;
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
  int _lastObservedMessageCount = 0;
  String _lastObservedSectorLabel = '';
  // -1 = "not yet observed" so the very first build never fires a threshold haptic.
  int _lastObservedOblivionLevel = -1;
  String? _lastSubmittedCommand;

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
  Color _narrativeColor(PsychoProfile? profile) {
    if (profile == null) return Colors.white;
    if (profile.anxiety > _panicAnxietyThreshold)
      return const Color(0xFFFFD8D8);
    if (profile.lucidity < _lowLucidityThreshold)
      return const Color(0xFFCCCCCC);
    if (profile.oblivionLevel > _highOblivionThreshold)
      return const Color(0xFFCCDDEE);
    return Colors.white;
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
    // Variable speed: faster for spaces/punctuation, slower for letters.
    // Finale nodes use a much slower pace so each word carries weight.
    final ch = _typewriterTarget![_typewriterIndex];
    final settings = ref.read(appSettingsProvider).valueOrNull;
    final currentNode =
        ref.read(gameStateProvider).valueOrNull?.currentNode ?? '';
    final baseDelay =
        _isFinaleNode(currentNode) ? 150 : (settings?.typewriterMillis ?? 22);
    final delay =
        (ch == ' ' || ch == '\n') ? (baseDelay ~/ 2).clamp(4, 20) : baseDelay;

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
    if (nodeId == 'garden_fountain') return 'try: wait';
    if (nodeId == 'obs_antechamber') return 'try: combine moon mercury sun';
    if (nodeId == 'gallery_hall') return 'try: walk backward';
    if (nodeId == 'lab_substances') return 'try: decipher symbols';
    if (nodeId == 'quinto_ritual_chamber') return 'try: hint';
    if (nodeId == 'il_nucleo') return 'try: answer, drop, or deposit';
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
        _QuickCommand('Arrange leaves', 'arrange leaves'),
      ]);
    } else if (nodeId == 'garden_fountain') {
      commands.insertAll(0, const [
        _QuickCommand('Wait', 'wait'),
        _QuickCommand('Hint full', 'hint full'),
      ]);
    } else if (nodeId == 'garden_grove') {
      commands.insertAll(0, const [
        _QuickCommand('Deposit everything', 'deposit everything'),
        _QuickCommand('Go east', 'go east'),
        _QuickCommand('Go west', 'go west'),
      ]);
    } else if (nodeId == 'obs_antechamber') {
      commands.insertAll(0, const [
        _QuickCommand('Combine lenses', 'combine moon mercury sun'),
        _QuickCommand('Go north', 'go north'),
      ]);
    } else if (nodeId == 'obs_void') {
      commands.insertAll(0, const [
        _QuickCommand('Wait', 'wait'),
        _QuickCommand('Measure', 'measure fluctuation'),
      ]);
    } else if (nodeId == 'obs_dome') {
      commands.insertAll(0, const [
        _QuickCommand('Invert mirror', 'invert mirror'),
        _QuickCommand('Confirm', 'confirm'),
        _QuickCommand('Observe', 'observe'),
      ]);
    } else if (nodeId == 'gallery_hall') {
      commands.insertAll(0, const [
        _QuickCommand('Walk backward', 'walk backward'),
        _QuickCommand('Observe', 'observe'),
      ]);
    } else if (nodeId == 'gallery_corridor') {
      commands.insertAll(0, const [
        _QuickCommand('Press tile', 'press anomalous tile'),
        _QuickCommand('Hint full', 'hint full'),
      ]);
    } else if (nodeId == 'gallery_central') {
      commands.insertAll(0, const [
        _QuickCommand('Break mirror', 'break mirror'),
        _QuickCommand('Hint full', 'hint full'),
      ]);
    } else if (nodeId == 'lab_substances') {
      commands.insertAll(0, const [
        _QuickCommand('Decipher', 'decipher symbols'),
        _QuickCommand('Collect mercury', 'collect mercury'),
        _QuickCommand('Collect sulphur', 'collect sulphur'),
        _QuickCommand('Collect salt', 'collect salt'),
      ]);
    } else if (nodeId == 'lab_furnace') {
      commands.insertAll(0, const [
        _QuickCommand('Calcinate', 'calcinate'),
        _QuickCommand('Wait', 'wait'),
      ]);
    } else if (nodeId == 'quinto_maturity') {
      commands.insertAll(0, const [
        _QuickCommand('Say …', 'say ', submit: false),
        _QuickCommand('Write …', 'write ', submit: false),
      ]);
    } else if (nodeId == 'quinto_ritual_chamber') {
      commands.insertAll(0, const [
        _QuickCommand('Place simulacrum', 'place ataraxia in cup'),
        _QuickCommand('Stir', 'stir'),
        _QuickCommand('Drink', 'drink'),
      ]);
    } else if (nodeId == 'il_nucleo' &&
        engine.inventory.any(
          (item) => !simulacraItemNames.contains(item),
        )) {
      commands.insertAll(0, const [
        _QuickCommand('Deposit', 'deposit everything'),
        _QuickCommand('Drop item', 'drop notebook'),
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
    final textScale = settings?.textScale ?? 1.0;
    final highContrast = settings?.highContrast ?? false;
    final currentNode = gameStateAsync.valueOrNull?.currentNode ?? 'intro_void';

    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    final bgColor = _backgroundColor(profile);
    final narrativeColor =
        highContrast ? const Color(0xFFF6F2E8) : _narrativeColor(profile);

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
                          textScale: textScale,
                          showAssist: settings?.commandAssist ?? true,
                          typewriterRunning: _typewriterRunning,
                        ),
                      ),
                    // ── Message history ──────────────────────────────────────
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.38),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.09),
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: GestureDetector(
                              onTap: _skipTypewriter,
                              child: ListView.builder(
                                controller: _scrollController,
                                padding:
                                    const EdgeInsets.fromLTRB(20, 24, 20, 8),
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
                                ),
                              ),
                            if (lastCommand != null)
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(12, 4, 12, 0),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: ActionChip(
                                    label: Text('↑ $lastCommand'),
                                    onPressed: () => _queueQuickCommand(
                                        lastCommand,
                                        submit: false),
                                    backgroundColor:
                                        Colors.white.withValues(alpha: 0.05),
                                    side: BorderSide(
                                        color: Colors.white
                                            .withValues(alpha: 0.08)),
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
  final double textScale;
  final ValueChanged<_GameMenuAction> onMenuSelected;
  final bool canReturnToTitle;

  const _TopHud({
    required this.sectorLabel,
    required this.nodeTitle,
    required this.narrativeColor,
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
                style: TextStyle(
                  color: narrativeColor.withValues(alpha: 0.75),
                  fontSize: 11 * textScale,
                  letterSpacing: 1.3,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                nodeTitle,
                style: TextStyle(
                  color: narrativeColor,
                  fontSize: 20 * textScale,
                  fontWeight: FontWeight.w600,
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
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Icon(
              Icons.more_horiz,
              color: narrativeColor.withValues(alpha: 0.85),
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
  final double textScale;
  final bool showAssist;
  final bool typewriterRunning;

  const _SessionCard({
    required this.sectorLabel,
    required this.nodeTitle,
    required this.itemCount,
    required this.weight,
    required this.narrativeColor,
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
        color: Colors.black.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$sectorLabel · $nodeTitle',
            style: TextStyle(
              color: narrativeColor.withValues(alpha: 0.54),
              fontSize: 11 * textScale,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$itemCount carried  ·  weight $weight  ·  autosave active',
            style: TextStyle(
              color: narrativeColor.withValues(alpha: 0.76),
              fontSize: 12 * textScale,
              letterSpacing: 0.5,
            ),
          ),
          if (showAssist) ...[
            const SizedBox(height: 8),
            Text(
              typewriterRunning
                  ? 'Tap the narrative to reveal the full line instantly.'
                  : 'Short commands work best. Mistakes may still advance the atmosphere.',
              style: TextStyle(
                color: narrativeColor.withValues(alpha: 0.65),
                fontSize: 12 * textScale,
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

  const _QuickCommandBar({
    required this.commands,
    required this.onCommand,
    required this.narrativeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final command in commands)
          ActionChip(
            label: Text(command.label),
            onPressed: () => onCommand(command.command, submit: command.submit),
            backgroundColor: Colors.white.withValues(alpha: 0.06),
            side: BorderSide(color: narrativeColor.withValues(alpha: 0.14)),
          ),
      ],
    );
  }
}

class _MessageTile extends StatelessWidget {
  final String text;
  final MessageRole role;
  final Color narrativeColor;
  final bool showCursor;
  final double textScale;

  const _MessageTile({
    required this.text,
    required this.role,
    required this.narrativeColor,
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
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.40),
                    fontFamily: 'monospace',
                    fontSize: 14 * textScale,
                    letterSpacing: 0.5,
                  ),
                ),
                TextSpan(
                  text: commandText,
                  style: TextStyle(
                    color: const Color(0xFFB99A58),
                    fontFamily: 'monospace',
                    fontSize: 14 * textScale,
                    letterSpacing: 0.5,
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
              style: TextStyle(
                color: narrativeColor,
                fontFamily: 'Georgia',
                fontSize: 16 * textScale,
                height: 1.65,
                letterSpacing: 0.2,
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
              fontFamily: 'monospace',
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
  final double textScale;
  final String? lastCommand;

  const _StatusBar({
    required this.weight,
    required this.itemCount,
    required this.profile,
    required this.color,
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
                      fontFamily: 'monospace',
                      fontSize: 11 * textScale,
                      letterSpacing: 0.6,
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
            ),
            const SizedBox(height: 4),
            _PsycheMiniBar(
              label: 'Anxiety',
              value: profile?.anxiety ?? 10,
              color: const Color(0xFFC97C7C),
            ),
            const SizedBox(height: 4),
            _PsycheMiniBar(
              label: 'Oblivion',
              value: profile?.oblivionLevel ?? 0,
              color: const Color(0xFF879EC4),
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

  const _PsycheMiniBar({
    required this.label,
    required this.value,
    required this.color,
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
              letterSpacing: 0.5,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: clampedValue / 100,
              minHeight: 5,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
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
  final bool reduceMotion;

  const _PuzzleSolvedOverlay({
    required this.active,
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
            color: Colors.black.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFB99A58), width: 1.2),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '✦',
                style: TextStyle(
                  color: Color(0xFFDEC58A),
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
  final bool reduceMotion;

  const _SimulacrumBanner({
    required this.text,
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
              border: Border.all(color: const Color(0xFFB99A58)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.28),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Text(
              text ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFF1E5C9),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
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
            ? narrativeColor.withValues(alpha: 0.55)
            : Colors.white.withValues(alpha: 0.15);

        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  border: Border.all(color: borderColor),
                  borderRadius: BorderRadius.circular(16),
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
                              ? const Color(0xFFB99A58)
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
                        fontFamily: 'monospace',
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
                          fontFamily: 'monospace',
                          fontSize: 15 * textScale,
                        ),
                        cursorColor: narrativeColor,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: enabled ? hintText : '…',
                          hintStyle: TextStyle(
                            color: narrativeColor.withValues(alpha: 0.25),
                            fontFamily: 'monospace',
                            fontSize: 14 * textScale,
                          ),
                          suffixIcon: IconButton(
                            tooltip: 'Send',
                            onPressed: enabled ? onSubmit : null,
                            icon: Icon(
                              Icons.send_rounded,
                              size: 20,
                              color: enabled
                                  ? const Color(0xFFB99A58)
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
