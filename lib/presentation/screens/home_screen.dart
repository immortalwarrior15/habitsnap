import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../domain/entities/meditation_settings.dart';
import '../widgets/breathing_animation.dart';
import '../widgets/timer_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const _durations = [5, 10, 15, 30];
  static const _presets = <({String id, String title, IconData icon})>[
    (id: 'sleep', title: 'Сон', icon: Icons.nightlight_round),
    (id: 'focus', title: 'Фокус', icon: Icons.psychology_alt),
    (id: 'antiStress', title: 'Антистресс', icon: Icons.self_improvement),
    (id: 'castanedaEnergy', title: 'Энергия', icon: Icons.bolt),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(meditationControllerProvider);
    final controller = ref.read(meditationControllerProvider.notifier);
    final lastSync = state.lastHeartRateSyncAt;
    final isHeartRateFresh =
        lastSync != null && DateTime.now().difference(lastSync).inSeconds <= 35;

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
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _Metric(
                      label: 'Сессии',
                      value: '${state.totalSessions}',
                    ),
                    _Metric(
                      label: 'Минуты',
                      value: '${state.totalMeditationMinutes}',
                    ),
                    _Metric(
                      label: 'Streak',
                      value: '${state.currentStreak} дн.',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Пульс и адаптивное дыхание',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Пульс: ${state.currentHeartRate?.toString() ?? '—'} BPM',
                    ),
                    Text('Ритм дыхания: ${state.breathingPaceLabel}'),
                    Text(
                      'Энергия (по Кастанеде): ${state.castanedaEnergyLevel}%',
                    ),
                    const SizedBox(height: 4),
                    Text(
                      state.isHeartRatePermissionGranted
                          ? (isHeartRateFresh
                                ? 'Статус датчика: актуальные данные'
                                : 'Статус датчика: данные устарели')
                          : 'Статус датчика: доступ к пульсу не выдан',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: state.isAdaptiveModeEnabled,
                      title: const Text('Адаптировать под пульс (Apple Watch/Garmin/Wear OS)'),
                      subtitle: const Text(
                        'Требует доступ к Apple Health или Google Fit на устройстве.',
                      ),
                      onChanged: (_) => controller.toggleAdaptiveMode(),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.favorite),
                        label: const Text('Проверить пульс сейчас'),
                        onPressed: controller.refreshHeartRateNow,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Смарт-пресеты', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _presets
                  .map(
                    (preset) => ActionChip(
                      avatar: Icon(preset.icon, size: 18),
                      label: Text(preset.title),
                      onPressed: () => controller.applyPreset(preset.id),
                    ),
                  )
                  .toList(),
            ),
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
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Громкость'),
              subtitle: Slider(
                value: state.volume,
                min: 0,
                max: 1,
                divisions: 10,
                label: '${(state.volume * 100).round()}%',
                onChanged: controller.setVolume,
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

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
