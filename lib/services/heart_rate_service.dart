import 'package:health/health.dart';

int? _extractHeartRateValue(dynamic value) {
  if (value is num) return value.round();

  final match = RegExp(r'[-+]?\d*\.?\d+').firstMatch(value.toString());
  if (match == null) return null;

  return double.tryParse(match.group(0) ?? '')?.round();
}

class HeartRateService {
  final Health _health = Health();

  Future<bool> requestAccess() async {
    const types = [HealthDataType.HEART_RATE];
    const permissions = [HealthDataAccess.READ];

    try {
      return await _health.requestAuthorization(types, permissions: permissions);
    } catch (_) {
      return false;
    }
  }

  Future<int?> fetchLatestHeartRate() async {
    final now = DateTime.now();
    final from = now.subtract(const Duration(minutes: 10));

    try {
      final points = await _health.getHealthDataFromTypes(
        startTime: from,
        endTime: now,
        types: const [HealthDataType.HEART_RATE],
      );

      if (points.isEmpty) return null;

      points.sort((a, b) => b.dateTo.compareTo(a.dateTo));
      return _extractHeartRateValue(points.first.value);
    } catch (_) {
      return null;
    }
  }

  String breathingPaceForHeartRate(int bpm) {
    if (bpm >= 95) return '4-6';
    if (bpm >= 80) return '4-5';
    if (bpm >= 65) return '4-4';
    return '5-5';
  }
}
