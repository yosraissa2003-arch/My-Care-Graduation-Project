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
  static const Color warningColor = Color(0xFFED6C02);
  static const Color dangerColor = Color(0xFFD32F2F);
  static const Color backgroundColor = Color(0xFFF7F8FA);

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

    // للمريض الحالي فقط: تنبيهات تخص حسابه أو هو المستلم لها.
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
      if (aTime is Timestamp && bTime is Timestamp)
        return bTime.compareTo(aTime);
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
      default:
        return primaryColor;
    }
  }

  String getTypeLabel(String type) {
    switch (type) {
      case 'medication':
        return 'تنبيه دواء';
      case 'warning':
        return 'تنبيه صحي / AI';
      case 'allergy_warning':
        return 'تحذير حساسية دواء';
      case 'sos':
        return 'تنبيه طوارئ';
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
          title: const Text(
            'التنبيهات',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.black,
              fontFamily: 'Cairo',
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
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                    fontFamily: 'Cairo',
                  ),
                ),
              );
            }

            final notifications = snapshot.data ?? [];

            if (notifications.isEmpty) {
              return const Center(
                child: Text(
                  'لا توجد تنبيهات حاليًا',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                    fontFamily: 'Cairo',
                  ),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async => setState(() {}),
              child: ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: notifications.length,
                separatorBuilder: (_, _) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final data = notifications[index].data();
                  final String type = (data['type'] ?? 'general').toString();
                  final createdAt = data['createdAt'];

                  return InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () => openRelatedScreen(context, type),
                    child: NotificationCard(
                      title: (data['title'] ?? 'تنبيه').toString(),
                      message: (data['message'] ?? '').toString(),
                      typeLabel: getTypeLabel(type),
                      date: formatDate(createdAt),
                      clock:
                          (data['time'] ?? '').toString().isNotEmpty &&
                              data['time'].toString() != 'تنبيه'
                          ? data['time'].toString()
                          : formatTime(createdAt),
                      type: type,
                      icon: getIcon(type),
                      color: getColor(type),
                      onSpeak: () => speakNotification(
                        title: (data['title'] ?? 'تنبيه').toString(),
                        message: (data['message'] ?? '').toString(),
                        typeLabel: getTypeLabel(type),
                      ),
                    ),
                  );
                },
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 10),
          IconButton(
            tooltip: 'قراءة التنبيه صوتياً',
            onPressed: onSpeak,
            icon: Icon(Icons.volume_up_rounded, color: color, size: 30),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  typeLabel,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: color,
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  title,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                    height: 1.5,
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _miniInfo(
                      Icons.calendar_month_rounded,
                      date.isEmpty ? 'بدون تاريخ' : date,
                    ),
                    _miniInfo(
                      Icons.access_time_rounded,
                      clock.isEmpty ? 'بدون ساعة' : clock,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniInfo(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: color,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }
}
