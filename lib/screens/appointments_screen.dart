import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_appointment_screen.dart';

class AppointmentsScreen extends StatelessWidget {
  const AppointmentsScreen({super.key});

  static const Color dark = Color(0xff172638);
  static const Color background = Color(0xFFF7F8FA);
  static const Color border = Color(0xffE5E5E5);
  static const Color orange = Color(0xffD47443);

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

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('يجب تسجيل الدخول أولاً')));
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: background,
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: dark,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddAppointmentScreen()),
            );
          },
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: const Text(
            'إضافة موعد',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontFamily: 'Cairo',
            ),
          ),
        ),
        appBar: AppBar(
          backgroundColor: background,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'مواعيدي',
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
              .collection('appointments')
              .where('userId', isEqualTo: user.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: dark));
            }

            if (snapshot.hasError) {
              return const Center(
                child: Text(
                  'حدث خطأ أثناء تحميل المواعيد',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
              );
            }

            final docs = [...(snapshot.data?.docs ?? [])];

            docs.sort((a, b) {
              final aTime = a.data()['dateTime'];
              final bTime = b.data()['dateTime'];
              if (aTime is Timestamp && bTime is Timestamp) {
                return aTime.compareTo(bTime);
              }
              return 0;
            });

            if (docs.isEmpty) {
              return const Center(
                child: Text(
                  'لا توجد مواعيد بعد',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: dark,
                    fontFamily: 'Cairo',
                  ),
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.all(18),
              children: docs.map((doc) {
                final data = doc.data();
                final title = (data['title'] ?? 'موعد طبي').toString();
                final doctorName = (data['doctorName'] ?? '').toString();
                final location = (data['location'] ?? '').toString();
                final notes = (data['notes'] ?? '').toString();
                final dateTimeValue = data['dateTime'];
                final date = dateTimeValue is Timestamp
                    ? dateTimeValue.toDate()
                    : DateTime.now();

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 31,
                            backgroundColor: Color(0xfffff3e8),
                            child: Icon(Icons.calendar_month_rounded, color: orange, size: 36),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              title,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: dark,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _line(Icons.access_time_rounded, 'الوقت', '${_formatDate(date)} • ${_formatTime(date)}'),
                      if (doctorName.isNotEmpty) _line(Icons.person_rounded, 'الطبيب', doctorName),
                      if (location.isNotEmpty) _line(Icons.location_on_rounded, 'المكان', location),
                      if (notes.isNotEmpty) _line(Icons.notes_rounded, 'ملاحظات', notes),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }

  Widget _line(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(icon, color: dark, size: 22),
          const SizedBox(width: 8),
          Text(
            '$title: ',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: dark,
              fontFamily: 'Cairo',
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
                fontFamily: 'Cairo',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
