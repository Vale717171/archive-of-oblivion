import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
        body:
            'This is a parser narrative. Type short commands.\n\n'
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
        body:
            "L'Archivio dell'Oblio\n\n"
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
                onChanged: (value) => notifier.update(instantText: value),
                title: const Text('Instant text'),
                subtitle: const Text('Disable the typewriter effect.'),
              ),
              SwitchListTile(
                value: settings.reduceMotion,
                onChanged: (value) => notifier.update(reduceMotion: value),
                title: const Text('Reduce motion'),
                subtitle: const Text('Tone down flashes and animated transitions.'),
              ),
              SwitchListTile(
                value: settings.highContrast,
                onChanged: (value) => notifier.update(highContrast: value),
                title: const Text('High contrast'),
                subtitle: const Text('Increase readability on dim or low-quality screens.'),
              ),
              SwitchListTile(
                value: settings.commandAssist,
                onChanged: (value) => notifier.update(commandAssist: value),
                title: const Text('Command assist'),
                subtitle: const Text('Show quick commands and contextual hints.'),
              ),
              const SizedBox(height: 8),
              Text('Text size · ${(settings.textScale * 100).round()}%'),
              Slider(
                value: settings.textScale,
                min: 0.9,
                max: 1.4,
                divisions: 5,
                label: '${(settings.textScale * 100).round()}%',
                onChanged: (value) => notifier.update(textScale: value),
              ),
              Text('Typewriter pace · ${settings.typewriterMillis} ms'),
              Slider(
                value: settings.typewriterMillis.toDouble(),
                min: 8,
                max: 40,
                divisions: 8,
                label: '${settings.typewriterMillis} ms',
                onChanged: settings.instantText
                    ? null
                    : (value) => notifier.update(typewriterMillis: value.round()),
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
