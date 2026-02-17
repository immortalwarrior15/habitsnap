import '../entities/meditation_settings.dart';

abstract class SettingsRepository {
  Future<MeditationSettings> load();
  Future<void> save(MeditationSettings settings);
}
