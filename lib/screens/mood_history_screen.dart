import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/care_timeline_service.dart';

class MoodHistoryScreen extends StatefulWidget {
  const MoodHistoryScreen({super.key});

  @override
  State<MoodHistoryScreen> createState() => _MoodHistoryScreenState();
}

class _MoodHistoryScreenState extends State<MoodHistoryScreen> {
  static const Color dark = Color(0xff172638);
  static const Color background = Color(0xFFF7F8FA);
  static const Color border = Color(0xffE5E5E5);

  Future<void> _saveMood({
    required String uid,
    required String mood,
    required String label,
    required String emoji,
  }) async {
    final dateKey = CareTimelineService.todayKey();

    final existing = await FirebaseFirestore.instance
        .collection('moodLogs')
        .where('userId', isEqualTo: uid)
        .where('dateKey', isEqualTo: dateKey)
        .limit(1)
        .get();

    if (existing.docs.isEmpty) {
      await FirebaseFirestore.instance.collection('moodLogs').add({
        'userId': uid,
        'patientId': uid,
        'mood': mood,
        'moodLabel': label,
        'emoji': emoji,
        'dateKey': dateKey,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      await FirebaseFirestore.instance
          .collection('moodLogs')
          .doc(existing.docs.first.id)
          .update({
        'mood': mood,
        'moodLabel': label,
        'emoji': emoji,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await CareTimelineService.addEvent(
      userId: uid,
      type: 'mood',
      title: 'تم تسجيل مزاج المريض',
      details: '$emoji $label',
    );

    await CareTimelineService.updateLastActivity(uid);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: dark,
        content: Text(
          'تم تسجيل المزاج: $label',
          textAlign: TextAlign.right,
          style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  String _formatDate(dynamic value) {
    if (value is! Timestamp) return '';
    final date = value.toDate();
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('يجب تسجيل الدخول أولاً')));
    }

    final uid = user.uid;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          backgroundColor: background,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'مزاجي',
            style: TextStyle(
              color: dark,
              fontSize: 30,
              fontWeight: FontWeight.w900,
              fontFamily: 'Cairo',
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: border),
              ),
              child: Column(
                children: [
                  const Text(
                    'كيف تشعر اليوم؟',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.w900,
                      color: dark,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _moodButton(
                          uid: uid,
                          emoji: '🙂',
                          label: 'جيد',
                          mood: 'good',
                          color: const Color(0xff2E8B57),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _moodButton(
                          uid: uid,
                          emoji: '😐',
                          label: 'متعب',
                          mood: 'tired',
                          color: const Color(0xffED6C02),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _moodButton(
                          uid: uid,
                          emoji: '😢',
                          label: 'حزين',
                          mood: 'sad',
                          color: const Color(0xffD32F2F),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'سجل المزاج',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w900,
                color: dark,
                fontFamily: 'Cairo',
              ),
            ),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('moodLogs')
                  .where('userId', isEqualTo: uid)
                  .snapshots(),
              builder: (context, snapshot) {
                final docs = [...(snapshot.data?.docs ?? [])];

                docs.sort((a, b) {
                  final aTime = a.data()['createdAt'] ?? a.data()['updatedAt'];
                  final bTime = b.data()['createdAt'] ?? b.data()['updatedAt'];
                  if (aTime is Timestamp && bTime is Timestamp) {
                    return bTime.compareTo(aTime);
                  }
                  return 0;
                });

                final recent = docs.take(7).toList();

                if (snapshot.connectionState == ConnectionState.waiting && recent.isEmpty) {
                  return const Center(child: CircularProgressIndicator(color: dark));
                }

                if (recent.isEmpty) {
                  return const Text(
                    'لا توجد تسجيلات مزاج بعد',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.black54,
                      fontFamily: 'Cairo',
                    ),
                  );
                }

                final good = recent.where((doc) => doc.data()['mood'] == 'good').length;
                final tired = recent.where((doc) => doc.data()['mood'] == 'tired').length;
                final sad = recent.where((doc) => doc.data()['mood'] == 'sad').length;

                return Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xffF7F3FF),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: border),
                      ),
                      child: Text(
                        'آخر ${recent.length} أيام: جيد $good • متعب $tired • حزين $sad',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          color: dark,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...recent.map((doc) {
                      final data = doc.data();
                      final emoji = (data['emoji'] ?? '').toString();
                      final label = (data['moodLabel'] ?? '').toString();
                      final createdAt = data['createdAt'] ?? data['updatedAt'];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: border),
                        ),
                        child: Row(
                          children: [
                            Text(emoji, style: const TextStyle(fontSize: 30)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '$label  •  ${_formatDate(createdAt)}',
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w900,
                                  color: dark,
                                  fontFamily: 'Cairo',
                                ),
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
          ],
        ),
      ),
    );
  }

  Widget _moodButton({
    required String uid,
    required String emoji,
    required String label,
    required String mood,
    required Color color,
  }) {
    return InkWell(
      onTap: () => _saveMood(uid: uid, mood: mood, label: label, emoji: emoji),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 38)),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: color,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
