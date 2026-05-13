import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import 'notifications_screen.dart';

class AddMedicationScreen extends StatefulWidget {
  const AddMedicationScreen({super.key});

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController remainingPillsController =
      TextEditingController();
  final TextEditingController notesController = TextEditingController();

  String selectedDose = 'حبة واحدة';
  String selectedFrequency = 'مرة يوميًا';
  String selectedPeriod = 'بعد الأكل';
  String selectedDuration = 'أسبوع';
  String selectedImportance = 'مهم';

  String selectedTime1 = '08:00 صباحًا';
  String selectedTime2 = '08:00 مساءً';
  String selectedTime3 = '02:00 مساءً';

  File? selectedImage;
  bool isLoading = false;

  final List<String> doses = const [
    'نصف حبة',
    'حبة واحدة',
    'حبتان',
    '3 حبات',
    '5 مل',
    '10 مل',
    '15 مل',
    'نقطة واحدة',
    'نقطتان',
    'حقنة واحدة',
  ];

  final List<String> times = const [
    '06:00 صباحًا',
    '06:30 صباحًا',
    '07:00 صباحًا',
    '07:30 صباحًا',
    '08:00 صباحًا',
    '08:30 صباحًا',
    '09:00 صباحًا',
    '09:30 صباحًا',
    '10:00 صباحًا',
    '10:30 صباحًا',
    '11:00 صباحًا',
    '11:30 صباحًا',
    '12:00 ظهرًا',
    '12:30 ظهرًا',
    '01:00 مساءً',
    '01:30 مساءً',
    '02:00 مساءً',
    '02:30 مساءً',
    '03:00 مساءً',
    '03:30 مساءً',
    '04:00 مساءً',
    '04:30 مساءً',
    '05:00 مساءً',
    '05:30 مساءً',
    '06:00 مساءً',
    '06:30 مساءً',
    '07:00 مساءً',
    '07:30 مساءً',
    '08:00 مساءً',
    '08:30 مساءً',
    '09:00 مساءً',
    '09:30 مساءً',
    '10:00 مساءً',
  ];

  final List<String> frequencies = const [
    'مرة يوميًا',
    'مرتين يوميًا',
    'ثلاث مرات يوميًا',
    'عند الحاجة',
  ];

  final List<String> periods = const [
    'قبل الأكل',
    'بعد الأكل',
    'مع الأكل',
    'قبل النوم',
    'عند الاستيقاظ',
  ];

  final List<String> durations = const [
    '3 أيام',
    'أسبوع',
    'أسبوعين',
    'شهر',
    'دائم',
  ];

  final List<String> importanceLevels = const ['عادي', 'مهم', 'ضروري جدًا'];

  @override
  void dispose() {
    nameController.dispose();
    remainingPillsController.dispose();
    notesController.dispose();
    super.dispose();
  }

  List<String> getSelectedTimes() {
    if (selectedFrequency == 'عند الحاجة') return [];
    if (selectedFrequency == 'مرة يوميًا') return [selectedTime1];
    if (selectedFrequency == 'مرتين يوميًا') {
      return [selectedTime1, selectedTime2];
    }
    return [selectedTime1, selectedTime3, selectedTime2];
  }

  String getReminderPreviewText() {
    if (selectedFrequency == 'عند الحاجة') {
      return 'لن يتم تحديد وقت ثابت، يمكن استخدام الدواء عند الحاجة.';
    }

    final selectedTimes = getSelectedTimes().join('، ');
    return 'سيتم تذكيرك $selectedFrequency في الأوقات: $selectedTimes';
  }

  Future<void> pickMedicationImage() async {
    final ImagePicker picker = ImagePicker();

    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );

    if (image == null) return;

