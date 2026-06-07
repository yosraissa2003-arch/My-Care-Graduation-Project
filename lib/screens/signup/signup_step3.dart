import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'signup_step4.dart';

class SignUpStep3 extends StatefulWidget {
  final String role, fullName, phone, email, password, age, gender, relation;
  final String linkedPhone, doctorPhone, inviteCode;
  final String doctorSpecialty, doctorWorkplace, doctorLicenseNumber;

  const SignUpStep3({
    super.key,
    required this.role,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.password,
    required this.age,
    required this.gender,
    required this.relation,
    required this.linkedPhone,
    required this.doctorPhone,
    required this.inviteCode,
    required this.doctorSpecialty,
    required this.doctorWorkplace,
    required this.doctorLicenseNumber,
  });

  @override
  State<SignUpStep3> createState() => _SignUpStep3State();
}

class _SignUpStep3State extends State<SignUpStep3> {
  static const Color primaryColor = Color(0xFF1E3A5F);
  static const Color backgroundColor = Color(0xFFF7F8FA);
  static const Color cardColor = Colors.white;
  static const Color textColor = Color(0xFF1F2937);
  static const Color secondaryTextColor = Color(0xFF4B5563);
  static const Color warningColor = Color(0xFFED6C02);
  static const Color successColor = Color(0xFF2E7D32);

  String? bloodType;
  String? smokingStatus;

  bool remindersEnabled = true;
  bool wearableEnabled = false;

  final otherDiseaseController = TextEditingController();
  final diseaseSinceController = TextEditingController();
  final otherMedicineController = TextEditingController();
  final otherAllergyController = TextEditingController();
  final otherSurgeryController = TextEditingController();
  final cigarettesPerDayController = TextEditingController();
  final bloodPressureController = TextEditingController();
  final sugarController = TextEditingController();
  final heartRateController = TextEditingController();

  final Set<String> selectedDiseases = {};
  final Set<String> selectedMedicines = {};
  final Set<String> selectedAllergies = {};
  final Set<String> selectedSurgeries = {};
  final Set<String> selectedAllergyTypes = {};

  final List<String> bloodTypes = [
    "A+",
    "A-",
    "B+",
    "B-",
    "O+",
    "O-",
    "AB+",
    "AB-",
  ];

  final List<String> diseases = [
    "ارتفاع ضغط الدم",
    "السكري النوع الأول",
    "السكري النوع الثاني",
    "ارتفاع الكوليسترول",
    "أمراض القلب",
    "فشل القلب",
    "اضطراب نظم القلب",
    "ذبحة صدرية",
    "ربو",
    "حساسية صدر",
    "COPD",
    "صرع",
    "باركنسون",
    "الزهايمر",
    "أمراض أعصاب",
    "جلطة دماغية سابقة",
    "أمراض كلى",
    "غسيل كلى",
    "أمراض كبد",
    "مشاكل الغدة الدرقية",
    "هشاشة عظام",
    "التهاب مفاصل",
    "فقر دم",
    "سرطان",
    "اكتئاب",
    "قلق",
    "لا يوجد",
    "أخرى",
  ];

  final List<String> medicines = [
    "Metformin",
    "Insulin",
    "Glibenclamide",
    "Gliclazide",
    "Sitagliptin",
    "Amlodipine",
    "Lisinopril",
    "Losartan",
    "Valsartan",
    "Captopril",
    "Bisoprolol",
    "Atenolol",
    "Aspirin",
    "Clopidogrel",
    "Atorvastatin",
    "Rosuvastatin",
    "Furosemide",
    "Ventolin",
    "Symbicort",
    "Seretide",
    "Carbamazepine",
    "Valproate",
    "Levetiracetam",
    "Lamotrigine",
    "Euthyrox",
    "لا يوجد",
    "أخرى",
  ];

  final List<String> allergies = [
    "Penicillin",
    "Sulfa",
    "Aspirin",
    "Ibuprofen",
    "حساسية تخدير",
    "حساسية أدوية الصرع",
    "حساسية أدوية الأعصاب",
    "حساسية طعام",
    "لا يوجد",
    "أخرى",
  ];

  final List<String> allergyTypes = [
    "طفح جلدي",
    "تورم",
    "ضيق تنفس",
    "إغماء",
    "حكة",
    "صدمة تحسسية",
  ];

  final List<String> surgeries = [
    "عملية قلب",
    "قسطرة",
    "عملية عيون",
    "عملية عظام",
    "استئصال الزائدة",
    "استئصال المرارة",
    "عملية دماغ",
    "عملية كلى",
    "عملية كبد",
    "لا يوجد",
    "أخرى",
  ];

