import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/care_timeline_service.dart';
import '../services/notification_service.dart';

class AddAppointmentScreen extends StatefulWidget {
  const AddAppointmentScreen({super.key});

  @override
  State<AddAppointmentScreen> createState() => _AddAppointmentScreenState();
}

class _AddAppointmentScreenState extends State<AddAppointmentScreen> {
  static const Color dark = Color(0xff172638);
  static const Color green = Color(0xff2E8B57);
  static const Color background = Color(0xFFF7F8FA);

  final titleController = TextEditingController(text: 'موعد الطبيب');
  final doctorController = TextEditingController();
  final locationController = TextEditingController();
  final notesController = TextEditingController();

  DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay selectedTime = const TimeOfDay(hour: 15, minute: 0);
  bool isSaving = false;

  @override
  void dispose() {
    titleController.dispose();
    doctorController.dispose();
    locationController.dispose();
    notesController.dispose();
    super.dispose();
  }

  DateTime get selectedDateTime {
    return DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    int hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'مساءً' : 'صباحًا';
    if (hour > 12) hour -= 12;
    if (hour == 0) hour = 12;
    return '${hour.toString().padLeft(2, '0')}:$minute $period';
  }

  Future<void> _pickDate() async {
    final result = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (result != null) {
      setState(() => selectedDate = result);
    }
  }

  Future<void> _pickTime() async {
    final result = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );

    if (result != null) {
      setState(() => selectedTime = result);
    }
  }

  Future<void> _saveAppointment() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final title = titleController.text.trim().isEmpty
        ? 'موعد طبي'
        : titleController.text.trim();

    setState(() => isSaving = true);

    try {
      final appointmentTime = selectedDateTime;

      final ref = await FirebaseFirestore.instance.collection('appointments').add({
        'userId': user.uid,
        'patientId': user.uid,
        'title': title,
        'doctorName': doctorController.text.trim(),
        'location': locationController.text.trim(),
        'notes': notesController.text.trim(),
        'dateTime': Timestamp.fromDate(appointmentTime),
        'reminderEnabled': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await NotificationService.scheduleAppointmentReminder(
        appointmentId: ref.id,
        title: title,
        scheduledDateTime: appointmentTime,
      );

      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': user.uid,
        'patientId': user.uid,
        'recipientId': user.uid,
        'title': 'تذكير موعد طبي',
        'message': 'لديك موعد: $title',
        'type': 'appointment',
        'time': _formatTime(selectedTime),
        'isRead': false,
        'appointmentId': ref.id,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await CareTimelineService.addEvent(
        userId: user.uid,
        type: 'appointment',
        title: 'تم إضافة موعد طبي',
        details: '$title - ${_formatDate(appointmentTime)} ${_formatTime(selectedTime)}',
      );

      await CareTimelineService.updateLastActivity(user.uid);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: green,
          content: Text(
            'تم حفظ الموعد وتفعيل التذكير',
            textAlign: TextAlign.right,
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
          ),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'حدث خطأ أثناء حفظ الموعد',
            textAlign: TextAlign.right,
            style: TextStyle(fontFamily: 'Cairo'),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateTime = selectedDateTime;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          backgroundColor: background,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'إضافة موعد',
            style: TextStyle(
              color: dark,
              fontSize: 30,
              fontWeight: FontWeight.w900,
              fontFamily: 'Cairo',
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            _field(titleController, 'عنوان الموعد', Icons.event_note_rounded),
            const SizedBox(height: 14),
            _field(doctorController, 'اسم الطبيب / العيادة', Icons.person_rounded),
            const SizedBox(height: 14),
            _field(locationController, 'المكان', Icons.location_on_rounded),
            const SizedBox(height: 14),
            _field(notesController, 'ملاحظات', Icons.notes_rounded, maxLines: 3),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _pickerButton(
                    icon: Icons.calendar_month_rounded,
                    text: _formatDate(dateTime),
                    onTap: _pickDate,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _pickerButton(
                    icon: Icons.access_time_rounded,
                    text: _formatTime(selectedTime),
                    onTap: _pickTime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: isSaving ? null : _saveAppointment,
              style: ElevatedButton.styleFrom(
                backgroundColor: green,
                minimumSize: const Size(double.infinity, 66),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              icon: isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.save_rounded, color: Colors.white),
              label: const Text(
                'حفظ الموعد',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Cairo',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      textAlign: TextAlign.right,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        fontFamily: 'Cairo',
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: dark),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _pickerButton({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: dark),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: dark,
                  fontFamily: 'Cairo',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
