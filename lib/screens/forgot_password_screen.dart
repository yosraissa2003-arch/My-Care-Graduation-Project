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
  static const Color warningColor = Color(0xFFED6C02);

  final phoneController = TextEditingController();

  bool isLoading = false;

  @override
  void dispose() {
    phoneController.dispose();
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

  String _digitsOnly(String value) {
    return value.replaceAll(RegExp(r'[^0-9]'), '');
  }

  Set<String> _phoneVariants(String inputPhone, String normalizedPhone) {
    final variants = <String>{};
    final inputDigits = _digitsOnly(inputPhone);

    if (normalizedPhone.isNotEmpty) variants.add(normalizedPhone);
    if (inputDigits.isNotEmpty) variants.add(inputDigits);

    if (normalizedPhone.startsWith('970') && normalizedPhone.length >= 12) {
      variants.add('0${normalizedPhone.substring(3)}');
    }

    if (normalizedPhone.startsWith('972') && normalizedPhone.length >= 12) {
      variants.add('0${normalizedPhone.substring(3)}');
    }

    if (inputDigits.startsWith('0') && inputDigits.length == 10) {
      variants.add('970${inputDigits.substring(1)}');
      variants.add('972${inputDigits.substring(1)}');
    }

    return variants.where((item) => item.trim().isNotEmpty).toSet();
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

  Future<Map<String, dynamic>?> findUserDataByPhone({
    required String inputPhone,
    required String normalizedPhone,
  }) async {
    final variants = _phoneVariants(inputPhone, normalizedPhone);

    for (final phone in variants) {
      final byPhone = await FirebaseFirestore.instance
          .collection('users')
          .where('phone', isEqualTo: phone)
          .limit(5)
          .get();

      if (byPhone.docs.isNotEmpty) {
        final docsWithRealEmail = byPhone.docs.where((doc) {
          final email = (doc.data()['email'] ?? '').toString().trim();
          return email.isNotEmpty && !email.endsWith('@test.com');
        }).toList();

        final selectedDoc = docsWithRealEmail.isNotEmpty
            ? docsWithRealEmail.first
            : byPhone.docs.first;

        return {'uid': selectedDoc.id, ...selectedDoc.data()};
      }

      final byOriginalPhone = await FirebaseFirestore.instance
          .collection('users')
          .where('originalPhone', isEqualTo: phone)
          .limit(5)
          .get();

      if (byOriginalPhone.docs.isNotEmpty) {
        final docsWithRealEmail = byOriginalPhone.docs.where((doc) {
          final email = (doc.data()['email'] ?? '').toString().trim();
          return email.isNotEmpty && !email.endsWith('@test.com');
        }).toList();

        final selectedDoc = docsWithRealEmail.isNotEmpty
            ? docsWithRealEmail.first
            : byOriginalPhone.docs.first;

        return {'uid': selectedDoc.id, ...selectedDoc.data()};
      }
    }

    return null;
  }

  Future<void> sendPasswordResetLink() async {
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
      final userData = await findUserDataByPhone(
        inputPhone: inputPhone,
        normalizedPhone: normalizedPhone,
      );

      if (userData == null) {
        showMessage('هذا الرقم غير مسجل', color: errorColor);
        return;
      }

      final email = (userData['email'] ?? '').toString().trim().toLowerCase();

      if (email.isEmpty) {
        showMessage(
          'هذا الحساب لا يحتوي على بريد إلكتروني لإعادة تعيين كلمة المرور',
          color: errorColor,
        );
        return;
      }

      if (email.endsWith('@test.com')) {
        showMessage(
          'هذا الحساب مربوط ببريد تجريبي. يرجى تحديث البريد الإلكتروني الحقيقي أولًا',
          color: warningColor,
        );
        return;
      }

      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (!mounted) return;

      await showMessage(
        'تم إرسال رابط إعادة تعيين كلمة المرور إلى: $email\nتحققي من البريد الوارد أو الرسائل غير المرغوب فيها Spam.',
        color: successColor,
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('Password Reset Error: ${e.code}');

      switch (e.code) {
        case 'user-not-found':
          showMessage(
            'لا يوجد حساب في Authentication بهذا البريد',
            color: errorColor,
          );
          break;
        case 'invalid-email':
          showMessage('البريد الإلكتروني غير صحيح', color: errorColor);
          break;
        case 'network-request-failed':
          showMessage('تحققي من اتصال الإنترنت', color: errorColor);
          break;
        case 'too-many-requests':
          showMessage(
            'تم إرسال روابط كثيرة. انتظري قليلًا ثم جربي مرة أخرى',
            color: warningColor,
          );
          break;
        default:
          showMessage('تعذر إرسال رابط إعادة التعيين', color: errorColor);
      }
    } catch (e) {
      debugPrint('Password Reset General Error: $e');
      showMessage('حدث خطأ أثناء إرسال الرابط', color: errorColor);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
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

  Widget field({
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
                      Icons.mark_email_read_rounded,
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
                      'أدخلي رقم الهاتف المسجل، وسنرسل رابط إعادة تعيين كلمة المرور إلى البريد الإلكتروني المرتبط بحسابك.',
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
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2FA),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFD7E6F5)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: primaryColor),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'بعد الإرسال، افتحي البريد الوارد أو Spam واضغطي آخر رابط وصلك فقط.',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 15,
                          fontFamily: 'Cairo',
                          color: textColor,
                          height: 1.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : sendPasswordResetLink,
                  icon: isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.email_rounded, color: Colors.white),
                  label: Text(
                    isLoading
                        ? 'جاري إرسال الرابط'
                        : 'إرسال رابط إعادة التعيين',
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
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: primaryColor,
                  ),
                  label: const Text(
                    'العودة لتسجيل الدخول',
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
