import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:mycare/screens/signup/signup_step1.dart';
import 'package:mycare/screens/home_screen.dart';
import 'package:mycare/screens/caregiver_dashboard_screen.dart';
import 'package:mycare/screens/doctor_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;
  bool obscurePassword = true;

  static const Color primaryColor = Color(0xFF1E3A5F);
  static const Color backgroundColor = Color(0xFFF7F8FA);
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color textColor = Color(0xFF1F2937);
  static const Color secondaryTextColor = Color(0xFF4B5563);
  static const Color warningColor = Color(0xFFED6C02);
  static const Color errorColor = Color(0xFFD32F2F);

  @override
  void dispose() {
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  String? normalizePhoneNumber(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');

    if (cleaned.startsWith('970')) {
      cleaned = '0${cleaned.substring(3)}';
    } else if (cleaned.startsWith('972')) {
      cleaned = '0${cleaned.substring(3)}';
    }

    if (cleaned.length != 10) return null;

    if (cleaned.startsWith('059') || cleaned.startsWith('056')) {
      return '970${cleaned.substring(1)}';
    }

    if (cleaned.startsWith('050') ||
        cleaned.startsWith('052') ||
        cleaned.startsWith('053') ||
        cleaned.startsWith('054') ||
        cleaned.startsWith('055') ||
        cleaned.startsWith('058')) {
      return '972${cleaned.substring(1)}';
    }

    return null;
  }

  String generateEmailFromPhone(String normalizedPhone) {
    return '$normalizedPhone@test.com';
  }

  Future<void> showMessage(String message, {Color color = primaryColor}) async {
    if (!mounted) return;

    await SystemSound.play(SystemSoundType.alert);
    HapticFeedback.mediumImpact();

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
            fontWeight: FontWeight.w600,
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

  Widget getHomeScreenByRole(String role) {
    if (role == 'مريض') {
      return const HomeScreen();
    }

    if (role == 'مرافق') {
      return const CaregiverDashboardScreen();
    }

    if (role == 'طبيب') {
      return const DoctorDashboardScreen();
    }

    return const HomeScreen();
  }

  Future<void> login() async {
    if (isLoading) return;

    final phone = phoneController.text.trim();
    final password = passwordController.text.trim();

    if (phone.isEmpty) {
      showMessage('رقم الهاتف مطلوب', color: errorColor);
      return;
    }

    final normalizedPhone = normalizePhoneNumber(phone);

    if (normalizedPhone == null) {
      showMessage('رقم الهاتف غير صحيح', color: errorColor);
      return;
    }

    if (password.isEmpty) {
      showMessage('كلمة المرور مطلوبة', color: errorColor);
      return;
    }

    setState(() => isLoading = true);

    try {
      final email = generateEmailFromPhone(normalizedPhone);

      final user = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.user!.uid)
          .get();

      if (!userDoc.exists) {
        showMessage(
          'تم تسجيل الدخول لكن بيانات المستخدم غير موجودة',
          color: warningColor,
        );
        return;
      }

      final data = userDoc.data();
      final String role = (data?['role'] ?? '').toString().trim();

      if (role.isEmpty) {
        showMessage('نوع الحساب غير موجود في Firebase', color: errorColor);
        return;
      }

      TextInput.finishAutofillContext(shouldSave: true);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => getHomeScreenByRole(role)),
      );
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-credential':
          showMessage('رقم الهاتف أو كلمة المرور غير صحيحة', color: errorColor);
          break;
        case 'user-not-found':
          showMessage('هذا الحساب غير موجود', color: errorColor);
          break;
        case 'wrong-password':
          showMessage('كلمة المرور خاطئة', color: errorColor);
          break;
        case 'network-request-failed':
          showMessage('تحققي من اتصال الإنترنت', color: errorColor);
          break;
        default:
          showMessage('فشل تسجيل الدخول', color: errorColor);
      }
    } catch (_) {
      showMessage('حدث خطأ غير متوقع', color: errorColor);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

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
      prefixIcon: Icon(icon, color: primaryColor),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: cardColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  const Text(
                    'تسجيل الدخول',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w700,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'أدخل رقم الهاتف وكلمة المرور للوصول إلى حسابك.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontFamily: 'Cairo',
                        color: secondaryTextColor,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 56,
                    child: TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      autofillHints: const [
                        AutofillHints.username,
                        AutofillHints.telephoneNumber,
                      ],
                      textInputAction: TextInputAction.next,
                      style: const TextStyle(
                        fontSize: 18,
                        fontFamily: 'Cairo',
                        color: textColor,
                      ),
                      decoration: inputDecoration(
                        hint: 'رقم الهاتف',
                        icon: Icons.phone,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 56,
                    child: TextField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      autofillHints: const [AutofillHints.password],
                      textInputAction: TextInputAction.done,
                      style: const TextStyle(
                        fontSize: 18,
                        fontFamily: 'Cairo',
                        color: textColor,
                      ),
                      decoration: inputDecoration(
                        hint: 'كلمة المرور',
                        icon: Icons.lock,
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: secondaryTextColor,
                          ),
                          onPressed: () {
                            setState(() => obscurePassword = !obscurePassword);
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: isLoading ? null : login,
                      icon: isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.login, color: Colors.white),
                      label: Text(
                        isLoading ? 'جاري تسجيل الدخول' : 'تسجيل الدخول',
                        style: const TextStyle(
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
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SignUpStep1(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.person_add, color: primaryColor),
                      label: const Text(
                        'إنشاء حساب جديد',
                        style: TextStyle(
                          fontSize: 18,
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: primaryColor, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
