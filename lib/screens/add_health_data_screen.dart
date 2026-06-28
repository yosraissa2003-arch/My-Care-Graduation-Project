import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../services/notification_service.dart';
import '../services/care_timeline_service.dart';

class AddHealthDataScreen extends StatefulWidget {
  final bool autoImportFromWatch;

  const AddHealthDataScreen({super.key, this.autoImportFromWatch = false});

  @override
  State<AddHealthDataScreen> createState() => _AddHealthDataScreenState();
}

class _AddHealthDataScreenState extends State<AddHealthDataScreen> {
  final heartRateController = TextEditingController();
  final systolicController = TextEditingController();
  final diastolicController = TextEditingController();
  final glucoseController = TextEditingController();
  final oxygenController = TextEditingController();
  final temperatureController = TextEditingController();

  bool isLoading = false;
  bool isListening = false;
  String lastVoiceText = '';

  late final stt.SpeechToText _speech = stt.SpeechToText();
  late final FlutterTts _tts = FlutterTts();

  static const Color primaryColor = Color(0xFF1F4168);
  static const Color backgroundColor = Color(0xFFF7F9FC);
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color dark = Color(0xFF111827);
  static const Color secondaryTextColor = Color(0xFF4B5563);
  static const Color hintColor = Color(0xFF9CA3AF);
  static const Color green = Color(0xFF2E8B57);
  static const Color errorColor = Color(0xFFD32F2F);
  static const Color warningColor = Color(0xFFED6C02);
  static const Color border = Color(0xFFC9D6E2);
  static const Color fieldBg = Color(0xFFFFFFFF);

  @override
  void initState() {
    super.initState();
    _setupVoice();
  }

  Future<void> _setupVoice() async {
    try {
      await _tts.setLanguage('ar');
      await _tts.setSpeechRate(0.45);
      await _tts.setPitch(1.0);
    } catch (_) {}
  }

  Future<void> _speak(String message) async {
    try {
      await _tts.stop();
      await _tts.speak(message);
    } catch (_) {}
  }

