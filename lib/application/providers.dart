import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/settings_repository_impl.dart';
import '../domain/entities/meditation_settings.dart';
import '../domain/repositories/settings_repository.dart';
import '../services/audio_player_service.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepositoryImpl();
});

final audioPlayerServiceProvider = Provider<AudioPlayerService>((ref) {
  final service = AudioPlayerService();
  ref.onDispose(service.dispose);
  return service;
});

final meditationControllerProvider =
    StateNotifierProvider<MeditationController, MeditationSettings>((ref) {
      final controller = MeditationController(
        repository: ref.watch(settingsRepositoryProvider),
        audioService: ref.watch(audioPlayerServiceProvider),
      );
      unawaited(controller.init());
      return controller;
    });

class MeditationController extends StateNotifier<MeditationSettings> {
  MeditationController({
    required SettingsRepository repository,
    required AudioPlayerService audioService,
  })  : _repository = repository,
        _audioService = audioService,
        super(MeditationSettings.initial());

  final SettingsRepository _repository;
  final AudioPlayerService _audioService;
  Timer? _timer;

  Future<void> init() async {
    state = await _repository.load();
  }

  Future<void> setDuration(int minutes) async {
    state = state.copyWith(
      durationMinutes: minutes,
      remainingSeconds: minutes * 60,
      isPlaying: false,
    );
    _cancelTimer();
    await _repository.save(state);
  }

  Future<void> setSound(MeditationSound sound) async {
    state = state.copyWith(sound: sound);
    await _repository.save(state);
  }

  Future<void> toggleTheme() async {
    state = state.copyWith(isDarkTheme: !state.isDarkTheme);
    await _repository.save(state);
  }

  Future<void> toggleBreathingAnimation() async {
    state = state.copyWith(
      isBreathingAnimationEnabled: !state.isBreathingAnimationEnabled,
    );
    await _repository.save(state);
  }

  Future<void> startMeditation() async {
    await _audioService.setLoopSource(
      assetPath: state.sound.assetPath,
      streamUrl: state.sound.streamUrl,
    );
    await _audioService.play();

    state = state.copyWith(isPlaying: true);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (state.remainingSeconds <= 1) {
        await stopMeditation(playBell: true);
      } else {
        state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
      }
    });
  }

  Future<void> pauseMeditation() async {
    _cancelTimer();
    await _audioService.pause();
    state = state.copyWith(isPlaying: false);
  }

  Future<void> resumeMeditation() async {
    if (state.remainingSeconds <= 0) return;
    await _audioService.play();
    state = state.copyWith(isPlaying: true);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (state.remainingSeconds <= 1) {
        await stopMeditation(playBell: true);
      } else {
        state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
      }
    });
  }

  Future<void> stopMeditation({bool playBell = false}) async {
    _cancelTimer();

    if (playBell) {
      await _audioService.playBellAndFadeOut();
    } else {
      await _audioService.stop();
    }

    state = state.copyWith(
      isPlaying: false,
      remainingSeconds: state.durationMinutes * 60,
    );
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _cancelTimer();
    super.dispose();
  }
}
