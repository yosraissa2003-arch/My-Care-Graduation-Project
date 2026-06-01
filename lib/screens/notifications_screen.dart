import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  IconData getIcon(String type) {
    switch (type) {
      case 'medication':
        return Icons.medication_outlined;
      case 'warning':
        return Icons.warning_amber_rounded;
      case 'sos':
        return Icons.sos;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color getColor(String type) {
    switch (type) {
      case 'medication':
        return const Color(0xFF1E3A5F);
      case 'warning':
        return const Color(0xFFED6C02);
      case 'sos':
        return const Color(0xFFD32F2F);
      default:
        return const Color(0xFF1E3A5F);
    }
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
          .where('caregiverId', isEqualTo: uid),
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

  void openRelatedScreen(BuildContext context, String type) {
    if (type == 'medication') {
      Navigator.pushNamed(context, '/medication-list');
    } else if (type == 'warning') {
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
        backgroundColor: const Color(0xFFF7F8FA),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF7F8FA),
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'التنبيهات',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
        ),
        body: FutureBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
          future: loadMyNotifications(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF1E3A5F)),
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

                  return InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () => openRelatedScreen(context, type),
                    child: NotificationCard(
                      title: (data['title'] ?? 'تنبيه').toString(),
                      message: (data['message'] ?? '').toString(),
                      time: (data['time'] ?? formatTime(data['createdAt']))
                          .toString(),
                      type: type,
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
  final String time;
  final String type;

  const NotificationCard({
    super.key,
    required this.title,
    required this.message,
    required this.time,
    required this.type,
  });

  IconData getIcon() {
    switch (type) {
      case 'medication':
        return Icons.medication_outlined;
      case 'warning':
        return Icons.warning_amber_rounded;
      case 'sos':
        return Icons.sos;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color getColor() {
    switch (type) {
      case 'medication':
        return const Color(0xFF1E3A5F);
      case 'warning':
        return const Color(0xFFED6C02);
      case 'sos':
        return const Color(0xFFD32F2F);
      default:
        return const Color(0xFF1E3A5F);
    }
  }

  String getTypeLabel() {
    switch (type) {
      case 'medication':
        return 'تنبيه دواء';
      case 'warning':
        return 'تنبيه صحي / AI';
      case 'sos':
        return 'تنبيه طوارئ';
      default:
        return 'تنبيه عام';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = getColor();

    return Container(
      padding: const EdgeInsets.all(20),
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
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(getIcon(), color: color, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  getTypeLabel(),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  title,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  time,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
