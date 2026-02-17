import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/settings_repository_impl.dart';
import '../domain/entities/meditation_settings.dart';
import '../domain/repositories/settings_repository.dart';
import '../services/audio_player_service.dart';
import '../services/heart_rate_service.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepositoryImpl();
});

final audioPlayerServiceProvider = Provider<AudioPlayerService>((ref) {
  final service = AudioPlayerService();
  ref.onDispose(service.dispose);
  return service;
});

final heartRateServiceProvider = Provider<HeartRateService>((ref) {
  return HeartRateService();
});

final meditationControllerProvider =
    StateNotifierProvider<MeditationController, MeditationSettings>((ref) {
      final controller = MeditationController(
        repository: ref.watch(settingsRepositoryProvider),
        audioService: ref.watch(audioPlayerServiceProvider),
        heartRateService: ref.watch(heartRateServiceProvider),
      );
      unawaited(controller.init());
      return controller;
    });

class MeditationController extends StateNotifier<MeditationSettings> {
  MeditationController({
    required SettingsRepository repository,
    required AudioPlayerService audioService,
    required HeartRateService heartRateService,
  })  : _repository = repository,
        _audioService = audioService,
        _heartRateService = heartRateService,
        super(MeditationSettings.initial());

  final SettingsRepository _repository;
  final AudioPlayerService _audioService;
  final HeartRateService _heartRateService;
  Timer? _timer;
  Timer? _heartRateTimer;

  Future<void> init() async {
    state = await _repository.load();
  }

  Future<void> setDuration(int minutes) async {
    await _audioService.stop();
    _cancelHeartRateTimer();
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

    if (state.isPlaying) {
      await _audioService.setLoopSource(
        assetPath: sound.assetPath,
        streamUrl: sound.streamUrl,
      );
      await _audioService.play();
      await _audioService.setVolume(state.volume);
    }

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
    _cancelTimer();
    await _audioService.setLoopSource(
      assetPath: state.sound.assetPath,
      streamUrl: state.sound.streamUrl,
    );
    await _audioService.play();
    await _audioService.setVolume(state.volume);

    state = state.copyWith(isPlaying: true);
    await _startHeartRateSyncIfEnabled();

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
    _cancelHeartRateTimer();
    await _audioService.pause();
    state = state.copyWith(isPlaying: false);
  }

  Future<void> resumeMeditation() async {
    if (state.remainingSeconds <= 0) return;
    _cancelTimer();
    await _audioService.play();
    await _audioService.setVolume(state.volume);
    state = state.copyWith(isPlaying: true);
    await _startHeartRateSyncIfEnabled();

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
    _cancelHeartRateTimer();

    if (playBell) {
      await _audioService.playBellAndFadeOut();
    } else {
      await _audioService.stop();
    }

    var nextState = state.copyWith(
      isPlaying: false,
      remainingSeconds: state.durationMinutes * 60,
    );

    if (playBell) {
      nextState = _updateProgressAfterCompletedSession(nextState);
    }

    state = nextState;
    await _repository.save(state);
  }

  Future<void> setVolume(double value) async {
    final normalized = value.clamp(0.0, 1.0);
    state = state.copyWith(volume: normalized);
    await _audioService.setVolume(normalized);
    await _repository.save(state);
  }

  Future<void> applyPreset(String presetId) async {
    await _audioService.stop();
    _cancelTimer();
    _cancelHeartRateTimer();

    if (presetId == 'sleep') {
      state = state.copyWith(
        durationMinutes: 30,
        sound: MeditationSound.ocean,
        isBreathingAnimationEnabled: true,
        remainingSeconds: 30 * 60,
      );
    } else if (presetId == 'focus') {
      state = state.copyWith(
        durationMinutes: 15,
        sound: MeditationSound.forest,
        isBreathingAnimationEnabled: false,
        remainingSeconds: 15 * 60,
      );
    } else if (presetId == 'antiStress') {
      state = state.copyWith(
        durationMinutes: 10,
        sound: MeditationSound.rain,
        isBreathingAnimationEnabled: true,
        remainingSeconds: 10 * 60,
      );
    } else {
      return;
    }

    await _repository.save(state);
  }

  Future<void> toggleAdaptiveMode() async {
    final enabled = !state.isAdaptiveModeEnabled;
    state = state.copyWith(isAdaptiveModeEnabled: enabled);
    await _repository.save(state);

    if (!enabled) {
      _cancelHeartRateTimer();
      state = state.copyWith(
        clearCurrentHeartRate: true,
        breathingPaceLabel: '4-4',
        clearLastHeartRateSyncAt: true,
      );
      await _repository.save(state);
    } else if (state.isPlaying) {
      await _startHeartRateSyncIfEnabled();
    }
  }

  Future<void> _startHeartRateSyncIfEnabled() async {
    if (!state.isAdaptiveModeEnabled) return;
    _cancelHeartRateTimer();

    final granted = await _heartRateService.requestAccess();
    state = state.copyWith(isHeartRatePermissionGranted: granted);
    await _repository.save(state);

    if (!granted) {
      state = state.copyWith(
        clearCurrentHeartRate: true,
        breathingPaceLabel: '4-4',
        clearLastHeartRateSyncAt: true,
      );
      await _repository.save(state);
      return;
    }

    await _syncHeartRate();
    _heartRateTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
      await _syncHeartRate();
    });
  }

  Future<void> _syncHeartRate() async {
    final bpm = await _heartRateService.fetchLatestHeartRate();
    if (bpm == null) return;

    state = state.copyWith(
      currentHeartRate: bpm,
      breathingPaceLabel: _heartRateService.breathingPaceForHeartRate(bpm),
      lastHeartRateSyncAt: DateTime.now(),
    );
    await _repository.save(state);
  }

  // Ручная проверка канала пульса для QA/диагностики.
  Future<void> refreshHeartRateNow() async {
    if (!state.isAdaptiveModeEnabled) {
      state = state.copyWith(
        clearCurrentHeartRate: true,
        clearLastHeartRateSyncAt: true,
      );
      await _repository.save(state);
      return;
    }

    final granted = await _heartRateService.requestAccess();
    state = state.copyWith(isHeartRatePermissionGranted: granted);
    await _repository.save(state);

    if (!granted) {
      state = state.copyWith(
        clearCurrentHeartRate: true,
        breathingPaceLabel: '4-4',
        clearLastHeartRateSyncAt: true,
      );
      await _repository.save(state);
      return;
    }

    await _syncHeartRate();
  }

  MeditationSettings _updateProgressAfterCompletedSession(
    MeditationSettings settings,
  ) {
    final now = DateTime.now();
    final dayIndex = DateTime(now.year, now.month, now.day)
            .millisecondsSinceEpoch ~/
        Duration.millisecondsPerDay;

    final lastDay = settings.lastCompletedDay;
    final streak = switch (lastDay) {
      null => 1,
      final d when d == dayIndex => settings.currentStreak,
      final d when d == dayIndex - 1 => settings.currentStreak + 1,
      _ => 1,
    };

    return settings.copyWith(
      totalSessions: settings.totalSessions + 1,
      totalMeditationMinutes:
          settings.totalMeditationMinutes + settings.durationMinutes,
      currentStreak: streak,
      lastCompletedDay: dayIndex,
    );
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _cancelHeartRateTimer() {
    _heartRateTimer?.cancel();
    _heartRateTimer = null;
  }

  @override
  void dispose() {
    _cancelTimer();
    _cancelHeartRateTimer();
    super.dispose();
  }
}
