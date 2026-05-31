import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'signup_step3.dart';

class SignUpStep2 extends StatefulWidget {
  final String role;
  final String fullName;
  final String phone;
  final String password;
  final String age;
  final String gender;
  final String relation;

  const SignUpStep2({
    super.key,
    required this.role,
    required this.fullName,
    required this.phone,
    required this.password,
    required this.age,
    required this.gender,
    required this.relation,
  });

  @override
  State<SignUpStep2> createState() => _SignUpStep2State();
}

class _SignUpStep2State extends State<SignUpStep2> {
  static const Color primaryColor = Color(0xFF1E3A5F);
  static const Color backgroundColor = Color(0xFFF7F8FA);
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color textColor = Color(0xFF1F2937);
  static const Color secondaryTextColor = Color(0xFF4B5563);
  static const Color warningColor = Color(0xFFED6C02);
  static const Color errorColor = Color(0xFFD32F2F);

  final TextEditingController linkPhoneController = TextEditingController();
  final TextEditingController doctorPhoneController = TextEditingController();
  final TextEditingController inviteCodeController = TextEditingController();

  final TextEditingController specialtyController = TextEditingController();
  final TextEditingController workplaceController = TextEditingController();
  final TextEditingController licenseNumberController = TextEditingController();

  String? doctorSpecialty;

  final List<String> specialties = [
    'طب عام',
    'باطنية',
    'قلب',
    'أعصاب',
    'سكري وغدد',
    'طوارئ',
    'جراحة',
    'عظام',
    'كلى',
    'صدرية',
    'أخرى',
  ];

  @override
  void dispose() {
    linkPhoneController.dispose();
    doctorPhoneController.dispose();
    inviteCodeController.dispose();
    specialtyController.dispose();
    workplaceController.dispose();
    licenseNumberController.dispose();
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
        action: SnackBarAction(
          label: 'تم',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  void goNext() {
    if (widget.role == "مريض") {
      if (linkPhoneController.text.trim().isEmpty &&
          inviteCodeController.text.trim().isEmpty) {
        showMessage("أدخلي رقم المرافق أو كود الدعوة", color: warningColor);
        return;
      }
    }

    if (widget.role == "مرافق") {
      if (linkPhoneController.text.trim().isEmpty &&
          inviteCodeController.text.trim().isEmpty) {
        showMessage("أدخلي رقم المريض أو كود الدعوة", color: warningColor);
        return;
      }
    }

    if (widget.role == "طبيب") {
      if (doctorSpecialty == null) {
        showMessage("اختاري تخصص الطبيب", color: errorColor);
        return;
      }

      if (doctorSpecialty == "أخرى" &&
          specialtyController.text.trim().isEmpty) {
        showMessage("اكتبي التخصص", color: errorColor);
        return;
      }

      if (workplaceController.text.trim().isEmpty) {
        showMessage("مكان العمل مطلوب", color: errorColor);
        return;
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SignUpStep3(
          role: widget.role,
          fullName: widget.fullName,
          phone: widget.phone,
          password: widget.password,
          age: widget.age,
          gender: widget.gender,
          relation: widget.relation,
          linkedPhone: linkPhoneController.text.trim(),
          doctorPhone: doctorPhoneController.text.trim(),
          inviteCode: inviteCodeController.text.trim(),
          doctorSpecialty: doctorSpecialty == "أخرى"
              ? specialtyController.text.trim()
              : doctorSpecialty ?? "",
          doctorWorkplace: workplaceController.text.trim(),
          doctorLicenseNumber: licenseNumberController.text.trim(),
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
        fontSize: 18,
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

  @override
  Widget build(BuildContext context) {
    final bool isPatient = widget.role == "مريض";
    final bool isCaregiver = widget.role == "مرافق";
    final bool isDoctor = widget.role == "طبيب";

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

                Text(
                  isDoctor ? 'بيانات الطبيب' : 'ربط الحسابات',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  isPatient ? 'الخطوة 2 من 5' : 'الخطوة 2 من 4',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'Cairo',
                    color: secondaryTextColor,
                  ),
                ),

                const SizedBox(height: 24),

                LinearProgressIndicator(
                  value: isPatient ? 0.4 : 0.5,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(20),
                  backgroundColor: Colors.grey.shade300,
                  color: primaryColor,
                ),

                const SizedBox(height: 32),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isPatient
                        ? 'أضيفي رقم هاتف المرافق أو كود الدعوة، ويمكنك إضافة رقم الطبيب اختياريًا لمتابعة التقارير والحالات الحرجة.'
                        : isCaregiver
                        ? 'أضيفي رقم هاتف المريض أو كود الدعوة لبدء المتابعة واستقبال التنبيهات.'
                        : 'أدخلي بيانات الطبيب ليتمكن المرضى من ربط حساباتهم معك ومشاركة التقارير الصحية.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontFamily: 'Cairo',
                      color: textColor,
                      height: 1.6,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                if (!isDoctor) ...[
                  buildField(
                    controller: linkPhoneController,
                    hint: isPatient ? 'رقم هاتف المرافق' : 'رقم هاتف المريض',
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                  ),

                  const SizedBox(height: 16),

                  if (isPatient) ...[
                    buildField(
                      controller: doctorPhoneController,
                      hint: 'رقم هاتف الطبيب (اختياري)',
                      icon: Icons.medical_services,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                  ],

                  buildField(
                    controller: inviteCodeController,
                    hint: 'كود الدعوة (اختياري)',
                    icon: Icons.qr_code,
                  ),
                ],

                if (isDoctor) ...[
                  DropdownButtonFormField<String>(
                    initialValue: doctorSpecialty,
                    decoration: inputDecoration(
                      hint: 'تخصص الطبيب',
                      icon: Icons.medical_services,
                    ),
                    style: const TextStyle(
                      fontSize: 18,
                      fontFamily: 'Cairo',
                      color: textColor,
                    ),
                    items: specialties
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        doctorSpecialty = value;
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  if (doctorSpecialty == "أخرى") ...[
                    buildField(
                      controller: specialtyController,
                      hint: 'اكتبي التخصص',
                      icon: Icons.edit,
                    ),
                    const SizedBox(height: 16),
                  ],

                  buildField(
                    controller: workplaceController,
                    hint: 'مكان العمل / العيادة / المستشفى',
                    icon: Icons.local_hospital,
                  ),

                  const SizedBox(height: 16),

                  buildField(
                    controller: licenseNumberController,
                    hint: 'رقم مزاولة المهنة (اختياري)',
                    icon: Icons.badge,
                  ),
                ],

                const SizedBox(height: 32),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: warningColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isPatient
                              ? 'سيتمكن المرافق من متابعة حالتك واستقبال تنبيهات SOS، والطبيب سيشاهد التقارير والحالات الحرجة فقط.'
                              : isCaregiver
                              ? 'سيصلك تنبيه عند احتياج المريض للمساعدة أو عند وجود حالة طارئة.'
                              : 'سيتم إنشاء كود طبيب خاص بك لاستخدامه في ربط المرضى لاحقًا.',
                          style: const TextStyle(
                            fontSize: 16,
                            fontFamily: 'Cairo',
                            color: secondaryTextColor,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
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
