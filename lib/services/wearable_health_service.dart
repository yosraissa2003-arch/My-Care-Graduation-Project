import 'dart:io';

import 'package:health/health.dart';

/// A normalized health reading imported from Apple Health (iOS)
/// or Google Health Connect (Android).
///
/// This makes the MyCare app work with most smart watches indirectly:
/// Apple Watch -> Apple Health -> MyCare
/// Samsung/Garmin/Fitbit/Xiaomi/etc. -> Health Connect -> MyCare
class WearableReading {
  final int? heartRate;
  final int? oxygen;
  final double? temperature;
  final int? systolic;
  final int? diastolic;
  final int? glucose;

  final DateTime? syncedAt;
  final String platform;
  final String sourceName;

  const WearableReading({
    this.heartRate,
    this.oxygen,
    this.temperature,
    this.systolic,
    this.diastolic,
    this.glucose,
    this.syncedAt,
    this.platform = '',
    this.sourceName = '',
  });

  bool get hasAnyValue =>
      heartRate != null ||
      oxygen != null ||
      temperature != null ||
      systolic != null ||
      diastolic != null ||
      glucose != null;

  String get missingValuesText {
    final missing = <String>[];

    if (heartRate == null) missing.add('النبض');
    if (oxygen == null) missing.add('الأكسجين');
    if (temperature == null) missing.add('الحرارة');
    if (systolic == null || diastolic == null) missing.add('الضغط');
    if (glucose == null) missing.add('السكر');

    if (missing.isEmpty) return '';
    return 'لم توفر الساعة قراءة: ${missing.join('، ')}. يمكن إدخالها يدويًا.';
  }

  String get summaryText {
    final parts = <String>[];

    if (heartRate != null) parts.add('النبض $heartRate');
    if (oxygen != null) parts.add('الأكسجين $oxygen%');
    if (temperature != null) {
      parts.add('الحرارة ${temperature!.toStringAsFixed(1)}');
    }
    if (systolic != null && diastolic != null) {
      parts.add('الضغط $systolic/$diastolic');
    }
    if (glucose != null) parts.add('السكر $glucose');

    if (parts.isEmpty) return 'لم يتم العثور على قراءات من الساعة.';
    return 'تم استيراد: ${parts.join('، ')}.';
  }
}

class WearableImportResult {
  final bool success;
  final WearableReading? reading;
  final String message;

  const WearableImportResult({
    required this.success,
    required this.message,
    this.reading,
  });
}

class WearableHealthService {
  WearableHealthService();

  final Health _health = Health();

  final List<HealthDataType> _requestedTypes = const [
    HealthDataType.HEART_RATE,
    HealthDataType.BLOOD_OXYGEN,
    HealthDataType.BODY_TEMPERATURE,
    HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
    HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
    HealthDataType.BLOOD_GLUCOSE,
  ];

  Future<WearableImportResult> fetchLatestReading({
    Duration lookback = const Duration(hours: 24),
  }) async {
    try {
      await _health.configure();

      if (Platform.isAndroid) {
        final available = await _health.isHealthConnectAvailable();

        if (!available) {
          try {
            await _health.installHealthConnect();
          } catch (_) {}

          return const WearableImportResult(
            success: false,
            message:
                'Health Connect غير موجود أو يحتاج تحديث. ثبّتيه وافتحي تطبيق الساعة ثم فعّلي مشاركة البيانات.',
          );
        }
      }

      final availableTypes = _requestedTypes
          .where((type) {
            try {
              return _health.isDataTypeAvailable(type);
            } catch (_) {
              return true;
            }
          })
          .toList();

      if (availableTypes.isEmpty) {
        return const WearableImportResult(
          success: false,
          message: 'هذا الجهاز لا يدعم قراءة بيانات الساعة من Apple Health أو Health Connect.',
        );
      }

      final permissions = availableTypes
          .map((_) => HealthDataAccess.READ)
          .toList(growable: false);

      final granted = await _health.requestAuthorization(
        availableTypes,
        permissions: permissions,
      );

      if (!granted) {
        return const WearableImportResult(
          success: false,
          message:
              'لم يتم منح صلاحية قراءة بيانات الصحة. افتحي إعدادات Apple Health أو Health Connect واسمحي لـ MyCare بالقراءة.',
        );
      }

      final now = DateTime.now();
      final start = now.subtract(lookback);

      var points = await _health.getHealthDataFromTypes(
        types: availableTypes,
        startTime: start,
        endTime: now,
      );

      points = _health.removeDuplicates(points);
      points.sort((a, b) => b.dateTo.compareTo(a.dateTo));

      final reading = _buildReading(points);

      if (!reading.hasAnyValue) {
        return const WearableImportResult(
          success: false,
          message:
              'لم يتم العثور على قراءات حديثة. افتحي تطبيق الساعة أو Health Connect واعملي مزامنة ثم حاولي مرة أخرى.',
        );
      }

      return WearableImportResult(
        success: true,
        reading: reading,
        message: '${reading.summaryText} ${reading.missingValuesText}',
      );
    } catch (e) {
      return WearableImportResult(
        success: false,
        message: 'حدث خطأ أثناء قراءة بيانات الساعة: $e',
      );
    }
  }

