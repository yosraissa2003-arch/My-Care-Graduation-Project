import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mycare/screens/login_screen.dart';

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
    if (patientId == null && patientData == null) return null;

    try {
      final List<QueryDocumentSnapshot<Map<String, dynamic>>> allDocs = [];
      final patientPhone = (patientData?['phone'] ?? '').toString();
      final originalPhone = (patientData?['originalPhone'] ?? '').toString();

      final possibleIds = <String>{
        if (patientId != null) patientId!,
        if ((patientData?['uid'] ?? '').toString().isNotEmpty)
          (patientData?['uid']).toString(),
        if ((patientData?['userId'] ?? '').toString().isNotEmpty)
          (patientData?['userId']).toString(),
        if ((patientData?['patientId'] ?? '').toString().isNotEmpty)
          (patientData?['patientId']).toString(),
      };

      for (final id in possibleIds) {
        final byUserId = await FirebaseFirestore.instance
            .collection('healthLogs')
            .where('userId', isEqualTo: id)
            .get();
        allDocs.addAll(byUserId.docs);

        final byPatientId = await FirebaseFirestore.instance
            .collection('healthLogs')
            .where('patientId', isEqualTo: id)
            .get();
        allDocs.addAll(byPatientId.docs);

        final oldByPatientId = await FirebaseFirestore.instance
            .collection('health_readings')
            .where('patientId', isEqualTo: id)
            .get();
        allDocs.addAll(oldByPatientId.docs);
      }

      for (final phone in {patientPhone, originalPhone}) {
        if (phone.isEmpty) continue;

        final byPhone = await FirebaseFirestore.instance
            .collection('healthLogs')
            .where('patientPhone', isEqualTo: phone)
            .get();
        allDocs.addAll(byPhone.docs);

        final oldByPhone = await FirebaseFirestore.instance
            .collection('health_readings')
            .where('patientPhone', isEqualTo: phone)
            .get();
        allDocs.addAll(oldByPhone.docs);
      }

      final uniqueDocs =
          <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
      for (final doc in allDocs) {
        uniqueDocs[doc.id] = doc;
      }

      final docs = uniqueDocs.values.toList();

      if (docs.isEmpty) {
        final lastReading = patientData?['lastHealthReading'];
        if (lastReading is Map<String, dynamic> && lastReading.isNotEmpty) {
          return Map<String, dynamic>.from(lastReading);
        }

        return null;
      }

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
    if (patientId == null && patientData == null) return null;

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final patientPhone = (patientData?['phone'] ?? '').toString();
      final originalPhone = (patientData?['originalPhone'] ?? '').toString();
      final emergencyContact = (patientData?['emergencyContact'] ?? '')
          .toString();
      final List<QueryDocumentSnapshot<Map<String, dynamic>>> allDocs = [];

      final possibleIds = <String>{
        if (patientId != null) patientId!,
        if ((patientData?['uid'] ?? '').toString().isNotEmpty)
          (patientData?['uid']).toString(),
        if ((patientData?['userId'] ?? '').toString().isNotEmpty)
          (patientData?['userId']).toString(),
      };

      for (final id in possibleIds) {
        final byUserId = await FirebaseFirestore.instance
            .collection('sosAlerts')
            .where('userId', isEqualTo: id)
            .where('status', isEqualTo: 'active')
            .get();
        allDocs.addAll(byUserId.docs);

        final byPatientId = await FirebaseFirestore.instance
            .collection('sosAlerts')
            .where('patientId', isEqualTo: id)
            .where('status', isEqualTo: 'active')
            .get();
        allDocs.addAll(byPatientId.docs);
      }

      for (final phone in {patientPhone, originalPhone}) {
        if (phone.isEmpty) continue;

        final byPatientPhone = await FirebaseFirestore.instance
            .collection('sosAlerts')
            .where('patientPhone', isEqualTo: phone)
            .where('status', isEqualTo: 'active')
            .get();
        allDocs.addAll(byPatientPhone.docs);
      }

      if (emergencyContact.isNotEmpty) {
        final byEmergencyPhone = await FirebaseFirestore.instance
            .collection('sosAlerts')
            .where('emergencyPhone', isEqualTo: emergencyContact)
            .where('status', isEqualTo: 'active')
            .get();
        allDocs.addAll(byEmergencyPhone.docs);
      }

      if (uid != null) {
        final byCaregiver = await FirebaseFirestore.instance
            .collection('sosAlerts')
            .where('caregiverId', isEqualTo: uid)
            .where('status', isEqualTo: 'active')
            .get();
        allDocs.addAll(byCaregiver.docs);
      }

      final uniqueDocs =
          <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
      for (final doc in allDocs) {
        uniqueDocs[doc.id] = doc;
      }

      final docs = uniqueDocs.values.toList();
      if (docs.isEmpty) return null;

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
    final phone = (patientData?['phone'] ?? patientData?['originalPhone'] ?? '')
        .toString();

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
    try {
      dynamic latitude = sosData?['latitude'] ?? sosData?['lat'];
      dynamic longitude = sosData?['longitude'] ?? sosData?['lng'];

      if ((latitude == null || longitude == null) &&
          sosData?['location'] is Map) {
        final location = sosData!['location'] as Map;
        latitude = location['latitude'] ?? location['lat'];
        longitude = location['longitude'] ?? location['lng'];
      }

      final latText = latitude?.toString().trim() ?? '';
      final lngText = longitude?.toString().trim() ?? '';

      if (latText.isEmpty ||
          lngText.isEmpty ||
          latText == 'null' ||
          lngText == 'null') {
        showMessage('لا يوجد موقع محفوظ لهذا التنبيه');
        return;
      }

      final uri = Uri.parse('https://maps.google.com/?q=$latText,$lngText');

      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Location Error: $e');
      showMessage('تعذر فتح الخريطة');
    }
  }

  String getPatientStatus(Map<String, dynamic>? reading) {
    if (reading == null) return 'لا توجد قراءات';

    final heart = double.tryParse('${reading['heartRate'] ?? ''}') ?? 0;
    final oxygen =
        double.tryParse(
          '${reading['oxygen'] ?? reading['oxygenLevel'] ?? ''}',
        ) ??
        0;
    final temp = double.tryParse('${reading['temperature'] ?? ''}') ?? 0;
    final glucose =
        double.tryParse('${reading['glucose'] ?? reading['sugar'] ?? ''}') ?? 0;
    final systolic =
        double.tryParse('${reading['bloodPressureSystolic'] ?? ''}') ?? 0;
    final diastolic =
        double.tryParse('${reading['bloodPressureDiastolic'] ?? ''}') ?? 0;

    if (oxygen > 0 && oxygen < 92) return 'حرجة';
    if (heart > 120 || heart < 45) return 'حرجة';
    if (temp >= 39) return 'حرجة';
    if (glucose > 250 || (glucose > 0 && glucose < 70)) return 'حرجة';
    if (systolic >= 180 || diastolic >= 120) return 'حرجة';

    if (oxygen > 0 && oxygen < 95) return 'تحذير';
    if (heart > 100 || heart < 55) return 'تحذير';
    if (temp >= 38) return 'تحذير';
    if (glucose > 180) return 'تحذير';
    if (systolic >= 140 || diastolic >= 90) return 'تحذير';

    return 'طبيعية';
  }

  String readingValue(Map<String, dynamic>? reading, List<String> keys) {
    if (reading == null) return 'لا يوجد';

    for (final key in keys) {
      final value = reading[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }

    return 'لا يوجد';
  }

  String bloodPressureValue(Map<String, dynamic>? reading) {
    if (reading == null) return 'لا يوجد';

    final full = reading['bloodPressure'];
    if (full != null && full.toString().trim().isNotEmpty) {
      return full.toString();
    }

    final systolic = reading['bloodPressureSystolic'];
    final diastolic = reading['bloodPressureDiastolic'];

    if (systolic != null && diastolic != null) {
      return '$systolic/$diastolic';
    }

    return 'لا يوجد';
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
                value: readingValue(reading, ['heartRate']),
                iconColor: dangerColor,
              ),
              infoCard(
                icon: Icons.bloodtype,
                title: 'ضغط الدم',
                value: bloodPressureValue(reading),
                iconColor: primaryColor,
              ),
              infoCard(
                icon: Icons.water_drop,
                title: 'السكر',
                value: readingValue(reading, ['glucose', 'sugar']),
                iconColor: warningColor,
              ),
              infoCard(
                icon: Icons.air,
                title: 'الأكسجين',
                value: readingValue(reading, ['oxygen', 'oxygenLevel']),
                iconColor: primaryColor,
              ),
              infoCard(
                icon: Icons.thermostat,
                title: 'الحرارة',
                value: readingValue(reading, ['temperature']),
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
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              tooltip: 'تسجيل الخروج',
              onPressed: () async {
                await FirebaseAuth.instance.signOut();

                if (!mounted) return;

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
            ),
          ],
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

class CaregiverNotificationsScreen extends StatefulWidget {
  const CaregiverNotificationsScreen({super.key});

  @override
  State<CaregiverNotificationsScreen> createState() =>
      _CaregiverNotificationsScreenState();
}

class _CaregiverNotificationsScreenState
    extends State<CaregiverNotificationsScreen> {
  static const Color primaryColor = Color(0xFF1E3A5F);
  static const Color backgroundColor = Color(0xFFF7F8FA);
  static const Color textColor = Color(0xFF1F2937);
  static const Color secondaryTextColor = Color(0xFF4B5563);
  static const Color dangerColor = Color(0xFFD32F2F);
  static const Color warningColor = Color(0xFFED6C02);

  bool loading = true;
  String? patientId;
  String? patientPhone;
  String? patientOriginalPhone;
  String? caregiverId;

  @override
  void initState() {
    super.initState();
    loadLinkedPatient();
  }

  Future<void> loadLinkedPatient() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      caregiverId = uid;

      if (uid == null) {
        if (mounted) setState(() => loading = false);
        return;
      }

      final caregiverDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      final caregiver = caregiverDoc.data() ?? {};
      final linkedPhone =
          (caregiver['linkedPatientPhone'] ??
                  caregiver['linkedPhone'] ??
                  caregiver['linkedPhoneNumber'] ??
                  '')
              .toString()
              .trim();

      if (linkedPhone.isNotEmpty) {
        final patientQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('phone', isEqualTo: linkedPhone)
            .where('role', isEqualTo: 'مريض')
            .limit(1)
            .get();

        if (patientQuery.docs.isNotEmpty) {
          final doc = patientQuery.docs.first;
          final patient = doc.data();
          patientId = doc.id;
          patientPhone = (patient['phone'] ?? '').toString();
          patientOriginalPhone = (patient['originalPhone'] ?? '').toString();
        }
      }
    } catch (e) {
      debugPrint('Caregiver notifications load error: $e');
    }

    if (mounted) setState(() => loading = false);
  }

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
      case 'sos':
        return dangerColor;
      case 'warning':
        return warningColor;
      default:
        return primaryColor;
    }
  }

  String formatTime(dynamic timestamp) {
    if (timestamp == null || timestamp is! Timestamp) return '';
    final date = timestamp.toDate();
    int hour = date.hour;
    final minute = date.minute;
    final period = hour >= 12 ? 'مساءً' : 'صباحًا';
    if (hour > 12) hour -= 12;
    if (hour == 0) hour = 12;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  loadNotifications() async {
    final ids = <String>{
      if (caregiverId != null && caregiverId!.isNotEmpty) caregiverId!,
    };

    final patientIds = <String>{
      if (patientId != null && patientId!.isNotEmpty) patientId!,
    };

    final phones = <String>{
      if (patientPhone != null && patientPhone!.isNotEmpty) patientPhone!,
      if (patientOriginalPhone != null && patientOriginalPhone!.isNotEmpty)
        patientOriginalPhone!,
    };

    final Map<String, QueryDocumentSnapshot<Map<String, dynamic>>> result = {};

    Future<void> addQuery(Query<Map<String, dynamic>> query) async {
      try {
        final snap = await query.get();
        for (final doc in snap.docs) {
          result[doc.id] = doc;
        }
      } catch (e) {
        debugPrint('Notification query ignored: $e');
      }
    }

    for (final id in ids) {
      await addQuery(
        FirebaseFirestore.instance
            .collection('notifications')
            .where('caregiverId', isEqualTo: id),
      );
      await addQuery(
        FirebaseFirestore.instance
            .collection('notifications')
            .where('recipientId', isEqualTo: id),
      );
    }

    for (final id in patientIds) {
      await addQuery(
        FirebaseFirestore.instance
            .collection('notifications')
            .where('patientId', isEqualTo: id),
      );
      await addQuery(
        FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: id),
      );
    }

    for (final phone in phones) {
      await addQuery(
        FirebaseFirestore.instance
            .collection('notifications')
            .where('patientPhone', isEqualTo: phone),
      );
    }

    final docs = result.values.where((doc) {
      final data = doc.data();
      final nCaregiverId = (data['caregiverId'] ?? data['recipientId'] ?? '')
          .toString();
      final nPatientId = (data['patientId'] ?? data['userId'] ?? '').toString();
      final nPatientPhone = (data['patientPhone'] ?? '').toString();

      final matchesCaregiver =
          caregiverId != null &&
          caregiverId!.isNotEmpty &&
          nCaregiverId == caregiverId;
      final matchesPatient =
          patientId != null && patientId!.isNotEmpty && nPatientId == patientId;
      final matchesPhone =
          nPatientPhone.isNotEmpty && phones.contains(nPatientPhone);

      return matchesCaregiver || matchesPatient || matchesPhone;
    }).toList();

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

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: backgroundColor,
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (caregiverId == null) {
      return const Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: backgroundColor,
          body: Center(child: Text('يجب تسجيل الدخول أولاً')),
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: primaryColor,
          title: const Text(
            'تنبيهات المرافق',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        body: FutureBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
          future: loadNotifications(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return const Center(
                child: Text(
                  'حدث خطأ أثناء تحميل التنبيهات',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 18,
                    color: textColor,
                  ),
                ),
              );
            }

            final notifications = snapshot.data ?? [];

            if (notifications.isEmpty) {
              return const Center(
                child: Text(
                  'لا توجد تنبيهات لهذا المريض حالياً',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: secondaryTextColor,
                  ),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async => setState(() {}),
              child: ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: notifications.length,
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final data = notifications[index].data();
                  final type = (data['type'] ?? 'general').toString();
                  final color = getColor(type);

                  return Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: color.withOpacity(0.20)),
                    ),
                    child: Row(
                      children: [
                        Icon(getIcon(type), color: color, size: 34),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (data['title'] ?? 'تنبيه').toString(),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontFamily: 'Cairo',
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                (data['message'] ?? '').toString(),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontFamily: 'Cairo',
                                  color: textColor,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                (data['time'] ?? formatTime(data['createdAt']))
                                    .toString(),
                                style: const TextStyle(
                                  fontSize: 14,
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
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
