import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_medication_screen.dart';
import '../services/care_timeline_service.dart';

class AppColors {
  static const Color primary = Color(0xFF1E3A5F);
  static const Color background = Color(0xFFF7F8FA);
  static const Color card = Colors.white;
  static const Color border = Color(0xFFE5E7EB);
  static const Color success = Color(0xFF2E7D32);
  static const Color danger = Color(0xFFD32F2F);
  static const Color warning = Color(0xFFED6C02);
}

enum MedicationFilter { all, morning, evening, taken, pending }

class MedicationListScreen extends StatefulWidget {
  const MedicationListScreen({super.key});

  @override
  State<MedicationListScreen> createState() => _MedicationListScreenState();
}

class _MedicationListScreenState extends State<MedicationListScreen> {
  final FlutterTts _tts = FlutterTts();
  MedicationFilter selectedFilter = MedicationFilter.all;

  @override
  void initState() {
    super.initState();
    _setupTts();
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _setupTts() async {
    await _tts.setLanguage('ar');
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  Future<void> _speak(String text) async {
    if (text.trim().isEmpty) return;
    await _tts.stop();
    await _tts.speak(text);
  }

  String _medicationSpeechText(Map<String, dynamic> data) {
    final String name = (data['name'] ?? 'دواء بدون اسم').toString();
    final String dose = (data['dose'] ?? '').toString();
    final String frequency = (data['frequency'] ?? '').toString();
    final String usagePeriod = (data['usagePeriod'] ?? '').toString();
    final String duration = (data['duration'] ?? '').toString();
    final String importance = (data['importance'] ?? '').toString();
    final String notes = (data['notes'] ?? '').toString();
    final String timesText = getTimesText(data);
    final bool isTaken = _isTakenToday(data);
    final bool allergyWarning = data['allergyWarning'] == true;
    final String allergyMessage = (data['allergyWarningMessage'] ?? '')
        .toString();

    return 'دواء $name. '
        '${dose.isNotEmpty ? 'الجرعة $dose. ' : ''}'
        'الموعد $timesText. '
        '${frequency.isNotEmpty ? 'عدد مرات الاستخدام $frequency. ' : ''}'
        '${usagePeriod.isNotEmpty ? 'طريقة الاستخدام $usagePeriod. ' : ''}'
        '${duration.isNotEmpty ? 'مدة الاستخدام $duration. ' : ''}'
        '${importance.isNotEmpty ? 'الأهمية $importance. ' : ''}'
        'الحالة ${isTaken ? 'تم أخذ الدواء اليوم' : 'لم يتم أخذ الدواء بعد'}. '
        '${allergyWarning ? 'تنبيه حساسية: ${allergyMessage.isEmpty ? 'هذا الدواء قد لا يناسب المريض.' : allergyMessage} ' : ''}'
        '${notes.isNotEmpty ? 'ملاحظات: $notes.' : ''}';
  }

  String _dailyMedicationsSummaryText(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> todayDocs,
    int takenCount,
  ) {
    final total = todayDocs.length;
    final pending = total - takenCount;

    if (total == 0) {
      return 'لا توجد أدوية مسجلة لليوم.';
    }

    final details = todayDocs
        .map((doc) {
          final data = doc.data();
          final name = (data['name'] ?? 'دواء بدون اسم').toString();
          final times = getTimesText(data);
          final status = _isTakenToday(data) ? 'تم أخذه' : 'لم يتم أخذه';
          return '$name، موعده $times، والحالة $status';
        })
        .join('. ');

    return 'ملخص أدوية اليوم. لديك $total أدوية. تم أخذ $takenCount. '
        'متبقي $pending. $details';
  }

  Widget buildVoiceSummaryCard(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> todayDocs,
    int takenCount,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2FA),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 27,
            backgroundColor: AppColors.primary,
            child: IconButton(
              icon: const Icon(
                Icons.volume_up_rounded,
                color: Colors.white,
                size: 29,
              ),
              onPressed: () =>
                  _speak(_dailyMedicationsSummaryText(todayDocs, takenCount)),
            ),
          ),
          const SizedBox(width: 13),
          const Expanded(
            child: Text(
              'اسمع ملخص أدوية اليوم ومواعيدها وحالة كل دواء.',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String getFilterText(MedicationFilter filter) {
    switch (filter) {
      case MedicationFilter.all:
        return 'الكل';
      case MedicationFilter.morning:
        return 'صباحي';
      case MedicationFilter.evening:
        return 'مسائي';
      case MedicationFilter.taken:
        return 'تم أخذه';
      case MedicationFilter.pending:
        return 'لم يتم أخذه';
    }
  }

  IconData getFilterIcon(MedicationFilter filter) {
    switch (filter) {
      case MedicationFilter.all:
        return Icons.medication_rounded;
      case MedicationFilter.morning:
        return Icons.wb_sunny_rounded;
      case MedicationFilter.evening:
        return Icons.nightlight_round;
      case MedicationFilter.taken:
        return Icons.check_circle_rounded;
      case MedicationFilter.pending:
        return Icons.pending_actions_rounded;
    }
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  DateTime? _createdDate(Map<String, dynamic> med) {
    final createdAt = med['createdAt'];
    if (createdAt is Timestamp) return createdAt.toDate();

    final createdDateKey = med['createdDateKey']?.toString();
    if (createdDateKey != null && createdDateKey.trim().isNotEmpty) {
      return DateTime.tryParse(createdDateKey);
    }

    return null;
  }

  int _durationDays(String duration) {
    switch (duration.trim()) {
      case '3 أيام':
        return 3;
      case 'أسبوع':
        return 7;
      case 'أسبوعين':
        return 14;
      case 'شهر':
        return 30;
      case 'دائم':
        return 36500;
      default:
        return 36500;
    }
  }

  bool _shouldShowMedicationToday(Map<String, dynamic> med) {
    if (med['isActive'] == false) return false;

    final frequency = (med['frequency'] ?? '').toString();
    final duration = (med['duration'] ?? 'دائم').toString();

    if (frequency == 'عند الحاجة') return true;
    if (duration == 'دائم') return true;

    final created = _createdDate(med);
    if (created == null) return true;

    final today = DateTime.now();
    final startDate = DateTime(created.year, created.month, created.day);
    final todayDate = DateTime(today.year, today.month, today.day);
    final usedDays = todayDate.difference(startDate).inDays;

    return usedDays >= 0 && usedDays < _durationDays(duration);
  }

  bool _isTakenToday(Map<String, dynamic> med) {
    final lastTakenDateKey = (med['lastTakenDateKey'] ?? '').toString();
    return (med['isTaken'] == true || med['taken'] == true) &&
        lastTakenDateKey == _todayKey();
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> filterMedications(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    return docs.where((doc) {
      final data = doc.data();
      final bool isTaken = _isTakenToday(data);
      final List times = data['times'] ?? [];
      final String allTimes = times.join(' ');

      if (!_shouldShowMedicationToday(data)) return false;

      switch (selectedFilter) {
        case MedicationFilter.all:
          return true;
        case MedicationFilter.morning:
          return allTimes.contains('صباح');
        case MedicationFilter.evening:
          return allTimes.contains('مساء');
        case MedicationFilter.taken:
          return isTaken;
        case MedicationFilter.pending:
          return !isTaken;
      }
    }).toList();
  }

  Future<void> toggleTaken(String id, bool currentValue) async {
    final today = _todayKey();
    final currentUser = FirebaseAuth.instance.currentUser;
    final medRef = FirebaseFirestore.instance.collection('medications').doc(id);
    final medSnapshot = await medRef.get();
    final medData = medSnapshot.data() ?? <String, dynamic>{};
    final medicationName = (medData['name'] ?? 'دواء').toString();

    await medRef.update({
      'isTaken': !currentValue,
      'taken': !currentValue,
      'lastTakenDateKey': !currentValue ? today : '',
      'takenAt': !currentValue ? FieldValue.serverTimestamp() : null,
    });

    if (!currentValue && currentUser != null) {
      await CareTimelineService.addEvent(
        userId: currentUser.uid,
        type: 'medication',
        title: 'تم أخذ دواء',
        details: medicationName,
      );
      await CareTimelineService.updateLastActivity(currentUser.uid);
    }
  }

  void openAddMedicationScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddMedicationScreen()),
    );
  }

  String getTimesText(Map<String, dynamic> data) {
    final List times = data['times'] ?? [];
    if (times.isEmpty) return 'عند الحاجة';
    return times.join('، ');
  }

  void showMedicationDetails(Map<String, dynamic> data) {
    final String name = data['name'] ?? 'دواء بدون اسم';
    final String dose = data['dose'] ?? '';
    final String frequency = data['frequency'] ?? '';
    final String usagePeriod = data['usagePeriod'] ?? '';
    final String duration = data['duration'] ?? '';
    final String importance = data['importance'] ?? '';
    final String remainingPills = data['remainingPills'] ?? '';
    final String notes = data['notes'] ?? '';
    final String timesText = getTimesText(data);
    final bool isTaken = _isTakenToday(data);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 28,
                        backgroundColor: Color(0xFFEAF2FA),
                        child: Icon(
                          Icons.medication_rounded,
                          color: AppColors.primary,
                          size: 34,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          name,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  buildDetailRow(
                    Icons.medical_services_rounded,
                    'الجرعة',
                    dose,
                  ),
                  buildDetailRow(
                    Icons.access_time_rounded,
                    'الأوقات',
                    timesText,
                  ),
                  buildDetailRow(Icons.repeat_rounded, 'عدد المرات', frequency),
                  buildDetailRow(
                    Icons.restaurant_rounded,
                    'طريقة الاستخدام',
                    usagePeriod,
                  ),
                  buildDetailRow(
                    Icons.calendar_month_rounded,
                    'مدة الاستخدام',
                    duration,
                  ),
                  buildDetailRow(
                    Icons.priority_high_rounded,
                    'الأهمية',
                    importance,
                  ),
                  buildDetailRow(
                    Icons.inventory_2_rounded,
                    'المتبقي',
                    remainingPills,
                  ),
                  buildDetailRow(
                    isTaken
                        ? Icons.check_circle_rounded
                        : Icons.pending_actions_rounded,
                    'الحالة',
                    isTaken ? 'تم أخذ الدواء' : 'لم يتم أخذه بعد',
                  ),
                  if (notes.isNotEmpty)
                    buildDetailRow(Icons.notes_rounded, 'ملاحظات', notes),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _speak(_medicationSpeechText(data)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      icon: const Icon(
                        Icons.volume_up_rounded,
                        color: AppColors.primary,
                      ),
                      label: const Text(
                        'اسمع تفاصيل الدواء',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget buildDetailRow(IconData icon, String title, String value) {
    if (value.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 26),
          const SizedBox(width: 10),
          Text(
            '$title: ',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSummaryCard(int total, int taken) {
    final int pending = total - taken;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.medication_liquid_rounded,
              color: AppColors.primary,
              size: 36,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'أدوية اليوم: $total\nتم أخذ $taken • متبقي $pending',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildFilterChips() {
    return SizedBox(
      height: 54,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        children: MedicationFilter.values.map((filter) {
          final isSelected = selectedFilter == filter;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: ChoiceChip(
              avatar: Icon(
                getFilterIcon(filter),
                color: isSelected ? Colors.white : AppColors.primary,
                size: 22,
              ),
              label: Text(
                getFilterText(filter),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: isSelected ? Colors.white : Colors.black,
                ),
              ),
              selected: isSelected,
              selectedColor: AppColors.primary,
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: const BorderSide(color: AppColors.border, width: 1.4),
              ),
              onSelected: (_) {
                setState(() {
                  selectedFilter = filter;
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget buildMedicationCard(String id, Map<String, dynamic> data) {
    final String name = data['name'] ?? 'دواء بدون اسم';
    final String dose = data['dose'] ?? '';
    final bool isTaken = _isTakenToday(data);
    final String timesText = getTimesText(data);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isTaken ? AppColors.success : AppColors.border,
          width: isTaken ? 2 : 1.3,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 29,
                backgroundColor: isTaken
                    ? const Color(0xFFE8F5E9)
                    : const Color(0xFFEAF2FA),
                child: Icon(
                  isTaken
                      ? Icons.check_circle_rounded
                      : Icons.medication_rounded,
                  color: isTaken ? AppColors.success : AppColors.primary,
                  size: 34,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  name,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 10,
            runSpacing: 10,
            children: [
              _infoChip(
                icon: Icons.access_time_rounded,
                text: timesText,
                iconColor: AppColors.warning,
                backgroundColor: const Color(0xFFFFF3E0),
              ),
              if (dose.trim().isNotEmpty)
                _infoChip(
                  icon: Icons.medical_services_rounded,
                  text: dose,
                  iconColor: AppColors.primary,
                  backgroundColor: const Color(0xFFEAF2FA),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isTaken
                  ? const Color(0xFFE8F5E9)
                  : const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isTaken ? AppColors.success : AppColors.danger,
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isTaken ? Icons.check_circle_rounded : Icons.error_rounded,
                  color: isTaken ? AppColors.success : AppColors.danger,
                  size: 25,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isTaken ? 'الحالة: تم أخذ الدواء' : 'الحالة: لم يتم أخذه',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      color: isTaken ? AppColors.success : AppColors.danger,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => showMedicationDetails(data),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  icon: const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.primary,
                  ),
                  label: const Text(
                    'تفاصيل',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => toggleTaken(id, isTaken),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isTaken
                        ? AppColors.success
                        : AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: Icon(
                    isTaken ? Icons.undo_rounded : Icons.check_rounded,
                    color: Colors.white,
                  ),
                  label: Text(
                    isTaken ? 'إلغاء' : 'أخذ',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _speak(_medicationSpeechText(data)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary, width: 1.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
              icon: const Icon(
                Icons.volume_up_rounded,
                color: AppColors.primary,
              ),
              label: const Text(
                'اسمع موعد الدواء',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip({
    required IconData icon,
    required String text,
    required Color iconColor,
    required Color backgroundColor,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 220),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildEmptyState() {
    return const Center(
      child: Text(
        'لا يوجد أدوية هنا',
        style: TextStyle(
          fontSize: 23,
          fontWeight: FontWeight.w900,
          color: Colors.black,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'يجب تسجيل الدخول أولاً',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: AppColors.primary,
          onPressed: openAddMedicationScreen,
          icon: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
          label: const Text(
            'إضافة دواء',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ),
        body: SafeArea(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('medications')
                .where('userId', isEqualTo: currentUser.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }

              if (snapshot.hasError) {
                return const Center(
                  child: Text(
                    'حدث خطأ أثناء تحميل الأدوية',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                );
              }

              final docs = snapshot.data?.docs ?? [];
              docs.sort((a, b) {
                final aTime = a.data()['createdAt'];
                final bTime = b.data()['createdAt'];

                if (aTime is Timestamp && bTime is Timestamp) {
                  return bTime.compareTo(aTime);
                }

                return 0;
              });

              final todayDocs = docs
                  .where((doc) => _shouldShowMedicationToday(doc.data()))
                  .toList();
              final filteredDocs = filterMedications(docs);
              final takenCount = todayDocs
                  .where((doc) => _isTakenToday(doc.data()))
                  .length;

              return Column(
                children: [
                  const SizedBox(height: 18),
                  const Text(
                    'أدويتي اليومية',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  buildSummaryCard(todayDocs.length, takenCount),
                  const SizedBox(height: 12),
                  buildVoiceSummaryCard(todayDocs, takenCount),
                  const SizedBox(height: 18),
                  buildFilterChips(),
                  const SizedBox(height: 14),
                  Expanded(
                    child: filteredDocs.isEmpty
                        ? buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                            itemCount: filteredDocs.length,
                            itemBuilder: (context, index) {
                              final doc = filteredDocs[index];
                              return buildMedicationCard(doc.id, doc.data());
                            },
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
