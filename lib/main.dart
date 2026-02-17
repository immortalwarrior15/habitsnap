import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализация фонового аудио для Android/iOS уведомлений.
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.habitsnap.meditation.audio',
    androidNotificationChannelName: 'Meditation Audio',
    androidNotificationOngoing: true,
  );

  runApp(const ProviderScope(child: MeditationApp()));
}
