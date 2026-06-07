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
  static const Color green = Color(0xff2E8B57);
  static const Color background = Color(0xFFF7F8FA);
  static const Color border = Color(0xffE5E5E5);

  bool _creatingDefaults = false;

  final List<Map<String, dynamic>> _defaultTasks = const [
    {
      'title': 'اشرب ماء',
      'type': 'water',
      'icon': 'water',
      'description': 'حافظ على شرب الماء خلال اليوم',
    },
    {
      'title': 'امشِ 10 دقائق',
      'type': 'walk',
      'icon': 'walk',
      'description': 'حركة بسيطة تساعد على النشاط',
    },
    {
      'title': 'افحص السكر',
      'type': 'glucose',
      'icon': 'glucose',
      'description': 'سجل قراءة السكر إذا كانت مطلوبة اليوم',
    },
    {
      'title': 'خذ الدواء',
      'type': 'medication',
      'icon': 'medication',
      'description': 'تأكد من أخذ أدوية اليوم في وقتها',
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
          title: const Text(
            'مهام اليوم',
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
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
              );
            }

            _ensureTodayTasks(uid, docs);

            docs.sort((a, b) {
              final aDone = a.data()['isDone'] == true ? 1 : 0;
              final bDone = b.data()['isDone'] == true ? 1 : 0;
              return aDone.compareTo(bDone);
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
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: border),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 31,
                          backgroundColor: Color(0xffEEF8F1),
                          child: Icon(
                            Icons.task_alt_rounded,
                            color: green,
                            size: 38,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            total == 0
                                ? 'يتم تجهيز مهام اليوم...'
                                : 'إنجاز اليوم: $doneCount من $total مهام',
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.w900,
                              color: dark,
                              height: 1.5,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  ...docs.map((doc) {
                    final data = doc.data();
                    final isDone = data['isDone'] == true;
                    final title = (data['title'] ?? 'مهمة').toString();
                    final description = (data['description'] ?? '').toString();
                    final icon = (data['icon'] ?? '').toString();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isDone ? green : border,
                          width: isDone ? 2 : 1.3,
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: isDone
                                ? const Color(0xffE4F3E8)
                                : const Color(0xffEAF2FA),
                            child: Icon(
                              isDone
                                  ? Icons.check_circle_rounded
                                  : _iconFor(icon),
                              color: isDone ? green : dark,
                              size: 34,
                            ),
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
                                    fontSize: 23,
                                    fontWeight: FontWeight.w900,
                                    color: dark,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                                if (description.isNotEmpty) ...[
                                  const SizedBox(height: 5),
                                  Text(
                                    description,
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black54,
                                      fontFamily: 'Cairo',
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: () => _toggleTask(
                              uid: uid,
                              docId: doc.id,
                              data: data,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDone ? green : dark,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 12,
                              ),
                            ),
                            child: Text(
                              isDone ? 'تم' : 'إنجاز',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
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
