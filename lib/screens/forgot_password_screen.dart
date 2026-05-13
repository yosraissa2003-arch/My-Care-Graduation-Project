import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  static const Color primaryColor = Color(0xFF1E3A5F);
  static const Color backgroundColor = Color(0xFFF7F8FA);
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color textColor = Color(0xFF1F2937);
  static const Color secondaryTextColor = Color(0xFF4B5563);
  static const Color errorColor = Color(0xFFD32F2F);
  static const Color successColor = Color(0xFF2E7D32);

  final phoneController = TextEditingController();
  final codeController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  bool isLoading = false;
  bool codeSent = false;
  bool showPassword = false;
  bool showConfirmPassword = false;

  String? verificationId;

  @override
  void dispose() {
    phoneController.dispose();
    codeController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  String? normalizePhoneNumber(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');

    if (cleaned.startsWith('970')) {
      cleaned = '0${cleaned.substring(3)}';
    } else if (cleaned.startsWith('972')) {
      cleaned = '0${cleaned.substring(3)}';
    }

    if (cleaned.length != 10) {
      return null;
    }

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

  String firebaseSmsPhone(String normalizedPhone) {
    return '+$normalizedPhone';
  }

  String generateEmailFromPhone(String normalizedPhone) {
    return "$normalizedPhone@test.com";
  }

  Future<void> showMessage(String message, {Color color = primaryColor}) async {
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

  Future<String?> findUidByPhone(String normalizedPhone) async {
    final result = await FirebaseFirestore.instance
        .collection('users')
        .where('phone', isEqualTo: normalizedPhone)
        .limit(1)
        .get();

    if (result.docs.isEmpty) return null;

    return result.docs.first.id;
  }

  Future<void> sendSmsCode() async {
    if (isLoading) return;

    final inputPhone = phoneController.text.trim();

    if (inputPhone.isEmpty) {
      showMessage('أدخلي رقم الهاتف', color: errorColor);
      return;
    }

    final normalizedPhone = normalizePhoneNumber(inputPhone);

    if (normalizedPhone == null) {
      showMessage(
        'رقم الهاتف غير صحيح. يجب أن يبدأ بـ 059 أو 056 أو 050 أو 052 أو 053 أو 054 أو 055 أو 058',
        color: errorColor,
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final uid = await findUidByPhone(normalizedPhone);

      if (uid == null) {
        showMessage('هذا الرقم غير مسجل', color: errorColor);
        setState(() => isLoading = false);
        return;
      }

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: firebaseSmsPhone(normalizedPhone),
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {},
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('SMS Verification Failed: ${e.code}');
          if (mounted) {
            setState(() => isLoading = false);
          }
          showMessage('فشل إرسال رمز التحقق', color: errorColor);
        },
        codeSent: (String id, int? resendToken) {
          setState(() {
            verificationId = id;
            codeSent = true;
            isLoading = false;
          });

          showMessage('تم إرسال رمز التحقق عبر SMS', color: successColor);
        },
        codeAutoRetrievalTimeout: (String id) {
          verificationId = id;
        },
      );
    } catch (e) {
      debugPrint('Send SMS Error: $e');
      if (mounted) {
        setState(() => isLoading = false);
      }
      showMessage('حدث خطأ أثناء إرسال الرمز', color: errorColor);
    }
  }

  Future<void> resetPasswordWithSms() async {
    if (isLoading) return;

    final inputPhone = phoneController.text.trim();
    final normalizedPhone = normalizePhoneNumber(inputPhone);

    final code = codeController.text.trim();
    final newPassword = passwordController.text.trim();
    final confirmPassword = confirmController.text.trim();

    if (normalizedPhone == null) {
      showMessage(
        'رقم الهاتف غير صحيح. يجب أن يبدأ بـ 059 أو 056 أو 050 أو 052 أو 053 أو 054 أو 055 أو 058',
        color: errorColor,
      );
      return;
    }

    if (verificationId == null) {
      showMessage('أرسلي رمز التحقق أولًا', color: errorColor);
      return;
    }

    if (code.isEmpty) {
      showMessage('أدخلي رمز التحقق', color: errorColor);
      return;
    }

    if (newPassword.length < 6) {
      showMessage('كلمة المرور يجب أن تكون 6 أحرف على الأقل', color: errorColor);
      return;
    }

    if (newPassword != confirmPassword) {
      showMessage('كلمتا المرور غير متطابقتين', color: errorColor);
      return;
    }

    setState(() => isLoading = true);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId!,
        smsCode: code,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        showMessage('فشل التحقق من المستخدم', color: errorColor);
        setState(() => isLoading = false);
        return;
      }

      await user.updatePassword(newPassword);

      final uid = await findUidByPhone(normalizedPhone);

      if (uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'passwordUpdatedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await FirebaseAuth.instance.signOut();

      showMessage('تم تغيير كلمة المرور بنجاح', color: successColor);

      if (!mounted) return;
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      debugPrint('Reset Password Error: ${e.code}');
      showMessage('رمز التحقق غير صحيح أو انتهت صلاحيته', color: errorColor);
    } catch (e) {
      debugPrint('Reset Password General Error: $e');
      showMessage('حدث خطأ أثناء تغيير كلمة المرور', color: errorColor);
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return SizedBox(
      height: 56,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
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

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          title: const Text(
            'إعادة تعيين كلمة المرور',
            style: TextStyle(
              fontSize: 20,
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.lock_reset,
                      size: 72,
                      color: primaryColor,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'استعادة الحساب',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'أدخلي رقم الهاتف المسجل، ثم أدخلي رمز SMS وكلمة المرور الجديدة.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontFamily: 'Cairo',
                        color: secondaryTextColor,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              field(
                controller: phoneController,
                hint: 'رقم الهاتف مثل 059 أو 050',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              if (codeSent) ...[
                field(
                  controller: codeController,
                  hint: 'رمز التحقق SMS',
                  icon: Icons.sms,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                field(
                  controller: passwordController,
                  hint: 'كلمة المرور الجديدة',
                  icon: Icons.lock,
                  obscureText: !showPassword,
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() => showPassword = !showPassword);
                    },
                    icon: Icon(
                      showPassword ? Icons.visibility : Icons.visibility_off,
                      color: secondaryTextColor,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                field(
                  controller: confirmController,
                  hint: 'تأكيد كلمة المرور',
                  icon: Icons.lock_outline,
                  obscureText: !showConfirmPassword,
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() => showConfirmPassword = !showConfirmPassword);
                    },
                    icon: Icon(
                      showConfirmPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: secondaryTextColor,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: isLoading
                      ? null
                      : codeSent
                          ? resetPasswordWithSms
                          : sendSmsCode,
                  icon: isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          codeSent ? Icons.check_circle : Icons.sms,
                          color: Colors.white,
                        ),
                  label: Text(
                    isLoading
                        ? 'جاري المعالجة'
                        : codeSent
                            ? 'تغيير كلمة المرور'
                            : 'إرسال رمز SMS',
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
              if (codeSent)
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: isLoading ? null : sendSmsCode,
                    icon: const Icon(Icons.refresh, color: primaryColor),
                    label: const Text(
                      'إعادة إرسال الرمز',
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
    );
  }
}