    setState(() {
      selectedImage = File(image.path);
    });
  }

  Future<String?> uploadMedicationImage() async {
    if (selectedImage == null) return null;

    final String fileName = DateTime.now().millisecondsSinceEpoch.toString();

    final Reference ref = FirebaseStorage.instance
        .ref()
        .child('medication_images')
        .child('$fileName.jpg');

    await ref.putFile(selectedImage!);

    return await ref.getDownloadURL();
  }

  Future<void> saveMedication() async {
    final name = nameController.text.trim();
    final remainingPills = remainingPillsController.text.trim();
    final notes = notesController.text.trim();

    if (name.isEmpty) {
      showMessage('يرجى إدخال اسم الدواء', false);
      return;
    }

    try {
      setState(() => isLoading = true);

      final String? imageUrl = await uploadMedicationImage();
      final List<String> selectedTimes = getSelectedTimes();

      await FirebaseFirestore.instance.collection('medications').add({
        'name': name,
        'dose': selectedDose,
        'frequency': selectedFrequency,
        'usagePeriod': selectedPeriod,
        'duration': selectedDuration,
        'importance': selectedImportance,
        'remainingPills': remainingPills,
        'notes': notes,
        'imageUrl': imageUrl,
        'times': selectedTimes,
        'time1': selectedTime1,
        'time2':
            selectedFrequency == 'مرتين يوميًا' ||
                selectedFrequency == 'ثلاث مرات يوميًا'
            ? selectedTime2
            : null,
        'time3': selectedFrequency == 'ثلاث مرات يوميًا' ? selectedTime3 : null,
        'isActive': true,
        'isTaken': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance.collection('notifications').add({
        'title': 'موعد الدواء',
        'message': selectedTimes.isEmpty
            ? 'تمت إضافة دواء $name ويستخدم عند الحاجة'
            : 'تمت إضافة دواء $name، موعده: ${selectedTimes.join('، ')}',
        'time': selectedTimes.isEmpty ? 'عند الحاجة' : selectedTimes.first,
        'type': 'medication',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      showMessage('تم حفظ الدواء وإضافة التنبيه بنجاح 💙', true);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const NotificationsScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      showMessage('حدث خطأ أثناء الحفظ، تأكد من الإنترنت و Firebase', false);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void showMessage(String message, bool success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.right,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Cairo',
          ),
        ),
        backgroundColor: success
            ? const Color(0xFF2E7D32)
            : const Color(0xFFD32F2F),
      ),
    );
  }

  InputDecoration inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w900,
        color: Colors.black,
        fontFamily: 'Cairo',
      ),
      floatingLabelStyle: const TextStyle(
        fontSize: 21,
        fontWeight: FontWeight.w900,
        color: Color(0xFF1E3A5F),
        fontFamily: 'Cairo',
      ),
      prefixIcon: Icon(icon, color: const Color(0xFF1E3A5F), size: 31),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.4),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: const BorderSide(color: Color(0xFF1E3A5F), width: 2),
      ),
    );
  }

  Widget buildDropdown({
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      dropdownColor: Colors.white,
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: Color(0xFF1E3A5F),
        size: 34,
      ),
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w900,
        color: Colors.black,
        fontFamily: 'Cairo',
      ),
      decoration: inputDecoration(label: label, icon: icon),
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(
            item,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w900,
              color: Colors.black,
              fontFamily: 'Cairo',
            ),
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w900,
        color: Colors.black,
        fontFamily: 'Cairo',
      ),
      decoration: inputDecoration(label: label, icon: icon),
    );
  }

  Widget buildTipCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2FA),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD7E6F5), width: 1.2),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تذكير ذكي وآمن 💙',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A5F),
                    fontFamily: 'Cairo',
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'قم بإضافة تفاصيل الدواء ليقوم تطبيق MyCare بتذكيرك بموعد الدواء بكل سهولة وأمان.',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                    height: 1.6,
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 14),
          CircleAvatar(
            radius: 25,
            backgroundColor: Color(0xFF1E3A5F),
            child: Icon(
              Icons.health_and_safety_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildImagePickerCard() {
    return InkWell(
      onTap: pickMedicationImage,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1.4),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: const Color(0xFFEAF2FA),
              backgroundImage: selectedImage != null
                  ? FileImage(selectedImage!)
                  : null,
              child: selectedImage == null
                  ? const Icon(
                      Icons.add_a_photo_rounded,
                      color: Color(0xFF1E3A5F),
                      size: 32,
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                'إضافة صورة الدواء',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                  fontFamily: 'Cairo',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildReminderPreview() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundColor: Color(0xFFEAF2FA),
            child: Icon(
              Icons.notifications_active_rounded,
              color: Color(0xFF1E3A5F),
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              getReminderPreviewText(),
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                height: 1.7,
                fontFamily: 'Cairo',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTimeFields() {
    if (selectedFrequency == 'عند الحاجة') {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        buildDropdown(
          label: selectedFrequency == 'مرة يوميًا'
              ? 'وقت الدواء'
              : 'وقت الجرعة الأولى',
          icon: Icons.wb_sunny_rounded,
          value: selectedTime1,
          items: times,
          onChanged: (value) {
            setState(() => selectedTime1 = value!);
          },
        ),
        if (selectedFrequency == 'ثلاث مرات يوميًا') ...[
          const SizedBox(height: 16),
          buildDropdown(
            label: 'وقت الجرعة الثانية',
            icon: Icons.wb_twilight_rounded,
            value: selectedTime3,
            items: times,
            onChanged: (value) {
              setState(() => selectedTime3 = value!);
            },
          ),
        ],
        if (selectedFrequency == 'مرتين يوميًا' ||
            selectedFrequency == 'ثلاث مرات يوميًا') ...[
          const SizedBox(height: 16),
          buildDropdown(
            label: selectedFrequency == 'مرتين يوميًا'
                ? 'وقت الجرعة الثانية'
                : 'وقت الجرعة الثالثة',
            icon: Icons.nightlight_round,
            value: selectedTime2,
            items: times,
            onChanged: (value) {
              setState(() => selectedTime2 = value!);
            },
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF7F8FA),
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'إضافة دواء',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
              fontFamily: 'Cairo',
            ),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                buildTipCard(),
                const SizedBox(height: 20),
                buildImagePickerCard(),
                const SizedBox(height: 16),
                buildTextField(
                  controller: nameController,
                  label: 'اسم الدواء',
                  icon: Icons.medication_outlined,
                ),
                const SizedBox(height: 16),
                buildDropdown(
                  label: 'الجرعة',
                  icon: Icons.medical_services_outlined,
                  value: selectedDose,
                  items: doses,
                  onChanged: (value) {
                    setState(() => selectedDose = value!);
                  },
                ),
                const SizedBox(height: 16),
                buildDropdown(
                  label: 'عدد مرات الاستخدام',
                  icon: Icons.repeat_rounded,
                  value: selectedFrequency,
                  items: frequencies,
                  onChanged: (value) {
                    setState(() => selectedFrequency = value!);
                  },
                ),
                const SizedBox(height: 16),
                buildTimeFields(),
                if (selectedFrequency != 'عند الحاجة')
                  const SizedBox(height: 16),
                buildDropdown(
                  label: 'طريقة الاستخدام',
                  icon: Icons.restaurant_rounded,
                  value: selectedPeriod,
                  items: periods,
                  onChanged: (value) {
                    setState(() => selectedPeriod = value!);
                  },
                ),
                const SizedBox(height: 16),
                buildDropdown(
                  label: 'مدة الاستخدام',
                  icon: Icons.calendar_month_rounded,
                  value: selectedDuration,
                  items: durations,
                  onChanged: (value) {
                    setState(() => selectedDuration = value!);
                  },
                ),
                const SizedBox(height: 16),
                buildDropdown(
                  label: 'أهمية الدواء',
                  icon: Icons.priority_high_rounded,
                  value: selectedImportance,
                  items: importanceLevels,
                  onChanged: (value) {
                    setState(() => selectedImportance = value!);
                  },
                ),
                const SizedBox(height: 16),
                buildTextField(
                  controller: remainingPillsController,
                  label: 'عدد الحبات المتبقية',
                  icon: Icons.inventory_2_rounded,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                buildTextField(
                  controller: notesController,
                  label: 'ملاحظات الدواء',
                  icon: Icons.notes_rounded,
                  maxLines: 3,
                ),
                const SizedBox(height: 20),
                buildReminderPreview(),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 62,
                  child: ElevatedButton.icon(
                    onPressed: isLoading ? null : saveMedication,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A5F),
                      disabledBackgroundColor: Colors.grey,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    icon: isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Icon(
                            Icons.save_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                    label: Text(
                      isLoading ? 'جاري الحفظ...' : 'حفظ الدواء',
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
