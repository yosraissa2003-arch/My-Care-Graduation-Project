import 'package:flutter/material.dart';

class MedicalInfoScreen extends StatelessWidget {
  final Map<String, dynamic> user;

  const MedicalInfoScreen({super.key, required this.user});

  static const Color dark = Color(0xff172638);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: dark),
        title: const Text(
          'المعلومات الطبية',
          style: TextStyle(
            color: dark,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            /// الطبيب
            _infoTile(
              title: 'الطبيب المعالج',
              value: user['doctorName'] ?? 'غير محدد',
              icon: Icons.medical_services_outlined,
            ),

            const SizedBox(height: 14),

            /// رقم الطبيب
            _infoTile(
              title: 'رقم الطبيب',
              value: user['doctorPhone'] ?? 'غير محدد',
              icon: Icons.phone_outlined,
            ),

            const SizedBox(height: 14),

            /// الأمراض
            _infoTile(
              title: 'الأمراض',
              value: _formatDiseases(user['diseases']),
              icon: Icons.assignment_outlined,
            ),

            const SizedBox(height: 14),

            /// فصيلة الدم
            _infoTile(
              title: 'فصيلة الدم',
              value: user['bloodType'] ?? 'غير معروف',
              icon: Icons.bloodtype_outlined,
            ),

            const SizedBox(height: 14),

            /// الحساسية
            _infoTile(
              title: 'الحساسية',
              value: user['allergy'] == '' ? 'لا يوجد' : user['allergy'],
              icon: Icons.warning_amber_rounded,
            ),

            const SizedBox(height: 14),

            /// العمر
            _infoTile(
              title: 'العمر',
              value: user['age'] ?? 'غير محدد',
              icon: Icons.person_outline,
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoTile({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xffF8F8F8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xffE5E5E5)),
      ),

      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          /// الأيقونة
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xffE5E5E5)),
            ),
            child: Icon(icon, color: dark, size: 30),
          ),

          const SizedBox(width: 16),

          /// النصوص
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  value,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 24,
                    color: dark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDiseases(dynamic diseases) {
    if (diseases == null) return 'لا يوجد';

    if (diseases is List) {
      return diseases.join('، ');
    }

    return diseases.toString();
  }
}
