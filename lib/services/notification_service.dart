import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static final FlutterTts _tts = FlutterTts();

  static const AndroidNotificationChannel _urgentChannel =
      AndroidNotificationChannel(
        'mycare_urgent_channel',
        'MyCare Alerts',
        description: 'تنبيهات الطوارئ والصحة لمشروع MyCare',
        importance: Importance.max,
        playSound: true,
      );

  static const AndroidNotificationChannel _medicationChannel =
      AndroidNotificationChannel(
        'mycare_medication_channel',
        'تذكيرات الأدوية',
        description: 'تنبيهات مواعيد الأدوية اليومية',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

  static const AndroidNotificationChannel _healthReadingChannel =
      AndroidNotificationChannel(
        'mycare_health_reading_channel',
        'تذكيرات القراءات الصحية',
        description:
            'تنبيهات إدخال قراءات الضغط والسكر والنبض والأكسجين والحرارة',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

  static const int _healthReadingMorningId = 10001000;
  static const int _healthReadingEveningId = 10002200;

  static Future<void> init() async {
    if (_initialized) return;

    tzdata.initializeTimeZones();
    _setLocalTimeZone();

    await _setupTextToSpeech();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(initSettings);

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidPlugin?.createNotificationChannel(_urgentChannel);
    await androidPlugin?.createNotificationChannel(_medicationChannel);
    await androidPlugin?.createNotificationChannel(_healthReadingChannel);
    await androidPlugin?.requestNotificationsPermission();

    _initialized = true;
  }

  static Future<void> _setupTextToSpeech() async {
    try {
      await _tts.setLanguage('ar');
      await _tts.setSpeechRate(0.45);
      await _tts.setPitch(1.0);
    } catch (e) {
      debugPrint('Text to speech setup error: $e');
    }
  }

  static Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;

    try {
      await init();
      await _tts.stop();
      await _tts.speak(text);
    } catch (e) {
      debugPrint('Text to speech error: $e');
    }
  }

  static void _setLocalTimeZone() {
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Hebron'));
    } catch (_) {
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Jerusalem'));
      } catch (_) {
        tz.setLocalLocation(tz.UTC);
      }
    }
  }

  static Future<void> _requestExactAlarmPermission() async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    try {
      await androidPlugin?.requestExactAlarmsPermission();
    } catch (e) {
      debugPrint('Exact alarm permission request error: $e');
    }
  }

  static Future<void> showNotification(RemoteMessage message) async {
    await init();

    final notification = message.notification;
    final data = message.data;

    final title = notification?.title ?? data['title'] ?? 'MyCare';
    final body = notification?.body ?? data['body'] ?? data['message'] ?? '';

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _urgentChannel.id,
          _urgentChannel.name,
          channelDescription: _urgentChannel.description,
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );

    await speak('$title. $body');
  }

  static Future<void> scheduleMedicationReminders({
    required String medicationId,
    required String medicationName,
    required List<String> selectedTimes,
  }) async {
    if (selectedTimes.isEmpty) return;

    await init();
    await _requestExactAlarmPermission();
    await cancelMedicationReminders(medicationId);

    for (int i = 0; i < selectedTimes.length; i++) {
      final scheduledDate = _timeTextToTZDateTime(selectedTimes[i]);
      if (scheduledDate == null) continue;

      final notificationId = _notificationIdFor(medicationId, i);

      await _scheduleOneMedicationReminder(
        id: notificationId,
        medicationName: medicationName,
        scheduledDate: scheduledDate,
      );

      debugPrint('Medication notification scheduled for: $scheduledDate');
    }
  }

  static Future<void> cancelMedicationReminders(String medicationId) async {
    await init();

    for (int i = 0; i < 6; i++) {
      await _plugin.cancel(_notificationIdFor(medicationId, i));
    }
  }

  static Future<void> _scheduleOneMedicationReminder({
    required int id,
    required String medicationName,
    required tz.TZDateTime scheduledDate,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'mycare_medication_channel',
      'تذكيرات الأدوية',
      channelDescription: 'تنبيهات مواعيد الأدوية اليومية',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      ticker: 'موعد الدواء',
      category: AndroidNotificationCategory.reminder,
      visibility: NotificationVisibility.public,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _plugin.zonedSchedule(
        id,
        'موعد الدواء',
        'حان موعد دواء: $medicationName',
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'medication:$id',
      );
    } on PlatformException catch (e) {
      debugPrint('Exact medication schedule failed: ${e.code} - ${e.message}');

      await _plugin.zonedSchedule(
        id,
        'موعد الدواء',
        'حان موعد دواء: $medicationName',
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'medication:$id',
      );
    } catch (e) {
      debugPrint('Medication schedule failed: $e');
    }
  }

  static Future<void> scheduleHealthReadingReminders({
    int morningHour = 8,
    int morningMinute = 0,
    int eveningHour = 20,
    int eveningMinute = 0,
  }) async {
    await init();
    await _requestExactAlarmPermission();
    await cancelHealthReadingReminders();

    final morningDate = _nextTZDateTime(morningHour, morningMinute);
    final eveningDate = _nextTZDateTime(eveningHour, eveningMinute);

    await _scheduleOneHealthReadingReminder(
      id: _healthReadingMorningId,
      title: 'تذكير صحي صباحي',
      body:
          'صباح الخير، حان وقت قياس الضغط والسكر والنبض والأكسجين والحرارة وإدخال القراءات.',
      scheduledDate: morningDate,
    );

    await _scheduleOneHealthReadingReminder(
      id: _healthReadingEveningId,
      title: 'تذكير صحي مسائي',
      body: 'مساء الخير، لا تنسَ إدخال قراءاتك الصحية لمتابعة حالتك.',
      scheduledDate: eveningDate,
    );

    final pending = await _plugin.pendingNotificationRequests();
    debugPrint(
      'Health reading reminders scheduled at: $morningDate and $eveningDate',
    );
    debugPrint('Pending notifications count: ${pending.length}');
  }

  static Future<void> testHealthNotificationAfterOneMinute() async {
    await init();
    await _requestExactAlarmPermission();

    final scheduledDate = tz.TZDateTime.now(
      tz.local,
    ).add(const Duration(minutes: 1));

    await _scheduleOneHealthReadingReminder(
      id: 999999,
      title: 'اختبار تنبيه',
      body: 'إذا وصل هذا التنبيه، فالجدولة شغالة.',
      scheduledDate: scheduledDate,
    );

    final pending = await _plugin.pendingNotificationRequests();
    debugPrint('Test health notification scheduled for: $scheduledDate');
    debugPrint('Pending notifications count: ${pending.length}');
  }

  static Future<void> cancelHealthReadingReminders() async {
    await init();
    await _plugin.cancel(_healthReadingMorningId);
    await _plugin.cancel(_healthReadingEveningId);
  }

  static Future<void> _scheduleOneHealthReadingReminder({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'mycare_health_reading_channel',
      'تذكيرات القراءات الصحية',
      channelDescription:
          'تنبيهات إدخال قراءات الضغط والسكر والنبض والأكسجين والحرارة',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      ticker: 'تذكير صحي',
      category: AndroidNotificationCategory.reminder,
      visibility: NotificationVisibility.public,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'health_reading:$id',
      );
    } on PlatformException catch (e) {
      debugPrint(
        'Exact health reminder schedule failed: ${e.code} - ${e.message}',
      );

      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'health_reading:$id',
      );
    } catch (e) {
      debugPrint('Health reminder schedule failed: $e');
    }
  }

  static tz.TZDateTime _nextTZDateTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduled.isBefore(now.add(const Duration(seconds: 20)))) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }

  static tz.TZDateTime? _timeTextToTZDateTime(String timeText) {
    final text = timeText.trim();
    final match = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(text);
    if (match == null) return null;

    int hour = int.tryParse(match.group(1) ?? '') ?? 8;
    final int minute = int.tryParse(match.group(2) ?? '') ?? 0;

    final bool isPm = text.contains('مساء') || text.contains('ظهر');
    final bool isAm = text.contains('صباح');

    if (isPm && hour < 12) hour += 12;
    if (isAm && hour == 12) hour = 0;

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduled.isBefore(now.add(const Duration(seconds: 20)))) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }

  static int _notificationIdFor(String medicationId, int index) {
    final raw = '$medicationId-$index';
    var hash = 0;

    for (final codeUnit in raw.codeUnits) {
      hash = (hash * 31 + codeUnit) & 0x7fffffff;
    }

    return hash == 0 ? index + 1 : hash;
  }
}
