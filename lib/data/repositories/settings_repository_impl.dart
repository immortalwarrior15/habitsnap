import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/meditation_settings.dart';
import '../../domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  static const _durationKey = 'duration_minutes';
  static const _soundKey = 'sound';
  static const _darkThemeKey = 'dark_theme';
  static const _breathingKey = 'breathing_enabled';
  static const _volumeKey = 'volume';
  static const _totalSessionsKey = 'total_sessions';
  static const _totalMinutesKey = 'total_minutes';
  static const _currentStreakKey = 'current_streak';
  static const _lastCompletedDayKey = 'last_completed_day';
  static const _adaptiveModeKey = 'adaptive_mode_enabled';

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
      volume: prefs.getDouble(_volumeKey) ?? 0.8,
      totalSessions: prefs.getInt(_totalSessionsKey) ?? 0,
      totalMeditationMinutes: prefs.getInt(_totalMinutesKey) ?? 0,
      currentStreak: prefs.getInt(_currentStreakKey) ?? 0,
      lastCompletedDay: prefs.getInt(_lastCompletedDayKey),
      isAdaptiveModeEnabled: prefs.getBool(_adaptiveModeKey) ?? true,
      currentHeartRate: null,
      breathingPaceLabel: '4-4',
    );
  }

  @override
  Future<void> save(MeditationSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_durationKey, settings.durationMinutes);
    await prefs.setInt(_soundKey, settings.sound.index);
    await prefs.setBool(_darkThemeKey, settings.isDarkTheme);
    await prefs.setBool(_breathingKey, settings.isBreathingAnimationEnabled);
    await prefs.setDouble(_volumeKey, settings.volume);
    await prefs.setInt(_totalSessionsKey, settings.totalSessions);
    await prefs.setInt(_totalMinutesKey, settings.totalMeditationMinutes);
    await prefs.setInt(_currentStreakKey, settings.currentStreak);
    await prefs.setBool(_adaptiveModeKey, settings.isAdaptiveModeEnabled);
    if (settings.lastCompletedDay != null) {
      await prefs.setInt(_lastCompletedDayKey, settings.lastCompletedDay!);
    }
  }
}
