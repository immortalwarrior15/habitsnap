import 'dart:async';

import 'package:just_audio/just_audio.dart';

class AudioPlayerService {
  AudioPlayerService();

  final AudioPlayer _player = AudioPlayer();
  bool _prepared = false;

  Future<void> setLoopAsset(String assetPath) async {
    await _player.setLoopMode(LoopMode.one);
    await _player.setAudioSource(AudioSource.asset(assetPath));
    _prepared = true;
  }

  Future<void> play() async {
    if (_prepared) {
      await _player.play();
    }
  }

  Future<void> pause() => _player.pause();

  Future<void> stop() async {
    await _player.stop();
  }

  Future<void> playBellAndFadeOut() async {
    await _player.setLoopMode(LoopMode.off);
    await _player.setAudioSource(AudioSource.asset('assets/audio/bell.mp3'));
    await _player.setVolume(1.0);
    await _player.play();

    // Плавное затухание звука колокольчика.
    for (var i = 10; i >= 0; i--) {
      await Future<void>.delayed(const Duration(milliseconds: 120));
      await _player.setVolume(i / 10);
    }

    await _player.stop();
    await _player.setVolume(1);
    _prepared = false;
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}
