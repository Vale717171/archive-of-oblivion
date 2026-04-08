import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/storage/database_service.dart';

class AppSettings {
  final bool instantText;
  final bool reduceMotion;
  final bool highContrast;
  final bool commandAssist;
  final double textScale;
  final int typewriterMillis;

  const AppSettings({
    required this.instantText,
    required this.reduceMotion,
    required this.highContrast,
    required this.commandAssist,
    required this.textScale,
    required this.typewriterMillis,
  });

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      instantText: (map['instant_text'] as int? ?? 0) == 1,
      reduceMotion: (map['reduce_motion'] as int? ?? 0) == 1,
      highContrast: (map['high_contrast'] as int? ?? 0) == 1,
      commandAssist: (map['command_assist'] as int? ?? 1) == 1,
      textScale: (map['text_scale'] as num? ?? 1.0).toDouble(),
      typewriterMillis: (map['typewriter_millis'] as num? ?? 22).toInt(),
    );
  }

  AppSettings copyWith({
    bool? instantText,
    bool? reduceMotion,
    bool? highContrast,
    bool? commandAssist,
    double? textScale,
    int? typewriterMillis,
  }) {
    return AppSettings(
      instantText: instantText ?? this.instantText,
      reduceMotion: reduceMotion ?? this.reduceMotion,
      highContrast: highContrast ?? this.highContrast,
      commandAssist: commandAssist ?? this.commandAssist,
      textScale: textScale ?? this.textScale,
      typewriterMillis: typewriterMillis ?? this.typewriterMillis,
    );
  }
}

class AppSettingsNotifier extends AsyncNotifier<AppSettings> {
  final _dbService = DatabaseService.instance;

  @override
  Future<AppSettings> build() async {
    return _fetchSettings();
  }

  Future<AppSettings> _fetchSettings() async {
    final db = await _dbService.database;
    final rows = await db.query('app_settings', where: 'id = 1', limit: 1);
    if (rows.isNotEmpty) {
      return AppSettings.fromMap(rows.first);
    }
    return AppSettings.fromMap(DatabaseService.defaultAppSettingsRow);
  }

  Future<void> update({
    bool? instantText,
    bool? reduceMotion,
    bool? highContrast,
    bool? commandAssist,
    double? textScale,
    int? typewriterMillis,
  }) async {
    final current = state.valueOrNull ?? await _fetchSettings();
    final clampedTextScale = textScale == null
        ? null
        : textScale < 0.9
            ? 0.9
            : textScale > 1.4
                ? 1.4
                : textScale;
    final clampedTypewriterMillis = typewriterMillis == null
        ? null
        : typewriterMillis < 8
            ? 8
            : typewriterMillis > 40
                ? 40
                : typewriterMillis;
    final next = current.copyWith(
      instantText: instantText,
      reduceMotion: reduceMotion,
      highContrast: highContrast,
      commandAssist: commandAssist,
      textScale: clampedTextScale,
      typewriterMillis: clampedTypewriterMillis,
    );

    final db = await _dbService.database;
    await db.insert(
      'app_settings',
      {
        'id': 1,
        'instant_text': next.instantText ? 1 : 0,
        'reduce_motion': next.reduceMotion ? 1 : 0,
        'high_contrast': next.highContrast ? 1 : 0,
        'command_assist': next.commandAssist ? 1 : 0,
        'text_scale': next.textScale,
        'typewriter_millis': next.typewriterMillis,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    state = AsyncValue.data(next);
  }

  Future<void> reset() async {
    final db = await _dbService.database;
    await db.insert(
      'app_settings',
      DatabaseService.defaultAppSettingsRow,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    state = AsyncValue.data(await _fetchSettings());
  }
}

final appSettingsProvider =
    AsyncNotifierProvider<AppSettingsNotifier, AppSettings>(
      AppSettingsNotifier.new,
    );
