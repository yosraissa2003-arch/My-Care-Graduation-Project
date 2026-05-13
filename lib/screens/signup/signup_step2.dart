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

  final TextEditingController linkPhoneController =
      TextEditingController();

  final TextEditingController inviteCodeController =
      TextEditingController();

  // ================= DISPOSE =================

  @override
  void dispose() {
    linkPhoneController.dispose();
    inviteCodeController.dispose();
    super.dispose();
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

  // ================= NEXT =================

  void goNext() {
    if (linkPhoneController.text.trim().isEmpty &&
        inviteCodeController.text.trim().isEmpty) {
      showMessage(
        "أدخلي رقم الهاتف أو كود الدعوة",
        color: warningColor,
      );
      return;
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

          linkedPhone:
              linkPhoneController.text.trim(),

          inviteCode:
              inviteCodeController.text.trim(),
        ),
      ),
    );
  }

  // ================= INPUT STYLE =================

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
      prefixIcon: Icon(
        icon,
        color: primaryColor,
      ),
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
    TextInputType keyboardType =
        TextInputType.text,
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
        decoration: inputDecoration(
          hint: hint,
          icon: icon,
        ),
      ),
    );
  }

  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    final bool isPatient =
        widget.role == "مريض";

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

                // ================= TITLE =================

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
                  'ربط الحسابات',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  isPatient
                      ? 'الخطوة 2 من 5'
                      : 'الخطوة 2 من 4',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'Cairo',
                    color: secondaryTextColor,
                  ),
                ),

                const SizedBox(height: 24),

                // ================= PROGRESS =================

                LinearProgressIndicator(
                  value: isPatient ? 0.4 : 0.5,
                  minHeight: 8,
                  borderRadius:
                      BorderRadius.circular(20),
                  backgroundColor:
                      Colors.grey.shade300,
                  color: primaryColor,
                ),

                const SizedBox(height: 32),

                // ================= DESCRIPTION CARD =================

                Container(
                  padding:
                      const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius:
                        BorderRadius.circular(
                            20),
                  ),
                  child: Text(
                    isPatient
                        ? 'أضيفي رقم هاتف المعتني أو كود الدعوة للربط مع شخص يتابع حالتك الصحية.'
                        : 'أضيفي رقم هاتف المريض أو كود الدعوة لبدء المتابعة واستقبال التنبيهات.',
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

                // ================= PHONE =================

                buildField(
                  controller:
                      linkPhoneController,
                  hint: isPatient
                      ? 'رقم هاتف المعتني'
                      : 'رقم هاتف المريض',
                  icon: Icons.phone,
                  keyboardType:
                      TextInputType.phone,
                ),

                const SizedBox(height: 16),

                // ================= INVITE CODE =================

                buildField(
                  controller:
                      inviteCodeController,
                  hint: 'كود الدعوة (اختياري)',
                  icon: Icons.qr_code,
                ),

                const SizedBox(height: 32),

                // ================= INFO =================

                Container(
                  padding:
                      const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.orange
                        .withOpacity(0.08),
                    borderRadius:
                        BorderRadius.circular(
                            20),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: warningColor,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isPatient
                              ? 'سيتمكن المعتني من متابعة حالتك الصحية واستقبال تنبيهات SOS.'
                              : 'سيصلك تنبيه عند احتياج المريض للمساعدة أو عند وجود حالة طارئة.',
                          style:
                              const TextStyle(
                            fontSize: 16,
                            fontFamily:
                                'Cairo',
                            color:
                                secondaryTextColor,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // ================= NEXT BUTTON =================

                SizedBox(
                  height: 56,
                  child:
                      ElevatedButton.icon(
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
                    style:
                        ElevatedButton.styleFrom(
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