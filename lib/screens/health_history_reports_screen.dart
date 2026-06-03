import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HealthHistoryReportsScreen extends StatelessWidget {
  const HealthHistoryReportsScreen({super.key});

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
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'يجب تسجيل الدخول أولاً',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    final uid = user.uid;

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
            onPressed: () => Navigator.pop(context),
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
              fontFamily: 'Cairo',
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

            if (snapshot.hasError) {
              return const Center(
                child: Text(
                  'حدث خطأ أثناء تحميل التقارير',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: dark,
                    fontFamily: 'Cairo',
                  ),
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
                  'لا توجد تقارير صحية بعد',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                    color: dark,
                    fontFamily: 'Cairo',
                  ),
                ),
              );
            }

            final reports = docs.map((doc) {
              final data = doc.data();
              final heartRate = _toInt(data['heartRate']);
              final systolic = _toInt(data['bloodPressureSystolic']);
              final diastolic = _toInt(data['bloodPressureDiastolic']);
              final glucose = _toInt(data['glucose'] ?? data['sugar']);
              final oxygen = _toInt(data['oxygen'] ?? data['oxygenLevel']);
              final temperature = _toDouble(data['temperature']);
              final createdAt = data['createdAt'];
              final date = createdAt is Timestamp
                  ? createdAt.toDate()
                  : DateTime.now();
              final status = (data['aiStatus'] ?? '').toString().isNotEmpty
                  ? _arabicStatus(data['aiStatus'].toString())
                  : getHealthStatus(
                      heartRate: heartRate,
                      systolic: systolic,
                      diastolic: diastolic,
                      glucose: glucose,
                      oxygen: oxygen,
                      temperature: temperature,
                    );

              return HealthReport(
                heartRate: heartRate,
                systolic: systolic,
                diastolic: diastolic,
                glucose: glucose,
                oxygen: oxygen,
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

            return RefreshIndicator(
              onRefresh: () async {},
              child: ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  _summaryCard(latest, reports.length, criticalCount),
                  const SizedBox(height: 18),
                  Row(
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
                  const SizedBox(height: 10),
                  Row(
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
                  const SizedBox(height: 22),
                  _evaluationCard(latest.status),
                  const SizedBox(height: 24),
                  const Text(
                    'سجل القراءات',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: dark,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  const SizedBox(height: 14),
                  ...reports.map((report) => _reportCard(report: report)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _summaryCard(HealthReport latest, int count, int criticalCount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _statusBg(latest.status),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'الحالة الصحية العامة',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: dark,
                        fontFamily: 'Cairo',
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
                        fontFamily: 'Cairo',
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
          const SizedBox(height: 16),
          _dateTimeLine('آخر تحديث', latest.date),
          const SizedBox(height: 8),
          Text(
            'عدد القراءات: $count  |  الحالات الخطرة: $criticalCount',
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: dark,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }

  Widget _evaluationCard(String status) {
    return Container(
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
              status == 'خطر'
                  ? 'تقييم الحالة الصحية: تم اكتشاف قراءة خطيرة، يفضّل مراجعة الطبيب.'
                  : status == 'تحتاج متابعة'
                  ? 'تقييم الحالة الصحية: توجد قراءة تحتاج متابعة خلال اليوم.'
                  : 'تقييم الحالة الصحية: الحالة مستقرة حالياً.',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: dark,
                height: 1.5,
                fontFamily: 'Cairo',
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
    );
  }

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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'الحالة: ${report.status}',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                    color: _statusColor(report.status),
                    fontFamily: 'Cairo',
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
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _readingChip(
                Icons.favorite,
                'النبض',
                report.heartRate.toString(),
              ),
              _readingChip(
                Icons.bloodtype,
                'الضغط',
                '${report.systolic}/${report.diastolic}',
              ),
              _readingChip(
                Icons.water_drop,
                'السكر',
                report.glucose.toString(),
              ),
              _readingChip(Icons.air, 'الأكسجين', report.oxygen.toString()),
              _readingChip(
                Icons.thermostat,
                'الحرارة',
                report.temperature.toStringAsFixed(1),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _dateTimeLine('التاريخ والوقت', report.date),
        ],
      ),
    );
  }

  Widget _readingChip(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: dark, size: 22),
          const SizedBox(width: 6),
          Text(
            '$label: $value',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: dark,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateTimeLine(String title, DateTime date) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_month_rounded, color: dark, size: 22),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              '$title: ${_formatDate(date)}  •  ${_formatTime(date)}',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: dark,
                fontFamily: 'Cairo',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color bgColor,
    required Color iconColor,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 126),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: iconColor.withOpacity(0.15)),
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(height: 9),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: dark,
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: dark,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }

  String getHealthStatus({
    required int heartRate,
    required int systolic,
    required int diastolic,
    required int glucose,
    required int oxygen,
    required double temperature,
  }) {
    if (heartRate < 50 ||
        heartRate > 120 ||
        systolic >= 180 ||
        diastolic >= 120 ||
        glucose < 70 ||
        glucose > 250 ||
        (oxygen > 0 && oxygen < 90) ||
        temperature >= 39) {
      return 'خطر';
    }

    if (heartRate < 60 ||
        heartRate > 100 ||
        systolic >= 140 ||
        diastolic >= 90 ||
        glucose > 180 ||
        (oxygen > 0 && oxygen < 94) ||
        temperature >= 38) {
      return 'تحتاج متابعة';
    }

    return 'مستقرة';
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String)
      return double.tryParse(value.replaceAll(',', '.')) ?? 0;
    return 0;
  }

  String _arabicStatus(String value) {
    final status = value.toLowerCase().trim();
    if (status == 'critical' || status == 'خطر' || status == 'حرجة')
      return 'خطر';
    if (status == 'warning' || status == 'تحذير' || status == 'تحتاج متابعة')
      return 'تحتاج متابعة';
    return 'مستقرة';
  }

  Color _statusBg(String status) {
    if (status == 'خطر') return softRed;
    if (status == 'تحتاج متابعة') return softOrange;
    return softGreen;
  }

  Color _statusColor(String status) {
    if (status == 'خطر') return Colors.red;
    if (status == 'تحتاج متابعة') return Colors.orange;
    return green;
  }

  IconData _statusIcon(String status) {
    if (status == 'خطر') return Icons.warning_amber_rounded;
    if (status == 'تحتاج متابعة') return Icons.info_outline_rounded;
    return Icons.verified_user;
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
}

class HealthReport {
  final int heartRate;
  final int systolic;
  final int diastolic;
  final int glucose;
  final int oxygen;
  final double temperature;
  final String status;
  final DateTime date;

  HealthReport({
    required this.heartRate,
    required this.systolic,
    required this.diastolic,
    required this.glucose,
    required this.oxygen,
    required this.temperature,
    required this.status,
    required this.date,
  });
}
