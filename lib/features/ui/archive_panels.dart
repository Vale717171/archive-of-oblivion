import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/save_service.dart';
import '../../core/storage/database_service.dart';
import '../game/game_engine_provider.dart';
import '../settings/app_settings_provider.dart';

class ArchivePanels {
  static Future<void> showIntroduction(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) => const _ArchiveTextDialog(
        title: 'Introduction',
        body:
            'You awaken in the Archive, a metaphysical threshold between memory and oblivion.\n\n'
            'Four sectors ask you to recover what gives human life weight: philosophy, science, art, and transformation. A fifth asks what remains when memory itself speaks.\n\n'
            'The Archive does not judge. It witnesses.',
      ),
    );
  }

  static Future<void> showHowToPlay(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) => const _ArchiveTextDialog(
        title: 'How to play',
        body: 'This is a parser narrative. Type short commands.\n\n'
            'Useful verbs:\n'
            '• go north / south / east / west\n'
            '• look\n'
            '• examine object\n'
            '• take object\n'
            '• wait\n'
            '• inventory\n'
            '• hint / hint more / hint full\n'
            '• help\n\n'
            'Unrecognised commands do not always mean failure: the Demiurge may answer instead.\n\n'
            'Psychological weight matters. Carrying everything is not always wise.',
      ),
    );
  }

  static Future<void> showCredits(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) => const _ArchiveTextDialog(
        title: 'Credits',
        body: "The Archive of Oblivion\n\n"
            'A psycho-philosophical interactive fiction for Android.\n\n'
            'Built with Flutter, Riverpod, sqflite, just_audio, and the deterministic narrator “All That Is”.\n\n'
            'Citations are curated from public-domain sources.',
      ),
    );
  }

  static Future<void> showSettings(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF101114),
      builder: (context) => const _SettingsSheet(),
    );
  }

  static Future<void> showArchiveStatus(
    BuildContext context,
    GameEngineState engine,
  ) {
    return showDialog<void>(
      context: context,
      builder: (context) => _ArchiveStatusDialog(engine: engine),
    );
  }

  static Future<void> showSaveLoad(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF101114),
      builder: (context) => const _SaveLoadSheet(),
    );
  }

  static Future<void> showPlayerMemories(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) => const _PlayerMemoriesDialog(),
    );
  }
}

class _ArchiveTextDialog extends StatelessWidget {
  final String title;
  final String body;

