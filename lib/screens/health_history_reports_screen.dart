import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HealthHistoryReportsScreen extends StatelessWidget {
  const HealthHistoryReportsScreen({super.key});

  final String uid = "1sxPcUvNOJRS88X7xtDlx4Te5v62";

  static const Color dark = Color(0xff172638);
  static const Color green = Color(0xff2E8B57);

  static const Color softGreen = Color(0xffEEF8F1);
  static const Color softOrange = Color(0xffFFF7ED);
  static const Color softRed = Color(0xffFFF0F0);
  static const Color softBlue = Color(0xffF1F8FC);
  static const Color softPurple = Color(0xffF7F3FF);

  static const Color border = Color(0xffE5E5E5);

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
            'التقارير الصحية',

            style: TextStyle(
              color: dark,
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),

        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('healthLogs')
              .where('userId', isEqualTo: uid)
              .snapshots(),

          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data?.docs ?? [];

            if (docs.isEmpty) {
              return const Center(
                child: Text(
                  'لا توجد تقارير صحية بعد',

                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                    color: dark,
                  ),
                ),
              );
            }

            docs.sort((a, b) {
              final aTime = a.data()['createdAt'] as Timestamp;

              final bTime = b.data()['createdAt'] as Timestamp;

              return bTime.compareTo(aTime);
            });

            final reports = docs.map((doc) {
              final data = doc.data();

              final heartRate = _toInt(data['heartRate']);

              final systolic = _toInt(data['bloodPressureSystolic']);

              final diastolic = _toInt(data['bloodPressureDiastolic']);

              final glucose = _toInt(data['glucose']);

              final temperature = _toDouble(data['temperature']);

              final createdAt = data['createdAt'] as Timestamp;

              final date = createdAt.toDate();

              final status = getHealthStatus(
                heartRate: heartRate,
                systolic: systolic,
                diastolic: diastolic,
                glucose: glucose,
                temperature: temperature,
              );

              return HealthReport(
                heartRate: heartRate,
                systolic: systolic,
                diastolic: diastolic,
                glucose: glucose,
                temperature: temperature,
                status: status,
                date: date,
              );
            }).toList();

            final latest = reports.first;

            final criticalCount = reports
                .where((r) => r.status == 'خطر')
                .length;

            final avgHeart =
                reports.map((r) => r.heartRate).reduce((a, b) => a + b) /
                reports.length;

            final avgGlucose =
                reports.map((r) => r.glucose).reduce((a, b) => a + b) /
                reports.length;

            return ListView(
              padding: const EdgeInsets.all(18),

              children: [
                /// الحالة العامة
                Container(
                  width: double.infinity,

                  padding: const EdgeInsets.all(22),

                  decoration: BoxDecoration(
                    color: _statusBg(latest.status),

                    borderRadius: BorderRadius.circular(26),

                    border: Border.all(color: border),
                  ),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,

                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,

                              children: [
                                const Text(
                                  'الحالة الصحية العامة',

                                  textAlign: TextAlign.right,

                                  style: TextStyle(
                                    fontSize: 22,

                                    fontWeight: FontWeight.w800,

                                    color: dark,
                                  ),
                                ),

                                const SizedBox(height: 6),

                                Text(
                                  latest.status,

                                  textAlign: TextAlign.right,

                                  style: TextStyle(
                                    fontSize: 34,

                                    fontWeight: FontWeight.w900,

                                    color: _statusColor(latest.status),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 14),

                          Container(
                            width: 70,
                            height: 70,

                            decoration: const BoxDecoration(
                              color: Colors.white,

                              shape: BoxShape.circle,
                            ),

                            child: Icon(
                              _statusIcon(latest.status),

                              color: _statusColor(latest.status),

                              size: 42,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      Text(
                        'آخر تحديث: '
                        '${latest.date.day}/${latest.date.month}/${latest.date.year}'
                        ' - '
                        '${latest.date.hour}:${latest.date.minute.toString().padLeft(2, '0')}',

                        textAlign: TextAlign.right,

                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,

                          color: dark,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        'عدد القراءات: ${reports.length}'
                        ' | '
                        'الحالات الخطرة: $criticalCount',

                        textAlign: TextAlign.right,

                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,

                          color: dark,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                /// الكروت الصغيرة
                Directionality(
                  textDirection: TextDirection.rtl,

                  child: Row(
                    children: [
                      Expanded(
                        child: _smallStatCard(
                          title: 'عدد القراءات',

                          value: reports.length.toString(),

                          icon: Icons.folder_copy_outlined,

                          bgColor: softBlue,

                          iconColor: const Color(0xff407C99),
                        ),
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: _smallStatCard(
                          title: 'حالات خطر',

                          value: criticalCount.toString(),

                          icon: Icons.warning_amber_rounded,

                          bgColor: softRed,

                          iconColor: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                Directionality(
                  textDirection: TextDirection.rtl,

                  child: Row(
                    children: [
                      Expanded(
                        child: _smallStatCard(
                          title: 'متوسط النبض',

                          value: avgHeart.toStringAsFixed(0),

                          icon: Icons.favorite_border,

                          bgColor: softPurple,

                          iconColor: const Color(0xff755BB5),
                        ),
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: _smallStatCard(
                          title: 'متوسط السكر',

                          value: avgGlucose.toStringAsFixed(0),

                          icon: Icons.bloodtype_outlined,

                          bgColor: softOrange,

                          iconColor: const Color(0xffD47443),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                /// تقييم الحالة
                Container(
                  width: double.infinity,

                  padding: const EdgeInsets.all(18),

                  decoration: BoxDecoration(
                    color: softBlue,

                    borderRadius: BorderRadius.circular(22),

                    border: Border.all(color: border),
                  ),

                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          latest.status == 'خطر'
                              ? 'تقييم الحالة الصحية: تم اكتشاف قراءة خطيرة، يفضّل مراجعة الطبيب.'
                              : latest.status == 'تحتاج متابعة'
                              ? 'تقييم الحالة الصحية: توجد قراءة تحتاج متابعة خلال اليوم.'
                              : 'تقييم الحالة الصحية: الحالة مستقرة حالياً.',

                          textAlign: TextAlign.right,

                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w800,

                            color: dark,
                            height: 1.4,
                          ),
                        ),
                      ),

                      const SizedBox(width: 14),

                      Container(
                        width: 58,
                        height: 58,

                        decoration: const BoxDecoration(
                          color: Colors.white,

                          shape: BoxShape.circle,
                        ),

                        child: const Icon(
                          Icons.psychology_alt_outlined,

                          color: Color(0xff407C99),

                          size: 34,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  'سجل القراءات',

                  textAlign: TextAlign.right,

                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: dark,
                  ),
                ),

                const SizedBox(height: 14),

                ...reports.map((report) {
                  return _reportCard(report: report);
                }),
              ],
            );
          },
        ),
      ),
    );
  }

  /// كرت التقرير

  Widget _reportCard({required HealthReport report}) {
    return Container(
      width: double.infinity,

      margin: const EdgeInsets.only(bottom: 16),

      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: _statusBg(report.status),

        borderRadius: BorderRadius.circular(22),

        border: Border.all(color: border),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,

        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'الحالة: ${report.status}',

                  textAlign: TextAlign.right,

                  style: TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w900,

                    color: _statusColor(report.status),
                  ),
                ),
              ),

              const SizedBox(width: 14),

              Container(
                width: 58,
                height: 58,

                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),

                child: Icon(
                  _statusIcon(report.status),

                  color: _statusColor(report.status),

                  size: 34,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          _infoText('النبض: ${report.heartRate}'),

          _infoText(
            'الضغط: '
            '${report.systolic}/${report.diastolic}',
          ),

          _infoText('السكر: ${report.glucose}'),

          _infoText(
            'درجة الحرارة: '
            '${report.temperature.toStringAsFixed(1)}',
          ),

          const SizedBox(height: 12),

          Text(
            'التاريخ: '
            '${report.date.day}/${report.date.month}/${report.date.year}'
            ' - '
            '${report.date.hour}:${report.date.minute.toString().padLeft(2, '0')}',

            textAlign: TextAlign.right,

            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: dark,
            ),
          ),
        ],
      ),
    );
  }

  /// الكروت الصغيرة

  Widget _smallStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color bgColor,
    required Color iconColor,
  }) {
    return Container(
      height: 150,

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: bgColor,

        borderRadius: BorderRadius.circular(24),

        border: Border.all(color: border),
      ),

      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,

              crossAxisAlignment: CrossAxisAlignment.end,

              children: [
                Text(
                  value,

                  textAlign: TextAlign.right,

                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,

                    color: dark,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  title,

                  textAlign: TextAlign.right,

                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,

                    color: dark,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 14),

          Container(
            width: 56,
            height: 56,

            decoration: BoxDecoration(
              color: Colors.white,

              shape: BoxShape.circle,

              border: Border.all(color: iconColor.withOpacity(0.15)),
            ),

            child: Icon(icon, color: iconColor, size: 32),
          ),
        ],
      ),
    );
  }

  Widget _infoText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),

      child: Text(
        text,

        textAlign: TextAlign.right,

        style: const TextStyle(
          fontSize: 23,
          fontWeight: FontWeight.w800,
          color: dark,
        ),
      ),
    );
  }

  String getHealthStatus({
    required int heartRate,
    required int systolic,
    required int diastolic,
    required int glucose,
    required double temperature,
  }) {
    if (heartRate < 50 ||
        heartRate > 120 ||
        systolic >= 180 ||
        diastolic >= 120 ||
        glucose < 70 ||
        glucose > 250 ||
        temperature >= 39) {
      return 'خطر';
    }

    if (heartRate < 60 ||
        heartRate > 100 ||
        systolic >= 140 ||
        diastolic >= 90 ||
        glucose > 180 ||
        temperature >= 38) {
      return 'تحتاج متابعة';
    }

    return 'مستقرة';
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;

    if (value is int) return value;

    if (value is double) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value) ?? 0;
    }

    return 0;
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;

    if (value is int) {
      return value.toDouble();
    }

    if (value is double) return value;

    if (value is String) {
      return double.tryParse(value) ?? 0;
    }

    return 0;
  }

  Color _statusBg(String status) {
    if (status == 'خطر') {
      return softRed;
    }

    if (status == 'تحتاج متابعة') {
      return softOrange;
    }

    return softGreen;
  }

  Color _statusColor(String status) {
    if (status == 'خطر') {
      return Colors.red;
    }

    if (status == 'تحتاج متابعة') {
      return Colors.orange;
    }

    return green;
  }

  IconData _statusIcon(String status) {
    if (status == 'خطر') {
      return Icons.warning_amber_rounded;
    }

    if (status == 'تحتاج متابعة') {
      return Icons.info_outline_rounded;
    }

    return Icons.verified_user;
  }
}

class HealthReport {
  final int heartRate;
  final int systolic;
  final int diastolic;
  final int glucose;

  final double temperature;

  final String status;

  final DateTime date;

  HealthReport({
    required this.heartRate,
    required this.systolic,
    required this.diastolic,
    required this.glucose,
    required this.temperature,
    required this.status,
    required this.date,
  });
}