  @override
  void dispose() {
    otherDiseaseController.dispose();
    diseaseSinceController.dispose();
    otherMedicineController.dispose();
    otherAllergyController.dispose();
    otherSurgeryController.dispose();
    cigarettesPerDayController.dispose();
    bloodPressureController.dispose();
    sugarController.dispose();
    heartRateController.dispose();
    super.dispose();
  }

  void showMessage(String message, {Color color = primaryColor}) async {
    await SystemSound.play(SystemSoundType.alert);
    HapticFeedback.mediumImpact();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Text(
          message,
          textAlign: TextAlign.right,
          style: const TextStyle(
            fontSize: 18,
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Future<void> pickDiseaseSinceDate() async {
    final DateTime now = DateTime.now();

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'اختاري تاريخ بداية المرض',
      cancelText: 'إلغاء',
      confirmText: 'اختيار',
      fieldLabelText: 'تاريخ بداية المرض',
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: primaryColor,
                onPrimary: Colors.white,
                onSurface: textColor,
              ),
            ),
            child: child!,
          ),
        );
      },
    );

    if (pickedDate == null) return;

    final String formattedDate =
        '${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}';

    setState(() {
      diseaseSinceController.text = formattedDate;
    });
  }

  String joinValues(Set<String> values, TextEditingController otherController) {
    final result = values.toList();
    if (values.contains("أخرى") && otherController.text.trim().isNotEmpty) {
      result.remove("أخرى");
      result.add(otherController.text.trim());
    }
    return result.join(", ");
  }

  void goNext() {
    if (widget.role == "مريض") {
      if (selectedDiseases.isEmpty) {
        showMessage("اختاري الأمراض المزمنة أو لا يوجد", color: warningColor);
        return;
      }

      if (selectedDiseases.contains("أخرى") &&
          otherDiseaseController.text.trim().isEmpty) {
        showMessage("اكتبي المرض غير الموجود", color: warningColor);
        return;
      }

      if (selectedMedicines.isEmpty) {
        showMessage("اختاري الأدوية المزمنة أو لا يوجد", color: warningColor);
        return;
      }

      if (selectedMedicines.contains("أخرى") &&
          otherMedicineController.text.trim().isEmpty) {
        showMessage("اكتبي الدواء غير الموجود", color: warningColor);
        return;
      }

      if (selectedAllergies.isEmpty) {
        showMessage("اختاري الحساسية أو لا يوجد", color: warningColor);
        return;
      }

      if (selectedAllergies.contains("أخرى") &&
          otherAllergyController.text.trim().isEmpty) {
        showMessage("اكتبي الحساسية غير الموجودة", color: warningColor);
        return;
      }

      if (selectedSurgeries.isEmpty) {
        showMessage("اختاري العمليات السابقة أو لا يوجد", color: warningColor);
        return;
      }

      if (selectedSurgeries.contains("أخرى") &&
          otherSurgeryController.text.trim().isEmpty) {
        showMessage("اكتبي العملية غير الموجودة", color: warningColor);
        return;
      }

      if (bloodType == null) {
        showMessage("اختاري فصيلة الدم", color: warningColor);
        return;
      }

      if (smokingStatus == null) {
        showMessage("اختاري حالة التدخين", color: warningColor);
        return;
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SignUpStep4(
          role: widget.role,
          fullName: widget.fullName,
          phone: widget.phone,
          email: widget.email,
          password: widget.password,
          age: widget.age,
          gender: widget.gender,
          relation: widget.relation,
          linkedPhone: widget.linkedPhone,
          doctorPhone: widget.doctorPhone,
          inviteCode: widget.inviteCode,
          doctorSpecialty: widget.doctorSpecialty,
          doctorWorkplace: widget.doctorWorkplace,
          doctorLicenseNumber: widget.doctorLicenseNumber,
          diseases: joinValues(selectedDiseases, otherDiseaseController),
          diseaseSince: diseaseSinceController.text.trim(),
          medicines: joinValues(selectedMedicines, otherMedicineController),
          allergy: joinValues(selectedAllergies, otherAllergyController),
          allergyTypes: selectedAllergyTypes.join(", "),
          surgeries: joinValues(selectedSurgeries, otherSurgeryController),
          smokingStatus: smokingStatus ?? "",
          cigarettesPerDay: cigarettesPerDayController.text.trim(),
          bloodType: bloodType ?? "",
          bloodPressure: bloodPressureController.text.trim(),
          sugar: sugarController.text.trim(),
          heartRate: heartRateController.text.trim(),
          remindersEnabled: remindersEnabled,
          wearableEnabled: wearableEnabled,
        ),
      ),
    );
  }

  InputDecoration inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        fontSize: 17,
        fontFamily: 'Cairo',
        color: secondaryTextColor,
      ),
      prefixIcon: Icon(icon, color: primaryColor),
      filled: true,
      fillColor: cardColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return SizedBox(
      height: 56,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(
          fontSize: 18,
          fontFamily: 'Cairo',
          color: textColor,
        ),
        decoration: inputDecoration(hint: hint, icon: icon),
      ),
    );
  }

  Widget buildDateField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 56,
      child: TextField(
        controller: controller,
        readOnly: true,
        onTap: onTap,
        style: const TextStyle(
          fontSize: 18,
          fontFamily: 'Cairo',
          color: textColor,
        ),
        decoration: inputDecoration(hint: hint, icon: icon).copyWith(
          suffixIcon: const Icon(Icons.calendar_month, color: primaryColor),
        ),
      ),
    );
  }

  Widget buildPickerCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Set<String> selectedValues,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, color: primaryColor, size: 32),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 19,
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    selectedValues.isEmpty
                        ? subtitle
                        : "${selectedValues.length} عناصر مختارة",
                    style: const TextStyle(
                      fontSize: 15,
                      fontFamily: 'Cairo',
                      color: secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: secondaryTextColor,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  void openSelectionSheet({
    required String title,
    required List<String> items,
    required Set<String> selectedValues,
    TextEditingController? otherController,
  }) {
    final tempSelected = Set<String>.from(selectedValues);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.75,
                    child: Column(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: ListView.separated(
                            itemCount: items.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final item = items[index];
                              final selected = tempSelected.contains(item);

                              return Container(
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: CheckboxListTile(
                                  value: selected,
                                  activeColor: successColor,
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  title: Text(
                                    item,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontFamily: 'Cairo',
                                      fontWeight: FontWeight.w600,
                                      color: textColor,
                                    ),
                                  ),
                                  onChanged: (value) {
                                    setSheetState(() {
                                      if (item == "لا يوجد" && value == true) {
                                        tempSelected.clear();
                                        tempSelected.add(item);
                                        otherController?.clear();
                                      } else {
                                        tempSelected.remove("لا يوجد");

                                        if (value == true) {
                                          tempSelected.add(item);
                                        } else {
                                          tempSelected.remove(item);
                                        }
                                      }
                                    });
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                        if (tempSelected.contains("أخرى") &&
                            otherController != null) ...[
                          const SizedBox(height: 12),
                          buildField(
                            controller: otherController,
                            hint: 'اكتبي هنا',
                            icon: Icons.edit,
                          ),
                        ],
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 54,
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                selectedValues
                                  ..clear()
                                  ..addAll(tempSelected);
                              });
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'حفظ الاختيارات',
                              style: TextStyle(
                                fontSize: 18,
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget buildSmallCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(children: children),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isPatient = widget.role == "مريض";
    final bool isDoctor = widget.role == "طبيب";

    if (!isPatient) {
      Future.microtask(() {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SignUpStep4(
              role: widget.role,
              fullName: widget.fullName,
              phone: widget.phone,
              email: widget.email,
              password: widget.password,
              age: widget.age,
              gender: widget.gender,
              relation: widget.relation,
              linkedPhone: widget.linkedPhone,
              doctorPhone: widget.doctorPhone,
              inviteCode: widget.inviteCode,
              doctorSpecialty: widget.doctorSpecialty,
              doctorWorkplace: widget.doctorWorkplace,
              doctorLicenseNumber: widget.doctorLicenseNumber,
              diseases: "",
              diseaseSince: "",
              medicines: "",
              allergy: "",
              allergyTypes: "",
              surgeries: "",
              smokingStatus: "",
              cigarettesPerDay: "",
              bloodType: "",
              bloodPressure: "",
              sugar: "",
              heartRate: "",
              remindersEnabled: false,
              wearableEnabled: false,
            ),
          ),
        );
      });

      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: Text(
            isDoctor ? "جاري تجهيز بيانات الطبيب..." : "جاري المتابعة...",
            style: const TextStyle(
              fontSize: 18,
              fontFamily: 'Cairo',
              color: primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                const Text(
                  'رعايتي ❤️',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'الملف الطبي',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'الخطوة 3 من 5',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Cairo',
                    color: secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 24),
                LinearProgressIndicator(
                  value: 0.6,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(20),
                  backgroundColor: Colors.grey.shade300,
                  color: primaryColor,
                ),
                const SizedBox(height: 24),

                buildPickerCard(
                  title: 'الأمراض المزمنة',
                  subtitle: 'اختاري الأمراض من قائمة مرتبة',
                  icon: Icons.medical_services,
                  selectedValues: selectedDiseases,
                  onTap: () => openSelectionSheet(
                    title: 'اختيار الأمراض المزمنة',
                    items: diseases,
                    selectedValues: selectedDiseases,
                    otherController: otherDiseaseController,
                  ),
                ),

                const SizedBox(height: 14),

                buildDateField(
                  controller: diseaseSinceController,
                  hint: 'تاريخ بداية المرض',
                  icon: Icons.calendar_month,
                  onTap: pickDiseaseSinceDate,
                ),

                const SizedBox(height: 14),

                buildPickerCard(
                  title: 'الأدوية المزمنة / اليومية',
                  subtitle: 'اختاري الأدوية المستخدمة يوميًا',
                  icon: Icons.medication,
                  selectedValues: selectedMedicines,
                  onTap: () => openSelectionSheet(
                    title: 'اختيار الأدوية المزمنة',
                    items: medicines,
                    selectedValues: selectedMedicines,
                    otherController: otherMedicineController,
                  ),
                ),

                const SizedBox(height: 14),

                buildPickerCard(
                  title: 'الحساسية',
                  subtitle: 'اختاري نوع الحساسية إن وجدت',
                  icon: Icons.warning,
                  selectedValues: selectedAllergies,
                  onTap: () => openSelectionSheet(
                    title: 'اختيار الحساسية',
                    items: allergies,
                    selectedValues: selectedAllergies,
                    otherController: otherAllergyController,
                  ),
                ),

                const SizedBox(height: 14),

                buildPickerCard(
                  title: 'نوع رد فعل الحساسية',
                  subtitle: 'طفح، تورم، ضيق تنفس...',
                  icon: Icons.info_outline,
                  selectedValues: selectedAllergyTypes,
                  onTap: () => openSelectionSheet(
                    title: 'اختيار نوع الحساسية',
                    items: allergyTypes,
                    selectedValues: selectedAllergyTypes,
                  ),
                ),

                const SizedBox(height: 14),

                buildPickerCard(
                  title: 'العمليات السابقة',
                  subtitle: 'اختاري العمليات السابقة أو لا يوجد',
                  icon: Icons.local_hospital,
                  selectedValues: selectedSurgeries,
                  onTap: () => openSelectionSheet(
                    title: 'اختيار العمليات السابقة',
                    items: surgeries,
                    selectedValues: selectedSurgeries,
                    otherController: otherSurgeryController,
                  ),
                ),

                const SizedBox(height: 18),

                buildSmallCard(
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: bloodType,
                      decoration: inputDecoration(
                        hint: 'فصيلة الدم',
                        icon: Icons.bloodtype,
                      ),
                      style: const TextStyle(
                        fontSize: 18,
                        fontFamily: 'Cairo',
                        color: textColor,
                      ),
                      items: bloodTypes
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() => bloodType = value);
                      },
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: smokingStatus,
                      decoration: inputDecoration(
                        hint: 'حالة التدخين',
                        icon: Icons.smoking_rooms,
                      ),
                      style: const TextStyle(
                        fontSize: 18,
                        fontFamily: 'Cairo',
                        color: textColor,
                      ),
                      items: ['غير مدخن', 'مدخن', 'مدخن سابق']
                          .map(
                            (status) => DropdownMenuItem(
                              value: status,
                              child: Text(status),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() => smokingStatus = value);
                      },
                    ),
                    if (smokingStatus == "مدخن") ...[
                      const SizedBox(height: 14),
                      buildField(
                        controller: cigarettesPerDayController,
                        hint: 'عدد السجائر يوميًا',
                        icon: Icons.numbers,
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 18),

                buildSmallCard(
                  children: [
                    buildField(
                      controller: bloodPressureController,
                      hint: 'ضغط الدم مثال: 120/80',
                      icon: Icons.favorite,
                    ),
                    const SizedBox(height: 14),
                    buildField(
                      controller: sugarController,
                      hint: 'مستوى السكر',
                      icon: Icons.water_drop,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 14),
                    buildField(
                      controller: heartRateController,
                      hint: 'نبض القلب',
                      icon: Icons.monitor_heart,
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                buildSmallCard(
                  children: [
                    SwitchListTile(
                      value: remindersEnabled,
                      activeThumbColor: successColor,
                      title: const Text(
                        'تفعيل تذكيرات الأدوية',
                        style: TextStyle(
                          fontSize: 18,
                          fontFamily: 'Cairo',
                          color: textColor,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() => remindersEnabled = value);
                      },
                    ),
                    SwitchListTile(
                      value: wearableEnabled,
                      activeThumbColor: successColor,
                      title: const Text(
                        'استخدام بيانات ساعة ذكية لاحقًا',
                        style: TextStyle(
                          fontSize: 18,
                          fontFamily: 'Cairo',
                          color: textColor,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() => wearableEnabled = value);
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: goNext,
                    icon: const Icon(Icons.arrow_forward, color: Colors.white),
                    label: const Text(
                      'التالي',
                      style: TextStyle(
                        fontSize: 18,
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

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