  void _showSnack(String message, {Color color = primaryColor}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        content: Text(
          message,
          textAlign: TextAlign.right,
          style: const TextStyle(
            fontSize: 18,
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Future<String?> _bestArabicLocale() async {
    try {
      final locales = await _speech.locales();

      final preferred = [
        'ar_PS',
        'ar-PS',
        'ar_IL',
        'ar-IL',
        'ar_SA',
        'ar-SA',
        'ar_EG',
        'ar-EG',
        'ar',
      ];

      for (final code in preferred) {
        for (final locale in locales) {
          if (locale.localeId.toLowerCase() == code.toLowerCase()) {
            return locale.localeId;
          }
        }
      }

      for (final locale in locales) {
        if (locale.localeId.toLowerCase().startsWith('ar')) {
          return locale.localeId;
        }
      }
    } catch (_) {}

    return null;
  }

  @override
  void dispose() {
    heartRateController.dispose();
    systolicController.dispose();
    diastolicController.dispose();
    glucoseController.dispose();
    oxygenController.dispose();
    temperatureController.dispose();
    _speech.stop();
    _tts.stop();
    super.dispose();
  }

  Future<Position?> _getCurrentPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      try {
        return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 12),
        );
      } catch (_) {
        return await Geolocator.getLastKnownPosition();
      }
    } catch (_) {
      return null;
    }
  }

  Map<String, String> analyzeHealth({
    required int heartRate,
    required int systolic,
    required int diastolic,
    required int glucose,
    required int oxygen,
    required double temperature,
  }) {
    if (heartRate > 140 ||
        heartRate < 50 ||
        systolic > 180 ||
        diastolic > 120 ||
        glucose > 250 ||
        glucose < 60 ||
        oxygen < 90 ||
        temperature >= 39) {
      return {
        'status': 'Critical',
        'message':
            'هناك قراءة صحية خطيرة، يرجى طلب المساعدة أو التواصل مع الطبيب.',
      };
    }

    if (heartRate > 110 ||
        heartRate < 60 ||
        systolic > 140 ||
        diastolic > 90 ||
        glucose > 180 ||
        glucose < 70 ||
        oxygen < 94 ||
        temperature >= 38) {
      return {
        'status': 'Warning',
        'message': 'هناك قراءة غير طبيعية وتحتاج إلى متابعة.',
      };
    }

    return {'status': 'Normal', 'message': 'القراءات ضمن الوضع الطبيعي.'};
  }

  Future<void> saveHealthData() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      _showSnack('يجب تسجيل الدخول أولًا', color: errorColor);
      return;
    }

    final uid = currentUser.uid;

    if (heartRateController.text.trim().isEmpty ||
        systolicController.text.trim().isEmpty ||
        diastolicController.text.trim().isEmpty ||
        glucoseController.text.trim().isEmpty ||
        oxygenController.text.trim().isEmpty ||
        temperatureController.text.trim().isEmpty) {
      _showSnack('يرجى تعبئة جميع الحقول', color: warningColor);
      return;
    }

    final heartRate = int.tryParse(heartRateController.text.trim());
    final systolic = int.tryParse(systolicController.text.trim());
    final diastolic = int.tryParse(diastolicController.text.trim());
    final glucose = int.tryParse(glucoseController.text.trim());
    final oxygen = int.tryParse(oxygenController.text.trim());
    final temperature = double.tryParse(
      temperatureController.text.trim().replaceAll(',', '.'),
    );

    if (heartRate == null ||
        systolic == null ||
        diastolic == null ||
        glucose == null ||
        oxygen == null ||
        temperature == null) {
      _showSnack('تأكد أن جميع القيم أرقام صحيحة', color: errorColor);
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      final userData = userDoc.data() ?? {};

      final patientName =
          (userData['fullName'] ??
                  userData['name'] ??
                  currentUser.displayName ??
                  'المريض')
              .toString();

      final patientPhone = (userData['phone'] ?? '').toString();
      final emergencyPhone = (userData['emergencyContact'] ?? '').toString();

      String caregiverId = '';

      final linkedCaregiverPhone =
          (userData['linkedPhone'] ??
                  userData['linkedPatientPhone'] ??
                  userData['linkedPhoneNumber'] ??
                  '')
              .toString();

      final possibleCaregiverPhones = <String>{
        if (linkedCaregiverPhone.trim().isNotEmpty) linkedCaregiverPhone.trim(),
        if (emergencyPhone.trim().isNotEmpty) emergencyPhone.trim(),
      };

      for (final phone in possibleCaregiverPhones) {
        final caregiverQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('phone', isEqualTo: phone)
            .where('role', whereIn: ['مرافق', 'معتني'])
            .limit(1)
            .get();

        if (caregiverQuery.docs.isNotEmpty) {
          caregiverId = caregiverQuery.docs.first.id;
          break;
        }
      }

      final aiResult = analyzeHealth(
        heartRate: heartRate,
        systolic: systolic,
        diastolic: diastolic,
        glucose: glucose,
        oxygen: oxygen,
        temperature: temperature,
      );

      final healthData = {
        'userId': uid,
        'patientId': uid,
        'patientName': patientName,
        'patientPhone': patientPhone,
        'heartRate': heartRate,
        'bloodPressureSystolic': systolic,
        'bloodPressureDiastolic': diastolic,
        'bloodPressure': '$systolic/$diastolic',
        'glucose': glucose,
        'sugar': glucose,
        'oxygen': oxygen,
        'temperature': temperature,
        'aiStatus': aiResult['status'],
        'aiMessage': aiResult['message'],
        'source': 'manual',
        'isWearableReading': false,
        'createdAt': Timestamp.now(),
      };

      await FirebaseFirestore.instance.collection('healthLogs').add(healthData);

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'lastHealthReading': healthData,
        'lastAiStatus': aiResult['status'],
        'lastAiMessage': aiResult['message'],
        'lastReadingAt': Timestamp.now(),
        'lastActivityAt': Timestamp.now(),
      }, SetOptions(merge: true));

      await CareTimelineService.addEvent(
        userId: uid,
        type: 'health',
        title: 'تم تسجيل قراءة صحية',
        details:
            'النبض $heartRate، الضغط $systolic/$diastolic، السكر $glucose، الأكسجين $oxygen، الحرارة $temperature',
      );

      if (aiResult['status'] == 'Warning' || aiResult['status'] == 'Critical') {
        await FirebaseFirestore.instance.collection('notifications').add({
          'userId': uid,
          'patientId': uid,
          'caregiverId': caregiverId,
          'recipientId': caregiverId,
          'linkedCaregiverPhone': linkedCaregiverPhone,
          'emergencyPhone': emergencyPhone,
          'patientName': patientName,
          'patientPhone': patientPhone,
          'title': aiResult['status'] == 'Critical'
              ? 'تنبيه صحي خطير'
              : 'تنبيه صحي',
          'message': aiResult['message'],
          'type': 'warning',
          'time': aiResult['status'] == 'Critical' ? 'حالة خطيرة' : 'تحذير',
          'isRead': false,
          'createdAt': Timestamp.now(),
        });
      }

      if (aiResult['status'] == 'Critical') {
        final position = await _getCurrentPosition();
        final hasLocation = position != null;

        await FirebaseFirestore.instance.collection('sosAlerts').add({
          'userId': uid,
          'patientId': uid,
          'caregiverId': caregiverId,
          'linkedCaregiverPhone': linkedCaregiverPhone,
          'patientName': patientName,
          'patientPhone': patientPhone,
          'emergencyPhone': emergencyPhone,
          'source': 'ai',
          'status': 'active',
          'message': 'تم اكتشاف حالة صحية خطيرة بواسطة AI',
          'locationAvailable': hasLocation,
          'latitude': position?.latitude,
          'longitude': position?.longitude,
          'location': hasLocation
              ? {'latitude': position.latitude, 'longitude': position.longitude}
              : null,
          'createdAt': Timestamp.now(),
        });

        await FirebaseFirestore.instance.collection('notifications').add({
          'userId': uid,
          'patientId': uid,
          'caregiverId': caregiverId,
          'recipientId': caregiverId,
          'linkedCaregiverPhone': linkedCaregiverPhone,
          'emergencyPhone': emergencyPhone,
          'patientName': patientName,
          'patientPhone': patientPhone,
          'title': 'تنبيه طوارئ SOS',
          'message': hasLocation
              ? 'تم اكتشاف حالة صحية خطيرة بواسطة AI وتم إرفاق موقع المريض'
              : 'تم اكتشاف حالة صحية خطيرة بواسطة AI ولم يتم الحصول على الموقع',
          'type': 'sos',
          'time': 'طوارئ',
          'isRead': false,
          'locationAvailable': hasLocation,
          'latitude': position?.latitude,
          'longitude': position?.longitude,
          'createdAt': Timestamp.now(),
        });
      }

      bool remindersScheduled = false;

      try {
        await NotificationService.scheduleHealthReadingReminders(
          morningHour: 8,
          morningMinute: 0,
          eveningHour: 20,
          eveningMinute: 0,
        );

        remindersScheduled = true;
        debugPrint(
          'Health reading reminders scheduled after saving health data.',
        );
      } catch (e) {
        debugPrint('Health reading reminders scheduling error: $e');
      }

      if (!mounted) return;

      _showSnack(
        remindersScheduled
            ? 'تم حفظ القراءة بنجاح\nتم تفعيل تذكير 8 صباحًا و8 مساءً'
            : 'تم حفظ القراءة بنجاح',
        color: green,
      );

      Navigator.pop(context);
    } catch (e) {
      try {
        await NotificationService.scheduleHealthReadingReminders(
          morningHour: 8,
          morningMinute: 0,
          eveningHour: 20,
          eveningMinute: 0,
        );
      } catch (e) {
        debugPrint('Health reading reminders scheduling error: $e');
      }

      if (!mounted) return;

      _showSnack('حدث خطأ أثناء حفظ القراءة', color: errorColor);
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Widget _voiceHealthInputCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3FF),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFCFE1F7), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white,
                child: Icon(
                  isListening ? Icons.hearing_rounded : Icons.mic_rounded,
                  color: primaryColor,
                  size: 32,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  isListening ? 'أنا أسمعك الآن' : 'إدخال بالصوت',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Cairo',
                    color: dark,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'قل مثلاً: نبضي 75، ضغطي 120 على 80، سكري 100، أكسجيني 98، حرارتي 37.',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              fontFamily: 'Cairo',
              color: secondaryTextColor,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: isListening
                ? _finishVoiceListening
                : _listenAndFillHealthData,
            icon: Icon(
              isListening ? Icons.hearing_rounded : Icons.mic_rounded,
              color: Colors.white,
              size: 28,
            ),
            label: Text(
              isListening ? 'إيقاف وإدخال القراءات' : 'اضغط وتكلم',
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w900,
                fontFamily: 'Cairo',
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              minimumSize: const Size(double.infinity, 58),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _listenAndFillHealthData() async {
    final micStatus = await Permission.microphone.request();

    if (!micStatus.isGranted) {
      await _speak(
        'يجب السماح باستخدام المايك حتى أستطيع تسجيل القراءة بالصوت',
      );

      if (mounted) {
        _showSnack('يجب السماح بصلاحية المايك', color: warningColor);
      }

      return;
    }

    final available = await _speech.initialize(
      onError: (error) => debugPrint('Speech error: $error'),
      onStatus: (status) => debugPrint('Speech status: $status'),
    );

    if (!available) {
      await _speak('التعرف على الصوت غير متاح على هذا الجهاز');
      return;
    }

    await _tts.stop();
    await Future.delayed(const Duration(milliseconds: 300));

    lastVoiceText = '';
    final localeId = await _bestArabicLocale();

    if (mounted) {
      setState(() {
        isListening = true;
      });
    }

    if (mounted) {
      _showSnack(
        'أنا أسمع الآن... قل القراءات، ثم اضغط إيقاف',
        color: primaryColor,
      );
    }

    await _speech.listen(
      localeId: localeId,
      listenFor: const Duration(seconds: 35),
      pauseFor: const Duration(seconds: 8),
      partialResults: true,
      listenMode: stt.ListenMode.dictation,
      cancelOnError: false,
      onResult: (result) {
        final heard = result.recognizedWords.trim();

        if (heard.isNotEmpty && heard.length >= lastVoiceText.length) {
          lastVoiceText = heard;
        }

        debugPrint('Health voice heard: $lastVoiceText');
      },
    );

    await Future.delayed(const Duration(seconds: 35));

    if (isListening) {
      await _finishVoiceListening();
    }
  }

  Future<void> _finishVoiceListening() async {
    if (!isListening) return;

    await _speech.stop();

    if (mounted) {
      setState(() {
        isListening = false;
      });
    }

    await _processSpokenHealthText();
  }

  Future<void> _processSpokenHealthText() async {
    final spokenText = lastVoiceText.trim();

    if (spokenText.isEmpty) {
      await _speak('لم أسمع القراءة، حاول مرة أخرى');
      return;
    }

    final filledCount = _fillControllersFromVoice(spokenText);

    if (!mounted) return;

    if (filledCount > 0) {
      _showSnack('تم تعبئة $filledCount قراءة بالصوت', color: green);
      await _speak('تم تعبئة القراءات التي سمعتها');
    } else {
      _showSnack(
        'لم أفهم الأرقام. قل مثلًا: نبضي 75، ضغطي 120 على 80، أكسجيني 98، حرارتي 37',
        color: warningColor,
      );
      await _speak('لم أفهم القراءات. حاول مرة أخرى بوضوح');
    }
  }

  int _fillControllersFromVoice(String input) {
    final text = _normalizeVoiceText(input);
    int filled = 0;

    final pressure = RegExp(
      r'(?:ضغط|ضغطي|الضغط)\s*(\d{2,3})\s*(?:على|علي|/|و|الى|إلى| )\s*(\d{2,3})',
    ).firstMatch(text);

    if (pressure != null) {
      systolicController.text = pressure.group(1)!;
      diastolicController.text = pressure.group(2)!;
      filled += 2;
    }

    final heartRate = _firstNumberAfterAny(text, [
      'نبضي',
      'نبض',
      'القلب',
      'دقات',
    ]);

    if (heartRate != null) {
      heartRateController.text = heartRate;
      filled++;
    }

    final glucose = _firstNumberAfterAny(text, [
      'سكري',
      'السكر',
      'سكر',
      'الجلوكوز',
    ]);

    if (glucose != null) {
      glucoseController.text = glucose;
      filled++;
    }

    final oxygen = _firstNumberAfterAny(text, [
      'نسبة الاكسجين',
      'نسبه الاكسجين',
      'الاكسجين',
      'اكسجين',
      'الأكسجين',
      'اوكسجين',
      'تشبع الاكسجين',
      'تشبع الأكسجين',
      'اكسجيني',
      'أكسجيني',
      'اوكسجيني',
    ]);

    if (oxygen != null) {
      oxygenController.text = oxygen;
      filled++;
    }

    final temperature = _firstNumberAfterAny(text, [
      'درجة الحرارة',
      'درجة الحراره',
      'حرارتي',
      'الحراره',
      'الحرارة',
      'حراره',
      'حرارة',
      'حرارته',
    ], allowDecimal: true);

    if (temperature != null) {
      temperatureController.text = temperature;
      filled++;
    }

    setState(() {});
    return filled;
  }

  String? _firstNumberAfterAny(
    String text,
    List<String> keywords, {
    bool allowDecimal = false,
  }) {
    final numberPattern = allowDecimal
        ? r'(\d{1,3}(?:[\.,]\d+)?)'
        : r'(\d{1,3})';

    for (final keyword in keywords) {
      final normalizedKeyword = _normalizeVoiceText(keyword);

      final pattern = RegExp(
        '$normalizedKeyword\\s+(?:[^\\d\\s]+\\s+){0,3}$numberPattern',
      );

      final match = pattern.firstMatch(text);

      if (match != null) {
        return match.group(1)!.replaceAll(',', '.');
      }
    }

    return null;
  }

  String _normalizeVoiceText(String text) {
    const arabicDigits = {
      '٠': '0',
      '١': '1',
      '٢': '2',
      '٣': '3',
      '٤': '4',
      '٥': '5',
      '٦': '6',
      '٧': '7',
      '٨': '8',
      '٩': '9',
    };

    var result = text.toLowerCase();

    arabicDigits.forEach((arabic, english) {
      result = result.replaceAll(arabic, english);
    });

    return result
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ى', 'ي')
        .replaceAll('ة', 'ه')
        .replaceAll('ؤ', 'و')
        .replaceAll('ئ', 'ي')
        .replaceAll(RegExp(r'[\u064B-\u065F]'), '')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: backgroundColor,
          elevation: 0,
          centerTitle: true,
          automaticallyImplyLeading: false,
          leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: dark,
              size: 26,
            ),
          ),
          title: const Text(
            'إضافة قراءة صحية',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: dark,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              fontFamily: 'Cairo',
            ),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'أدخل قراءاتك الصحية لليوم',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Cairo',
                      color: dark,
                      height: 1.3,
                    ),
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  'يمكنك إدخال القراءات يدوياً أو بالصوت',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Cairo',
                    color: secondaryTextColor,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 18),

                _voiceHealthInputCard(),

                const SizedBox(height: 24),

                _inputField(
                  controller: heartRateController,
                  label: 'نبض القلب',
                  hint: 'مثال: 75',
                ),

                const SizedBox(height: 16),

                _inputField(
                  controller: systolicController,
                  label: 'الضغط الانقباضي',
                  hint: 'مثال: 120',
                ),

                const SizedBox(height: 16),

                _inputField(
                  controller: diastolicController,
                  label: 'الضغط الانبساطي',
                  hint: 'مثال: 80',
                ),

                const SizedBox(height: 16),

                _inputField(
                  controller: glucoseController,
                  label: 'مستوى السكر',
                  hint: 'مثال: 100',
                ),

                const SizedBox(height: 16),

                _inputField(
                  controller: oxygenController,
                  label: 'نسبة الأكسجين',
                  hint: 'مثال: 98',
                ),

                const SizedBox(height: 16),

                _inputField(
                  controller: temperatureController,
                  label: 'درجة الحرارة',
                  hint: 'مثال: 37',
                ),

                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: ElevatedButton.icon(
                    onPressed: isLoading ? null : saveHealthData,
                    icon: isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.6,
                            ),
                          )
                        : const Icon(
                            Icons.check_circle,
                            color: Colors.white,
                            size: 28,
                          ),
                    label: Text(
                      isLoading ? 'جاري الحفظ...' : 'حفظ القراءة',
                      style: const TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Cairo',
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: green,
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: border, width: 1.4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.right,
        textInputAction: TextInputAction.next,
        style: const TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          fontFamily: 'Cairo',
          color: dark,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          labelStyle: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            fontFamily: 'Cairo',
            color: dark,
          ),
          hintStyle: const TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w600,
            fontFamily: 'Cairo',
            color: hintColor,
          ),
          filled: true,
          fillColor: fieldBg,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 22,
            horizontal: 20,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: const BorderSide(color: green, width: 2),
          ),
        ),
      ),
    );
  }
}
