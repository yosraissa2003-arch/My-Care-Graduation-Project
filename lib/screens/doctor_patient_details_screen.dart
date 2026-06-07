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

    final healthLogsSnapshot = await FirebaseFirestore.instance
        .collection('healthLogs')
        .where('userId', isEqualTo: widget.patientId)
        .get();

    final notesSnapshot = await FirebaseFirestore.instance
        .collection('doctor_notes')
        .where('patientId', isEqualTo: widget.patientId)
        .get();

    final moodSnapshot = await FirebaseFirestore.instance
        .collection('moodLogs')
        .where('userId', isEqualTo: widget.patientId)
        .get();

    final healthLogs = healthLogsSnapshot.docs.toList();
    healthLogs.sort((a, b) {
      final aTime = a.data()['createdAt'];
      final bTime = b.data()['createdAt'];

      if (aTime is Timestamp && bTime is Timestamp) {
        return bTime.compareTo(aTime);
      }

      return 0;
    });

    final notes = notesSnapshot.docs.toList();
    notes.sort((a, b) {
      final aTime = a.data()['createdAt'];
      final bTime = b.data()['createdAt'];

      if (aTime is Timestamp && bTime is Timestamp) {
        return bTime.compareTo(aTime);
      }

      return 0;
    });

    final moodLogs = moodSnapshot.docs.toList();
    moodLogs.sort((a, b) {
      final aTime = a.data()['createdAt'];
      final bTime = b.data()['createdAt'];

      if (aTime is Timestamp && bTime is Timestamp) {
        return bTime.compareTo(aTime);
      }

      return 0;
    });

    Map<String, dynamic> todayMood = {};
    final today = _todayKey();

    for (final moodDoc in moodLogs) {
      final mood = moodDoc.data();
      if ((mood['dateKey'] ?? '').toString() == today) {
        todayMood = mood;
        break;
      }
    }

    if (todayMood.isEmpty && moodLogs.isNotEmpty) {
      todayMood = moodLogs.first.data();
    }

    return {
      'user': userDoc.data() ?? {},
      'medical': medicalDoc.data() ?? {},
      'lastHealthLog': healthLogs.isNotEmpty ? healthLogs.first.data() : {},
      'latestMood': todayMood,
      'notes': notes.map((e) => e.data()).toList(),
    };
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  String getValue(dynamic value) {
    if (value == null) return '';
    final text = value.toString().trim();
    if (text.isEmpty || text == 'null') return '';
    return text;
  }

  String getBloodPressure(Map<String, dynamic> readings) {
    final direct = getValue(readings['bloodPressure']);
    if (direct.isNotEmpty) return direct;

    final systolic = getValue(readings['bloodPressureSystolic']);
    final diastolic = getValue(readings['bloodPressureDiastolic']);

    if (systolic.isNotEmpty && diastolic.isNotEmpty) {
      return '$systolic/$diastolic';
    }

    return '';
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  String getMoodEmoji(Map<String, dynamic> mood) {
    final emoji = (mood['emoji'] ?? '').toString().trim();
    if (emoji.isNotEmpty) return emoji;

    final text = '${mood['moodLabel'] ?? mood['label'] ?? mood['mood'] ?? ''}';

    if (text.contains('جيد') ||
        text.contains('سعيد') ||
        text.contains('good')) {
      return '🙂';
    }
    if (text.contains('حزين') || text.contains('sad')) {
      return '😢';
    }
    if (text.contains('متعب') || text.contains('tired')) {
      return '😐';
    }

    return '😐';
  }

  String getMoodLabel(Map<String, dynamic> mood) {
    final label = (mood['moodLabel'] ?? mood['label'] ?? '').toString().trim();
    if (label.isNotEmpty) return label;

    final value = (mood['mood'] ?? '').toString().trim().toLowerCase();

    if (value == 'good') return 'جيد';
    if (value == 'tired') return 'متعب';
    if (value == 'sad') return 'حزين';

    return value.isEmpty ? 'غير محدد' : value;
  }

  String getRiskStatus(Map<String, dynamic> readings) {
    final heartRate = _toInt(readings['heartRate']);
    final sugar = _toInt(readings['sugar'] ?? readings['glucose']);
    final oxygen = _toInt(readings['oxygen']);
    final temperature = double.tryParse(getValue(readings['temperature'])) ?? 0;
    final systolic = _toInt(readings['bloodPressureSystolic']);
    final diastolic = _toInt(readings['bloodPressureDiastolic']);

    int parsedSystolic = systolic;
    int parsedDiastolic = diastolic;
    final bloodPressure = getValue(readings['bloodPressure']);

    if (bloodPressure.contains('/')) {
      final parts = bloodPressure.split('/');
      parsedSystolic = int.tryParse(parts.first.trim()) ?? parsedSystolic;
      if (parts.length > 1) {
        parsedDiastolic = int.tryParse(parts[1].trim()) ?? parsedDiastolic;
      }
    }

    if (heartRate > 120 ||
        heartRate < 50 ||
        sugar > 250 ||
        sugar < 70 ||
        oxygen < 90 ||
        temperature >= 39 ||
        parsedSystolic >= 180 ||
        parsedDiastolic >= 120) {
      return 'Critical';
    }

    if (heartRate > 100 ||
        heartRate < 60 ||
        sugar > 180 ||
        oxygen < 95 ||
        temperature >= 38 ||
        parsedSystolic >= 140 ||
        parsedDiastolic >= 90) {
      return 'Warning';
    }

    if (readings.isEmpty) return 'No Readings';

    return 'Normal';
  }

  String getArabicStatus(String status) {
    if (status == 'Critical') return 'خطر';
    if (status == 'Warning') return 'تحتاج متابعة';
    if (status == 'No Readings') return 'لا توجد قراءات';
    return 'طبيعي';
  }

  Color getStatusColor(String status) {
    if (status == 'Critical') return errorColor;
    if (status == 'Warning') return warningColor;
    if (status == 'No Readings') return secondaryTextColor;
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
              Icon(icon, color: primaryColor, size: 28),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 18,
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 18,
                fontFamily: 'Cairo',
                color: secondaryTextColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildStatusCard(String status) {
    final statusColor = getStatusColor(status);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withOpacity(0.35)),
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
            getArabicStatus(status),
            style: TextStyle(
              fontSize: 30,
              fontFamily: 'Cairo',
              color: statusColor,
              fontWeight: FontWeight.bold,
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

            if (snapshot.hasError) {
              return const Center(
                child: Text(
                  'حدث خطأ أثناء تحميل بيانات المريض',
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 18),
                ),
              );
            }

            final data = snapshot.data ?? {};
            final user = (data['user'] ?? {}) as Map<String, dynamic>;
            final medical = (data['medical'] ?? {}) as Map<String, dynamic>;
            final healthProfile =
                (user['healthProfile'] ?? {}) as Map<dynamic, dynamic>;
            final lastHealthLog =
                (data['lastHealthLog'] ?? {}) as Map<String, dynamic>;
            final notes = (data['notes'] ?? []) as List;
            final latestMood =
                (data['latestMood'] ?? {}) as Map<String, dynamic>;

            final status = getRiskStatus(lastHealthLog);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  buildStatusCard(status),

                  const SizedBox(height: 16),

                  buildInfoCard(
                    title: 'مزاج المريض',
                    icon: Icons.mood,
                    children: [
                      buildRow(
                        'مزاج اليوم',
                        latestMood.isEmpty
                            ? 'لم يسجل المريض مزاجه اليوم'
                            : '${getMoodEmoji(latestMood)} ${getMoodLabel(latestMood)}',
                      ),
                    ],
                  ),

                  buildInfoCard(
                    title: 'البيانات الأساسية',
                    icon: Icons.person,
                    children: [
                      buildRow('الاسم', getValue(user['fullName'])),
                      buildRow(
                        'العمر',
                        getValue(user['age'] ?? medical['age']),
                      ),
                      buildRow(
                        'الجنس',
                        getValue(user['gender'] ?? medical['gender']),
                      ),
                      buildRow(
                        'فصيلة الدم',
                        getValue(
                          healthProfile['bloodType'] ?? medical['bloodType'],
                        ),
                      ),
                      buildRow('رقم الهاتف', getValue(user['phone'])),
                    ],
                  ),

                  buildInfoCard(
                    title: 'الملف الطبي',
                    icon: Icons.medical_information,
                    children: [
                      buildRow(
                        'الأمراض المزمنة',
                        getValue(
                          healthProfile['diseases'] ??
                              medical['pastMedicalHistory'] ??
                              medical['diseases'],
                        ),
                      ),
                      buildRow(
                        'منذ متى',
                        getValue(
                          healthProfile['diseaseSince'] ??
                              medical['diseaseSince'],
                        ),
                      ),
                      buildRow(
                        'الأدوية المزمنة',
                        getValue(
                          healthProfile['medicines'] ??
                              medical['chronicMedicines'] ??
                              medical['medicines'],
                        ),
                      ),
                      buildRow(
                        'الحساسية',
                        getValue(
                          healthProfile['allergy'] ??
                              medical['allergies'] ??
                              medical['allergy'],
                        ),
                      ),
                      buildRow(
                        'نوع الحساسية',
                        getValue(
                          healthProfile['allergyTypes'] ??
                              medical['allergyTypes'],
                        ),
                      ),
                      buildRow(
                        'العمليات السابقة',
                        getValue(
                          healthProfile['surgeries'] ??
                              medical['pastSurgicalHistory'] ??
                              medical['surgeries'],
                        ),
                      ),
                      buildRow(
                        'التدخين',
                        getValue(
                          healthProfile['smokingStatus'] ??
                              medical['smokingStatus'],
                        ),
                      ),
                    ],
                  ),

                  buildInfoCard(
                    title: 'آخر القراءات',
                    icon: Icons.monitor_heart,
                    children: [
                      buildRow('ضغط الدم', getBloodPressure(lastHealthLog)),
                      buildRow(
                        'السكر',
                        getValue(
                          lastHealthLog['sugar'] ?? lastHealthLog['glucose'],
                        ),
                      ),
                      buildRow(
                        'نبض القلب',
                        getValue(lastHealthLog['heartRate']),
                      ),
                      buildRow('الأكسجين', getValue(lastHealthLog['oxygen'])),
                      buildRow(
                        'الحرارة',
                        getValue(lastHealthLog['temperature']),
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
                        textAlign: TextAlign.right,
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
                                textAlign: TextAlign.right,
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
