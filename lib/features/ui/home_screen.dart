import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';

import '../game/game_engine_provider.dart';
import '../settings/app_settings_provider.dart';
import '../state/game_state_provider.dart';
import 'archive_panels.dart';
import 'background_service.dart';
import 'game_screen.dart';
import 'ritual_style.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, this.audioFailed = false});

  /// True when AudioService.initialize() threw at startup.
  /// Shown as a one-time muted banner so the player understands the silence.
  final bool audioFailed;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _showTitle = false;
  bool _audioBannerDismissed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _showTitle = true);
      final settings = ref.read(appSettingsProvider).valueOrNull;
      if ((settings?.enableHaptics ?? true) &&
          !(settings?.reduceMotion ?? false)) {
        HapticFeedback.mediumImpact();
      }
    });
  }

  Future<void> _openGame({required bool startFresh}) async {
    if (startFresh) {
      final gameState = ref.read(gameStateProvider).valueOrNull;
      final hasProgress = gameState != null &&
          (gameState.currentNode != 'intro_void' ||
              gameState.completedPuzzles.isNotEmpty ||
              gameState.inventory.length > 1);
      if (hasProgress) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF111111),
            title: const Text('Start a new game'),
            content: const Text(
              'This will replace your current run and rebuild the opening scene.',
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
        if (confirmed != true || !mounted) return;
      }
      await ref.read(gameEngineProvider.notifier).startNewGame();
    }

    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const GameScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider).valueOrNull;
    final gameState = ref.watch(gameStateProvider).valueOrNull;
    final highContrast = settings?.highContrast ?? false;
    final textScale = settings?.textScale ?? 1.0;
    final currentNode = gameState?.currentNode;
    final hasProgress = gameState != null &&
        (currentNode != 'intro_void' ||
            gameState.completedPuzzles.isNotEmpty ||
            gameState.inventory.length > 1);
    final backgroundPath =
        BackgroundService.getBackgroundForNodeOrDefault(currentNode);

    final bodyColor = highContrast ? Colors.white : const Color(0xFFE9E3D6);
    final mutedColor = highContrast
        ? Colors.white70
        : const Color(0xFFD4C7AE).withValues(alpha: 0.88);
    final profile = visualProfileForNode(currentNode ?? 'intro_void');

    return Scaffold(
      backgroundColor: const Color(0xFF05070C),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background fades smoothly when the sector image changes
          // (e.g. returning from game, or starting a new run).
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 800),
            child: Image.asset(
              backgroundPath,
              key: ValueKey(backgroundPath),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.58),
                  Colors.black.withValues(alpha: 0.74),
                  Colors.black.withValues(alpha: 0.86),
                ],
              ),
            ),
          ),
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.38),
                  radius: 1.24,
                  colors: [
                    profile.glow.withValues(alpha: 0.16),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.52),
                  ],
                  stops: const [0.08, 0.52, 1.0],
                ),
              ),
            ),
          ),
          IgnorePointer(
            child: Stack(
              children: [
                Positioned(
                  top: 118,
                  left: 26,
                  right: 26,
                  child: Container(
                    height: 1,
                    color: profile.frame.withValues(alpha: 0.34),
                  ),
                ),
                Positioned(
                  bottom: 118,
                  left: 26,
                  right: 26,
                  child: Container(
                    height: 1,
                    color: profile.frame.withValues(alpha: 0.26),
                  ),
                ),
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 22,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          profile.glow.withValues(alpha: 0.14),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 22,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerRight,
                        end: Alignment.centerLeft,
                        colors: [
                          profile.glow.withValues(alpha: 0.14),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
                child: AnimatedScale(
                  scale: _showTitle ? 1.0 : 0.88,
                  duration: Duration(
                    milliseconds: (settings?.reduceMotion ?? false) ? 0 : 1200,
                  ),
                  curve: Curves.easeOutCubic,
                  child: AnimatedOpacity(
                    opacity: _showTitle ? 1 : 0,
                    duration: Duration(
                      milliseconds: (settings?.reduceMotion ?? false) ? 0 : 900,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 620),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(32),
                              border: Border.all(
                                color: profile.frame.withValues(alpha: 0.92),
                              ),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.18),
                                  Colors.black.withValues(alpha: 0.39),
                                  Colors.black.withValues(alpha: 0.63),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: profile.glow.withValues(alpha: 0.25),
                                  blurRadius: 44,
                                  spreadRadius: 3,
                                ),
                              ],
                            ),
                            child: DefaultTextStyle(
                              style: RitualTypography.narrative(
                                16 * textScale,
                                color: bodyColor,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Center(
                                    child: Column(
                                      children: [
                                        Text(
                                          'RITUAL TEXT EXPERIENCE',
                                          style: RitualTypography.command(
                                            11.4 * textScale,
                                            color: profile.accent
                                                .withValues(alpha: 0.86),
                                          ).copyWith(letterSpacing: 1.35),
                                        ),
                                        const SizedBox(height: 10),
                                        Container(
                                          width: 190,
                                          height: 1.1,
                                          color: profile.accent
                                              .withValues(alpha: 0.52),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'THE ARCHIVE',
                                          textAlign: TextAlign.center,
                                          style: RitualTypography.display(
                                            43 * textScale,
                                            color: bodyColor,
                                            height: 1.04,
                                          ),
                                        ),
                                        Text(
                                          'OF OBLIVION',
                                          textAlign: TextAlign.center,
                                          style: RitualTypography.display(
                                            32 * textScale,
                                            color: profile.accent,
                                          ),
                                        ),
                                        const SizedBox(height: 14),
                                        Text(
                                          '✦',
                                          style: RitualTypography.display(
                                            18 * textScale,
                                            color: profile.accent
                                                .withValues(alpha: 0.92),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Container(
                                          width: 190,
                                          height: 1.1,
                                          color: profile.accent
                                              .withValues(alpha: 0.52),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    'A psycho-philosophical ritual text adventure about memory, burden, and the temptation of oblivion.',
                                    style: RitualTypography.narrative(
                                      18.5 * textScale,
                                      color: bodyColor.withValues(alpha: 0.95),
                                      weight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    'ENGLISH ONLY · SLOW INPUT · 10–20 MINUTES PER SESSION',
                                    style: RitualTypography.ritualSans(
                                      12.2 * textScale,
                                      color: mutedColor.withValues(alpha: 0.95),
                                      weight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  _HomeActionButton(
                                    label: hasProgress
                                        ? 'Continue the Descent'
                                        : 'Enter the Archive',
                                    onPressed: () =>
                                        _openGame(startFresh: false),
                                  ),
                                  const SizedBox(height: 10),
                                  _HomeActionButton(
                                    label: 'Begin a New Run',
                                    outlined: true,
                                    onPressed: () =>
                                        _openGame(startFresh: true),
                                  ),
                                  const SizedBox(height: 24),
                                  if (gameState != null)
                                    _SaveSummaryCard(gameState: gameState),
                                  const SizedBox(height: 18),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      _HomeChip(
                                        label: 'Introduction',
                                        onPressed: () =>
                                            ArchivePanels.showIntroduction(
                                                context),
                                      ),
                                      _HomeChip(
                                        label: 'How to play',
                                        onPressed: () =>
                                            ArchivePanels.showHowToPlay(
                                                context),
                                      ),
                                      _HomeChip(
                                        label: 'Settings',
                                        onPressed: () =>
                                            ArchivePanels.showSettings(context),
                                      ),
                                      _HomeChip(
                                        label: 'Credits',
                                        onPressed: () =>
                                            ArchivePanels.showCredits(context),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 18),
                                  Text(
                                    'The Demiurge answers uncertainty. Mistakes may still be coordinates.',
                                    style: RitualTypography.narrative(
                                      14 * textScale,
                                      color: mutedColor.withValues(alpha: 0.92),
                                      weight: FontWeight.w500,
                                    ),
                                  ),
                                  if (widget.audioFailed &&
                                      !_audioBannerDismissed) ...[
                                    const SizedBox(height: 16),
                                    _AudioFailedBanner(
                                      onDismiss: () => setState(
                                          () => _audioBannerDismissed = true),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeActionButton extends ConsumerWidget {
  final String label;
  final VoidCallback onPressed;
  final bool outlined;

  const _HomeActionButton({
    required this.label,
    required this.onPressed,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider).valueOrNull;
    final hapticsOn =
        (settings?.enableHaptics ?? true) && !(settings?.reduceMotion ?? false);

    void handlePress() {
      if (hapticsOn) HapticFeedback.selectionClick();
      onPressed();
    }

    final child = SizedBox(
      width: double.infinity,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: RitualTypography.ritualSans(
          17,
          color: outlined ? const Color(0xFFEDE5D7) : Colors.black,
          weight: FontWeight.w600,
        ),
      ),
    );

    if (outlined) {
      return OutlinedButton(
        onPressed: handlePress,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFE9E3D6),
          side:
              BorderSide(color: const Color(0xFFB99A58).withValues(alpha: 0.9)),
          backgroundColor: Colors.black.withValues(alpha: 0.30),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
        child: child,
      );
    }

    return FilledButton(
      onPressed: handlePress,
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFFC6A45E),
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0.2,
        shadowColor: const Color(0xCCB88C43),
      ),
      child: child,
    );
  }
}

class _HomeChip extends ConsumerWidget {
  final String label;
  final VoidCallback onPressed;

  const _HomeChip({
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider).valueOrNull;
    final hapticsOn =
        (settings?.enableHaptics ?? true) && !(settings?.reduceMotion ?? false);

    return ActionChip(
      label: Text(
        label,
        style: RitualTypography.command(
          12.5,
          color: const Color(0xFFE9E3D6),
        ),
      ),
      onPressed: () {
        if (hapticsOn) HapticFeedback.selectionClick();
        onPressed();
      },
      backgroundColor: Colors.white.withValues(alpha: 0.05),
      side: BorderSide(color: Colors.white.withValues(alpha: 0.22)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

class _AudioFailedBanner extends StatelessWidget {
  final VoidCallback onDismiss;
  const _AudioFailedBanner({required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          const Icon(Icons.volume_off, color: Colors.amber, size: 16),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Audio unavailable — the Archive continues in silence.',
              style: TextStyle(
                  color: Colors.amber, fontSize: 12, letterSpacing: 0.3),
            ),
          ),
          GestureDetector(
            onTap: onDismiss,
            child: const Icon(Icons.close, color: Colors.amber, size: 16),
          ),
        ],
      ),
    );
  }
}

class _SaveSummaryCard extends StatelessWidget {
  final GameState gameState;

  const _SaveSummaryCard({required this.gameState});

  @override
  Widget build(BuildContext context) {
    final nodeTitle = gameNodeTitle(gameState.currentNode);
    final sector = gameSectorLabel(gameState.currentNode);
    final progress = gameState.completedPuzzles.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.06),
            Colors.white.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current run',
            style: RitualTypography.command(
              11.5,
              color: const Color(0xFFDCCCAE),
            ).copyWith(
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            nodeTitle,
            style: RitualTypography.display(
              22,
              color: const Color(0xFFF1E7D5),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$sector  ·  ${gameState.inventory.length} carried  ·  weight ${gameState.psychoWeight}  ·  $progress puzzle states',
            style: RitualTypography.narrative(
              14,
              color: const Color(0xFFE5DBC8).withValues(alpha: 0.82),
            ),
          ),
        ],
      ),
    );
  }
}
