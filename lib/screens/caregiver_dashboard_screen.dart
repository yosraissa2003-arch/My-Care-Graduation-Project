import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class CaregiverDashboardScreen extends StatefulWidget {
  const CaregiverDashboardScreen({super.key});

  @override
  State<CaregiverDashboardScreen> createState() =>
      _CaregiverDashboardScreenState();
}

class _CaregiverDashboardScreenState extends State<CaregiverDashboardScreen> {
  static const Color primaryColor = Color(0xFF1E3A5F);
  static const Color backgroundColor = Color(0xFFF7F8FA);
  static const Color cardColor = Colors.white;
  static const Color textColor = Color(0xFF1F2937);
  static const Color secondaryTextColor = Color(0xFF4B5563);
  static const Color dangerColor = Color(0xFFD32F2F);
  static const Color warningColor = Color(0xFFED6C02);
  static const Color successColor = Color(0xFF2E7D32);

  bool loading = true;
  Map<String, dynamic>? caregiverData;
  Map<String, dynamic>? patientData;
  String? patientId;

  @override
  void initState() {
    super.initState();
    loadCaregiverAndPatient();
  }

  Future<void> loadCaregiverAndPatient() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        setState(() => loading = false);
        return;
      }

      final caregiverDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      caregiverData = caregiverDoc.data();

      final linkedPhone =
          (caregiverData?['linkedPatientPhone'] ??
                  caregiverData?['linkedPhone'] ??
                  caregiverData?['linkedPhoneNumber'] ??
                  '')
              .toString();

      if (linkedPhone.isNotEmpty) {
        final patientQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('phone', isEqualTo: linkedPhone)
            .where('role', isEqualTo: 'مريض')
            .limit(1)
            .get();

        if (patientQuery.docs.isNotEmpty) {
          patientId = patientQuery.docs.first.id;
          patientData = patientQuery.docs.first.data();
        }
      }
    } catch (e) {
      debugPrint('Caregiver load error: $e');
    }

    if (mounted) setState(() => loading = false);
  }

  Future<Map<String, dynamic>?> getLastHealthReading() async {
    if (patientId == null) return null;

    try {
      final query = await FirebaseFirestore.instance
          .collection('healthLogs')
          .where('userId', isEqualTo: patientId)
          .get();

      if (query.docs.isEmpty) return null;

      final docs = query.docs;
      docs.sort((a, b) {
        final aTime = a.data()['createdAt'];
        final bTime = b.data()['createdAt'];

        if (aTime is Timestamp && bTime is Timestamp) {
          return bTime.compareTo(aTime);
        }

        return 0;
      });

      return docs.first.data();
    } catch (e) {
      debugPrint('Last health reading error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getLatestActiveSos() async {
    if (patientId == null) return null;

    try {
      final query = await FirebaseFirestore.instance
          .collection('sosAlerts')
          .where('userId', isEqualTo: patientId)
          .where('status', isEqualTo: 'active')
          .get();

      if (query.docs.isEmpty) return null;

      final docs = query.docs;
      docs.sort((a, b) {
        final aTime = a.data()['createdAt'];
        final bTime = b.data()['createdAt'];

        if (aTime is Timestamp && bTime is Timestamp) {
          return bTime.compareTo(aTime);
        }

        return 0;
      });

      return docs.first.data();
    } catch (e) {
      debugPrint('SOS load error: $e');
      return null;
    }
  }

  Future<void> makePhoneCall() async {
    final phone = (patientData?['phone'] ?? '').toString();

    if (phone.isEmpty || phone == 'غير متوفر') {
      showMessage('لا يوجد رقم هاتف للمريض');
      return;
    }

    final uri = Uri.parse('tel:$phone');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      showMessage('تعذر فتح الاتصال');
    }
  }

  Future<void> openPatientLocation(Map<String, dynamic>? sosData) async {
    final latitude = sosData?['latitude'];
    final longitude = sosData?['longitude'];

    if (latitude == null || longitude == null) {
      showMessage('لا يوجد موقع محفوظ لهذا التنبيه');
      return;
    }

    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      showMessage('تعذر فتح الخريطة');
    }
  }

  String getPatientStatus(Map<String, dynamic>? reading) {
    if (reading == null) return 'لا توجد قراءات';

    final heart = double.tryParse('${reading['heartRate'] ?? ''}') ?? 0;
    final oxygen = double.tryParse('${reading['oxygen'] ?? ''}') ?? 0;
    final temp = double.tryParse('${reading['temperature'] ?? ''}') ?? 0;

    if (oxygen > 0 && oxygen < 92) return 'حرجة';
    if (heart > 120 || heart < 45) return 'حرجة';
    if (temp >= 39) return 'حرجة';

    if (oxygen > 0 && oxygen < 95) return 'تحذير';
    if (heart > 100 || heart < 55) return 'تحذير';
    if (temp >= 38) return 'تحذير';

    return 'طبيعية';
  }

  Color statusColor(String status) {
    if (status == 'حرجة') return dangerColor;
    if (status == 'تحذير') return warningColor;
    if (status == 'طبيعية') return successColor;
    return secondaryTextColor;
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.right,
          style: const TextStyle(fontFamily: 'Cairo', fontSize: 16),
        ),
        backgroundColor: primaryColor,
      ),
    );
  }

  Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 21,
          fontFamily: 'Cairo',
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  Widget infoCard({
    required IconData icon,
    required String title,
    required String value,
    Color iconColor = primaryColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 34),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'Cairo',
                    color: secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 20,
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget actionButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color color = primaryColor,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 30),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget patientProfileCard() {
    final name = patientData?['fullName'] ?? 'لا يوجد مريض مرتبط';
    final phone = patientData?['phone'] ?? 'غير متوفر';
    final age = patientData?['age'] ?? 'غير متوفر';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.elderly, color: primaryColor, size: 38),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'العمر: $age',
                  style: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'Cairo',
                    color: secondaryTextColor,
                  ),
                ),
                Text(
                  'الهاتف: $phone',
                  style: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'Cairo',
                    color: secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget healthStatusCard() {
    return FutureBuilder<Map<String, dynamic>?>(
      future: getLastHealthReading(),
      builder: (context, snapshot) {
        final reading = snapshot.data;
        final status = getPatientStatus(reading);

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.monitor_heart,
                    color: statusColor(status),
                    size: 34,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'حالة المريض الآن: $status',
                      style: TextStyle(
                        fontSize: 21,
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        color: statusColor(status),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              infoCard(
                icon: Icons.favorite,
                title: 'نبض القلب',
                value: '${reading?['heartRate'] ?? 'لا يوجد'}',
                iconColor: dangerColor,
              ),
              infoCard(
                icon: Icons.air,
                title: 'الأكسجين',
                value: '${reading?['oxygen'] ?? 'لا يوجد'}',
                iconColor: primaryColor,
              ),
              infoCard(
                icon: Icons.thermostat,
                title: 'الحرارة',
                value: '${reading?['temperature'] ?? 'لا يوجد'}',
                iconColor: warningColor,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget sosCard() {
    return FutureBuilder<Map<String, dynamic>?>(
      future: getLatestActiveSos(),
      builder: (context, snapshot) {
        final sosData = snapshot.data;
        final hasSos = sosData != null;
        final message = hasSos
            ? (sosData['message'] ?? 'المريض يحتاج مساعدة فورية').toString()
            : 'لا يوجد طلب طوارئ نشط حالياً. سيظهر هنا إذا ضغط المريض زر SOS.';

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: hasSos
                ? dangerColor.withOpacity(0.10)
                : dangerColor.withOpacity(0.06),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: hasSos
                  ? dangerColor.withOpacity(0.45)
                  : dangerColor.withOpacity(0.22),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: dangerColor,
                    size: 36,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      hasSos ? 'طلب طوارئ نشط SOS' : 'منطقة الطوارئ SOS',
                      style: const TextStyle(
                        fontSize: 22,
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        color: dangerColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 16,
                  fontFamily: 'Cairo',
                  color: textColor,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  actionButton(
                    icon: Icons.call,
                    title: 'اتصال',
                    color: dangerColor,
                    onTap: makePhoneCall,
                  ),
                  const SizedBox(width: 12),
                  actionButton(
                    icon: Icons.location_on,
                    title: 'الموقع',
                    color: warningColor,
                    onTap: () => openPatientLocation(sosData),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget quickActions() {
    return Row(
      children: [
        actionButton(
          icon: Icons.person,
          title: 'بيانات المريض',
          onTap: () {
            if (patientData == null) {
              showMessage('لا يوجد مريض مرتبط بعد');
              return;
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    CaregiverPatientDetailsScreen(patientData: patientData!),
              ),
            );
          },
        ),
        const SizedBox(width: 12),
        actionButton(
          icon: Icons.notifications_active,
          title: 'التنبيهات',
          color: warningColor,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CaregiverNotificationsScreen(),
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final caregiverName = caregiverData?['fullName'] ?? '';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: primaryColor,
          title: const Text(
            'متابعة المريض',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: loadCaregiverAndPatient,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(
                      caregiverName.isEmpty
                          ? 'أهلاً بك'
                          : 'أهلاً $caregiverName',
                      style: const TextStyle(
                        fontSize: 26,
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'تابعي حالة المريض والتنبيهات المهمة من هنا.',
                      style: TextStyle(
                        fontSize: 17,
                        fontFamily: 'Cairo',
                        color: secondaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 22),

                    sectionTitle('المريض المرتبط'),
                    patientProfileCard(),

                    const SizedBox(height: 18),
                    sectionTitle('الحالة الصحية'),
                    healthStatusCard(),

                    const SizedBox(height: 18),
                    sectionTitle('الطوارئ'),
                    sosCard(),

                    const SizedBox(height: 18),
                    sectionTitle('الخدمات السريعة'),
                    quickActions(),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }
}

class CaregiverPatientDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> patientData;

  const CaregiverPatientDetailsScreen({super.key, required this.patientData});

  @override
  Widget build(BuildContext context) {
    final health = patientData['healthProfile'] as Map<String, dynamic>? ?? {};

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E3A5F),
          title: const Text(
            'بيانات المريض',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _card('المعلومات الأساسية', [
              'الاسم: ${patientData['fullName'] ?? 'غير متوفر'}',
              'الهاتف: ${patientData['phone'] ?? 'غير متوفر'}',
              'العمر: ${patientData['age'] ?? 'غير متوفر'}',
              'الجنس: ${patientData['gender'] ?? 'غير متوفر'}',
              'رقم الطوارئ: ${patientData['emergencyContact'] ?? 'غير متوفر'}',
            ]),
            _card('المعلومات الطبية', [
              'الأمراض: ${health['diseases'] ?? 'غير متوفر'}',
              'منذ: ${health['diseaseSince'] ?? 'غير متوفر'}',
              'الأدوية: ${health['medicines'] ?? 'غير متوفر'}',
              'الحساسية: ${health['allergy'] ?? 'غير متوفر'}',
              'نوع الحساسية: ${health['allergyTypes'] ?? 'غير متوفر'}',
              'العمليات السابقة: ${health['surgeries'] ?? 'غير متوفر'}',
              'التدخين: ${health['smokingStatus'] ?? 'غير متوفر'}',
              'فصيلة الدم: ${health['bloodType'] ?? 'غير متوفر'}',
            ]),
          ],
        ),
      ),
    );
  }

  Widget _card(String title, List<String> items) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A5F),
            ),
          ),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                item,
                style: const TextStyle(
                  fontSize: 17,
                  fontFamily: 'Cairo',
                  color: Color(0xFF1F2937),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CaregiverNotificationsScreen extends StatelessWidget {
  const CaregiverNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifications = [
      {
        'icon': Icons.warning_amber_rounded,
        'title': 'حالة طارئة',
        'body': 'إذا ضغط المريض SOS ستظهر هنا.',
        'color': Color(0xFFD32F2F),
      },
      {
        'icon': Icons.monitor_heart,
        'title': 'تنبيه صحي',
        'body': 'أي قراءة خطرة أو غير طبيعية ستظهر هنا.',
        'color': Color(0xFFED6C02),
      },
      {
        'icon': Icons.medication,
        'title': 'تنبيه دواء',
        'body': 'إذا لم يأخذ المريض الدواء سيظهر التنبيه هنا.',
        'color': Color(0xFF1E3A5F),
      },
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E3A5F),
          title: const Text(
            'تنبيهات المرافق',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        body: ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final item = notifications[index];
            final color = item['color'] as Color;

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  Icon(item['icon'] as IconData, color: color, size: 34),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['title'] as String,
                          style: TextStyle(
                            fontSize: 20,
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item['body'] as String,
                          style: const TextStyle(
                            fontSize: 16,
                            fontFamily: 'Cairo',
                            color: Color(0xFF4B5563),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
