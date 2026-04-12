import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/game_engine_provider.dart';
import '../settings/app_settings_provider.dart';
import '../state/game_state_provider.dart';
import 'archive_panels.dart';
import 'background_service.dart';
import 'game_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _showTitle = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _showTitle = true);
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
    final backgroundPath = BackgroundService.getBackgroundForNodeOrDefault(currentNode);

    final bodyColor = highContrast ? Colors.white : const Color(0xFFE9E3D6);
    final mutedColor = highContrast
        ? Colors.white70
        : const Color(0xFFD4C7AE).withValues(alpha: 0.88);

    return Scaffold(
      backgroundColor: const Color(0xFF07090D),
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
          Container(color: Colors.black.withValues(alpha: 0.62)),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
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
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: DefaultTextStyle(
                      style: TextStyle(
                        color: bodyColor,
                        fontSize: 16 * textScale,
                        height: 1.5,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'The Archive of Oblivion',
                            style: TextStyle(
                              color: bodyColor,
                              fontSize: 34 * textScale,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'A psycho-philosophical text adventure about memory, burden, and the temptation of oblivion.',
                            style: TextStyle(
                              color: mutedColor,
                              fontSize: 16 * textScale,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'A contemplative parser narrative in English.\nAverage session: 10–20 minutes.\nBest with headphones, patience, and short commands.',
                            style: TextStyle(
                              color: mutedColor,
                              fontSize: 14 * textScale,
                            ),
                          ),
                          const SizedBox(height: 28),
                          _HomeActionButton(
                            label: hasProgress ? 'Continue' : 'Enter the Archive',
                            onPressed: () => _openGame(startFresh: false),
                          ),
                          const SizedBox(height: 10),
                          _HomeActionButton(
                            label: 'New game',
                            outlined: true,
                            onPressed: () => _openGame(startFresh: true),
                          ),
                          const SizedBox(height: 24),
                          if (gameState != null) _SaveSummaryCard(gameState: gameState),
                          const SizedBox(height: 20),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _HomeChip(
                                label: 'Introduction',
                                onPressed: () => ArchivePanels.showIntroduction(context),
                              ),
                              _HomeChip(
                                label: 'How to play',
                                onPressed: () => ArchivePanels.showHowToPlay(context),
                              ),
                              _HomeChip(
                                label: 'Settings',
                                onPressed: () => ArchivePanels.showSettings(context),
                              ),
                              _HomeChip(
                                label: 'Credits',
                                onPressed: () => ArchivePanels.showCredits(context),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'The Demiurge answers uncertainty. Mistakes are sometimes discoveries.',
                            style: TextStyle(
                              color: mutedColor,
                              fontSize: 13 * textScale,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
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

class _HomeActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool outlined;

  const _HomeActionButton({
    required this.label,
    required this.onPressed,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final child = SizedBox(
      width: double.infinity,
      child: Text(label, textAlign: TextAlign.center),
    );

    if (outlined) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFE9E3D6),
          side: const BorderSide(color: Color(0xFFB99A58)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        ),
        child: child,
      );
    }

    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFFB99A58),
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
      child: child,
    );
  }
}

class _HomeChip extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _HomeChip({
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onPressed,
      backgroundColor: Colors.white.withValues(alpha: 0.06),
      side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
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
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current run',
            style: TextStyle(
              fontSize: 12,
              letterSpacing: 1.2,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            nodeTitle,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            '$sector  ·  ${gameState.inventory.length} carried  ·  weight ${gameState.psychoWeight}  ·  $progress puzzle states',
            style: const TextStyle(color: Colors.white70, height: 1.4),
          ),
        ],
      ),
    );
  }
}
