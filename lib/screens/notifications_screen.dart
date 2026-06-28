import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_tts/flutter_tts.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const Color primaryColor = Color(0xFF1E3A5F);
  static const Color warningColor = Color(0xFFB42318);
  static const Color dangerColor = Color(0xFFD32F2F);
  static const Color backgroundColor = Color(0xFFF7F9FC);
  static const Color borderColor = Color(0xFFE5E7EB);

  final FlutterTts _tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _setupTts();
  }

  Future<void> _setupTts() async {
    await _tts.setLanguage('ar');
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> speakNotification({
    required String title,
    required String message,
    required String typeLabel,
  }) async {
    await _tts.stop();
    await _tts.speak('$typeLabel. $title. $message');
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  loadMyNotifications() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];

    final Map<String, QueryDocumentSnapshot<Map<String, dynamic>>> result = {};

    Future<void> addQuery(Query<Map<String, dynamic>> query) async {
      try {
        final snap = await query.get();

        for (final doc in snap.docs) {
          result[doc.id] = doc;
        }
      } catch (e) {
        debugPrint('Notifications query ignored: $e');
      }
    }

    await addQuery(
      FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: uid),
    );

    await addQuery(
      FirebaseFirestore.instance
          .collection('notifications')
          .where('patientId', isEqualTo: uid),
    );

    await addQuery(
      FirebaseFirestore.instance
          .collection('notifications')
          .where('recipientId', isEqualTo: uid),
    );

    final docs = result.values.toList();

    docs.sort((a, b) {
      final aTime = a.data()['createdAt'];
      final bTime = b.data()['createdAt'];

      if (aTime is Timestamp && bTime is Timestamp) {
        return bTime.compareTo(aTime);
      }

      return 0;
    });

    return docs;
  }

  IconData getIcon(String type) {
    switch (type) {
      case 'medication':
        return Icons.medication_outlined;
      case 'warning':
        return Icons.warning_amber_rounded;
      case 'allergy_warning':
        return Icons.health_and_safety_rounded;
      case 'sos':
        return Icons.sos;
      case 'appointment':
        return Icons.calendar_month_rounded;
      case 'task':
        return Icons.task_alt_rounded;
      case 'mood':
        return Icons.mood_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color getColor(String type) {
    switch (type) {
      case 'medication':
        return primaryColor;
      case 'warning':
        return warningColor;
      case 'allergy_warning':
        return dangerColor;
      case 'sos':
        return dangerColor;
      case 'appointment':
        return primaryColor;
      case 'task':
        return primaryColor;
      case 'mood':
        return primaryColor;
      default:
        return primaryColor;
    }
  }

  String getTypeLabel(String type) {
    switch (type) {
      case 'medication':
        return 'تنبيه دواء';
      case 'warning':
        return 'تنبيه صحي مهم';
      case 'allergy_warning':
        return 'تحذير حساسية دواء';
      case 'sos':
        return 'تنبيه طوارئ';
      case 'appointment':
        return 'تذكير موعد';
      case 'task':
        return 'مهمة يومية';
      case 'mood':
        return 'مزاج المريض';
      default:
        return 'تنبيه عام';
    }
  }

  String formatDate(dynamic timestamp) {
    if (timestamp == null || timestamp is! Timestamp) return '';

    final date = timestamp.toDate();

    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String formatTime(dynamic timestamp) {
    if (timestamp == null || timestamp is! Timestamp) return '';

    final DateTime date = timestamp.toDate();

    int hour = date.hour;
    final int minute = date.minute;
    final String period = hour >= 12 ? 'مساءً' : 'صباحًا';

    if (hour > 12) hour -= 12;
    if (hour == 0) hour = 12;

    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }

  void openRelatedScreen(BuildContext context, String type) {
    if (type == 'medication') {
      Navigator.pushNamed(context, '/medication-list');
    } else if (type == 'warning' || type == 'allergy_warning') {
      Navigator.pushNamed(context, '/health-monitoring');
    } else if (type == 'sos') {
      Navigator.pushNamed(context, '/sos');
    }
  }

  Widget _introCard(int count) {
    return const Text(
      'تابع هنا تنبيهات الأدوية، التنبيهات الصحية، والطوارئ المهمة.',
      textAlign: TextAlign.right,
      textDirection: TextDirection.rtl,
      style: TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w800,
        color: Colors.black,
        fontFamily: 'Cairo',
        height: 1.6,
      ),
    );
  }

  Widget _emptyNotificationsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: const Text(
        'لا توجد تنبيهات حاليًا',
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w900,
          color: Colors.black,
          fontFamily: 'Cairo',
          height: 1.5,
        ),
      ),
    );
  }

  String cleanAiText(String text) {
    return text
        .replaceAll('بواسطة AI', '')
        .replaceAll('بواسطة Ai', '')
        .replaceAll('بواسطة ai', '')
        .replaceAll('بواسطة الذكاء الاصطناعي', '')
        .replaceAll('بواسطة ذكاء اصطناعي', '')
        .replaceAll('/ AI', '')
        .replaceAll('AI', '')
        .replaceAll('Ai', '')
        .replaceAll('ai', '')
        .replaceAll('ذكاء اصطناعي', '')
        .replaceAll('الذكاء الاصطناعي', '')
        .replaceAll('بواسطة', '')
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
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: primaryColor,
              size: 28,
            ),
          ),
          title: const Text(
            'التنبيهات',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.black,
              fontFamily: 'Cairo',
              height: 1.3,
            ),
          ),
        ),
        body: FutureBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
          future: loadMyNotifications(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: primaryColor),
              );
            }

            if (snapshot.hasError) {
              return const Center(
                child: Text(
                  'حدث خطأ أثناء تحميل التنبيهات',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                    fontFamily: 'Cairo',
                  ),
                ),
              );
            }

            final notifications = snapshot.data ?? [];

            return RefreshIndicator(
              onRefresh: () async => setState(() {}),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _introCard(notifications.length),

                  const SizedBox(height: 18),

                  if (notifications.isEmpty)
                    _emptyNotificationsCard()
                  else
                    ...notifications.map((notification) {
                      final data = notification.data();

                      final String type = (data['type'] ?? 'general')
                          .toString();
                      final createdAt = data['createdAt'];

                      final String title = cleanAiText(
                        (data['title'] ?? 'تنبيه').toString(),
                      );

                      final String message = cleanAiText(
                        (data['message'] ?? '').toString(),
                      );

                      final String rawTime = (data['time'] ?? '')
                          .toString()
                          .trim();

                      final bool invalidTime =
                          rawTime.isEmpty ||
                          rawTime == 'تنبيه' ||
                          rawTime == 'طوارئ' ||
                          rawTime == 'تحذير' ||
                          rawTime == 'SOS' ||
                          rawTime.toLowerCase() == 'sos';

                      final String clock = invalidTime
                          ? formatTime(createdAt)
                          : rawTime;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: () => openRelatedScreen(context, type),
                          child: NotificationCard(
                            title: title,
                            message: message,
                            typeLabel: getTypeLabel(type),
                            date: formatDate(createdAt),
                            clock: clock,
                            type: type,
                            icon: getIcon(type),
                            color: getColor(type),
                            onSpeak: () => speakNotification(
                              title: title,
                              message: message,
                              typeLabel: getTypeLabel(type),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class NotificationCard extends StatelessWidget {
  final String title;
  final String message;
  final String typeLabel;
  final String date;
  final String clock;
  final String type;
  final IconData icon;
  final Color color;
  final VoidCallback? onSpeak;

  const NotificationCard({
    super.key,
    required this.title,
    required this.message,
    required this.typeLabel,
    required this.date,
    required this.clock,
    required this.type,
    required this.icon,
    required this.color,
    this.onSpeak,
  });

  bool get isEmergency => type == 'sos' || type == 'allergy_warning';

  @override
  Widget build(BuildContext context) {
    final Color cardColor = isEmergency
        ? const Color(0xFFFFF1F1)
        : Colors.white;

    final Color miniBgColor = isEmergency
        ? const Color(0xFFFFE8E8)
        : const Color(0xFFF7F9FC);

    final Color infoColor = isEmergency ? color : const Color(0xFF1E3A5F);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isEmergency
              ? color.withOpacity(0.25)
              : const Color(0xFFE5E7EB),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      typeLabel,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: color,
                        fontFamily: 'Cairo',
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: IconButton(
                  tooltip: 'قراءة التنبيه صوتياً',
                  onPressed: onSpeak,
                  icon: Icon(Icons.volume_up_rounded, color: color, size: 28),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Text(
            title,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Colors.black,
              fontFamily: 'Cairo',
              height: 1.3,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            message,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.black,
              height: 1.7,
              fontFamily: 'Cairo',
            ),
          ),

          const SizedBox(height: 16),

          _miniInfo(
            Icons.calendar_month_rounded,
            "التاريخ: ${date.isEmpty ? 'بدون تاريخ' : date}",
            miniBgColor,
            infoColor,
          ),

          const SizedBox(height: 8),

          _miniInfo(
            Icons.access_time_rounded,
            "الوقت: ${clock.isEmpty ? 'بدون وقت' : clock}",
            miniBgColor,
            infoColor,
          ),
        ],
      ),
    );
  }

  Widget _miniInfo(IconData icon, String text, Color bgColor, Color infoColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.1),
      ),
      child: Row(
        children: [
          Icon(icon, size: 23, color: infoColor),

          const SizedBox(width: 8),

          Expanded(
            child: Text(
              text,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: infoColor,
                fontFamily: 'Cairo',
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
