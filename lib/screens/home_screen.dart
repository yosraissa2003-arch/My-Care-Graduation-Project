import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'medical_info_screen.dart';
import 'add_health_data_screen.dart';
import 'health_history_reports_screen.dart';
import 'package:mycare/screens/notifications_screen.dart';
import 'package:mycare/screens/medication_list_screen.dart';

import 'profile_settings_screen.dart';
import 'daily_tasks_screen.dart';
import 'appointments_screen.dart';
import 'care_timeline_screen.dart';
import 'mood_history_screen.dart';
import '../services/care_timeline_service.dart';
import '../widgets/nearby_medical_centers_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color primaryColor = Color(0xFF1E3A5F);
  static const Color backgroundColor = Color(0xFFF7F8FA);
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color textColor = Color(0xFF1F2937);
  static const Color secondaryTextColor = Color(0xFF4B5563);
  static const Color successColor = Color(0xFF2E7D32);
  static const Color errorColor = Color(0xFFD32F2F);
  static const Color warningColor = Color(0xFFED6C02);

  static const Color softGreen = Color(0xffEEF8F1);
  static const Color softOrange = Color(0xffFFF7ED);
  static const Color softPurple = Color(0xffF7F3FF);
  static const Color softBlue = Color(0xffF1F8FC);
  static const Color borderColor = Color(0xffE6E6E6);

  late final stt.SpeechToText _speech = stt.SpeechToText();
  late final FlutterTts _tts = FlutterTts();

  bool _isListening = false;
  String _lastVoiceText = '';

  @override
  void initState() {
    super.initState();
    _setupVoice();
  }

  @override
  void dispose() {
    _speech.stop();
    _tts.stop();
    super.dispose();
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
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'لم يتم تسجيل الدخول',
            style: TextStyle(fontSize: 18, fontFamily: 'Cairo'),
          ),
        ),
      );
    }

    final uid = currentUser.uid;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: primaryColor),
              );
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(
                child: Text(
                  'لا توجد بيانات للمستخدم',
                  style: TextStyle(
                    fontSize: 18,
                    fontFamily: 'Cairo',
                    color: textColor,
                  ),
                ),
              );
            }

            final user = snapshot.data!.data()!;
            final role = (user['role'] ?? '').toString();

            if (role == 'مرافق' || role == 'معتني') {
              return _buildCaregiverHome(context, uid, user);
            }

            return _buildPatientHome(context, uid, user);
          },
        ),
        bottomNavigationBar: _bottomNavigation(context),
      ),
    );
  }

  Widget _buildPatientHome(
    BuildContext context,
    String uid,
    Map<String, dynamic> user,
  ) {
    final name = (user['fullName'] ?? user['name'] ?? 'المستخدم').toString();

    return SafeArea(
      child: Column(
        children: [
          _header(name: name),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _voiceAssistantCard(context, uid, user),

                  const SizedBox(height: 24),

                  _patientHealthStatus(uid),

                  const SizedBox(height: 24),

                  _sectionTitle('أدوية اليوم'),

                  const SizedBox(height: 16),

                  _medicationsList(uid),

                  const SizedBox(height: 24),

                  _bigActionCard(
                    title: 'المعلومات الطبية',
                    icon: Icons.medical_information_outlined,
                    color: softOrange,
                    border: const Color(0xffF1DDC5),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MedicalInfoScreen(user: user),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  _sectionTitle('خدمات سريعة'),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: _serviceCard(
                          title: 'أدويتي',
                          icon: Icons.medication_liquid_rounded,
                          color: warningColor,
                          bgColor: const Color(0xffFFF1E7),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const MedicationListScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _serviceCard(
                          title: 'صحتي',
                          icon: Icons.monitor_heart_rounded,
                          color: successColor,
                          bgColor: softGreen,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AddHealthDataScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _serviceCard(
                          title: 'تقاريري',
                          icon: Icons.description_rounded,
                          color: const Color(0xff407C99),
                          bgColor: softBlue,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => HealthHistoryReportsScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  _smartDailyCareSection(context),

                  const SizedBox(height: 24),

                  const NearbyMedicalCentersSection(
                    title: 'أقرب المراكز الطبية',
                    limit: 5,
                  ),

                  const SizedBox(height: 24),

                  _sosButton(context, uid, user),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _smartDailyCareSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionTitle('رعاية يومية ذكية'),

        const SizedBox(height: 16),

        _moodQuickCard(context),

        const SizedBox(height: 14),

        Row(
          children: [
            Expanded(
              child: _smartFeatureCard(
                title: 'مهام اليوم',
                subtitle: 'ماء، مشي، سكر، دواء',
                icon: Icons.task_alt_rounded,
                color: successColor,
                bgColor: softGreen,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DailyTasksScreen()),
                  );
                },
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: _smartFeatureCard(
                title: 'مواعيدي',
                subtitle: 'موعد الطبيب',
                icon: Icons.calendar_month_rounded,
                color: warningColor,
                bgColor: softOrange,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AppointmentsScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        _smartFeatureCard(
          title: 'خط الرعاية اليومي',
          subtitle: 'كل أحداث اليوم في مكان واحد',
          icon: Icons.timeline_rounded,
          color: primaryColor,
          bgColor: softBlue,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CareTimelineScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _moodQuickCard(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(26),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MoodHistoryScreen()),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: softPurple,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: const Color(0xffE2DAF3), width: 1.2),
        ),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Center(
                child: Text('🙂', style: TextStyle(fontSize: 34)),
              ),
            ),

            const SizedBox(width: 14),

            const Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    'كيف تشعر اليوم؟',
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 23,
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w900,
                      color: textColor,
                      height: 1.3,
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(width: 10),

            Transform.scale(
              scaleX: -1,
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: primaryColor,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _smartFeatureCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 118),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: color.withOpacity(0.18)),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isSmallCard = constraints.maxWidth < 220;

            if (isSmallCard) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white,
                    child: Icon(icon, color: color, size: 32),
                  ),

                  const SizedBox(height: 10),

                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      title,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 23,
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w900,
                        color: textColor,
                        height: 1.25,
                      ),
                    ),
                  ),
                ],
              );
            }

            return Row(
              textDirection: TextDirection.rtl,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white,
                  child: Icon(icon, color: color, size: 32),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        title,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 20,
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w900,
                          color: textColor,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        subtitle,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 14,
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w700,
                          color: secondaryTextColor,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCaregiverHome(
    BuildContext context,
    String uid,
    Map<String, dynamic> user,
  ) {
    final name = (user['fullName'] ?? user['name'] ?? 'المعتني').toString();
    final caregiverPhone = (user['phone'] ?? '').toString();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(name: name),

            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'يمكنك متابعة المرضى المرتبطين بحسابك واستقبال التنبيهات الخاصة بهم.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontFamily: 'Cairo',
                  color: secondaryTextColor,
                  height: 1.5,
                ),
              ),
            ),

            const SizedBox(height: 24),

            const NearbyMedicalCentersSection(
              title: 'المراكز الطبية القريبة',
              limit: 5,
            ),

            const SizedBox(height: 24),

            _sectionTitle('المرضى المرتبطون'),

            const SizedBox(height: 16),

            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'مريض')
                  .where('linkedPhone', isEqualTo: caregiverPhone)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: primaryColor),
                  );
                }

                final patients = snapshot.data?.docs ?? [];

                if (patients.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'لا يوجد مرضى مرتبطون حاليًا.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontFamily: 'Cairo',
                        color: secondaryTextColor,
                      ),
                    ),
                  );
                }

                return Column(
                  children: patients.map((doc) {
                    return _patientCardForCaregiver(
                      context: context,
                      patientId: doc.id,
                      patient: doc.data(),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _voiceAssistantCard(
    BuildContext context,
    String uid,
    Map<String, dynamic> user,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xffEAF3FF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xffCFE1F7), width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 27,
                backgroundColor: Colors.white,
                child: Icon(
                  _isListening ? Icons.hearing_rounded : Icons.mic_rounded,
                  color: primaryColor,
                  size: 31,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  _isListening ? 'أنا أسمعك الآن...' : 'المساعد الصوتي',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 23,
                    fontFamily: 'Cairo',
                    color: textColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'قل مثلاً: افتح صحتي، افتح أدويتي، اقرأ حالتي، أو ساعدني.',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 18,
              fontFamily: 'Cairo',
              color: secondaryTextColor,
              height: 1.6,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: _isListening
                ? null
                : () => _startHomeVoiceCommand(context, uid, user),
            icon: Icon(
              _isListening ? Icons.hearing_rounded : Icons.mic_rounded,
              color: Colors.white,
              size: 30,
            ),
            label: Text(
              _isListening ? 'أسمعك الآن...' : 'اضغط وتكلم',
              style: const TextStyle(
                fontSize: 20,
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
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

  Future<void> _startHomeVoiceCommand(
    BuildContext context,
    String uid,
    Map<String, dynamic> user,
  ) async {
    final micStatus = await Permission.microphone.request();

    if (!micStatus.isGranted) {
      await _speak('يجب السماح باستخدام المايك حتى يعمل المساعد الصوتي');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'يجب السماح بصلاحية المايك',
              textAlign: TextAlign.right,
              style: TextStyle(fontFamily: 'Cairo'),
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

    _lastVoiceText = '';
    final localeId = await _bestArabicLocale();

    if (mounted) {
      setState(() {
        _isListening = true;
      });
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 3),
          content: Text(
            'أنا أسمع الآن... احكي: افتح صحتي أو روح على تقاريري أو افتح أدويتي',
            textAlign: TextAlign.right,
            style: TextStyle(fontFamily: 'Cairo'),
          ),
        ),
      );
    }

    await _tts.stop();
    await Future.delayed(const Duration(milliseconds: 300));

    await _speech.listen(
      localeId: localeId,
      listenFor: const Duration(seconds: 12),
      pauseFor: const Duration(seconds: 4),
      partialResults: true,
      onResult: (result) {
        _lastVoiceText = result.recognizedWords;
        debugPrint('Home voice heard: $_lastVoiceText');
      },
    );

    await Future.delayed(const Duration(seconds: 12));
    await _speech.stop();

    if (mounted) {
      setState(() {
        _isListening = false;
      });
    }

    if (!context.mounted) return;

    final command = _lastVoiceText.trim();

    if (command.isEmpty) {
      await _speak('لم أسمع الأمر، حاولي مرة أخرى');
      return;
    }

    await _handleHomeVoiceCommand(context, uid, user, command);
  }

  Future<void> _handleHomeVoiceCommand(
    BuildContext context,
    String uid,
    Map<String, dynamic> user,
    String command,
  ) async {
    final text = _normalizeArabic(command);

    if (_containsAny(text, [
      'ادويتي',
      'ادويه',
      'الادويه',
      'الادوية',
      'دوائي',
      'دواء',
    ])) {
      await _speak('سأفتح صفحة أدويتي');
      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MedicationListScreen()),
      );
      return;
    }

    if (_containsAny(text, [
      'الساعه',
      'الساعة',
      'ساعة',
      'سمارت',
      'واتش',
      'watch',
    ])) {
      await _speak('سأفتح صفحة استيراد القراءات من الساعة');
      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const AddHealthDataScreen(autoImportFromWatch: true),
        ),
      );
      return;
    }

    if (_containsAny(text, [
      'صحتي',
      'قراءه',
      'قراءة',
      'سجل قراءه',
      'سجل قراءة',
      'قياس',
    ])) {
      await _speak('سأفتح صفحة إضافة قراءة صحية');
      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AddHealthDataScreen()),
      );
      return;
    }

    if (_containsAny(text, ['تقريري', 'تقاريري', 'التقارير', 'تقرير'])) {
      await _speak('سأفتح صفحة التقارير الصحية');
      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => HealthHistoryReportsScreen()),
      );
      return;
    }

    if (_containsAny(text, ['تنبيهات', 'التنبيهات', 'اشعارات', 'الاشعارات'])) {
      await _speak('سأفتح صفحة التنبيهات');
      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const NotificationsScreen()),
      );
      return;
    }

    if (_containsAny(text, [
      'معلومات',
      'المعلومات الطبيه',
      'المعلومات الطبية',
      'ملفي',
      'الملف الطبي',
    ])) {
      await _speak('سأفتح المعلومات الطبية');
      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => MedicalInfoScreen(user: user)),
      );
      return;
    }

    if (_containsAny(text, [
      'اقرا حالتي',
      'اقرأ حالتي',
      'الحاله الصحيه',
      'الحالة الصحية',
      'حالتي',
    ])) {
      await _speakLatestHealthStatus(uid);
      return;
    }

    if (_containsAny(text, ['ساعدني', 'طوارئ', 'اس او اس', 'sos'])) {
      await _confirmAndSendSos(context, uid, user);
      return;
    }

    if (_containsAny(text, [
      'مهام',
      'مهامي',
      'مهام اليوم',
      'اشرب ماء',
      'مهمه',
      'مهمة',
    ])) {
      await _speak('سأفتح صفحة مهام اليوم');
      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DailyTasksScreen()),
      );
      return;
    }

    if (_containsAny(text, ['موعد', 'مواعيد', 'مواعيدي', 'طبيب', 'دكتور'])) {
      await _speak('سأفتح صفحة المواعيد');
      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AppointmentsScreen()),
      );
      return;
    }

    if (_containsAny(text, [
      'تايم لاين',
      'التايم لاين',
      'خط الرعايه',
      'خط الرعاية',
      'احداث اليوم',
      'أحداث اليوم',
    ])) {
      await _speak('سأفتح خط الرعاية اليومي');
      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CareTimelineScreen()),
      );
      return;
    }

    if (_containsAny(text, [
      'مزاج',
      'مزاجي',
      'شعوري',
      'كيف اشعر',
      'كيف أشعر',
    ])) {
      await _speak('سأفتح صفحة المزاج');
      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MoodHistoryScreen()),
      );
      return;
    }

    await _speak(
      'لم أسمع الأمر بوضوح. قل مثلًا: افتح صحتي، افتح أدويتي، اقرأ حالتي، أو ساعدني.',
    );
  }

  Future<void> _speakLatestHealthStatus(String uid) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('healthLogs')
          .where('userId', isEqualTo: uid)
          .get();

      final docs = [...snapshot.docs];

      if (docs.isEmpty) {
        await _speak('لا توجد قراءات صحية بعد');
        return;
      }

      docs.sort((a, b) {
        final aTime = a.data()['createdAt'];
        final bTime = b.data()['createdAt'];
        if (aTime is Timestamp && bTime is Timestamp) {
          return bTime.compareTo(aTime);
        }
        return 0;
      });

      final health = docs.first.data();

      final heartRate = _toInt(health['heartRate']);
      final systolic = _toInt(health['bloodPressureSystolic']);
      final diastolic = _toInt(health['bloodPressureDiastolic']);
      final glucose = _toInt(health['glucose'] ?? health['sugar']);
      final oxygen = _toInt(health['oxygen']);
      final temperature = (health['temperature'] ?? 'غير مسجلة').toString();

      final status = getHealthStatus(
        heartRate: heartRate,
        systolic: systolic,
        diastolic: diastolic,
        glucose: glucose,
      );

      await _speak(
        'الحالة الصحية $status. النبض $heartRate. الضغط $systolic على $diastolic. السكر $glucose. الأكسجين $oxygen. الحرارة $temperature.',
      );
    } catch (_) {
      await _speak('تعذر قراءة الحالة الصحية الآن');
    }
  }

  Future<void> _confirmAndSendSos(
    BuildContext context,
    String uid,
    Map<String, dynamic> user,
  ) async {
    await _speak('هل تريدين إرسال تنبيه طوارئ للمرافق؟');

    if (!context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text(
              'تأكيد الطوارئ',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
              ),
            ),
            content: const Text(
              'هل تريدين إرسال تنبيه SOS للمرافق الآن؟',
              style: TextStyle(fontFamily: 'Cairo', fontSize: 18),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text(
                  'إلغاء',
                  style: TextStyle(fontFamily: 'Cairo'),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                style: ElevatedButton.styleFrom(backgroundColor: errorColor),
                child: const Text(
                  'إرسال SOS',
                  style: TextStyle(fontFamily: 'Cairo', color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (confirmed == true) {
      await _sendSosAlert(context, uid, user);
    } else {
      await _speak('تم إلغاء تنبيه الطوارئ');
    }
  }

  Future<void> _sendSosAlert(
    BuildContext context,
    String uid,
    Map<String, dynamic> user,
  ) async {
    final patientName = (user['fullName'] ?? user['name'] ?? 'المريض')
        .toString();
    final emergencyPhone = (user['emergencyContact'] ?? '').toString();

    String caregiverId = '';
    final linkedCaregiverPhone =
        (user['linkedPhone'] ??
                user['linkedPatientPhone'] ??
                user['linkedPhoneNumber'] ??
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

    final position = await _getCurrentPosition(context);
    final hasLocation = position != null;

    await FirebaseFirestore.instance.collection('sosAlerts').add({
      'userId': uid,
      'patientId': uid,
      'caregiverId': caregiverId,
      'linkedCaregiverPhone': linkedCaregiverPhone,
      'patientName': patientName,
      'patientPhone': user['phone'] ?? '',
      'emergencyPhone': emergencyPhone,
      'source': 'voice',
      'status': 'active',
      'message': 'المريض $patientName يحتاج مساعدة فورية',
      'locationAvailable': hasLocation,
      'latitude': position?.latitude,
      'longitude': position?.longitude,
      'location': hasLocation
          ? {'latitude': position.latitude, 'longitude': position.longitude}
          : null,
      'createdAt': Timestamp.now(),
    });

    if (position != null) {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'lastLatitude': position.latitude,
        'lastLongitude': position.longitude,
        'lastLocation': {
          'latitude': position.latitude,
          'longitude': position.longitude,
        },
        'lastLocationUpdatedAt': Timestamp.now(),
      }, SetOptions(merge: true));
    }

    await FirebaseFirestore.instance.collection('notifications').add({
      'userId': uid,
      'patientId': uid,
      'caregiverId': caregiverId,
      'recipientId': caregiverId,
      'patientName': patientName,
      'patientPhone': user['phone'] ?? '',
      'linkedCaregiverPhone': linkedCaregiverPhone,
      'title': 'تنبيه طوارئ SOS',
      'message': 'المريض $patientName يحتاج مساعدة فورية',
      'type': 'sos',
      'time': 'طوارئ',
      'isRead': false,
      'createdAt': Timestamp.now(),
    });

    await _speak(
      hasLocation
          ? 'تم إرسال تنبيه الطوارئ مع الموقع للمرافق'
          : 'تم إرسال تنبيه الطوارئ بدون موقع',
    );

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: hasLocation ? successColor : errorColor,
        content: Text(
          hasLocation
              ? 'تم إرسال SOS بالصوت مع الموقع للمرافق'
              : 'تم إرسال SOS بالصوت بدون موقع',
          textAlign: TextAlign.right,
          style: const TextStyle(fontSize: 18, fontFamily: 'Cairo'),
        ),
      ),
    );
  }

  bool _containsAny(String text, List<String> words) {
    return words.any((word) => text.contains(_normalizeArabic(word)));
  }

  String _normalizeArabic(String text) {
    return text
        .toLowerCase()
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

  Widget _header({required String name}) {
    final cleanName = name.trim();
    final firstName = cleanName.isEmpty
        ? 'المستخدم'
        : cleanName.split(RegExp(r'\s+')).first;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3FF),
        border: const Border(
          bottom: BorderSide(color: Color(0xFFCFE1F7), width: 1.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.045),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'أهلاً $firstName',
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 30,
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w900,
                    color: textColor,
                    height: 1.25,
                  ),
                ),

                const SizedBox(height: 5),

                const Text(
                  'نتمنى لك يوماً صحياً ومطمئناً',
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w800,
                    color: secondaryTextColor,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 14),

          const CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, size: 40, color: primaryColor),
          ),
        ],
      ),
    );
  }

  Widget _patientHealthStatus(String uid) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('healthLogs')
          .where('userId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: primaryColor),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return _emptyCard('لا توجد قراءات صحية بعد');
        }

        docs.sort((a, b) {
          final aTime = a.data()['createdAt'];
          final bTime = b.data()['createdAt'];

          if (aTime is Timestamp && bTime is Timestamp) {
            return bTime.compareTo(aTime);
          }

          return 0;
        });

        final health = docs.first.data();

        final heartRate = _toInt(health['heartRate']);
        final systolic = _toInt(health['bloodPressureSystolic']);
        final diastolic = _toInt(health['bloodPressureDiastolic']);
        final glucose = _toInt(health['glucose'] ?? health['sugar']);
        final oxygen = _toInt(health['oxygen']);
        final temperature = health['temperature']?.toString() ?? 'لا يوجد';

        final status = getHealthStatus(
          heartRate: heartRate,
          systolic: systolic,
          diastolic: diastolic,
          glucose: glucose,
        );

        final bool isDanger = status == 'خطر';
        final bool isWarning = status == 'تحتاج متابعة';

        final Color mainColor = isDanger
            ? errorColor
            : isWarning
            ? warningColor
            : successColor;

        final Color bgColor = isDanger
            ? const Color(0xFFFFF0F0)
            : isWarning
            ? const Color(0xFFFFF7ED)
            : softGreen;

        final Color border = isDanger
            ? const Color(0xFFFFC9C9)
            : isWarning
            ? const Color(0xFFF6D3B0)
            : const Color(0xffD9EBDD);

        final IconData icon = isDanger
            ? Icons.warning_amber_rounded
            : isWarning
            ? Icons.info_rounded
            : Icons.verified_user_rounded;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: border, width: 1.3),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                textDirection: TextDirection.rtl,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'الحالة الصحية',
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 25,
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w900,
                            color: textColor,
                            height: 1.3,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          status,
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 27,
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w900,
                            color: mainColor,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 14),

                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: mainColor.withOpacity(0.25),
                        width: 1.2,
                      ),
                    ),
                    child: Icon(icon, color: mainColor, size: 38),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Wrap(
                alignment: WrapAlignment.end,
                spacing: 10,
                runSpacing: 10,
                children: [
                  _healthValueBox('النبض', '$heartRate'),
                  _healthValueBox('الضغط', '$systolic/$diastolic'),
                  _healthValueBox('السكر', '$glucose'),
                  _healthValueBox('الأكسجين', '$oxygen'),
                  _healthValueBox('الحرارة', temperature),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _healthValueBox(String title, String value) {
    return Container(
      width: 130,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1.1),
      ),
      child: Column(
        children: [
          Text(
            title,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w800,
              color: secondaryTextColor,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            value,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 21,
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _medicationsList(String uid) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('medications')
          .where('userId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: primaryColor),
          );
        }

        if (snapshot.hasError) {
          return _emptyCard('حدث خطأ أثناء تحميل أدوية اليوم');
        }

        final meds = [...(snapshot.data?.docs ?? [])];

        meds.sort((a, b) {
          final aTime = a.data()['createdAt'];
          final bTime = b.data()['createdAt'];

          if (aTime is Timestamp && bTime is Timestamp) {
            return bTime.compareTo(aTime);
          }

          return 0;
        });

        if (meds.isEmpty) {
          return _emptyCard('لا توجد أدوية اليوم');
        }

        return Column(
          children: meds.map((doc) {
            final med = doc.data();
            final List times = med['times'] is List ? med['times'] : [];
            final timeText = times.isEmpty
                ? ((med['time'] ?? 'عند الحاجة').toString())
                : times.join('، ');

            return _medCard(
              docId: doc.id,
              name: (med['name'] ?? 'دواء').toString(),
              time: timeText,
              taken: _isMedicationTakenToday(med),
              allergyWarning: med['allergyWarning'] == true,
              allergyWarningMessage: (med['allergyWarningMessage'] ?? '')
                  .toString(),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _patientCardForCaregiver({
    required BuildContext context,
    required String patientId,
    required Map<String, dynamic> patient,
  }) {
    final name = (patient['fullName'] ?? patient['name'] ?? 'مريض').toString();
    final phone = (patient['phone'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 30,
                backgroundColor: softGreen,
                child: Icon(Icons.elderly, color: successColor, size: 34),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontFamily: 'Cairo',
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      phone,
                      style: const TextStyle(
                        fontSize: 16,
                        fontFamily: 'Cairo',
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('healthLogs')
                .where('userId', isEqualTo: patientId)
                .snapshots(),
            builder: (context, snapshot) {
              final logs = snapshot.data?.docs ?? [];

              if (logs.isEmpty) {
                return const Text(
                  'لا توجد قراءات صحية لهذا المريض',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Cairo',
                    color: secondaryTextColor,
                  ),
                );
              }

              logs.sort((a, b) {
                final aTime = a.data()['createdAt'];
                final bTime = b.data()['createdAt'];

                if (aTime is Timestamp && bTime is Timestamp) {
                  return bTime.compareTo(aTime);
                }

                return 0;
              });

              final health = logs.first.data();

              final heartRate = _toInt(health['heartRate']);
              final systolic = _toInt(health['bloodPressureSystolic']);
              final diastolic = _toInt(health['bloodPressureDiastolic']);
              final glucose = _toInt(health['glucose']);

              final status = getHealthStatus(
                heartRate: heartRate,
                systolic: systolic,
                diastolic: diastolic,
                glucose: glucose,
              );

              return Text(
                'الحالة: $status | النبض: $heartRate | الضغط: $systolic/$diastolic | السكر: $glucose',
                style: const TextStyle(
                  fontSize: 16,
                  fontFamily: 'Cairo',
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _caregiverTaskProgress(patientId),
        ],
      ),
    );
  }

  Widget _caregiverTaskProgress(String patientId) {
    final dateKey = CareTimelineService.todayKey();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('dailyTasks')
          .where('userId', isEqualTo: patientId)
          .where('dateKey', isEqualTo: dateKey)
          .snapshots(),
      builder: (context, snapshot) {
        final tasks = snapshot.data?.docs ?? [];

        if (tasks.isEmpty) {
          return const Text(
            'مهام اليوم: لم تُجهز بعد',
            style: TextStyle(
              fontSize: 16,
              fontFamily: 'Cairo',
              color: secondaryTextColor,
              fontWeight: FontWeight.w700,
            ),
          );
        }

        final done = tasks.where((doc) => doc.data()['isDone'] == true).length;

        return Text(
          'إنجاز مهام اليوم: $done من ${tasks.length}',
          style: const TextStyle(
            fontSize: 16,
            fontFamily: 'Cairo',
            color: successColor,
            fontWeight: FontWeight.w900,
          ),
        );
      },
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      textAlign: TextAlign.right,
      style: const TextStyle(
        fontSize: 22,
        fontFamily: 'Cairo',
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
    );
  }

  Widget _emptyCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 18,
          fontFamily: 'Cairo',
          color: secondaryTextColor,
        ),
      ),
    );
  }

  Widget _bigActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required Color border,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Icon(icon, color: primaryColor, size: 34),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),
            Transform.scale(
              scaleX: -1,
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: primaryColor,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _medCard({
    required String docId,
    required String name,
    required String time,
    required bool taken,
    bool allergyWarning = false,
    String allergyWarningMessage = '',
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: softPurple,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xffE2DAF3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.medication,
                  color: Color(0xff755BB5),
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (allergyWarning) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: warningColor),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: warningColor,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      allergyWarningMessage.isEmpty
                          ? 'تحذير حساسية: هذا الدواء قد لا يناسب المريض'
                          : allergyWarningMessage,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 15,
                        fontFamily: 'Cairo',
                        color: warningColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),

          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('medications')
                .doc(docId)
                .snapshots(),
            builder: (context, snapshot) {
              final medication = snapshot.data?.data();
              final currentTaken = medication == null
                  ? taken
                  : _isMedicationTakenToday(medication);

              return Align(
                alignment: Alignment.centerRight,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () async {
                    await FirebaseFirestore.instance
                        .collection('medications')
                        .doc(docId)
                        .update({
                          'isTaken': !currentTaken,
                          'taken': !currentTaken,
                          'takenAt': !currentTaken
                              ? FieldValue.serverTimestamp()
                              : null,
                          'lastTakenDateKey': !currentTaken ? _todayKey() : '',
                        });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      color: currentTaken
                          ? const Color(0xffE4F3E8)
                          : const Color(0xffFFE5E5),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          currentTaken
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: currentTaken ? successColor : errorColor,
                          size: 24,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          currentTaken ? 'تم أخذه' : 'لم يتم أخذه',
                          style: TextStyle(
                            color: currentTaken ? successColor : errorColor,
                            fontSize: 16,
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 14),

          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [_medMiniInfo(Icons.access_time_rounded, time)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _medMiniInfo(IconData icon, String text) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 155),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xffE2DAF3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: const Color(0xff755BB5)),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontFamily: 'Cairo',
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _serviceCard({
    required String title,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.18)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Position?> _getCurrentPosition(BuildContext context) async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: warningColor,
              content: Text(
                'يرجى تفعيل خدمة الموقع من الهاتف ثم اضغطي SOS مرة أخرى',
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 18, fontFamily: 'Cairo'),
              ),
            ),
          );
        }
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: warningColor,
              content: Text(
                'الموقع مرفوض نهائياً. فعّليه من إعدادات التطبيق',
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 18, fontFamily: 'Cairo'),
              ),
            ),
          );
        }
        await Geolocator.openAppSettings();
        return null;
      }

      if (permission == LocationPermission.denied) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: warningColor,
              content: Text(
                'لم يتم السماح بالموقع، سيتم إرسال SOS بدون موقع',
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 18, fontFamily: 'Cairo'),
              ),
            ),
          );
        }
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

  Widget _sosButton(
    BuildContext context,
    String uid,
    Map<String, dynamic> user,
  ) {
    return SizedBox(
      height: 72,
      child: ElevatedButton.icon(
        onPressed: () async {
          final patientName = (user['fullName'] ?? user['name'] ?? 'المريض')
              .toString();

          final emergencyPhone = (user['emergencyContact'] ?? '').toString();

          String caregiverId = '';
          final linkedCaregiverPhone =
              (user['linkedPhone'] ??
                      user['linkedPatientPhone'] ??
                      user['linkedPhoneNumber'] ??
                      '')
                  .toString();

          final possibleCaregiverPhones = <String>{
            if (linkedCaregiverPhone.trim().isNotEmpty)
              linkedCaregiverPhone.trim(),
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

          final position = await _getCurrentPosition(context);

          final hasLocation = position != null;

          await FirebaseFirestore.instance.collection('sosAlerts').add({
            'userId': uid,
            'patientId': uid,
            'caregiverId': caregiverId,
            'linkedCaregiverPhone': linkedCaregiverPhone,
            'patientName': patientName,
            'patientPhone': user['phone'] ?? '',
            'emergencyPhone': emergencyPhone,
            'source': 'manual',
            'status': 'active',
            'message': 'المريض $patientName يحتاج مساعدة فورية',
            'locationAvailable': hasLocation,
            'latitude': position?.latitude,
            'longitude': position?.longitude,
            'location': hasLocation
                ? {
                    'latitude': position.latitude,
                    'longitude': position.longitude,
                  }
                : null,
            'createdAt': Timestamp.now(),
          });

          await FirebaseFirestore.instance.collection('notifications').add({
            'userId': uid,
            'patientId': uid,
            'caregiverId': caregiverId,
            'recipientId': caregiverId,
            'patientName': patientName,
            'patientPhone': user['phone'] ?? '',
            'linkedCaregiverPhone': linkedCaregiverPhone,
            'title': 'تنبيه طوارئ SOS',
            'message': 'المريض $patientName يحتاج مساعدة فورية',
            'type': 'sos',
            'time': 'طوارئ',
            'isRead': false,
            'createdAt': Timestamp.now(),
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: hasLocation ? successColor : errorColor,
              content: Text(
                hasLocation
                    ? 'تم إرسال SOS مع الموقع للمرافق'
                    : 'تم إرسال SOS بدون موقع. فعّلي الموقع من إعدادات الهاتف',
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 18, fontFamily: 'Cairo'),
              ),
            ),
          );
        },
        icon: const Icon(
          Icons.phone_in_talk_rounded,
          color: Colors.white,
          size: 34,
        ),
        label: const Text(
          'طوارئ SOS',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: errorColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }

  Widget _bottomNavigation(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      decoration: BoxDecoration(
        color: cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 18,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(26),
          topRight: Radius.circular(26),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: 0,
        elevation: 0,
        backgroundColor: Colors.transparent,
        selectedItemColor: primaryColor,
        unselectedItemColor: secondaryTextColor,
        selectedFontSize: 13,
        unselectedFontSize: 12,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == 0) {
            return;
          }

          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddHealthDataScreen()),
            );
          }

          if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => HealthHistoryReportsScreen()),
            );
          }

          if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            );
          }

          if (index == 4) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileSettingsScreen()),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded, size: 30),
            label: 'الرئيسية',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.monitor_heart_rounded, size: 28),
            label: 'صحتي',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description_rounded, size: 28),
            label: 'تقاريري',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_active_outlined, size: 28),
            label: 'التنبيهات',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded, size: 28),
            label: 'حسابي',
          ),
        ],
      ),
    );
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  bool _isMedicationTakenToday(Map<String, dynamic> med) {
    final lastTakenDateKey = (med['lastTakenDateKey'] ?? '').toString();
    return (med['isTaken'] == true || med['taken'] == true) &&
        lastTakenDateKey == _todayKey();
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatTime(DateTime date) {
    int hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'مساءً' : 'صباحًا';
    if (hour > 12) hour -= 12;
    if (hour == 0) hour = 12;
    return '${hour.toString().padLeft(2, '0')}:$minute $period';
  }

  String getHealthStatus({
    required int heartRate,
    required int systolic,
    required int diastolic,
    required int glucose,
  }) {
    if (heartRate < 50 ||
        heartRate > 120 ||
        systolic >= 180 ||
        diastolic >= 120 ||
        glucose < 70 ||
        glucose > 250) {
      return 'خطر';
    }

    if (heartRate < 60 ||
        heartRate > 100 ||
        systolic >= 140 ||
        diastolic >= 90 ||
        glucose > 180) {
      return 'تحتاج متابعة';
    }

    return 'مستقرة';
  }
}
