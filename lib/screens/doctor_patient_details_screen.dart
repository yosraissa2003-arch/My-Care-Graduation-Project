import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DoctorPatientDetailsScreen extends StatefulWidget {
  final String patientId;
  final String patientName;

  const DoctorPatientDetailsScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  State<DoctorPatientDetailsScreen> createState() =>
      _DoctorPatientDetailsScreenState();
}

class _DoctorPatientDetailsScreenState
    extends State<DoctorPatientDetailsScreen> {
  static const Color primaryColor = Color(0xFF1E3A5F);
  static const Color backgroundColor = Color(0xFFF7F8FA);
  static const Color cardColor = Colors.white;
  static const Color textColor = Color(0xFF1F2937);
  static const Color secondaryTextColor = Color(0xFF4B5563);
  static const Color warningColor = Color(0xFFED6C02);
  static const Color successColor = Color(0xFF2E7D32);
  static const Color errorColor = Color(0xFFD32F2F);

  final TextEditingController noteController = TextEditingController();

  @override
  void dispose() {
    noteController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> loadPatientData() async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.patientId)
        .get();

    final medicalDoc = await FirebaseFirestore.instance
        .collection('medical_profiles')
        .doc(widget.patientId)
        .get();

    final notesSnapshot = await FirebaseFirestore.instance
        .collection('doctor_notes')
        .where('patientId', isEqualTo: widget.patientId)
        .get();

    return {
      'user': userDoc.data() ?? {},
      'medical': medicalDoc.data() ?? {},
      'notes': notesSnapshot.docs.map((e) => e.data()).toList(),
    };
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

  Future<void> addDoctorNote() async {
    final note = noteController.text.trim();

    if (note.isEmpty) return;

    final doctorId = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance.collection('doctor_notes').add({
      'doctorId': doctorId,
      'patientId': widget.patientId,
      'note': note,
      'createdAt': FieldValue.serverTimestamp(),
    });

    noteController.clear();
    setState(() {});
  }

  Widget buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: primaryColor),
              const SizedBox(width: 8),
              Text(
                title,
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
          ...children,
        ],
      ),
    );
  }

  Widget buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 16,
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(
                fontSize: 16,
                fontFamily: 'Cairo',
                color: secondaryTextColor,
              ),
            ),
          ),
        ],
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
          title: Text(
            widget.patientName,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        body: FutureBuilder<Map<String, dynamic>>(
          future: loadPatientData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final data = snapshot.data ?? {};
            final user = data['user'] ?? {};
            final medical = data['medical'] ?? {};
            final notes = (data['notes'] ?? []) as List;

            final readings = medical['lastReadings'] ?? {};
            final status = getRiskStatus(medical);
            final statusColor = getStatusColor(status);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'AI Health Status',
                          style: TextStyle(
                            fontSize: 18,
                            fontFamily: 'Cairo',
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          status,
                          style: TextStyle(
                            fontSize: 28,
                            fontFamily: 'Cairo',
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  buildInfoCard(
                    title: 'البيانات الأساسية',
                    icon: Icons.person,
                    children: [
                      buildRow('الاسم', user['fullName'] ?? ''),
                      buildRow('العمر', user['age'] ?? medical['age'] ?? ''),
                      buildRow(
                        'الجنس',
                        user['gender'] ?? medical['gender'] ?? '',
                      ),
                      buildRow('فصيلة الدم', medical['bloodType'] ?? ''),
                      buildRow('رقم الهاتف', user['phone'] ?? ''),
                    ],
                  ),

                  buildInfoCard(
                    title: 'الملف الطبي',
                    icon: Icons.medical_information,
                    children: [
                      buildRow(
                        'الأمراض المزمنة',
                        medical['pastMedicalHistory'] ?? '',
                      ),
                      buildRow('منذ متى', medical['diseaseSince'] ?? ''),
                      buildRow(
                        'الأدوية المزمنة',
                        medical['chronicMedicines'] ?? '',
                      ),
                      buildRow('الحساسية', medical['allergies'] ?? ''),
                      buildRow('نوع الحساسية', medical['allergyTypes'] ?? ''),
                      buildRow(
                        'العمليات السابقة',
                        medical['pastSurgicalHistory'] ?? '',
                      ),
                      buildRow('التدخين', medical['smokingStatus'] ?? ''),
                    ],
                  ),

                  buildInfoCard(
                    title: 'آخر القراءات',
                    icon: Icons.monitor_heart,
                    children: [
                      buildRow(
                        'ضغط الدم',
                        readings['bloodPressure']?.toString() ?? '',
                      ),
                      buildRow('السكر', readings['sugar']?.toString() ?? ''),
                      buildRow(
                        'نبض القلب',
                        readings['heartRate']?.toString() ?? '',
                      ),
                    ],
                  ),

                  buildInfoCard(
                    title: 'ملاحظة الطبيب',
                    icon: Icons.edit_note,
                    children: [
                      TextField(
                        controller: noteController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'اكتب ملاحظة طبية...',
                          filled: true,
                          fillColor: backgroundColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: addDoctorNote,
                          icon: const Icon(Icons.save, color: Colors.white),
                          label: const Text(
                            'حفظ الملاحظة',
                            style: TextStyle(
                              fontSize: 17,
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  buildInfoCard(
                    title: 'ملاحظات سابقة',
                    icon: Icons.notes,
                    children: notes.isEmpty
                        ? [
                            const Text(
                              'لا توجد ملاحظات بعد.',
                              style: TextStyle(
                                fontSize: 16,
                                fontFamily: 'Cairo',
                                color: secondaryTextColor,
                              ),
                            ),
                          ]
                        : notes.map((note) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: backgroundColor,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                note['note'] ?? '',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontFamily: 'Cairo',
                                  color: textColor,
                                ),
                              ),
                            );
                          }).toList(),
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
