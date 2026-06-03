import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MedicalInfoScreen extends StatelessWidget {
  final Map<String, dynamic> user;

  const MedicalInfoScreen({super.key, required this.user});

  static const Color dark = Color(0xff172638);
  static const Color primary = Color(0xFF1E3A5F);
  static const Color background = Color(0xFFF7F8FA);
  static const Color card = Colors.white;
  static const Color border = Color(0xFFE5E7EB);
  static const Color softBlue = Color(0xFFEAF2FA);
  static const Color softOrange = Color(0xFFFFF7ED);
  static const Color softGreen = Color(0xFFEEF8F1);
  static const Color softRed = Color(0xFFFFEBEE);
  static const Color warning = Color(0xFFED6C02);
  static const Color danger = Color(0xFFD32F2F);
  static const Color success = Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'يجب تسجيل الدخول أولاً',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          backgroundColor: primary,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text(
            'المعلومات الطبية',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 25,
              fontFamily: 'Cairo',
            ),
          ),
        ),
        body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: primary),
              );
            }

            final currentUserData = snapshot.data?.data();
            final data = currentUserData ?? user;
            final healthProfile = _getHealthProfile(data);

            final doctorName = _safe(
              data['doctorName'] ?? data['doctorFullName'],
              fallback: 'غير محدد',
            );
            final doctorPhone = _safe(
              data['doctorPhone'],
              fallback: 'غير محدد',
            );
            final diseases = _safe(
              healthProfile['diseases'] ?? data['diseases'],
            );
            final diseaseSince = _safe(
              healthProfile['diseaseSince'] ?? data['diseaseSince'],
              fallback: 'غير محدد',
            );
            final medicines = _safe(
              healthProfile['medicines'] ?? data['medicines'],
            );
            final allergy = _safe(
              healthProfile['allergy'] ??
                  healthProfile['allergies'] ??
                  data['allergy'],
            );
            final allergyTypes = _safe(
              healthProfile['allergyTypes'] ?? data['allergyTypes'],
            );
            final surgeries = _safe(
              healthProfile['surgeries'] ?? data['surgeries'],
            );
            final smokingStatus = _safe(
              healthProfile['smokingStatus'] ?? data['smokingStatus'],
            );
            final cigarettesPerDay = _safe(
              healthProfile['cigarettesPerDay'] ?? data['cigarettesPerDay'],
            );
            final bloodType = _safe(
              healthProfile['bloodType'] ?? data['bloodType'],
              fallback: 'غير معروف',
            );
            final bloodPressure = _safe(
              healthProfile['bloodPressure'] ?? data['bloodPressure'],
              fallback: 'غير محدد',
            );
            final sugar = _safe(
              healthProfile['sugar'] ?? data['sugar'],
              fallback: 'غير محدد',
            );
            final heartRate = _safe(
              healthProfile['heartRate'] ?? data['heartRate'],
              fallback: 'غير محدد',
            );
            final age = _safe(data['age'], fallback: 'غير محدد');
            final gender = _safe(data['gender'], fallback: 'غير محدد');
            final phone = _safe(data['phone'], fallback: 'غير محدد');
            final fullName = _safe(
              data['fullName'] ?? data['name'],
              fallback: 'المستخدم',
            );

            return SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _headerCard(fullName: fullName, age: age, gender: gender),
                  const SizedBox(height: 16),
                  _sectionTitle('بيانات التواصل والطبيب'),
                  const SizedBox(height: 10),
                  _infoTile(
                    title: 'رقم الهاتف',
                    value: phone,
                    icon: Icons.phone_outlined,
                    color: softBlue,
                  ),
                  const SizedBox(height: 12),
                  _infoTile(
                    title: 'الطبيب المعالج',
                    value: doctorName,
                    icon: Icons.medical_services_outlined,
                    color: softGreen,
                  ),
                  const SizedBox(height: 12),
                  _infoTile(
                    title: 'رقم الطبيب',
                    value: doctorPhone,
                    icon: Icons.local_phone_outlined,
                    color: softBlue,
                  ),
                  const SizedBox(height: 20),
                  _sectionTitle('الملف الطبي'),
                  const SizedBox(height: 10),
                  _infoTile(
                    title: 'الأمراض المزمنة',
                    value: diseases,
                    icon: Icons.assignment_outlined,
                    color: softOrange,
                  ),
                  const SizedBox(height: 12),
                  _infoTile(
                    title: 'منذ متى لديك المرض',
                    value: diseaseSince,
                    icon: Icons.calendar_month_outlined,
                    color: softBlue,
                  ),
                  const SizedBox(height: 12),
                  _infoTile(
                    title: 'الأدوية المزمنة / اليومية',
                    value: medicines,
                    icon: Icons.medication_outlined,
                    color: softGreen,
                  ),
                  const SizedBox(height: 12),
                  _infoTile(
                    title: 'الحساسية',
                    value: allergy,
                    icon: Icons.warning_amber_rounded,
                    color: allergy == 'لا يوجد' ? softGreen : softRed,
                    iconColor: allergy == 'لا يوجد' ? success : danger,
                  ),
                  const SizedBox(height: 12),
                  _infoTile(
                    title: 'نوع رد فعل الحساسية',
                    value: allergyTypes,
                    icon: Icons.info_outline_rounded,
                    color: softOrange,
                    iconColor: warning,
                  ),
                  const SizedBox(height: 12),
                  _infoTile(
                    title: 'العمليات السابقة',
                    value: surgeries,
                    icon: Icons.local_hospital_outlined,
                    color: softBlue,
                  ),
                  const SizedBox(height: 12),
                  _infoTile(
                    title: 'حالة التدخين',
                    value: smokingStatus,
                    icon: Icons.smoking_rooms_outlined,
                    color: softOrange,
                  ),
                  if (smokingStatus == 'مدخن') ...[
                    const SizedBox(height: 12),
                    _infoTile(
                      title: 'عدد السجائر يوميًا',
                      value: cigarettesPerDay,
                      icon: Icons.numbers_rounded,
                      color: softOrange,
                    ),
                  ],
                  const SizedBox(height: 20),
                  _sectionTitle('مؤشرات صحية مسجلة'),
                  const SizedBox(height: 10),
                  _infoTile(
                    title: 'فصيلة الدم',
                    value: bloodType,
                    icon: Icons.bloodtype_outlined,
                    color: softRed,
                    iconColor: danger,
                  ),
                  const SizedBox(height: 12),
                  _infoTile(
                    title: 'ضغط الدم',
                    value: bloodPressure,
                    icon: Icons.favorite_outline_rounded,
                    color: softBlue,
                  ),
                  const SizedBox(height: 12),
                  _infoTile(
                    title: 'مستوى السكر',
                    value: sugar,
                    icon: Icons.water_drop_outlined,
                    color: softOrange,
                    iconColor: warning,
                  ),
                  const SizedBox(height: 12),
                  _infoTile(
                    title: 'نبض القلب',
                    value: heartRate,
                    icon: Icons.monitor_heart_outlined,
                    color: softGreen,
                    iconColor: success,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _safe(dynamic value, {String fallback = 'لا يوجد'}) {
    if (value == null) return fallback;
    if (value is List) {
      final values = value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty && item != 'null')
          .toList();
      if (values.isEmpty) return fallback;
      return values.join('، ');
    }
    final text = value.toString().trim();
    if (text.isEmpty || text == 'null') return fallback;
    return text;
  }

  Map<String, dynamic> _getHealthProfile(Map<String, dynamic> data) {
    final profile = data['healthProfile'];
    if (profile is Map) return Map<String, dynamic>.from(profile);
    return {};
  }

  Widget _headerCard({
    required String fullName,
    required String age,
    required String gender,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 34,
            backgroundColor: Colors.white,
            child: Icon(Icons.person_rounded, color: primary, size: 38),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'العمر: $age  |  الجنس: $gender',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 17,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      textAlign: TextAlign.right,
      style: const TextStyle(
        fontSize: 23,
        color: dark,
        fontWeight: FontWeight.w900,
        fontFamily: 'Cairo',
      ),
    );
  }

  Widget _infoTile({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    Color iconColor = primary,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: border),
            ),
            child: Icon(icon, color: iconColor, size: 31),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 17,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  value,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 22,
                    color: dark,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Cairo',
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
