import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'signup_step3.dart';

class SignUpStep2 extends StatefulWidget {
  final String role;
  final String fullName;
  final String phone;
  final String email;
  final String password;
  final String age;
  final String gender;
  final String relation;

  const SignUpStep2({
    super.key,
    required this.role,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.password,
    required this.age,
    required this.gender,
    required this.relation,
  });

  @override
  State<SignUpStep2> createState() => _SignUpStep2State();
}

class _SignUpStep2State extends State<SignUpStep2> {
  static const Color primaryColor = Color(0xFF1F4168);
  static const Color backgroundColor = Color(0xFFF7F9FC);
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color textColor = Color(0xFF111827);
  static const Color secondaryTextColor = Color(0xFF374151);
  static const Color hintColor = Color(0xFF6B7280);
  static const Color borderColor = Color(0xFFC9D6E2);
  static const Color warningColor = Color(0xFFED6C02);
  static const Color errorColor = Color(0xFFD32F2F);

  final TextEditingController linkPhoneController = TextEditingController();
  final TextEditingController doctorPhoneController = TextEditingController();

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
      if (linkPhoneController.text.trim().isEmpty) {
        showMessage("أدخل رقم هاتف المرافق", color: warningColor);
        return;
      }
    }

    if (widget.role == "مرافق") {
      if (linkPhoneController.text.trim().isEmpty) {
        showMessage("أدخل رقم هاتف المريض", color: warningColor);
        return;
      }
    }

    if (widget.role == "طبيب") {
      if (doctorSpecialty == null) {
        showMessage("اختر تخصص الطبيب", color: errorColor);
        return;
      }

      if (doctorSpecialty == "أخرى" &&
          specialtyController.text.trim().isEmpty) {
        showMessage("أدخل التخصص", color: errorColor);
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
          email: widget.email,
          password: widget.password,
          age: widget.age,
          gender: widget.gender,
          relation: widget.relation,
          linkedPhone: linkPhoneController.text.trim(),
          doctorPhone: doctorPhoneController.text.trim(),
          inviteCode: "",
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

  Widget buildPageTitle(bool isDoctor) {
    return const Text(
      'إنشاء حساب جديد',
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

  Widget buildStepIndicator(bool isPatient) {
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
            child: Text(
              isPatient ? 'الخطوة 2 من 5' : 'الخطوة 2 من 4',
              style: const TextStyle(
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
          child: LinearProgressIndicator(
            value: isPatient ? 0.4 : 0.5,
            minHeight: 10,
            backgroundColor: const Color(0xFFE5E7EB),
            valueColor: const AlwaysStoppedAnimation<Color>(primaryColor),
          ),
        ),
      ],
    );
  }

  Widget buildInfoCard({required String text}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 20,
          fontFamily: 'Cairo',
          fontWeight: FontWeight.w700,
          color: textColor,
          height: 1.7,
        ),
      ),
    );
  }

  Widget buildWarningCard({required String text}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: warningColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: warningColor.withOpacity(0.18), width: 1.2),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: warningColor, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 17,
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w700,
                color: secondaryTextColor,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
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
    final bool isCaregiver = widget.role == "مرافق";
    final bool isDoctor = widget.role == "طبيب";

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

                buildPageTitle(isDoctor),

                const SizedBox(height: 20),

                buildStepIndicator(isPatient),

                const SizedBox(height: 24),

                buildInfoCard(
                  text: isPatient
                      ? 'أضف رقم هاتف المرافق، ويمكن إضافة رقم الطبيب اختيارياً لمتابعة التقارير والحالات الحرجة.'
                      : isCaregiver
                      ? 'أضف رقم هاتف المريض لبدء المتابعة واستقبال التنبيهات.'
                      : 'أدخل بيانات الطبيب ليتمكن المرضى من ربط حساباتهم معك ومشاركة التقارير الصحية.',
                ),

                const SizedBox(height: 24),

                if (!isDoctor) ...[
                  buildField(
                    controller: linkPhoneController,
                    hint: isPatient ? 'رقم هاتف المرافق' : 'رقم هاتف المريض',
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                  ),

                  const SizedBox(height: 18),

                  if (isPatient) ...[
                    buildField(
                      controller: doctorPhoneController,
                      hint: 'رقم هاتف الطبيب (اختياري)',
                      icon: Icons.medical_services,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 18),
                  ],
                ],

                if (isDoctor) ...[
                  SizedBox(
                    height: 62,
                    child: DropdownButtonFormField<String>(
                      initialValue: doctorSpecialty,
                      decoration: inputDecoration(
                        hint: 'تخصص الطبيب',
                        icon: Icons.medical_services,
                      ),
                      style: dropdownTextStyle,
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        color: primaryColor,
                        size: 30,
                      ),
                      dropdownColor: cardColor,
                      items: specialties
                          .map(
                            (s) => DropdownMenuItem(
                              value: s,
                              child: Text(s, style: dropdownTextStyle),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          doctorSpecialty = value;
                        });
                      },
                    ),
                  ),

                  const SizedBox(height: 18),

                  if (doctorSpecialty == "أخرى") ...[
                    buildField(
                      controller: specialtyController,
                      hint: 'اكتب التخصص',
                      icon: Icons.edit,
                    ),
                    const SizedBox(height: 18),
                  ],

                  buildField(
                    controller: workplaceController,
                    hint: 'مكان العمل / العيادة / المستشفى',
                    icon: Icons.local_hospital,
                  ),

                  const SizedBox(height: 18),

                  buildField(
                    controller: licenseNumberController,
                    hint: 'رقم مزاولة المهنة (اختياري)',
                    icon: Icons.badge,
                  ),
                ],

                const SizedBox(height: 30),

                buildWarningCard(
                  text: isPatient
                      ? 'سيتمكن المرافق من متابعة الحالة واستقبال تنبيهات SOS، والطبيب سيشاهد التقارير والحالات الحرجة فقط.'
                      : isCaregiver
                      ? 'سيصلك تنبيه عند احتياج المريض للمساعدة أو عند وجود حالة طارئة.'
                      : 'سيتم إنشاء حساب طبيب لاستخدامه في متابعة تقارير المرضى لاحقًا.',
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
