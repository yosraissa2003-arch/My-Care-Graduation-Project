import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
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

  Future<void> _speak(String text) async {
    if (text.trim().isEmpty) return;

    final tts = FlutterTts();
    await tts.setLanguage('ar');
    await tts.setSpeechRate(0.45);
    await tts.setVolume(1.0);
    await tts.setPitch(1.0);
    await tts.speak(text);
  }

  String _summaryVoiceText({
    required HealthReport latest,
    required int count,
    required int criticalCount,
    required double avgHeart,
    required double avgGlucose,
  }) {
    final evaluation = latest.status == 'خطر'
        ? 'تم اكتشاف قراءة خطيرة، يفضل مراجعة الطبيب.'
        : latest.status == 'تحتاج متابعة'
        ? 'توجد قراءة تحتاج متابعة خلال اليوم.'
        : 'الحالة مستقرة حاليا.';

    return 'ملخص التقرير الصحي. الحالة الصحية العامة ${latest.status}. '
        'عدد القراءات $count. عدد الحالات الخطرة $criticalCount. '
        'متوسط النبض ${avgHeart.toStringAsFixed(0)}. '
        'متوسط السكر ${avgGlucose.toStringAsFixed(0)}. '
        'آخر قراءة: النبض ${latest.heartRate}، الضغط ${latest.systolic} على ${latest.diastolic}، '
        'السكر ${latest.glucose}، الأكسجين ${latest.oxygen}، والحرارة ${latest.temperature.toStringAsFixed(1)}. '
        '$evaluation';
  }

  String _singleReportVoiceText(HealthReport report) {
    return 'تفاصيل القراءة الصحية. الحالة ${report.status}. '
        'النبض ${report.heartRate}. الضغط ${report.systolic} على ${report.diastolic}. '
        'السكر ${report.glucose}. الأكسجين ${report.oxygen}. '
        'الحرارة ${report.temperature.toStringAsFixed(1)}. '
        'التاريخ ${_formatDate(report.date)} الساعة ${_formatTime(report.date)}.';
  }

  Widget _voiceSummaryCard({
    required HealthReport latest,
    required int count,
    required int criticalCount,
    required double avgHeart,
    required double avgGlucose,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: softBlue,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: dark,
            child: IconButton(
              icon: const Icon(
                Icons.volume_up_rounded,
                color: Colors.white,
                size: 30,
              ),
              onPressed: () => _speak(
                _summaryVoiceText(
                  latest: latest,
                  count: count,
                  criticalCount: criticalCount,
                  avgHeart: avgHeart,
                  avgGlucose: avgGlucose,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'اسمع ملخص التقرير الصحي والحالة العامة والقراءات الأخيرة.',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: dark,
                height: 1.5,
                fontFamily: 'Cairo',
              ),
            ),
          ),
        ],
      ),
    );
  }

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
                  const SizedBox(height: 12),
                  _voiceSummaryCard(
                    latest: latest,
                    count: reports.length,
                    criticalCount: criticalCount,
                    avgHeart: avgHeart,
                    avgGlucose: avgGlucose,
                  ),
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
                          bgColor: const Color(0xFFEAF3FF),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _statusBg(latest.status),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: border, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _statusIcon(latest.status),
                  color: _statusColor(latest.status),
                  size: 36,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        'الحالة الصحية العامة',
                        maxLines: 1,
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: dark,
                          fontFamily: 'Cairo',
                          height: 1.2,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        latest.status,
                        maxLines: 1,
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: _statusColor(latest.status),
                          fontFamily: 'Cairo',
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: border, width: 1.1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'آخر تحديث:',
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: dark,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),

                const SizedBox(height: 7),

                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'التاريخ: ${_formatDate(latest.date)}',
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: dark,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),

                const SizedBox(height: 5),

                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'الوقت: ${_formatTime(latest.date)}',
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: dark,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _evaluationCard(String status) {
    final bool isDanger = status == 'خطر';
    final bool isWarning = status == 'تحتاج متابعة';

    final String title = isDanger
        ? 'تقييم الحالة الصحية'
        : isWarning
        ? 'تقييم الحالة الصحية'
        : 'تقييم الحالة الصحية';

    final String message = isDanger
        ? 'تم اكتشاف قراءة خطيرة. يفضّل مراجعة الطبيب أو طلب المساعدة الطبية.'
        : isWarning
        ? 'توجد قراءة تحتاج متابعة خلال اليوم. راقب القراءات وأعد القياس لاحقًا.'
        : 'الحالة مستقرة حالياً. استمر بمتابعة صحتك بانتظام.';

    final Color mainColor = isDanger
        ? Colors.red
        : isWarning
        ? const Color(0xFF1F4168)
        : green;

    final Color bgColor = isDanger
        ? softRed
        : isWarning
        ? const Color(0xFFEAF3FF)
        : softGreen;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            textAlign: TextAlign.right,
            maxLines: 1,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: mainColor,
              fontFamily: 'Cairo',
              height: 1.3,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            message,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: dark,
              height: 1.6,
              fontFamily: 'Cairo',
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'قراءة صحية',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                    color: dark,
                    fontFamily: 'Cairo',
                    height: 1.3,
                  ),
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: _statusBg(report.status),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: _statusColor(report.status).withOpacity(0.25),
                  ),
                ),
                child: Text(
                  report.status,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: _statusColor(report.status),
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          _dateTimeLine('التاريخ والوقت', report.date),

          const SizedBox(height: 14),

          _readingRow(
            icon: Icons.favorite_rounded,
            label: 'النبض',
            value: report.heartRate.toString(),
          ),

          _readingRow(
            icon: Icons.bloodtype_rounded,
            label: 'الضغط',
            value: '${report.systolic}/${report.diastolic}',
          ),

          _readingRow(
            icon: Icons.water_drop_rounded,
            label: 'السكر',
            value: report.glucose.toString(),
          ),

          _readingRow(
            icon: Icons.air_rounded,
            label: 'الأكسجين',
            value: report.oxygen.toString(),
          ),

          _readingRow(
            icon: Icons.thermostat_rounded,
            label: 'الحرارة',
            value: report.temperature.toStringAsFixed(1),
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _speak(_singleReportVoiceText(report)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: dark, width: 1.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
              icon: const Icon(Icons.volume_up_rounded, color: dark, size: 25),
              label: const Text(
                'اسمع هذه القراءة',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: dark,
                  fontFamily: 'Cairo',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _readingRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 1.1),
      ),
      child: Row(
        children: [
          Icon(icon, color: dark, size: 24),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: dark,
                fontFamily: 'Cairo',
              ),
            ),
          ),

          Text(
            value,
            textAlign: TextAlign.left,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w900,
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
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 1.1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '$title:',
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: dark,
                fontFamily: 'Cairo',
              ),
            ),
          ),

          const SizedBox(height: 6),

          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'التاريخ: ${_formatDate(date)}',
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: dark,
                fontFamily: 'Cairo',
              ),
            ),
          ),

          const SizedBox(height: 4),

          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'الوقت: ${_formatTime(date)}',
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 18,
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
      constraints: const BoxConstraints(minHeight: 125),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),

          const SizedBox(height: 10),

          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 1,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: dark,
              fontFamily: 'Cairo',
              height: 1.1,
            ),
          ),

          const SizedBox(height: 6),

          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: dark,
                fontFamily: 'Cairo',
                height: 1.2,
              ),
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
    if (status == 'تحتاج متابعة') return const Color(0xFFEAF3FF);
    return softGreen;
  }

  Color _statusColor(String status) {
    if (status == 'خطر') return Colors.red;
    if (status == 'تحتاج متابعة') return const Color(0xFF1F4168);
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
