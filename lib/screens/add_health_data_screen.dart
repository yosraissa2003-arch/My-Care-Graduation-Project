import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../services/notification_service.dart';

class AddHealthDataScreen extends StatefulWidget {
  const AddHealthDataScreen({super.key});

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

  static const Color dark = Color(0xff172638);
  static const Color green = Color(0xff2E8B57);
  static const Color border = Color(0xffD8D8D8);
  static const Color fieldBg = Color(0xffF8F8F8);

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'يجب تسجيل الدخول أولاً',
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
      return;
    }

    final uid = currentUser.uid;

    if (heartRateController.text.trim().isEmpty ||
        systolicController.text.trim().isEmpty ||
        diastolicController.text.trim().isEmpty ||
        glucoseController.text.trim().isEmpty ||
        oxygenController.text.trim().isEmpty ||
        temperatureController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'الرجاء تعبئة جميع الحقول',
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تأكدي أن جميع القيم أرقام صحيحة',
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
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
        'createdAt': Timestamp.now(),
      };

      await FirebaseFirestore.instance.collection('healthLogs').add(healthData);

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'lastHealthReading': healthData,
        'lastAiStatus': aiResult['status'],
        'lastAiMessage': aiResult['message'],
        'lastReadingAt': Timestamp.now(),
      }, SetOptions(merge: true));

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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: green,
          content: Text(
            remindersScheduled
                ? 'تم الحفظ - الحالة: ${aiResult['status']}\nتم تفعيل تذكير 8 صباحاً و8 مساءً'
                : 'تم الحفظ - الحالة: ${aiResult['status']}',
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'حدث خطأ أثناء حفظ القراءة',
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
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
        color: const Color(0xffEAF3FF),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xffCFE1F7), width: 1.4),
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
                  color: dark,
                  size: 32,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  isListening
                      ? 'أنا أسمع... احكي كل القراءات ثم اضغطي إيقاف'
                      : 'إدخال القراءة بالصوت',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: dark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'اضغطي واحكي مثلًا: نبضي 75، ضغطي 120 على 80، سكري 100، الأكسجين 98، الحرارة 37.',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xff4B5563),
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
              size: 30,
            ),
            label: Text(
              isListening ? 'إيقاف وإدخال القراءات' : 'اضغطي واحكي القراءات',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: dark,
              minimumSize: const Size(double.infinity, 58),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'يجب السماح بصلاحية المايك',
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 18),
            ),
          ),
        );
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 5),
          content: Text(
            'أنا أسمع الآن... احكي كل القراءات، ولما تخلصي اضغطي زر إيقاف وإدخال القراءات',
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: 17),
          ),
        ),
      );
    }

    await _speech.listen(
      localeId: localeId,
      listenFor: const Duration(seconds: 45),
      pauseFor: const Duration(seconds: 10),
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

    // لو المستخدم ما ضغط إيقاف، نعطيه وقت طويل وبعدين نعالج الكلام تلقائيًا.
    await Future.delayed(const Duration(seconds: 45));
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
      await _speak('لم أسمع القراءة، حاولي مرة أخرى');
      return;
    }

    final filledCount = _fillControllersFromVoice(spokenText);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: filledCount > 0 ? green : Colors.orange,
        content: Text(
          filledCount > 0
              ? 'تم تعبئة $filledCount قراءة بالصوت'
              : 'لم أفهم الأرقام، حاولي قول: نبضي 75، ضغطي 120 على 80، سكري 100',
          textAlign: TextAlign.right,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );

    if (filledCount > 0) {
      await _speak('تم تعبئة القراءات التي سمعتها');
    } else {
      await _speak('لم أفهم القراءات. حاولي مرة أخرى بوضوح');
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
      'الاكسجين',
      'اكسجين',
      'الأكسجين',
      'اوكسجين',
    ]);

    if (oxygen != null) {
      oxygenController.text = oxygen;
      filled++;
    }

    final temperature = _firstNumberAfterAny(text, [
      'حرارتي',
      'الحراره',
      'الحرارة',
      'حراره',
      'حرارة',
      'درجة الحراره',
      'درجة الحرارة',
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
    for (final keyword in keywords) {
      final normalizedKeyword = _normalizeVoiceText(keyword);
      final pattern = allowDecimal
          ? RegExp('$normalizedKeyword\\s*(\\d{1,3}(?:[\\.,]\\d+)?)')
          : RegExp('$normalizedKeyword\\s*(\\d{1,3})');

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
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
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
              size: 28,
            ),
          ),
          title: const Text(
            'إضافة قراءة صحية',
            style: TextStyle(
              color: dark,
              fontSize: 34,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'سيتم حفظ القراءة بتاريخ اليوم',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: dark,
                ),
              ),
              const SizedBox(height: 18),
              _voiceHealthInputCard(),
              const SizedBox(height: 28),
              _inputField(
                controller: heartRateController,
                label: 'نبض القلب',
                hint: 'مثال: 75',
              ),
              const SizedBox(height: 18),
              _inputField(
                controller: systolicController,
                label: 'الضغط الانقباضي',
                hint: 'مثال: 120',
              ),
              const SizedBox(height: 18),
              _inputField(
                controller: diastolicController,
                label: 'الضغط الانبساطي',
                hint: 'مثال: 80',
              ),
              const SizedBox(height: 18),
              _inputField(
                controller: glucoseController,
                label: 'مستوى السكر',
                hint: 'مثال: 100',
              ),
              const SizedBox(height: 18),
              _inputField(
                controller: oxygenController,
                label: 'نسبة الأكسجين',
                hint: 'مثال: 98',
              ),
              const SizedBox(height: 18),
              _inputField(
                controller: temperatureController,
                label: 'درجة الحرارة',
                hint: 'مثال: 37',
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : saveHealthData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: green,
                    minimumSize: const Size(double.infinity, 76),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'حفظ القراءة',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
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
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textAlign: TextAlign.right,
      style: const TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w900,
        color: dark,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        labelStyle: const TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w900,
          color: dark,
        ),
        hintStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w500,
          color: dark.withOpacity(0.35),
        ),
        filled: true,
        fillColor: fieldBg,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 32,
          horizontal: 24,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: border, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: border, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: green, width: 3),
        ),
      ),
    );
  }
}
