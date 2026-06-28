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

  static const Color primaryColor = Color(0xFF1F4168);
  static const Color backgroundColor = Color(0xFFF7F9FC);
  static const Color cardColor = Color(0xFFFFFFFF);

  // Darker text colors for better readability for elderly users
  static const Color textColor = Color(0xFF111827);
  static const Color secondaryTextColor = Color(0xFF374151);
  static const Color borderColor = Color(0xFFC9D6E2);

  static const Color warningColor = Color(0xFFED6C02);
  static const Color errorColor = Color(0xFFD32F2F);
  static const Color successColor = Color(0xFF2E7D32);

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

  Set<String> phoneSearchVariants(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final variants = <String>{};

    if (cleaned.isEmpty) return variants;

    variants.add(cleaned);

    final normalized = normalizePhoneNumber(cleaned);
    if (normalized != null) {
      variants.add(normalized);

      if (normalized.startsWith('970') || normalized.startsWith('972')) {
        variants.add('0${normalized.substring(3)}');
      }
    }

    if (cleaned.startsWith('970') && cleaned.length >= 12) {
      variants.add('0${cleaned.substring(3)}');
    }

    if (cleaned.startsWith('972') && cleaned.length >= 12) {
      variants.add('0${cleaned.substring(3)}');
    }

    if (cleaned.startsWith('0') && cleaned.length == 10) {
      variants.add('970${cleaned.substring(1)}');
      variants.add('972${cleaned.substring(1)}');
    }

    return variants.where((item) => item.trim().isNotEmpty).toSet();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>?> findUserByPhone(
    String phone,
  ) async {
    final variants = phoneSearchVariants(phone);

    for (final variant in variants) {
      final byPhone = await FirebaseFirestore.instance
          .collection('users')
          .where('phone', isEqualTo: variant)
          .limit(1)
          .get();

      if (byPhone.docs.isNotEmpty) {
        return byPhone.docs.first;
      }

      final byOriginalPhone = await FirebaseFirestore.instance
          .collection('users')
          .where('originalPhone', isEqualTo: variant)
          .limit(1)
          .get();

      if (byOriginalPhone.docs.isNotEmpty) {
        return byOriginalPhone.docs.first;
      }
    }

    return null;
  }

  Future<String?> getEmailForLogin(String phone) async {
    final userDoc = await findUserByPhone(phone);

    if (userDoc != null) {
      final data = userDoc.data() ?? {};
      final email = (data['email'] ?? '').toString().trim();

      if (email.isNotEmpty) {
        return email;
      }
    }

    final normalizedPhone = normalizePhoneNumber(phone);
    if (normalizedPhone == null) return null;

    return generateEmailFromPhone(normalizedPhone);
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
      final email = await getEmailForLogin(phone);

      if (email == null || email.isEmpty) {
        showMessage(
          'لم يتم العثور على بريد إلكتروني لهذا الرقم',
          color: errorColor,
        );
        return;
      }

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
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        showMessage(
          'لا يمكن البحث عن الحساب قبل تسجيل الدخول. راجعي Firestore Rules.',
          color: errorColor,
        );
      } else {
        showMessage('حدث خطأ في Firebase', color: errorColor);
      }
    } catch (_) {
      showMessage('حدث خطأ غير متوقع', color: errorColor);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> resetPasswordByPhone(String phone) async {
    if (isLoading) return;

    if (phone.trim().isEmpty) {
      showMessage('أدخلي رقم الهاتف أولاً', color: errorColor);
      return;
    }

    final normalizedPhone = normalizePhoneNumber(phone);

    if (normalizedPhone == null) {
      showMessage('رقم الهاتف غير صحيح', color: errorColor);
      return;
    }

    setState(() => isLoading = true);

    try {
      final userDoc = await findUserByPhone(phone);

      if (userDoc == null || !userDoc.exists) {
        showMessage('لا يوجد حساب بهذا الرقم', color: errorColor);
        return;
      }

      final data = userDoc.data() ?? {};
      final email = (data['email'] ?? '').toString().trim();

      if (email.isEmpty) {
        showMessage(
          'هذا الحساب لا يحتوي على بريد إلكتروني لإعادة كلمة المرور',
          color: errorColor,
        );
        return;
      }

      if (email.endsWith('@test.com')) {
        showMessage(
          'هذا الحساب مربوط بإيميل تجريبي. عدّلي الإيميل في Authentication و Firestore لإيميل حقيقي.',
          color: warningColor,
        );
        return;
      }

      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (!mounted) return;

      showMessage(
        'تم إرسال رابط إعادة تعيين كلمة المرور إلى البريد الإلكتروني',
        color: successColor,
      );
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          showMessage(
            'لا يوجد مستخدم بهذا البريد في Authentication',
            color: errorColor,
          );
          break;
        case 'invalid-email':
          showMessage('البريد الإلكتروني غير صحيح', color: errorColor);
          break;
        case 'network-request-failed':
          showMessage('تحققي من اتصال الإنترنت', color: errorColor);
          break;
        default:
          showMessage('تعذر إرسال رابط إعادة التعيين', color: errorColor);
      }
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        showMessage(
          'لا يمكن البحث عن الحساب. راجعي Firestore Rules.',
          color: errorColor,
        );
      } else {
        showMessage('حدث خطأ في Firebase', color: errorColor);
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
        fontSize: 19,
        fontFamily: 'Cairo',
        color: Color(0xFF6B7280),
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

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 36),

                  const Text(
                    'تسجيل الدخول',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 30,
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w800,
                      color: primaryColor,
                    ),
                  ),

                  const SizedBox(height: 22),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 22,
                    ),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: borderColor, width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Column(
                      children: [
                        Text(
                          'أهلًا بك في رعايتي',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontFamily: 'Cairo',
                            color: primaryColor,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'أدخل رقم الهاتف وكلمة المرور لتسجيل الدخول إلى حسابك.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 19,
                            fontFamily: 'Cairo',
                            color: textColor,
                            height: 1.6,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 26),

                  SizedBox(
                    height: 62,
                    child: TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      autofillHints: const [
                        AutofillHints.username,
                        AutofillHints.telephoneNumber,
                      ],
                      textInputAction: TextInputAction.next,
                      style: const TextStyle(
                        fontSize: 20,
                        fontFamily: 'Cairo',
                        color: textColor,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: inputDecoration(
                        hint: 'رقم الهاتف',
                        icon: Icons.phone,
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  SizedBox(
                    height: 62,
                    child: TextField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      autofillHints: const [AutofillHints.password],
                      textInputAction: TextInputAction.done,
                      style: const TextStyle(
                        fontSize: 20,
                        fontFamily: 'Cairo',
                        color: textColor,
                        fontWeight: FontWeight.w600,
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
                            size: 28,
                          ),
                          onPressed: () {
                            setState(() => obscurePassword = !obscurePassword);
                          },
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: isLoading
                          ? null
                          : () {
                              FocusScope.of(context).unfocus();
                              resetPasswordByPhone(phoneController.text.trim());
                            },
                      child: const Text(
                        'نسيت كلمة المرور؟',
                        style: TextStyle(
                          fontSize: 18,
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w800,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    height: 62,
                    child: ElevatedButton.icon(
                      onPressed: isLoading ? null : login,
                      icon: isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.7,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.login,
                              color: Colors.white,
                              size: 28,
                            ),
                      label: Text(
                        isLoading ? 'جاري تسجيل الدخول' : 'تسجيل الدخول',
                        style: const TextStyle(
                          fontSize: 21,
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

                  const SizedBox(height: 16),

                  SizedBox(
                    height: 62,
                    child: OutlinedButton.icon(
                      onPressed: isLoading
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SignUpStep1(),
                                ),
                              );
                            },
                      icon: const Icon(
                        Icons.person_add,
                        color: primaryColor,
                        size: 28,
                      ),
                      label: const Text(
                        'إنشاء حساب جديد',
                        style: TextStyle(
                          fontSize: 21,
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w800,
                          color: primaryColor,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: primaryColor, width: 1.8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
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
      ),
    );
  }
}
