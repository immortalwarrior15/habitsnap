import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../domain/entities/meditation_settings.dart';
import '../widgets/breathing_animation.dart';
import '../widgets/timer_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const _durations = [5, 10, 15, 30];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(meditationControllerProvider);
    final controller = ref.read(meditationControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meditation & Relax'),
        actions: [
          IconButton(
            tooltip: 'Темная тема',
            icon: Icon(state.isDarkTheme ? Icons.dark_mode : Icons.light_mode),
            onPressed: controller.toggleTheme,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (state.isBreathingAnimationEnabled) const BreathingAnimation(),
            const SizedBox(height: 16),
            TimerCard(remainingSeconds: state.remainingSeconds),
            const SizedBox(height: 16),
            Text('Длительность', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _durations
                  .map(
                    (minutes) => ChoiceChip(
                      label: Text('$minutes мин'),
                      selected: state.durationMinutes == minutes,
                      onSelected: (_) => controller.setDuration(minutes),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 20),
            Text('Фоновые звуки', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...MeditationSound.values.map(
              (sound) => RadioListTile<MeditationSound>(
                title: Text(sound.title),
                value: sound,
                groupValue: state.sound,
                onChanged: (value) {
                  if (value != null) {
                    controller.setSound(value);
                  }
                },
              ),
            ),
            SwitchListTile(
              value: state.isBreathingAnimationEnabled,
              title: const Text('Дыхательная анимация (вдох-выдох)'),
              onChanged: (_) => controller.toggleBreathingAnimation(),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: Icon(state.isPlaying ? Icons.pause : Icons.play_arrow),
              label: Text(state.isPlaying ? 'Пауза' : 'Начать медитацию'),
              onPressed: () {
                if (state.isPlaying) {
                  controller.pauseMeditation();
                } else if (state.remainingSeconds < state.durationMinutes * 60 &&
                    state.remainingSeconds > 0) {
                  controller.resumeMeditation();
                } else {
                  controller.startMeditation();
                }
              },
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.stop_circle_outlined),
              label: const Text('Остановить'),
              onPressed: () => controller.stopMeditation(),
            ),
          ],
        ),
      ),
    );
  }
}
