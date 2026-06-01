import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'doctor_patient_details_screen.dart';
import 'package:mycare/screens/login_screen.dart';

class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  static const Color primaryColor = Color(0xFF1E3A5F);
  static const Color backgroundColor = Color(0xFFF7F8FA);
  static const Color cardColor = Colors.white;
  static const Color textColor = Color(0xFF1F2937);
  static const Color secondaryTextColor = Color(0xFF4B5563);
  static const Color warningColor = Color(0xFFED6C02);
  static const Color successColor = Color(0xFF2E7D32);
  static const Color errorColor = Color(0xFFD32F2F);

  Future<Map<String, dynamic>> loadDoctorData() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final doctorDoc = await FirebaseFirestore.instance
        .collection('doctor_profiles')
        .doc(uid)
        .get();

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    final doctorData = doctorDoc.data() ?? {};
    final userData = userDoc.data() ?? {};

    final doctorPhone = doctorData['phone'] ?? userData['phone'] ?? '';

    final linksSnapshot = await FirebaseFirestore.instance
        .collection('doctor_patient_links')
        .where('doctorPhone', isEqualTo: doctorPhone)
        .get();

    final List<Map<String, dynamic>> patients = [];

    for (final link in linksSnapshot.docs) {
      final linkData = link.data();
      final patientId = linkData['patientId'];

      if (patientId == null) continue;

      final patientUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(patientId)
          .get();

      final medicalDoc = await FirebaseFirestore.instance
          .collection('medical_profiles')
          .doc(patientId)
          .get();

      if (!patientUserDoc.exists) continue;

      patients.add({
        'linkId': link.id,
        'patientId': patientId,
        'linkStatus': linkData['status'] ?? 'pending',
        'user': patientUserDoc.data() ?? {},
        'medical': medicalDoc.data() ?? {},
      });
    }

    return {'doctor': doctorData, 'user': userData, 'patients': patients};
  }

  String getRiskStatus(Map<String, dynamic> medical) {
    final readings = medical['lastReadings'] ?? {};

    final heartRate =
        double.tryParse((readings['heartRate'] ?? '').toString()) ?? 0;

    final sugar = double.tryParse((readings['sugar'] ?? '').toString()) ?? 0;

    final bloodPressure = (readings['bloodPressure'] ?? '').toString();
    double systolic = 0;

    if (bloodPressure.contains('/')) {
      systolic = double.tryParse(bloodPressure.split('/').first) ?? 0;
    }

    if (heartRate > 120 || sugar > 250 || systolic > 180) {
      return 'Critical';
    }

    if (heartRate > 100 || sugar > 180 || systolic > 140) {
      return 'Warning';
    }

    return 'Normal';
  }

  Color getStatusColor(String status) {
    if (status == 'Critical') return errorColor;
    if (status == 'Warning') return warningColor;
    return successColor;
  }

  Widget buildDoctorCard(
    Map<String, dynamic> doctor,
    Map<String, dynamic> user,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 34,
            backgroundColor: primaryColor,
            child: Icon(Icons.medical_services, color: Colors.white, size: 34),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['fullName'] ?? doctor['fullName'] ?? 'طبيب',
                  style: const TextStyle(
                    fontSize: 20,
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  doctor['specialty'] ?? 'تخصص غير محدد',
                  style: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'Cairo',
                    color: secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'كود الطبيب: ${doctor['doctorCode'] ?? '-'}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontFamily: 'Cairo',
                    color: primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildPatientCard(Map<String, dynamic> patientItem) {
    final user = patientItem['user'] as Map<String, dynamic>;
    final medical = patientItem['medical'] as Map<String, dynamic>;
    final patientId = patientItem['patientId'];
    final status = getRiskStatus(medical);
    final statusColor = getStatusColor(status);

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DoctorPatientDetailsScreen(
              patientId: patientId,
              patientName: user['fullName'] ?? 'مريض',
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: statusColor.withOpacity(0.15),
              child: Icon(Icons.person, color: statusColor, size: 30),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user['fullName'] ?? 'مريض',
                    style: const TextStyle(
                      fontSize: 19,
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'الحالة: $status',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Cairo',
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'العمر: ${user['age'] ?? medical['age'] ?? '-'}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontFamily: 'Cairo',
                      color: secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: secondaryTextColor),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: primaryColor,
          title: const Text(
            '🩺 إدارة المرضى',
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
        body: FutureBuilder<Map<String, dynamic>>(
          future: loadDoctorData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return const Center(
                child: Text(
                  'حدث خطأ أثناء تحميل بيانات الطبيب',
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 18),
                ),
              );
            }

            final data = snapshot.data ?? {};
            final doctor = data['doctor'] ?? {};
            final user = data['user'] ?? {};
            final patients =
                (data['patients'] ?? []) as List<Map<String, dynamic>>;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  buildDoctorCard(doctor, user),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      const Icon(Icons.groups, color: primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        'المرضى المرتبطين (${patients.length})',
                        style: const TextStyle(
                          fontSize: 20,
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  if (patients.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'لا يوجد مرضى مرتبطين بهذا الطبيب حاليًا.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontFamily: 'Cairo',
                          color: secondaryTextColor,
                        ),
                      ),
                    )
                  else
                    ...patients.map(buildPatientCard),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
