import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'signup_step2.dart';

class SignUpStep1 extends StatefulWidget {
  const SignUpStep1({super.key});

  @override
  State<SignUpStep1> createState() => _SignUpStep1State();
}

class _SignUpStep1State extends State<SignUpStep1> {
  // ================= COLORS =================

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
  static const Color errorColor = Color(0xFFD32F2F);

  // ================= CONTROLLERS =================

  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController ageController = TextEditingController();

  // ================= VARIABLES =================

  bool showPassword = false;
  bool showConfirmPassword = false;

  String? role;
  String? gender;
  String? relation;

  // ================= LISTS =================

  final List<String> relations = [
    "ابن",
    "ابنة",
    "زوج",
    "زوجة",
    "أخ",
    "أخت",
    "حفيد",
    "ممرض",
    "فرد عائلة",
    "أخرى",
  ];

  // ================= DISPOSE =================

  @override
  void dispose() {
    fullNameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    ageController.dispose();
    super.dispose();
  }

  // ================= VALIDATION =================

  void goNext() {
    if (role == null) {
      showMessage("اختاري نوع الحساب", color: warningColor);
      return;
    }

    if (fullNameController.text.trim().isEmpty) {
      showMessage("الاسم الكامل مطلوب", color: errorColor);
      return;
    }

    if (phoneController.text.trim().isEmpty) {
      showMessage("رقم الهاتف مطلوب", color: errorColor);
      return;
    }

    final email = emailController.text.trim().toLowerCase();
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    if (email.isEmpty) {
      showMessage("البريد الإلكتروني مطلوب", color: errorColor);
      return;
    }

    if (!emailRegex.hasMatch(email)) {
      showMessage("البريد الإلكتروني غير صحيح", color: errorColor);
      return;
    }

    if (passwordController.text.trim().isEmpty) {
      showMessage("كلمة المرور مطلوبة", color: errorColor);
      return;
    }

    if (passwordController.text.trim().length < 6) {
      showMessage(
        "كلمة المرور يجب أن تكون 6 أحرف على الأقل",
        color: errorColor,
      );
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      showMessage("كلمتا المرور غير متطابقتين", color: errorColor);
      return;
    }

    // ================= PATIENT =================

    if (role == "مريض") {
      if (ageController.text.trim().isEmpty) {
        showMessage("العمر مطلوب", color: errorColor);
        return;
      }

      if (gender == null) {
        showMessage("اختاري الجنس", color: errorColor);
        return;
      }
    }

    // ================= CAREGIVER =================

    if (role == "مرافق") {
      if (relation == null) {
        showMessage("اختاري صلة القرابة", color: errorColor);
        return;
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SignUpStep2(
          role: role!,
          fullName: fullNameController.text.trim(),
          phone: phoneController.text.trim(),
          email: emailController.text.trim().toLowerCase(),
          password: passwordController.text.trim(),
          age: role == "مريض" ? ageController.text.trim() : "",
          gender: role == "مريض" ? gender ?? "" : "",
          relation: role == "مرافق" ? relation ?? "" : "",
        ),
      ),
    );
  }

  // ================= MESSAGE =================

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

  // ================= INPUT DECORATION =================

  InputDecoration inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
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
      suffixIcon: suffixIcon,
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

  // ================= FIELD =================

