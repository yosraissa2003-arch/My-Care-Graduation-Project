import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'medical_info_screen.dart';
import 'add_health_data_screen.dart';
import 'health_history_reports_screen.dart';
import 'package:mycare/screens/notifications_screen.dart';
import 'package:mycare/screens/medication_list_screen.dart';

import 'profile_settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const Color primaryColor = Color(0xFF1E3A5F);
  static const Color backgroundColor = Color(0xFFF7F8FA);
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color textColor = Color(0xFF1F2937);
  static const Color secondaryTextColor = Color(0xFF4B5563);
  static const Color successColor = Color(0xFF2E7D32);
  static const Color errorColor = Color(0xFFD32F2F);
  static const Color warningColor = Color(0xFFED6C02);

  static const Color softGreen = Color(0xffEEF8F1);
  static const Color softOrange = Color(0xffFFF7ED);
  static const Color softPurple = Color(0xffF7F3FF);
  static const Color softBlue = Color(0xffF1F8FC);
  static const Color borderColor = Color(0xffE6E6E6);

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'لم يتم تسجيل الدخول',
            style: TextStyle(fontSize: 18, fontFamily: 'Cairo'),
          ),
        ),
      );
    }

    final uid = currentUser.uid;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: primaryColor),
              );
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(
                child: Text(
                  'لا توجد بيانات للمستخدم',
                  style: TextStyle(
                    fontSize: 18,
                    fontFamily: 'Cairo',
                    color: textColor,
                  ),
                ),
              );
            }

            final user = snapshot.data!.data()!;
            final role = (user['role'] ?? '').toString();

            if (role == 'مرافق' || role == 'معتني') {
              return _buildCaregiverHome(context, uid, user);
            }

            return _buildPatientHome(context, uid, user);
          },
        ),
        bottomNavigationBar: _bottomNavigation(context),
      ),
    );
  }

  Widget _buildPatientHome(
    BuildContext context,
    String uid,
    Map<String, dynamic> user,
  ) {
    final name = (user['fullName'] ?? user['name'] ?? 'المستخدم').toString();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(name: name),

            const SizedBox(height: 24),

            _patientHealthStatus(uid),

            const SizedBox(height: 24),

            _sectionTitle('أدوية اليوم'),

            const SizedBox(height: 16),

            _medicationsList(uid),

            const SizedBox(height: 24),

            _bigActionCard(
              title: 'المعلومات الطبية',
              icon: Icons.medical_information_outlined,
              color: softOrange,
              border: const Color(0xffF1DDC5),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MedicalInfoScreen(user: user),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            _sectionTitle('خدمات سريعة'),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child:
                      //  _serviceCard(
                      //   title: 'أدويتي',
                      //   icon: Icons.medication_liquid_rounded,
                      //   color: warningColor,
                      //   bgColor: const Color(0xffFFF1E7),
                      //   onTap: () {},
                      // ),
                      _serviceCard(
                        title: 'أدويتي',
                        icon: Icons.medication_liquid_rounded,
                        color: warningColor,
                        bgColor: const Color(0xffFFF1E7),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MedicationListScreen(),
                            ),
                          );
                        },
                      ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _serviceCard(
                    title: 'صحتي',
                    icon: Icons.monitor_heart_rounded,
                    color: successColor,
                    bgColor: softGreen,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddHealthDataScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _serviceCard(
                    title: 'تقاريري',
                    icon: Icons.description_rounded,
                    color: const Color(0xff407C99),
                    bgColor: softBlue,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => HealthHistoryReportsScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            _sosButton(context, uid, user),
          ],
        ),
      ),
    );
  }

  Widget _buildCaregiverHome(
    BuildContext context,
    String uid,
    Map<String, dynamic> user,
  ) {
    final name = (user['fullName'] ?? user['name'] ?? 'المعتني').toString();
    final caregiverPhone = (user['phone'] ?? '').toString();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(name: name),

            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'يمكنك متابعة المرضى المرتبطين بحسابك واستقبال التنبيهات الخاصة بهم.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontFamily: 'Cairo',
                  color: secondaryTextColor,
                  height: 1.5,
                ),
              ),
            ),

            const SizedBox(height: 24),

            _sectionTitle('المرضى المرتبطون'),

            const SizedBox(height: 16),

            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'مريض')
                  .where('linkedPhone', isEqualTo: caregiverPhone)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: primaryColor),
                  );
                }

                final patients = snapshot.data?.docs ?? [];

                if (patients.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'لا يوجد مرضى مرتبطون حاليًا.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontFamily: 'Cairo',
                        color: secondaryTextColor,
                      ),
                    ),
                  );
                }

                return Column(
                  children: patients.map((doc) {
                    return _patientCardForCaregiver(
                      context: context,
                      patientId: doc.id,
                      patient: doc.data(),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _header({required String name}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'مرحباً $name',
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 26,
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ),
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: const Icon(
            Icons.notifications_none,
            color: primaryColor,
            size: 30,
          ),
        ),
      ],
    );
  }

  Widget _patientHealthStatus(String uid) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('healthLogs')
          .where('userId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: primaryColor),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return _emptyCard('لا توجد قراءات صحية بعد');
        }

        docs.sort((a, b) {
          final aTime = a.data()['createdAt'];
          final bTime = b.data()['createdAt'];

          if (aTime is Timestamp && bTime is Timestamp) {
            return bTime.compareTo(aTime);
          }

          return 0;
        });

        final health = docs.first.data();

        final heartRate = _toInt(health['heartRate']);
        final systolic = _toInt(health['bloodPressureSystolic']);
        final diastolic = _toInt(health['bloodPressureDiastolic']);
        final glucose = _toInt(health['glucose']);

        final status = getHealthStatus(
          heartRate: heartRate,
          systolic: systolic,
          diastolic: diastolic,
          glucose: glucose,
        );

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: softGreen,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xffD9EBDD)),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 34,
                backgroundColor: Colors.white,
                child: Icon(Icons.verified_user, color: successColor, size: 38),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الحالة الصحية: $status',
                      style: const TextStyle(
                        fontSize: 22,
                        fontFamily: 'Cairo',
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'النبض: $heartRate | الضغط: $systolic/$diastolic | السكر: $glucose',
                      style: const TextStyle(
                        fontSize: 18,
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
    );
  }

  Widget _medicationsList(String uid) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('medications')
          .where('userId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: primaryColor),
          );
        }

        final meds = snapshot.data?.docs ?? [];

        if (meds.isEmpty) {
          return _emptyCard('لا توجد أدوية اليوم');
        }

        return Column(
          children: meds.map((doc) {
            final med = doc.data();

            return _medCard(
              docId: doc.id,
              name: (med['name'] ?? 'دواء').toString(),
              time: (med['time'] ?? '').toString(),
              taken: med['taken'] == true,
            );
          }).toList(),
        );
      },
    );
  }

  Widget _patientCardForCaregiver({
    required BuildContext context,
    required String patientId,
    required Map<String, dynamic> patient,
  }) {
    final name = (patient['fullName'] ?? patient['name'] ?? 'مريض').toString();
    final phone = (patient['phone'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 30,
                backgroundColor: softGreen,
                child: Icon(Icons.elderly, color: successColor, size: 34),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontFamily: 'Cairo',
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      phone,
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
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('healthLogs')
                .where('userId', isEqualTo: patientId)
                .snapshots(),
            builder: (context, snapshot) {
              final logs = snapshot.data?.docs ?? [];

              if (logs.isEmpty) {
                return const Text(
                  'لا توجد قراءات صحية لهذا المريض',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Cairo',
                    color: secondaryTextColor,
                  ),
                );
              }

              logs.sort((a, b) {
                final aTime = a.data()['createdAt'];
                final bTime = b.data()['createdAt'];

                if (aTime is Timestamp && bTime is Timestamp) {
                  return bTime.compareTo(aTime);
                }

                return 0;
              });

              final health = logs.first.data();

              final heartRate = _toInt(health['heartRate']);
              final systolic = _toInt(health['bloodPressureSystolic']);
              final diastolic = _toInt(health['bloodPressureDiastolic']);
              final glucose = _toInt(health['glucose']);

              final status = getHealthStatus(
                heartRate: heartRate,
                systolic: systolic,
                diastolic: diastolic,
                glucose: glucose,
              );

              return Text(
                'الحالة: $status | النبض: $heartRate | الضغط: $systolic/$diastolic | السكر: $glucose',
                style: const TextStyle(
                  fontSize: 16,
                  fontFamily: 'Cairo',
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              );
            },
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
        fontSize: 22,
        fontFamily: 'Cairo',
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
    );
  }

  Widget _emptyCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 18,
          fontFamily: 'Cairo',
          color: secondaryTextColor,
        ),
      ),
    );
  }

  Widget _bigActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required Color border,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Icon(icon, color: primaryColor, size: 34),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: primaryColor,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _medCard({
    required String docId,
    required String name,
    required String time,
    required bool taken,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: softPurple,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xffE2DAF3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.medication,
                  color: Color(0xff755BB5),
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('medications')
                    .doc(docId)
                    .snapshots(),
                builder: (context, snapshot) {
                  final currentTaken = snapshot.data?.data()?['taken'] == true
                      ? true
                      : taken;

                  return InkWell(
                    onTap: () async {
                      await FirebaseFirestore.instance
                          .collection('medications')
                          .doc(docId)
                          .update({'taken': !currentTaken});
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: currentTaken
                            ? const Color(0xffE4F3E8)
                            : const Color(0xffFFE5E5),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            currentTaken
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: currentTaken ? successColor : errorColor,
                            size: 24,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            currentTaken ? 'تم أخذه' : 'لم يتم أخذه',
                            style: TextStyle(
                              color: currentTaken ? successColor : errorColor,
                              fontSize: 16,
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const Spacer(),
              Row(
                children: [
                  const Icon(
                    Icons.access_time_rounded,
                    size: 24,
                    color: Color(0xff755BB5),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    time,
                    style: const TextStyle(
                      fontSize: 18,
                      fontFamily: 'Cairo',
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _serviceCard({
    required String title,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.18)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sosButton(
    BuildContext context,
    String uid,
    Map<String, dynamic> user,
  ) {
    return SizedBox(
      height: 72,
      child: ElevatedButton.icon(
        onPressed: () async {
          final patientName = (user['fullName'] ?? user['name'] ?? 'المريض')
              .toString();

          final emergencyPhone = (user['emergencyContact'] ?? '').toString();

          String caregiverId = '';

          if (emergencyPhone.isNotEmpty) {
            final caregiverQuery = await FirebaseFirestore.instance
                .collection('users')
                .where('phone', isEqualTo: emergencyPhone)
                .limit(1)
                .get();

            if (caregiverQuery.docs.isNotEmpty) {
              caregiverId = caregiverQuery.docs.first.id;
            }
          }

          await FirebaseFirestore.instance.collection('sosAlerts').add({
            'userId': uid,
            'caregiverId': caregiverId,
            'patientName': patientName,
            'emergencyPhone': emergencyPhone,
            'source': 'manual',
            'status': 'active',
            'message': 'المريض $patientName يحتاج مساعدة فورية',
            'createdAt': Timestamp.now(),
          });

          await FirebaseFirestore.instance.collection('notifications').add({
            'title': 'تنبيه طوارئ SOS',
            'message': 'المريض $patientName يحتاج مساعدة فورية',
            'type': 'sos',
            'time': 'طوارئ',
            'isRead': false,
            'createdAt': Timestamp.now(),
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: errorColor,
              content: Text(
                'تم إرسال تنبيه الطوارئ للمرافق',
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 18, fontFamily: 'Cairo'),
              ),
            ),
          );
        },
        icon: const Icon(
          Icons.phone_in_talk_rounded,
          color: Colors.white,
          size: 34,
        ),
        label: const Text(
          'طوارئ SOS',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: errorColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }

  Widget _bottomNavigation(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      decoration: BoxDecoration(
        color: cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 18,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(26),
          topRight: Radius.circular(26),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: 0,
        elevation: 0,
        backgroundColor: Colors.transparent,
        selectedItemColor: primaryColor,
        unselectedItemColor: secondaryTextColor,
        selectedFontSize: 16,
        unselectedFontSize: 15,
        type: BottomNavigationBarType.fixed,

        onTap: (index) {
          // الرئيسية
          if (index == 0) {
            return;
          }

          // التنبيهات
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            );
          }

          // حسابي
          if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileSettingsScreen()),
            );
          }
        },

        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded, size: 32),
            label: 'الرئيسية',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_active_outlined, size: 30),
            label: 'التنبيهات',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded, size: 30),
            label: 'حسابي',
          ),
        ],
      ),
    );
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  String getHealthStatus({
    required int heartRate,
    required int systolic,
    required int diastolic,
    required int glucose,
  }) {
    if (heartRate < 50 ||
        heartRate > 120 ||
        systolic >= 180 ||
        diastolic >= 120 ||
        glucose < 70 ||
        glucose > 250) {
      return 'خطر';
    }

    if (heartRate < 60 ||
        heartRate > 100 ||
        systolic >= 140 ||
        diastolic >= 90 ||
        glucose > 180) {
      return 'تحتاج متابعة';
    }

    return 'مستقرة';
  }
}
