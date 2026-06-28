import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/care_timeline_service.dart';

class DailyTasksScreen extends StatefulWidget {
  const DailyTasksScreen({super.key});

  @override
  State<DailyTasksScreen> createState() => _DailyTasksScreenState();
}

class _DailyTasksScreenState extends State<DailyTasksScreen> {
  static const Color dark = Color(0xff172638);
  static const Color primary = Color(0xFF1E3A5F);
  static const Color green = Color(0xff2E8B57);
  static const Color background = Color(0xFFF7F9FC);
  static const Color border = Color(0xffE5E7EB);
  static const Color softBlue = Color(0xFFEAF3FF);
  static const Color softGreen = Color(0xffEAF7EF);

  bool _creatingDefaults = false;

  final List<Map<String, dynamic>> _defaultTasks = const [
    {
      'title': 'خذ الدواء',
      'type': 'medication',
      'icon': 'medication',
      'description': 'تأكد من أخذ أدوية اليوم في وقتها',
    },
    {
      'title': 'امشِ 10 دقائق',
      'type': 'walk',
      'icon': 'walk',
      'description': 'حركة بسيطة تساعد على النشاط',
    },
    {
      'title': 'اشرب ماء',
      'type': 'water',
      'icon': 'water',
      'description': 'حافظ على شرب الماء خلال اليوم',
    },
    {
      'title': 'افحص السكر',
      'type': 'glucose',
      'icon': 'glucose',
      'description': 'سجل قراءة السكر إذا كانت مطلوبة اليوم',
    },
  ];

  Future<void> _ensureTodayTasks(
    String uid,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) async {
    if (_creatingDefaults || docs.isNotEmpty) return;

    _creatingDefaults = true;

    final batch = FirebaseFirestore.instance.batch();
    final dateKey = CareTimelineService.todayKey();

    for (final task in _defaultTasks) {
      final ref = FirebaseFirestore.instance.collection('dailyTasks').doc();

      batch.set(ref, {
        'userId': uid,
        'patientId': uid,
        'title': task['title'],
        'type': task['type'],
        'icon': task['icon'],
        'description': task['description'],
        'dateKey': dateKey,
        'isDone': false,
        'completedAt': null,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();

    _creatingDefaults = false;
  }

  Future<void> _toggleTask({
    required String uid,
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    final isDone = data['isDone'] == true;
    final newValue = !isDone;
    final title = (data['title'] ?? 'مهمة يومية').toString();

    await FirebaseFirestore.instance
        .collection('dailyTasks')
        .doc(docId)
        .update({
          'isDone': newValue,
          'completedAt': newValue ? FieldValue.serverTimestamp() : null,
        });

    if (newValue) {
      await CareTimelineService.addEvent(
        userId: uid,
        type: 'task',
        title: 'تم إنجاز مهمة يومية',
        details: title,
      );

      await CareTimelineService.updateLastActivity(uid);
    }
  }

  IconData _iconFor(String icon) {
    switch (icon) {
      case 'water':
        return Icons.water_drop_rounded;
      case 'walk':
        return Icons.directions_walk_rounded;
      case 'glucose':
        return Icons.bloodtype_rounded;
      case 'medication':
        return Icons.medication_rounded;
      default:
        return Icons.task_alt_rounded;
    }
  }

  int _taskOrder(String type) {
    switch (type) {
      case 'medication':
        return 0;
      case 'walk':
        return 1;
      case 'water':
        return 2;
      case 'glucose':
        return 3;
      default:
        return 4;
    }
  }

  Widget _progressCard({required int doneCount, required int total}) {
    final double progress = total == 0 ? 0 : doneCount / total;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  color: softGreen,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.check_circle_outline_rounded,
                  color: green,
                  size: 40,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'تقدّم اليوم',
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                        color: dark,
                        fontFamily: 'Cairo',
                        height: 1.3,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      total == 0
                          ? 'يتم تجهيز مهام اليوم...'
                          : 'تم إنجاز $doneCount من $total مهام',
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF4B5563),
                        fontFamily: 'Cairo',
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              minHeight: 12,
              value: progress,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: const AlwaysStoppedAnimation<Color>(green),
            ),
          ),
        ],
      ),
    );
  }

  Widget _taskCard({
    required String uid,
    required String docId,
    required Map<String, dynamic> data,
  }) {
    final bool isDone = data['isDone'] == true;
    final String title = (data['title'] ?? 'مهمة').toString();
    final String description = (data['description'] ?? '').toString();
    final String icon = (data['icon'] ?? '').toString();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDone ? green : border,
          width: isDone ? 2 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 9,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: isDone ? softGreen : softBlue,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              isDone ? Icons.check_circle_rounded : _iconFor(icon),
              color: isDone ? green : dark,
              size: 36,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                    color: isDone ? green : dark,
                    fontFamily: 'Cairo',
                    height: 1.3,
                  ),
                ),

                if (description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    description,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF6B7280),
                      fontFamily: 'Cairo',
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 12),

          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: () => _toggleTask(uid: uid, docId: docId, data: data),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDone ? green : primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 18),
              ),
              child: Text(
                isDone ? 'تم' : 'إنجاز',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Cairo',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _introText() {
    return const Text(
      'تابع مهامك اليومية البسيطة، واضغط إنجاز عند الانتهاء من كل مهمة.',
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.right,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: Color(0xFF4B5563),
        fontFamily: 'Cairo',
        height: 1.6,
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
    final dateKey = CareTimelineService.todayKey();

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
              Icons.arrow_forward_ios_rounded,
              color: dark,
              size: 28,
            ),
          ),
          title: const Text(
            'مهامي اليومية',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: dark,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              fontFamily: 'Cairo',
              height: 1.3,
            ),
          ),
        ),
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('dailyTasks')
              .where('userId', isEqualTo: uid)
              .where('dateKey', isEqualTo: dateKey)
              .snapshots(),
          builder: (context, snapshot) {
            final docs = <QueryDocumentSnapshot<Map<String, dynamic>>>[
              ...(snapshot.data?.docs ??
                  <QueryDocumentSnapshot<Map<String, dynamic>>>[]),
            ];

            if (snapshot.connectionState == ConnectionState.waiting &&
                docs.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(color: dark),
              );
            }

            if (snapshot.hasError) {
              return const Center(
                child: Text(
                  'حدث خطأ أثناء تحميل المهام',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: dark,
                    fontFamily: 'Cairo',
                  ),
                ),
              );
            }

            _ensureTodayTasks(uid, docs);

            docs.sort((a, b) {
              final aDone = a.data()['isDone'] == true ? 1 : 0;
              final bDone = b.data()['isDone'] == true ? 1 : 0;

              if (aDone != bDone) {
                return aDone.compareTo(bDone);
              }

              final aType = (a.data()['type'] ?? '').toString();
              final bType = (b.data()['type'] ?? '').toString();

              return _taskOrder(aType).compareTo(_taskOrder(bType));
            });

            final doneCount = docs
                .where((doc) => doc.data()['isDone'] == true)
                .length;

            final total = docs.length;

            return RefreshIndicator(
              onRefresh: () async => setState(() {}),
              child: ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  _introText(),

                  const SizedBox(height: 14),

                  _progressCard(doneCount: doneCount, total: total),

                  const SizedBox(height: 18),

                  ...docs.map((doc) {
                    return _taskCard(uid: uid, docId: doc.id, data: doc.data());
                  }),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
