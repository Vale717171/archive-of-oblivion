import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/storage/database_service.dart';

class AppSettings {
  final bool instantText;
  final bool reduceMotion;
  final bool highContrast;
  final bool commandAssist;
  final bool musicEnabled;
  final double musicVolume;
  final bool sfxEnabled;
  final double sfxVolume;
  final double textScale;
  final int typewriterMillis;
  final bool muteInBackground;
  final bool enableHaptics;

  const AppSettings({
    required this.instantText,
    required this.reduceMotion,
    required this.highContrast,
    required this.commandAssist,
    required this.musicEnabled,
    required this.musicVolume,
    required this.sfxEnabled,
    required this.sfxVolume,
    required this.textScale,
    required this.typewriterMillis,
    required this.muteInBackground,
    required this.enableHaptics,
  });

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      instantText: (map['instant_text'] as int? ?? 0) == 1,
      reduceMotion: (map['reduce_motion'] as int? ?? 0) == 1,
      highContrast: (map['high_contrast'] as int? ?? 0) == 1,
      commandAssist: (map['command_assist'] as int? ?? 1) == 1,
      musicEnabled: (map['music_enabled'] as int? ?? 1) == 1,
      musicVolume: (map['music_volume'] as num? ?? 0.85).toDouble(),
      sfxEnabled: (map['sfx_enabled'] as int? ?? 1) == 1,
      sfxVolume: (map['sfx_volume'] as num? ?? 0.90).toDouble(),
      textScale: (map['text_scale'] as num? ?? 1.0).toDouble(),
      typewriterMillis: (map['typewriter_millis'] as num? ?? 22).toInt(),
      muteInBackground: (map['mute_in_background'] as int? ?? 1) == 1,
      enableHaptics: (map['enable_haptics'] as int? ?? 1) == 1,
    );
  }

  AppSettings copyWith({
    bool? instantText,
    bool? reduceMotion,
    bool? highContrast,
    bool? commandAssist,
    bool? musicEnabled,
    double? musicVolume,
    bool? sfxEnabled,
    double? sfxVolume,
    double? textScale,
    int? typewriterMillis,
    bool? muteInBackground,
    bool? enableHaptics,
  }) {
    return AppSettings(
      instantText: instantText ?? this.instantText,
      reduceMotion: reduceMotion ?? this.reduceMotion,
      highContrast: highContrast ?? this.highContrast,
      commandAssist: commandAssist ?? this.commandAssist,
      musicEnabled: musicEnabled ?? this.musicEnabled,
      musicVolume: musicVolume ?? this.musicVolume,
      sfxEnabled: sfxEnabled ?? this.sfxEnabled,
      sfxVolume: sfxVolume ?? this.sfxVolume,
      textScale: textScale ?? this.textScale,
      typewriterMillis: typewriterMillis ?? this.typewriterMillis,
      muteInBackground: muteInBackground ?? this.muteInBackground,
      enableHaptics: enableHaptics ?? this.enableHaptics,
    );
  }
}

class AppSettingsNotifier extends AsyncNotifier<AppSettings> {
  final _dbService = DatabaseService.instance;

  double _clampTextScale(double value) {
    if (value < 0.9) return 0.9;
    if (value > 1.4) return 1.4;
    return value;
  }

  int _clampTypewriterMillis(int value) {
    if (value < 8) return 8;
    if (value > 40) return 40;
    return value;
  }

  double _clampVolume(double value) {
    if (value < 0.0) return 0.0;
    if (value > 1.0) return 1.0;
    return value;
  }

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

  Future<void> saveSettings({
    bool? instantText,
    bool? reduceMotion,
    bool? highContrast,
    bool? commandAssist,
    bool? musicEnabled,
    double? musicVolume,
    bool? sfxEnabled,
    double? sfxVolume,
    double? textScale,
    int? typewriterMillis,
    bool? muteInBackground,
    bool? enableHaptics,
  }) async {
    final current = state.valueOrNull ?? await _fetchSettings();
    final next = current.copyWith(
      instantText: instantText,
      reduceMotion: reduceMotion,
      highContrast: highContrast,
      commandAssist: commandAssist,
      musicEnabled: musicEnabled,
      musicVolume: musicVolume == null ? null : _clampVolume(musicVolume),
      sfxEnabled: sfxEnabled,
      sfxVolume: sfxVolume == null ? null : _clampVolume(sfxVolume),
      textScale: textScale == null ? null : _clampTextScale(textScale),
      typewriterMillis: typewriterMillis == null
          ? null
          : _clampTypewriterMillis(typewriterMillis),
      muteInBackground: muteInBackground,
      enableHaptics: enableHaptics,
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
        'music_enabled': next.musicEnabled ? 1 : 0,
        'music_volume': next.musicVolume,
        'sfx_enabled': next.sfxEnabled ? 1 : 0,
        'sfx_volume': next.sfxVolume,
        'text_scale': next.textScale,
        'typewriter_millis': next.typewriterMillis,
        'mute_in_background': next.muteInBackground ? 1 : 0,
        'enable_haptics': next.enableHaptics ? 1 : 0,
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
