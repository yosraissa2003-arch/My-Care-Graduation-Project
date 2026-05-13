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

  static const Color primaryColor = Color(0xFF1E3A5F);
  static const Color backgroundColor = Color(0xFFF7F8FA);
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color textColor = Color(0xFF1F2937);
  static const Color secondaryTextColor = Color(0xFF4B5563);
  static const Color warningColor = Color(0xFFED6C02);
  static const Color successColor = Color(0xFF2E7D32);
  static const Color errorColor = Color(0xFFD32F2F);

  // ================= CONTROLLERS =================

  final TextEditingController fullNameController =
      TextEditingController();

  final TextEditingController phoneController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  final TextEditingController confirmPasswordController =
      TextEditingController();

  final TextEditingController ageController =
      TextEditingController();

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
    "ممرض",
    "طبيب",
    "فرد عائلة",
  ];

  // ================= DISPOSE =================

  @override
  void dispose() {
    fullNameController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    ageController.dispose();
    super.dispose();
  }

  // ================= VALIDATION =================

  void goNext() {
    if (role == null) {
      showMessage(
        "اختاري نوع الحساب",
        color: warningColor,
      );
      return;
    }

    if (fullNameController.text.trim().isEmpty) {
      showMessage(
        "الاسم الكامل مطلوب",
        color: errorColor,
      );
      return;
    }

    if (phoneController.text.trim().isEmpty) {
      showMessage(
        "رقم الهاتف مطلوب",
        color: errorColor,
      );
      return;
    }

    if (passwordController.text.trim().isEmpty) {
      showMessage(
        "كلمة المرور مطلوبة",
        color: errorColor,
      );
      return;
    }

    if (passwordController.text.trim().length < 6) {
      showMessage(
        "كلمة المرور يجب أن تكون 6 أحرف على الأقل",
        color: errorColor,
      );
      return;
    }

    if (passwordController.text !=
        confirmPasswordController.text) {
      showMessage(
        "كلمتا المرور غير متطابقتين",
        color: errorColor,
      );
      return;
    }

    // ================= PATIENT =================

    if (role == "مريض") {
      if (ageController.text.trim().isEmpty) {
        showMessage(
          "العمر مطلوب",
          color: errorColor,
        );
        return;
      }

      if (gender == null) {
        showMessage(
          "اختاري الجنس",
          color: errorColor,
        );
        return;
      }
    }

    // ================= CAREGIVER =================

    if (role == "مرافق") {
      if (relation == null) {
        showMessage(
          "اختاري صلة القرابة",
          color: errorColor,
        );
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
          password: passwordController.text.trim(),

          age: role == "مريض"
              ? ageController.text.trim()
              : "",

          gender: role == "مريض"
              ? gender ?? ""
              : "",

          relation: role == "مرافق"
              ? relation ?? ""
              : "",
        ),
      ),
    );
  }

  // ================= MESSAGE =================

  void showMessage(
    String message, {
    Color color = primaryColor,
  }) async {
    await SystemSound.play(SystemSoundType.alert);
    HapticFeedback.mediumImpact();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
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

  // ================= INPUT =================

  InputDecoration inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        fontSize: 18,
        fontFamily: 'Cairo',
        color: secondaryTextColor,
      ),
      prefixIcon: Icon(
        icon,
        color: primaryColor,
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: cardColor,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
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
      height: 56,
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        style: const TextStyle(
          fontSize: 18,
          fontFamily: 'Cairo',
          color: textColor,
        ),
        decoration: inputDecoration(
          hint: hint,
          icon: icon,
          suffixIcon: suffixIcon,
        ),
      ),
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
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),

                // ================= LOGO =================

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
                  'إنشاء حساب جديد',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w700,
                    color: primaryColor,
                  ),
                ),

                const SizedBox(height: 4),

                const Text(
                  'الخطوة 1 من 5',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Cairo',
                    color: secondaryTextColor,
                  ),
                ),

                const SizedBox(height: 24),

                // ================= PROGRESS =================

                LinearProgressIndicator(
                  value: 0.2,
                  minHeight: 8,
                  borderRadius:
                      BorderRadius.circular(20),
                  backgroundColor:
                      Colors.grey.shade300,
                  color: primaryColor,
                ),

                const SizedBox(height: 24),

                // ================= ROLE =================

                const Text(
                  'نوع الحساب',
                  style: TextStyle(
                    fontSize: 20,
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),

                const SizedBox(height: 16),

                GestureDetector(
                  onTap: () {
                    setState(() {
                      role = "مريض";
                    });
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius:
                          BorderRadius.circular(20),
                      border: Border.all(
                        color: role == "مريض"
                            ? primaryColor
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.elderly,
                          color: primaryColor,
                          size: 32,
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Text(
                            'مريض / مستخدم كبير سن',
                            style: TextStyle(
                              fontSize: 18,
                              fontFamily: 'Cairo',
                              fontWeight:
                                  FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ),
                        if (role == "مريض")
                          const Icon(
                            Icons.check_circle,
                            color: successColor,
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                GestureDetector(
                  onTap: () {
                    setState(() {
                      role = "مرافق";
                    });
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius:
                          BorderRadius.circular(20),
                      border: Border.all(
                        color: role == "مرافق"
                            ? primaryColor
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.health_and_safety,
                          color: primaryColor,
                          size: 32,
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Text(
                            'معتني / فرد عائلة',
                            style: TextStyle(
                              fontSize: 18,
                              fontFamily: 'Cairo',
                              fontWeight:
                                  FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ),
                        if (role == "مرافق")
                          const Icon(
                            Icons.check_circle,
                            color: successColor,
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ================= BASIC INFO =================

                buildField(
                  controller: fullNameController,
                  hint: 'الاسم الكامل',
                  icon: Icons.person,
                ),

                const SizedBox(height: 16),

                buildField(
                  controller: phoneController,
                  hint: 'رقم الهاتف',
                  icon: Icons.phone,
                  keyboardType:
                      TextInputType.phone,
                ),

                const SizedBox(height: 16),

                buildField(
                  controller: passwordController,
                  hint: 'كلمة المرور',
                  icon: Icons.lock,
                  isPassword: !showPassword,
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        showPassword =
                            !showPassword;
                      });
                    },
                    icon: Icon(
                      showPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: secondaryTextColor,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                buildField(
                  controller:
                      confirmPasswordController,
                  hint: 'تأكيد كلمة المرور',
                  icon: Icons.lock_outline,
                  isPassword:
                      !showConfirmPassword,
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        showConfirmPassword =
                            !showConfirmPassword;
                      });
                    },
                    icon: Icon(
                      showConfirmPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: secondaryTextColor,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ================= PATIENT FIELDS =================

                if (role == "مريض") ...[
                  buildField(
                    controller: ageController,
                    hint: 'العمر',
                    icon: Icons.cake,
                    keyboardType:
                        TextInputType.number,
                  ),

                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    initialValue: gender,
                    decoration:
                        inputDecoration(
                      hint: 'الجنس',
                      icon: Icons.person_2,
                    ),
                    style: const TextStyle(
                      fontSize: 18,
                      fontFamily: 'Cairo',
                      color: textColor,
                    ),
                    items: ['ذكر', 'أنثى']
                        .map(
                          (g) =>
                              DropdownMenuItem(
                            value: g,
                            child: Text(g),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        gender = value;
                      });
                    },
                  ),
                ],

                // ================= CAREGIVER FIELDS =================

                if (role == "مرافق") ...[
                  DropdownButtonFormField<String>(
                    initialValue: relation,
                    decoration:
                        inputDecoration(
                      hint: 'صلة القرابة',
                      icon: Icons.family_restroom,
                    ),
                    style: const TextStyle(
                      fontSize: 18,
                      fontFamily: 'Cairo',
                      color: textColor,
                    ),
                    items: relations
                        .map(
                          (r) =>
                              DropdownMenuItem(
                            value: r,
                            child: Text(r),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        relation = value;
                      });
                    },
                  ),
                ],

                const SizedBox(height: 32),

                // ================= NEXT BUTTON =================

                SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: goNext,
                    icon: const Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'التالي',
                      style: TextStyle(
                        fontSize: 18,
                        fontFamily: 'Cairo',
                        fontWeight:
                            FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          primaryColor,
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                                16),
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