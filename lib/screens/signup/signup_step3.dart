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
  static const Color primaryColor = Color(0xFF1F4168);
  static const Color backgroundColor = Color(0xFFF7F9FC);
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color textColor = Color(0xFF111827);
  static const Color secondaryTextColor = Color(0xFF374151);
  static const Color hintColor = Color(0xFF6B7280);
  static const Color borderColor = Color(0xFFC9D6E2);
  static const Color selectedCardColor = Color(0xFFEFF4FB);

  static const Color warningColor = Color(0xFFED6C02);
  static const Color successColor = Color(0xFF2E7D32);

  String? bloodType;
  String? smokingStatus;

  bool remindersEnabled = true;

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        content: Text(
          message,
          textAlign: TextAlign.right,
          style: const TextStyle(
            fontSize: 18,
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w700,
            color: Colors.white,
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
      helpText: 'اختر تاريخ بداية المرض',
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
        showMessage(
          "يرجى اختيار الأمراض المزمنة أو لا يوجد",
          color: warningColor,
        );
        return;
      }

      if (selectedDiseases.contains("أخرى") &&
          otherDiseaseController.text.trim().isEmpty) {
        showMessage("يرجى إدخال المرض غير الموجود", color: warningColor);
        return;
      }

      if (selectedMedicines.isEmpty) {
        showMessage(
          "يرجى اختيار الأدوية المزمنة أو لا يوجد",
          color: warningColor,
        );
        return;
      }

      if (selectedMedicines.contains("أخرى") &&
          otherMedicineController.text.trim().isEmpty) {
        showMessage("يرجى إدخال الدواء غير الموجود", color: warningColor);
        return;
      }

      if (selectedAllergies.isEmpty) {
        showMessage("يرجى اختيار الحساسية أو لا يوجد", color: warningColor);
        return;
      }

      if (selectedAllergies.contains("أخرى") &&
          otherAllergyController.text.trim().isEmpty) {
        showMessage("يرجى إدخال الحساسية غير الموجودة", color: warningColor);
        return;
      }

      if (selectedSurgeries.isEmpty) {
        showMessage(
          "يرجى اختيار العمليات السابقة أو لا يوجد",
          color: warningColor,
        );
        return;
      }

      if (selectedSurgeries.contains("أخرى") &&
          otherSurgeryController.text.trim().isEmpty) {
        showMessage("يرجى إدخال العملية غير الموجودة", color: warningColor);
        return;
      }

      if (bloodType == null) {
        showMessage("يرجى اختيار فصيلة الدم", color: warningColor);
        return;
      }

      if (smokingStatus == null) {
        showMessage("يرجى اختيار حالة التدخين", color: warningColor);
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
          wearableEnabled: false,
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
        fontSize: 19,
        fontFamily: 'Cairo',
        color: hintColor,
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: Icon(icon, color: primaryColor, size: 28),
      filled: true,
      fillColor: cardColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: borderColor, width: 1.3),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: borderColor, width: 1.3),
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
      height: 62,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textInputAction: TextInputAction.next,
        style: const TextStyle(
          fontSize: 20,
          fontFamily: 'Cairo',
          color: textColor,
          fontWeight: FontWeight.w600,
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
      height: 62,
      child: TextField(
        controller: controller,
        readOnly: true,
        onTap: onTap,
        textAlign: TextAlign.right,
        style: const TextStyle(
          fontSize: 20,
          fontFamily: 'Cairo',
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
        decoration: inputDecoration(hint: hint, icon: icon),
      ),
    );
  }

  Widget buildPageTitle() {
    return const Text(
      'الملف الطبي',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 34,
        fontFamily: 'Cairo',
        fontWeight: FontWeight.w900,
        color: primaryColor,
        height: 1.3,
      ),
    );
  }

  Widget buildStepIndicator() {
    return Column(
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: const Text(
              'الخطوة 3 من 5',
              style: TextStyle(
                fontSize: 18,
                fontFamily: 'Cairo',
                color: secondaryTextColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: const LinearProgressIndicator(
            value: 0.60,
            minHeight: 10,
            backgroundColor: Color(0xFFE5E7EB),
            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
          ),
        ),
      ],
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
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.035),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: primaryColor, size: 34),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 23,
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w900,
                      color: textColor,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    selectedValues.isEmpty
                        ? subtitle
                        : "${selectedValues.length} عناصر مختارة",
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 18,
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w600,
                      color: secondaryTextColor,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: secondaryTextColor,
              size: 22,
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
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w900,
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
                                  border: Border.all(
                                    color: selected
                                        ? primaryColor
                                        : borderColor,
                                    width: selected ? 1.8 : 1,
                                  ),
                                ),
                                child: CheckboxListTile(
                                  value: selected,
                                  activeColor: successColor,
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  title: Text(
                                    item,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontFamily: 'Cairo',
                                      fontWeight: FontWeight.w700,
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
                            hint: 'أدخل هنا',
                            icon: Icons.edit,
                          ),
                        ],
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 58,
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
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: const Text(
                              'حفظ الاختيارات',
                              style: TextStyle(
                                fontSize: 20,
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.w800,
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  TextStyle get dropdownTextStyle {
    return const TextStyle(
      fontSize: 20,
      fontFamily: 'Cairo',
      color: textColor,
      fontWeight: FontWeight.w600,
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
              fontSize: 20,
              fontFamily: 'Cairo',
              color: primaryColor,
              fontWeight: FontWeight.w800,
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),

                buildPageTitle(),

                const SizedBox(height: 20),

                buildStepIndicator(),

                const SizedBox(height: 28),

                buildPickerCard(
                  title: 'الأمراض المزمنة',
                  subtitle: 'اختر الأمراض من قائمة مرتبة',
                  icon: Icons.medical_services,
                  selectedValues: selectedDiseases,
                  onTap: () => openSelectionSheet(
                    title: 'اختيار الأمراض المزمنة',
                    items: diseases,
                    selectedValues: selectedDiseases,
                    otherController: otherDiseaseController,
                  ),
                ),

                const SizedBox(height: 16),

                buildDateField(
                  controller: diseaseSinceController,
                  hint: 'تاريخ بداية المرض',
                  icon: Icons.calendar_month,
                  onTap: pickDiseaseSinceDate,
                ),

                const SizedBox(height: 16),

                buildPickerCard(
                  title: 'الأدوية المزمنة / اليومية',
                  subtitle: 'اختر الأدوية المستخدمة يوميًا',
                  icon: Icons.medication,
                  selectedValues: selectedMedicines,
                  onTap: () => openSelectionSheet(
                    title: 'اختيار الأدوية المزمنة',
                    items: medicines,
                    selectedValues: selectedMedicines,
                    otherController: otherMedicineController,
                  ),
                ),

                const SizedBox(height: 16),

                buildPickerCard(
                  title: 'الحساسية',
                  subtitle: 'اختر نوع الحساسية إن وجدت',
                  icon: Icons.warning,
                  selectedValues: selectedAllergies,
                  onTap: () => openSelectionSheet(
                    title: 'اختيار الحساسية',
                    items: allergies,
                    selectedValues: selectedAllergies,
                    otherController: otherAllergyController,
                  ),
                ),

                const SizedBox(height: 16),

                buildPickerCard(
                  title: 'نوع رد فعل الحساسية',
                  subtitle: 'طفح، تورم، ضيق تنفس...',
                  icon: Icons.info_outline,
                  selectedValues: selectedAllergyTypes,
                  onTap: () => openSelectionSheet(
                    title: 'اختيار نوع رد فعل الحساسية',
                    items: allergyTypes,
                    selectedValues: selectedAllergyTypes,
                  ),
                ),

                const SizedBox(height: 16),

                buildPickerCard(
                  title: 'العمليات السابقة',
                  subtitle: 'اختر العمليات السابقة أو لا يوجد',
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
                    SizedBox(
                      height: 62,
                      child: DropdownButtonFormField<String>(
                        initialValue: bloodType,
                        decoration: inputDecoration(
                          hint: 'فصيلة الدم',
                          icon: Icons.bloodtype,
                        ),
                        style: dropdownTextStyle,
                        icon: const Icon(
                          Icons.keyboard_arrow_down,
                          color: primaryColor,
                          size: 30,
                        ),
                        dropdownColor: cardColor,
                        items: bloodTypes
                            .map(
                              (type) => DropdownMenuItem(
                                value: type,
                                child: Text(type, style: dropdownTextStyle),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() => bloodType = value);
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    SizedBox(
                      height: 62,
                      child: DropdownButtonFormField<String>(
                        initialValue: smokingStatus,
                        decoration: inputDecoration(
                          hint: 'حالة التدخين',
                          icon: Icons.smoking_rooms,
                        ),
                        style: dropdownTextStyle,
                        icon: const Icon(
                          Icons.keyboard_arrow_down,
                          color: primaryColor,
                          size: 30,
                        ),
                        dropdownColor: cardColor,
                        items: ['غير مدخن', 'مدخن', 'مدخن سابق']
                            .map(
                              (status) => DropdownMenuItem(
                                value: status,
                                child: Text(status, style: dropdownTextStyle),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() => smokingStatus = value);
                        },
                      ),
                    ),

                    if (smokingStatus == "مدخن") ...[
                      const SizedBox(height: 16),
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
                    const SizedBox(height: 16),
                    buildField(
                      controller: sugarController,
                      hint: 'مستوى السكر',
                      icon: Icons.water_drop,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
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
                          fontSize: 21,
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() => remindersEnabled = value);
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                SizedBox(
                  height: 62,
                  child: ElevatedButton.icon(
                    onPressed: goNext,
                    icon: const Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                      size: 28,
                    ),
                    label: const Text(
                      'التالي',
                      style: TextStyle(
                        fontSize: 22,
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