  Widget buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
  }) {
    return SizedBox(
      height: 62,
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        textInputAction: TextInputAction.next,
        style: const TextStyle(
          fontSize: 20,
          fontFamily: 'Cairo',
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
        decoration: inputDecoration(
          hint: hint,
          icon: icon,
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }

  // ================= PAGE TITLE =================

  Widget buildPageTitle() {
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

  // ================= STEP INDICATOR =================

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
              'الخطوة 1 من 5',
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
            value: 0.20,
            minHeight: 10,
            backgroundColor: Color(0xFFE5E7EB),
            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
          ),
        ),
      ],
    );
  }

  // ================= ROLE CARD =================

  Widget buildRoleCard({
    required String value,
    required String title,
    required IconData icon,
  }) {
    final bool isSelected = role == value;

    return InkWell(
      onTap: () {
        setState(() {
          role = value;
        });
      },
      borderRadius: BorderRadius.circular(22),
      child: Container(
        height: 88,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected ? selectedCardColor : cardColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected ? primaryColor : borderColor,
            width: isSelected ? 2 : 1.2,
          ),
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
              child: Text(
                title,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 21,
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w700,
                  color: textColor,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? successColor : borderColor,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }

  // ================= DROPDOWN STYLE =================

  TextStyle get dropdownTextStyle {
    return const TextStyle(
      fontSize: 20,
      fontFamily: 'Cairo',
      color: textColor,
      fontWeight: FontWeight.w600,
    );
  }

  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {
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

                // ================= PAGE TITLE FIRST =================
                buildPageTitle(),

                const SizedBox(height: 20),

                // ================= STEP =================
                buildStepIndicator(),

                const SizedBox(height: 20),

                const Text(
                  'يرجى اختيار نوع الحساب وإدخال البيانات الأساسية',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 19,
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w600,
                    color: secondaryTextColor,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 28),

                // ================= ROLE =================
                const Text(
                  'نوع الحساب',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 24,
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),

                const SizedBox(height: 16),

                buildRoleCard(
                  value: "مريض",
                  title: 'مريض / مستخدم كبير سن',
                  icon: Icons.elderly,
                ),

                const SizedBox(height: 16),

                buildRoleCard(
                  value: "مرافق",
                  title: 'مرافق / فرد عائلة',
                  icon: Icons.volunteer_activism,
                ),

                const SizedBox(height: 16),

                buildRoleCard(value: "طبيب", title: 'طبيب', icon: Icons.badge),

                const SizedBox(height: 28),

                // ================= BASIC INFO =================
                const Text(
                  'البيانات الأساسية',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 24,
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),

                const SizedBox(height: 16),

                buildField(
                  controller: fullNameController,
                  hint: 'الاسم الكامل',
                  icon: Icons.person,
                ),

                const SizedBox(height: 18),

                buildField(
                  controller: phoneController,
                  hint: 'رقم الهاتف',
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                ),

                const SizedBox(height: 18),

                buildField(
                  controller: emailController,
                  hint: 'البريد الإلكتروني الحقيقي',
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                ),

                const SizedBox(height: 18),

                buildField(
                  controller: passwordController,
                  hint: 'كلمة المرور',
                  icon: Icons.lock,
                  isPassword: !showPassword,
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        showPassword = !showPassword;
                      });
                    },
                    icon: Icon(
                      showPassword ? Icons.visibility : Icons.visibility_off,
                      color: hintColor,
                      size: 28,
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                buildField(
                  controller: confirmPasswordController,
                  hint: 'تأكيد كلمة المرور',
                  icon: Icons.lock_outline,
                  isPassword: !showConfirmPassword,
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        showConfirmPassword = !showConfirmPassword;
                      });
                    },
                    icon: Icon(
                      showConfirmPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: hintColor,
                      size: 28,
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // ================= PATIENT FIELDS =================
                if (role == "مريض") ...[
                  buildField(
                    controller: ageController,
                    hint: 'العمر',
                    icon: Icons.calendar_month,
                    keyboardType: TextInputType.number,
                  ),

                  const SizedBox(height: 18),

                  SizedBox(
                    height: 62,
                    child: DropdownButtonFormField<String>(
                      initialValue: gender,
                      decoration: inputDecoration(
                        hint: 'الجنس',
                        icon: Icons.person_2,
                      ),
                      style: dropdownTextStyle,
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        color: primaryColor,
                        size: 30,
                      ),
                      dropdownColor: cardColor,
                      items: ['ذكر', 'أنثى']
                          .map(
                            (g) => DropdownMenuItem(
                              value: g,
                              child: Text(g, style: dropdownTextStyle),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          gender = value;
                        });
                      },
                    ),
                  ),

                  const SizedBox(height: 18),
                ],

                // ================= CAREGIVER FIELDS =================
                if (role == "مرافق") ...[
                  SizedBox(
                    height: 62,
                    child: DropdownButtonFormField<String>(
                      initialValue: relation,
                      decoration: inputDecoration(
                        hint: 'صلة القرابة',
                        icon: Icons.family_restroom,
                      ),
                      style: dropdownTextStyle,
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        color: primaryColor,
                        size: 30,
                      ),
                      dropdownColor: cardColor,
                      items: relations
                          .map(
                            (r) => DropdownMenuItem(
                              value: r,
                              child: Text(r, style: dropdownTextStyle),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          relation = value;
                        });
                      },
                    ),
                  ),

                  const SizedBox(height: 18),
                ],

                const SizedBox(height: 18),

                // ================= NEXT BUTTON =================
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
