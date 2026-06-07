import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/care_timeline_service.dart';

class CareTimelineScreen extends StatelessWidget {
  const CareTimelineScreen({super.key});

  static const Color dark = Color(0xff172638);
  static const Color background = Color(0xFFF7F8FA);
  static const Color border = Color(0xffE5E5E5);

  IconData _iconFor(String type) {
    switch (type) {
      case 'medication':
        return Icons.medication_rounded;
      case 'health':
        return Icons.monitor_heart_rounded;
      case 'warning':
        return Icons.warning_amber_rounded;
      case 'sos':
        return Icons.sos_rounded;
      case 'appointment':
        return Icons.calendar_month_rounded;
      case 'mood':
        return Icons.mood_rounded;
      case 'task':
        return Icons.task_alt_rounded;
      default:
        return Icons.timeline_rounded;
    }
  }

  Color _colorFor(String type) {
    switch (type) {
      case 'medication':
        return const Color(0xffED6C02);
      case 'health':
        return const Color(0xff2E8B57);
      case 'warning':
      case 'sos':
        return Colors.red;
      case 'appointment':
        return const Color(0xff407C99);
      case 'mood':
        return const Color(0xff755BB5);
      case 'task':
        return const Color(0xff2E7D32);
      default:
        return dark;
    }
  }

  String _formatTime(dynamic value) {
    if (value is! Timestamp) return 'الآن';
    final date = value.toDate();
    int hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'مساءً' : 'صباحًا';
    if (hour > 12) hour -= 12;
    if (hour == 0) hour = 12;
    return '${hour.toString().padLeft(2, '0')}:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('يجب تسجيل الدخول أولاً')));
    }

    final uid = user.uid;
    final dateKey = CareTimelineService.todayKey();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          backgroundColor: background,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'خط الرعاية اليومي',
            style: TextStyle(
              color: dark,
              fontSize: 30,
              fontWeight: FontWeight.w900,
              fontFamily: 'Cairo',
            ),
          ),
        ),
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('careTimeline')
              .where('userId', isEqualTo: uid)
              .where('dateKey', isEqualTo: dateKey)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: dark));
            }

            if (snapshot.hasError) {
              return const Center(
                child: Text(
                  'حدث خطأ أثناء تحميل خط الرعاية',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
              );
            }

            final docs = [...(snapshot.data?.docs ?? [])];

            docs.sort((a, b) {
              final aTime = a.data()['createdAt'];
              final bTime = b.data()['createdAt'];
              if (aTime is Timestamp && bTime is Timestamp) {
                return bTime.compareTo(aTime);
              }
              return 0;
            });

            if (docs.isEmpty) {
              return const Center(
                child: Text(
                  'لا توجد أحداث اليوم بعد',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: dark,
                    fontFamily: 'Cairo',
                  ),
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.all(18),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: border),
                  ),
                  child: Text(
                    'أحداث اليوم: ${docs.length}',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                      color: dark,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ...docs.map((doc) {
                  final data = doc.data();
                  final type = (data['type'] ?? 'general').toString();
                  final title = (data['title'] ?? 'حدث').toString();
                  final details = (data['details'] ?? '').toString();
                  final createdAt = data['createdAt'];
                  final color = _colorFor(type);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: border),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 31,
                          backgroundColor: color.withOpacity(0.12),
                          child: Icon(_iconFor(type), color: color, size: 35),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: dark,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                              if (details.isNotEmpty) ...[
                                const SizedBox(height: 5),
                                Text(
                                  details,
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black54,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                              ],
                              const SizedBox(height: 8),
                              Text(
                                _formatTime(createdAt),
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: color,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }
}
