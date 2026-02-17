enum MeditationSound {
  rain('Дождь', 'assets/audio/rain.mp3'),
  forest('Лес', 'assets/audio/forest.mp3'),
  ocean('Океан', 'assets/audio/ocean.mp3'),
  whiteNoise('Белый шум', 'assets/audio/white_noise.mp3'),
  music('Медитативная музыка', 'assets/audio/meditation_music.mp3');

  const MeditationSound(this.title, this.assetPath);
  final String title;
  final String assetPath;
}

class MeditationSettings {
  const MeditationSettings({
    required this.durationMinutes,
    required this.sound,
    required this.isDarkTheme,
    required this.isBreathingAnimationEnabled,
    required this.isPlaying,
    required this.remainingSeconds,
  });

  final int durationMinutes;
  final MeditationSound sound;
  final bool isDarkTheme;
  final bool isBreathingAnimationEnabled;
  final bool isPlaying;
  final int remainingSeconds;

  factory MeditationSettings.initial() {
    return const MeditationSettings(
      durationMinutes: 10,
      sound: MeditationSound.rain,
      isDarkTheme: true,
      isBreathingAnimationEnabled: true,
      isPlaying: false,
      remainingSeconds: 10 * 60,
    );
  }

  MeditationSettings copyWith({
    int? durationMinutes,
    MeditationSound? sound,
    bool? isDarkTheme,
    bool? isBreathingAnimationEnabled,
    bool? isPlaying,
    int? remainingSeconds,
  }) {
    return MeditationSettings(
      durationMinutes: durationMinutes ?? this.durationMinutes,
      sound: sound ?? this.sound,
      isDarkTheme: isDarkTheme ?? this.isDarkTheme,
      isBreathingAnimationEnabled:
          isBreathingAnimationEnabled ?? this.isBreathingAnimationEnabled,
      isPlaying: isPlaying ?? this.isPlaying,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
    );
  }
}
