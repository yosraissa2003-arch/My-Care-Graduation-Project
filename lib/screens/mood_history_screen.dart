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
  static const Color primary = Color(0xFF1E3A5F);
  static const Color background = Color(0xFFF7F9FC);
  static const Color border = Color(0xffE5E7EB);

  static const Color goodColor = Color(0xff2E8B57);
  static const Color tiredColor = Color(0xffB45309);
  static const Color sadColor = Color(0xffB42318);

  static const Color goodBg = Color(0xffEEF8F1);
  static const Color tiredBg = Color(0xffFFF7ED);
  static const Color sadBg = Color(0xffFFF0F0);

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
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _formatDate(dynamic value) {
    if (value is! Timestamp) return '';
    final date = value.toDate();
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Color _moodColor(String mood, String label) {
    if (mood == 'good' || label == 'جيد') return goodColor;
    if (mood == 'tired' || label == 'متعب') return tiredColor;
    if (mood == 'sad' || label == 'حزين') return sadColor;
    return primary;
  }

  Color _moodBgColor(String mood, String label) {
    if (mood == 'good' || label == 'جيد') return goodBg;
    if (mood == 'tired' || label == 'متعب') return tiredBg;
    if (mood == 'sad' || label == 'حزين') return sadBg;
    return const Color(0xFFEAF3FF);
  }

  Widget _moodQuestionCard(String uid) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'كيف تشعر اليوم؟',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 29,
              fontWeight: FontWeight.w900,
              color: dark,
              fontFamily: 'Cairo',
              height: 1.3,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'اختر حالتك اليوم ليتم حفظها في سجل المزاج.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF4B5563),
              fontFamily: 'Cairo',
              height: 1.5,
            ),
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: _moodButton(
                  uid: uid,
                  emoji: '🙂',
                  label: 'جيد',
                  mood: 'good',
                  color: goodColor,
                  bgColor: goodBg,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: _moodButton(
                  uid: uid,
                  emoji: '😐',
                  label: 'متعب',
                  mood: 'tired',
                  color: tiredColor,
                  bgColor: tiredBg,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: _moodButton(
                  uid: uid,
                  emoji: '😢',
                  label: 'حزين',
                  mood: 'sad',
                  color: sadColor,
                  bgColor: sadBg,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryCard({
    required int total,
    required int good,
    required int tired,
    required int sad,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'ملخص آخر $total أيام',
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: dark,
              fontFamily: 'Cairo',
              height: 1.3,
            ),
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _summaryItem(
                  emoji: '🙂',
                  label: 'جيد',
                  value: good.toString(),
                  color: goodColor,
                  bgColor: goodBg,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: _summaryItem(
                  emoji: '😐',
                  label: 'متعب',
                  value: tired.toString(),
                  color: tiredColor,
                  bgColor: tiredBg,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: _summaryItem(
                  emoji: '😢',
                  label: 'حزين',
                  value: sad.toString(),
                  color: sadColor,
                  bgColor: sadBg,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryItem({
    required String emoji,
    required String label,
    required String value,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.25), width: 1.1),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),

          const SizedBox(height: 6),

          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w900,
              color: dark,
              fontFamily: 'Cairo',
              height: 1.1,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: color,
              fontFamily: 'Cairo',
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _moodHistoryCard({
    required String emoji,
    required String label,
    required String mood,
    required dynamic date,
  }) {
    final moodColor = _moodColor(mood, label);
    final moodBg = _moodBgColor(mood, label);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: moodBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: moodColor.withOpacity(0.25)),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 34)),
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'المزاج: $label',
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    color: moodColor,
                    fontFamily: 'Cairo',
                    height: 1.3,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  'التاريخ: ${_formatDate(date)}',
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: dark,
                    fontFamily: 'Cairo',
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyMoodCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: border, width: 1.2),
      ),
      child: const Text(
        'لا توجد تسجيلات مزاج بعد',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: Colors.black54,
          fontFamily: 'Cairo',
          height: 1.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('يجب تسجيل الدخول أولاً')),
      );
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
          automaticallyImplyLeading: false,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: dark,
              size: 28,
            ),
          ),
          title: const Text(
            'مزاجي',
            style: TextStyle(
              color: dark,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              fontFamily: 'Cairo',
              height: 1.3,
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            _moodQuestionCard(uid),

            const SizedBox(height: 24),

            const Text(
              'سجل المزاج',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: dark,
                fontFamily: 'Cairo',
                height: 1.3,
              ),
            ),

            const SizedBox(height: 14),

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

                if (snapshot.connectionState == ConnectionState.waiting &&
                    recent.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(color: dark),
                  );
                }

                if (recent.isEmpty) {
                  return _emptyMoodCard();
                }

                final good = recent
                    .where((doc) => doc.data()['mood'] == 'good')
                    .length;

                final tired = recent
                    .where((doc) => doc.data()['mood'] == 'tired')
                    .length;

                final sad = recent
                    .where((doc) => doc.data()['mood'] == 'sad')
                    .length;

                return Column(
                  children: [
                    _summaryCard(
                      total: recent.length,
                      good: good,
                      tired: tired,
                      sad: sad,
                    ),

                    const SizedBox(height: 14),

                    ...recent.map((doc) {
                      final data = doc.data();

                      final emoji = (data['emoji'] ?? '').toString();
                      final label = (data['moodLabel'] ?? '').toString();
                      final mood = (data['mood'] ?? '').toString();
                      final createdAt = data['createdAt'] ?? data['updatedAt'];

                      return _moodHistoryCard(
                        emoji: emoji,
                        label: label,
                        mood: mood,
                        date: createdAt,
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
    required Color bgColor,
  }) {
    return InkWell(
      onTap: () => _saveMood(uid: uid, mood: mood, label: label, emoji: emoji),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: color.withOpacity(0.30), width: 1.2),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 39)),

            const SizedBox(height: 8),

            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: color,
                  fontFamily: 'Cairo',
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
