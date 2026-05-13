import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_medication_screen.dart';

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
  MedicationFilter selectedFilter = MedicationFilter.all;

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

  List<QueryDocumentSnapshot<Map<String, dynamic>>> filterMedications(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    return docs.where((doc) {
      final data = doc.data();
      final bool isTaken = data['isTaken'] == true;
      final List times = data['times'] ?? [];
      final String allTimes = times.join(' ');

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
    await FirebaseFirestore.instance.collection('medications').doc(id).update({
      'isTaken': !currentValue,
      'takenAt': !currentValue ? FieldValue.serverTimestamp() : null,
    });
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
    final bool isTaken = data['isTaken'] == true;

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
    final bool isTaken = data['isTaken'] == true;
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
          Row(
            children: [
              const Icon(
                Icons.access_time_rounded,
                color: AppColors.warning,
                size: 25,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  timesText,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.medical_services_rounded,
                color: AppColors.primary,
                size: 25,
              ),
              const SizedBox(width: 8),
              Text(
                dose,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
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
        ],
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
                .orderBy('createdAt', descending: true)
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
              final filteredDocs = filterMedications(docs);
              final takenCount = docs
                  .where((doc) => doc.data()['isTaken'] == true)
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
                  buildSummaryCard(docs.length, takenCount),
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