  WearableReading _buildReading(List<HealthDataPoint> points) {
    int? heartRate;
    int? oxygen;
    double? temperature;
    int? systolic;
    int? diastolic;
    int? glucose;

    DateTime? latestTime;
    String latestSource = '';
    String platform = Platform.isIOS ? 'Apple Health' : 'Health Connect';

    for (final point in points) {
      final value = _numericValue(point.value);
      if (value == null) continue;

      latestTime ??= point.dateTo;
      if (latestSource.isEmpty) {
        latestSource = point.sourceName;
      }

      switch (point.type) {
        case HealthDataType.HEART_RATE:
          heartRate ??= _validInt(value, min: 25, max: 240);
          break;

        case HealthDataType.BLOOD_OXYGEN:
          oxygen ??= _normalizeOxygen(value);
          break;

        case HealthDataType.BODY_TEMPERATURE:
          temperature ??= _validDouble(value, min: 30, max: 45);
          break;

        case HealthDataType.BLOOD_PRESSURE_SYSTOLIC:
          systolic ??= _validInt(value, min: 50, max: 260);
          break;

        case HealthDataType.BLOOD_PRESSURE_DIASTOLIC:
          diastolic ??= _validInt(value, min: 30, max: 180);
          break;

        case HealthDataType.BLOOD_GLUCOSE:
          glucose ??= _normalizeGlucose(value);
          break;

        default:
          break;
      }
    }

    return WearableReading(
      heartRate: heartRate,
      oxygen: oxygen,
      temperature: temperature,
      systolic: systolic,
      diastolic: diastolic,
      glucose: glucose,
      syncedAt: latestTime,
      platform: platform,
      sourceName: latestSource,
    );
  }

  double? _numericValue(HealthValue value) {
    if (value is NumericHealthValue) {
      return value.numericValue.toDouble();
    }

    final json = value.toJson();
    final direct = json['numeric_value'] ?? json['numericValue'] ?? json['value'];
    if (direct is num) return direct.toDouble();

    final text = value.toString();
    final match = RegExp(r'[-+]?\d+(\.\d+)?').firstMatch(text);
    if (match == null) return null;

    return double.tryParse(match.group(0)!);
  }

  int? _validInt(double value, {required int min, required int max}) {
    final rounded = value.round();
    if (rounded < min || rounded > max) return null;
    return rounded;
  }

  double? _validDouble(double value, {required double min, required double max}) {
    if (value < min || value > max) return null;
    return value;
  }

  int? _normalizeOxygen(double value) {
    final percent = value <= 1 ? value * 100 : value;
    return _validInt(percent, min: 50, max: 100);
  }

  int? _normalizeGlucose(double value) {
    // Health Connect and Apple Health usually return mg/dL in this package.
    // If a value looks like mmol/L, convert it to mg/dL.
    final mgDl = value < 30 ? value * 18 : value;
    return _validInt(mgDl, min: 20, max: 600);
  }
}