  const _ArchiveTextDialog({
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF111111),
      title: Text(title),
      content: SingleChildScrollView(
        child: Text(
          body,
          style: const TextStyle(height: 1.5),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _SettingsSheet extends ConsumerWidget {
  const _SettingsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider).valueOrNull;
    if (settings == null) {
      return const SafeArea(
        child: SizedBox(
          height: 220,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final notifier = ref.read(appSettingsProvider.notifier);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          20 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Settings',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Shape readability, motion, and parser assistance without breaking the contemplative tone.',
                style: TextStyle(color: Colors.white70, height: 1.4),
              ),
              const SizedBox(height: 20),
              SwitchListTile(
                value: settings.instantText,
                onChanged: (value) => notifier.saveSettings(instantText: value),
                title: const Text('Instant text'),
                subtitle: const Text('Disable the typewriter effect.'),
              ),
              SwitchListTile(
                value: settings.reduceMotion,
                onChanged: (value) =>
                    notifier.saveSettings(reduceMotion: value),
                title: const Text('Reduce motion'),
                subtitle:
                    const Text('Tone down flashes and animated transitions.'),
              ),
              SwitchListTile(
                value: settings.highContrast,
                onChanged: (value) =>
                    notifier.saveSettings(highContrast: value),
                title: const Text('High contrast'),
                subtitle: const Text(
                    'Increase readability on dim or low-quality screens.'),
              ),
              SwitchListTile(
                value: settings.commandAssist,
                onChanged: (value) =>
                    notifier.saveSettings(commandAssist: value),
                title: const Text('Command assist'),
                subtitle:
                    const Text('Show quick commands and contextual hints.'),
              ),
              SwitchListTile(
                value: settings.musicEnabled,
                onChanged: (value) =>
                    notifier.saveSettings(musicEnabled: value),
                title: const Text('Music and ambience'),
                subtitle: const Text(
                    'Enable background music, ritual cues, and atmospheric transitions.'),
              ),
              Text('Music volume · ${(settings.musicVolume * 100).round()}%'),
              Slider(
                value: settings.musicVolume,
                min: 0.0,
                max: 1.0,
                divisions: 10,
                label: '${(settings.musicVolume * 100).round()}%',
                onChanged: settings.musicEnabled
                    ? (value) => notifier.saveSettings(musicVolume: value)
                    : null,
              ),
              SwitchListTile(
                value: settings.sfxEnabled,
                onChanged: (value) => notifier.saveSettings(sfxEnabled: value),
                title: const Text('Sound effects'),
                subtitle: const Text(
                    'Enable one-shot cues such as Proustian or ritual effects when assets are present.'),
              ),
              Text('Effects volume · ${(settings.sfxVolume * 100).round()}%'),
              Slider(
                value: settings.sfxVolume,
                min: 0.0,
                max: 1.0,
                divisions: 10,
                label: '${(settings.sfxVolume * 100).round()}%',
                onChanged: settings.sfxEnabled
                    ? (value) => notifier.saveSettings(sfxVolume: value)
                    : null,
              ),
              SwitchListTile(
                value: settings.muteInBackground,
                onChanged: (value) =>
                    notifier.saveSettings(muteInBackground: value),
                title: const Text('Mute when in background'),
                subtitle: const Text(
                    'Pause audio automatically when you switch to another app.'),
              ),
              SwitchListTile(
                value: settings.enableHaptics,
                onChanged: (value) =>
                    notifier.saveSettings(enableHaptics: value),
                title: const Text('Haptic feedback'),
                subtitle: const Text(
                    'Vibration cues for commands, puzzle events, and narrative thresholds.'),
              ),
              const SizedBox(height: 8),
              Text('Text size · ${(settings.textScale * 100).round()}%'),
              Slider(
                value: settings.textScale,
                min: 1.0,
                max: 1.8,
                divisions: 8,
                label: '${(settings.textScale * 100).round()}%',
                onChanged: (value) => notifier.saveSettings(textScale: value),
              ),
              Text('Typewriter pace · ${settings.typewriterMillis} ms'),
              Slider(
                value: settings.typewriterMillis.toDouble(),
                min: 12,
                max: 60,
                divisions: 12,
                label: '${settings.typewriterMillis} ms',
                onChanged: settings.instantText
                    ? null
                    : (value) =>
                        notifier.saveSettings(typewriterMillis: value.round()),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: notifier.reset,
                  child: const Text('Reset defaults'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArchiveStatusDialog extends StatelessWidget {
  final GameEngineState engine;

  const _ArchiveStatusDialog({required this.engine});

  @override
  Widget build(BuildContext context) {
    final statuses = <_SectorStatus>[
      _SectorStatus(
        label: 'Garden',
        stateLabel: engine.completedPuzzles.contains('garden_complete')
            ? 'Ataraxia recovered'
            : 'Unexplored',
        detail: engine.completedPuzzles.contains('garden_complete')
            ? 'The statue accepted your burden.'
            : 'Relief still waits in the grove.',
        complete: engine.completedPuzzles.contains('garden_complete') ||
            engine.inventory.contains('ataraxia'),
      ),
      _SectorStatus(
        label: 'Observatory',
        stateLabel: engine.completedPuzzles.contains('obs_complete')
            ? 'The Constant recovered'
            : 'Unexplored',
        detail: engine.completedPuzzles.contains('obs_complete')
            ? 'The inward observation is complete.'
            : 'The telescope still seeks its witness.',
        complete: engine.completedPuzzles.contains('obs_complete') ||
            engine.inventory.contains('the constant'),
      ),
      _SectorStatus(
        label: 'Gallery',
        stateLabel: engine.completedPuzzles.contains('gallery_complete')
            ? 'The Proportion recovered'
            : 'Unexplored',
        detail: engine.completedPuzzles.contains('gallery_complete')
            ? 'The mirror yielded its geometry.'
            : 'The boundary is not ready to break.',
        complete: engine.completedPuzzles.contains('gallery_complete') ||
            engine.inventory.contains('the proportion'),
      ),
      _SectorStatus(
        label: 'Laboratory',
        stateLabel: engine.completedPuzzles.contains('lab_complete')
            ? 'The Catalyst recovered'
            : 'Unexplored',
        detail: engine.completedPuzzles.contains('lab_complete')
            ? 'Transformation recognised your breath.'
            : 'The Great Work remains unfinished.',
        complete: engine.completedPuzzles.contains('lab_complete') ||
            engine.inventory.contains('the catalyst'),
      ),
      _SectorStatus(
        label: 'Memory',
        stateLabel: engine.completedPuzzles.contains('ritual_complete')
            ? 'Ritual completed'
            : engine.completedPuzzles.containsAll(const {
                'memory_childhood',
                'memory_youth',
                'memory_maturity',
                'memory_old_age',
              })
                ? 'Four memories offered'
                : 'Unexplored',
        detail: engine.completedPuzzles.contains('ritual_complete')
            ? 'The fifth descent is open.'
            : 'The sector waits for what only you can say.',
        complete: engine.completedPuzzles.contains('ritual_complete') ||
            engine.completedPuzzles.containsAll(const {
              'memory_childhood',
              'memory_youth',
              'memory_maturity',
              'memory_old_age',
            }),
      ),
    ];

    return AlertDialog(
      backgroundColor: const Color(0xFF111111),
      title: const Text('Archive Status'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final status in statuses) ...[
                _SectorStatusCard(status: status),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _PlayerMemoriesDialog extends StatelessWidget {
  const _PlayerMemoriesDialog();

  String _prettyKey(String key) {
    final words = <String>[];
    for (final part in key.replaceAll('_', ' ').split(' ')) {
      if (part.isEmpty) continue;
      words.add('${part[0].toUpperCase()}${part.substring(1)}');
    }
    return words.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF111111),
      title: const Text('Your Memories'),
      content: SizedBox(
        width: 520,
        child: FutureBuilder<Map<String, String>>(
          future: DatabaseService.instance.loadAllMemories(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              if (snapshot.hasError) {
                return const Text(
                  'The Archive cannot retrieve your memories right now.',
                  style: TextStyle(height: 1.5),
                );
              }
              return const SizedBox(
                height: 140,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final memories = snapshot.data!;
            if (memories.isEmpty) {
              return const Text(
                'No memories have been offered yet.\n\nThe Archive is still waiting for your words.',
                style: TextStyle(height: 1.5),
              );
            }

            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final entry in memories.entries) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Memory · ${_prettyKey(entry.key)}',
                            style: const TextStyle(
                              fontSize: 12,
                              letterSpacing: 0.8,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '“${entry.value}”',
                            style: const TextStyle(
                              height: 1.5,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _SectorStatus {
  final String label;
  final String stateLabel;
  final String detail;
  final bool complete;

  const _SectorStatus({
    required this.label,
    required this.stateLabel,
    required this.detail,
    required this.complete,
  });
}

// ── Save / Load sheet ─────────────────────────────────────────────────────────

class _SaveLoadSheet extends ConsumerStatefulWidget {
  const _SaveLoadSheet();

  @override
  ConsumerState<_SaveLoadSheet> createState() => _SaveLoadSheetState();
}

class _SaveLoadSheetState extends ConsumerState<_SaveLoadSheet> {
  late Future<List<SaveSlot>> _slotsFuture;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _slotsFuture = SaveService.instance.listSlots();
  }

  void _reload() => setState(() {
        _slotsFuture = SaveService.instance.listSlots();
      });

  Future<void> _save(int slot) async {
    setState(() => _busy = true);
    try {
      await ref.read(gameEngineProvider.notifier).saveToSlot(slot);
      _reload();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved to slot $slot.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Save failed. Try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _load(SaveSlot slot) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111111),
        title: const Text('Load save'),
        content: Text(
          'This will replace your current session with the '
          '${slot.slot == 0 ? "auto-save" : "slot ${slot.slot}"} '
          '(${slot.sectorLabel}). Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Load'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await ref.read(gameEngineProvider.notifier).loadSlot(slot);
      if (mounted) Navigator.of(context).pop(); // close sheet
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Load failed. Try again.')),
        );
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          20 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Save / Load',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            const Text(
              'Auto-save runs every 6 commands or on sector change.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<SaveSlot>>(
              future: _slotsFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final slots = snapshot.data!;
                return Column(
                  children: [
                    for (final slot in slots)
                      _SlotCard(
                        slot: slot,
                        busy: _busy,
                        onSave: slot.slot == 0 ? null : () => _save(slot.slot),
                        onLoad: slot.isEmpty ? null : () => _load(slot),
                      ),
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

class _SlotCard extends StatelessWidget {
  final SaveSlot slot;
  final bool busy;
  final VoidCallback? onSave;
  final VoidCallback? onLoad;

  const _SlotCard({
    required this.slot,
    required this.busy,
    required this.onSave,
    required this.onLoad,
  });

  String get _label => slot.slot == 0 ? 'Auto save' : 'Slot ${slot.slot}';

  String get _preview {
    if (slot.isEmpty) return 'Empty';
    final date = slot.savedAt;
    final dateStr = date != null
        ? '${date.day.toString().padLeft(2, '0')}/'
            '${date.month.toString().padLeft(2, '0')} '
            '${date.hour.toString().padLeft(2, '0')}:'
            '${date.minute.toString().padLeft(2, '0')}'
        : '';
    return '${slot.sectorLabel}  ·  Awareness ${slot.awarenessLevel}%'
        '${dateStr.isNotEmpty ? '  ·  $dateStr' : ''}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 3),
                Text(_preview,
                    style:
                        const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          if (onSave != null)
            TextButton(
              onPressed: busy ? null : onSave,
              child: const Text('Save'),
            ),
          if (onLoad != null)
            TextButton(
              onPressed: busy ? null : onLoad,
              child: const Text('Load'),
            ),
        ],
      ),
    );
  }
}

class _SectorStatusCard extends StatelessWidget {
  final _SectorStatus status;

  const _SectorStatusCard({required this.status});

  @override
  Widget build(BuildContext context) {
    final accent = status.complete
        ? const Color(0xFF7ABF8A)
        : Colors.white.withValues(alpha: 0.28);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            status.complete ? Icons.task_alt : Icons.radio_button_unchecked,
            color: accent,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  status.stateLabel,
                  style: TextStyle(
                    color: accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  status.detail,
                  style: const TextStyle(color: Colors.white70, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
