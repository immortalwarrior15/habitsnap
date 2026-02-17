import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/meditation_settings.dart';
import '../../domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  static const _durationKey = 'duration_minutes';
  static const _soundKey = 'sound';
  static const _darkThemeKey = 'dark_theme';
  static const _breathingKey = 'breathing_enabled';

  @override
  Future<MeditationSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final duration = prefs.getInt(_durationKey) ?? 10;
    final soundIndex = prefs.getInt(_soundKey) ?? 0;

    return MeditationSettings(
      durationMinutes: duration,
      sound: MeditationSound.values[soundIndex],
      isDarkTheme: prefs.getBool(_darkThemeKey) ?? true,
      isBreathingAnimationEnabled: prefs.getBool(_breathingKey) ?? true,
      isPlaying: false,
      remainingSeconds: duration * 60,
    );
  }

  @override
  Future<void> save(MeditationSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_durationKey, settings.durationMinutes);
    await prefs.setInt(_soundKey, settings.sound.index);
    await prefs.setBool(_darkThemeKey, settings.isDarkTheme);
    await prefs.setBool(_breathingKey, settings.isBreathingAnimationEnabled);
  }
}
