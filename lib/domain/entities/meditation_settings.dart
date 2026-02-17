enum MeditationSound {
  rain(
    'Дождь',
    'assets/audio/rain.mp3',
    'https://cdn.pixabay.com/audio/2022/03/15/audio_c8c8a73467.mp3',
  ),
  forest(
    'Лес',
    'assets/audio/forest.mp3',
    'https://cdn.pixabay.com/audio/2022/08/04/audio_2dde668d05.mp3',
  ),
  ocean(
    'Океан',
    'assets/audio/ocean.mp3',
    'https://cdn.pixabay.com/audio/2021/08/04/audio_c6ccf9ba2f.mp3',
  ),
  whiteNoise(
    'Белый шум',
    'assets/audio/white_noise.mp3',
    'https://cdn.pixabay.com/audio/2024/04/17/audio_5605f65c04.mp3',
  ),
  music(
    'Медитативная музыка',
    'assets/audio/meditation_music.mp3',
    'https://cdn.pixabay.com/audio/2022/05/16/audio_1e34e17f4f.mp3',
  );

  const MeditationSound(this.title, this.assetPath, this.streamUrl);
  final String title;
  final String assetPath;
  final String streamUrl;
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
