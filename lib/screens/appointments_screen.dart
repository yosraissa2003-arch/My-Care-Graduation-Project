import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_appointment_screen.dart';

class AppointmentsScreen extends StatelessWidget {
  const AppointmentsScreen({super.key});

  static const Color dark = Color(0xff172638);
  static const Color primary = Color(0xFF1E3A5F);
  static const Color background = Color(0xFFF7F9FC);
  static const Color border = Color(0xffE5E7EB);
  static const Color orange = Color(0xffD47443);
  static const Color softOrange = Color(0xfffff3e8);
  static const Color textGray = Color(0xFF6B7280);

  String _formatDate(DateTime? date) {
    if (date == null) return 'غير محدد';

    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatTime(DateTime? date) {
    if (date == null) return 'غير محدد';

    int hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'مساءً' : 'صباحًا';

    if (hour > 12) hour -= 12;
    if (hour == 0) hour = 12;

    return '${hour.toString().padLeft(2, '0')}:$minute $period';
  }

  DateTime? _getAppointmentDate(Map<String, dynamic> data) {
    final dateTimeValue = data['dateTime'];

    if (dateTimeValue is Timestamp) {
      return dateTimeValue.toDate();
    }

    return null;
  }

  Widget _introText() {
    return const Text(
      'تابعي مواعيد الطبيب القادمة، واحتفظي باسم الطبيب والمكان والملاحظات المهمة.',
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.right,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: textGray,
        fontFamily: 'Cairo',
        height: 1.6,
      ),
    );
  }

  Widget _emptyAppointmentsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border, width: 1.2),
      ),
      child: const Column(
        children: [
          Text(
            'لا توجد مواعيد بعد',
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w900,
              color: dark,
              fontFamily: 'Cairo',
              height: 1.4,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'اضغطي على زر إضافة موعد لإدخال موعد جديد.',
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: textGray,
              fontFamily: 'Cairo',
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _appointmentCard({
    required String title,
    required String doctorName,
    required String location,
    required String notes,
    required DateTime? date,
  }) {
    final bool isPast = date != null && date.isBefore(DateTime.now());

    final Color mainColor = isPast ? textGray : orange;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: isPast ? border : orange.withOpacity(0.22),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: dark,
              fontFamily: 'Cairo',
              height: 1.3,
            ),
          ),

          const SizedBox(height: 8),

          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isPast ? const Color(0xFFF3F4F6) : softOrange,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                isPast ? 'موعد سابق' : 'موعد قادم',
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: mainColor,
                  fontFamily: 'Cairo',
                  height: 1.2,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          _infoBox(
            icon: Icons.calendar_today_rounded,
            title: 'التاريخ',
            value: _formatDate(date),
          ),

          const SizedBox(height: 9),

          _infoBox(
            icon: Icons.access_time_rounded,
            title: 'الوقت',
            value: _formatTime(date),
          ),

          if (doctorName.isNotEmpty) ...[
            const SizedBox(height: 9),
            _infoBox(
              icon: Icons.person_rounded,
              title: 'الطبيب',
              value: doctorName,
            ),
          ],

          if (location.isNotEmpty) ...[
            const SizedBox(height: 9),
            _infoBox(
              icon: Icons.location_on_rounded,
              title: 'المكان',
              value: location,
            ),
          ],

          if (notes.isNotEmpty) ...[
            const SizedBox(height: 9),
            _infoBox(icon: Icons.notes_rounded, title: 'ملاحظات', value: notes),
          ],
        ],
      ),
    );
  }

  Widget _infoBox({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border, width: 1.1),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Icon(icon, color: primary, size: 24),

          const SizedBox(width: 9),

          Text(
            '$title:',
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: dark,
              fontFamily: 'Cairo',
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Text(
              value,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
                fontFamily: 'Cairo',
                height: 1.4,
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
        body: Center(child: Text('يجب تسجيل الدخول أولاً')),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: background,
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: primary,
          elevation: 4,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddAppointmentScreen()),
            );
          },
          icon: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
          label: const Text(
            'إضافة موعد',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w900,
              fontFamily: 'Cairo',
            ),
          ),
        ),
        appBar: AppBar(
          backgroundColor: background,
          elevation: 0,
          centerTitle: true,
          automaticallyImplyLeading: false,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_forward_ios_rounded,
              color: dark,
              size: 28,
            ),
          ),
          title: const Text(
            'مواعيدي الطبية',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: dark,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              fontFamily: 'Cairo',
              height: 1.3,
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
              return const Center(
                child: CircularProgressIndicator(color: dark),
              );
            }

            if (snapshot.hasError) {
              return const Center(
                child: Text(
                  'حدث خطأ أثناء تحميل المواعيد',
                  textAlign: TextAlign.center,
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
              final aDate = _getAppointmentDate(a.data());
              final bDate = _getAppointmentDate(b.data());

              if (aDate == null && bDate == null) return 0;
              if (aDate == null) return 1;
              if (bDate == null) return -1;

              return aDate.compareTo(bDate);
            });

            return ListView(
              padding: const EdgeInsets.all(18),
              children: [
                _introText(),

                const SizedBox(height: 16),

                if (docs.isEmpty)
                  _emptyAppointmentsCard()
                else
                  ...docs.map((doc) {
                    final data = doc.data();

                    final title = (data['title'] ?? 'موعد طبي').toString();
                    final doctorName = (data['doctorName'] ?? '').toString();
                    final location = (data['location'] ?? '').toString();
                    final notes = (data['notes'] ?? '').toString();
                    final date = _getAppointmentDate(data);

                    return _appointmentCard(
                      title: title,
                      doctorName: doctorName,
                      location: location,
                      notes: notes,
                      date: date,
                    );
                  }).toList(),
              ],
            );
          },
        ),
      ),
    );
  }
}
