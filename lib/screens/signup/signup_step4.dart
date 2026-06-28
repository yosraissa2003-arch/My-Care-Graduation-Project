import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mycare/screens/login_screen.dart';

class SignUpStep4 extends StatefulWidget {
  final String role;
  final String fullName;
  final String phone;
  final String password;
  final String email;

  final String age;
  final String gender;
  final String relation;

  final String linkedPhone;
  final String doctorPhone;
  final String inviteCode;

  final String doctorSpecialty;
  final String doctorWorkplace;
  final String doctorLicenseNumber;

  final String diseases;
  final String diseaseSince;
  final String medicines;
  final String allergy;
  final String allergyTypes;
  final String surgeries;
  final String smokingStatus;
  final String cigarettesPerDay;
  final String bloodType;
  final String bloodPressure;
  final String sugar;
  final String heartRate;

  final bool remindersEnabled;
  final bool wearableEnabled;

  const SignUpStep4({
    super.key,
    required this.role,
    required this.fullName,
    required this.phone,
    required this.password,
    required this.email,
    required this.age,
    required this.gender,
    required this.relation,
    required this.linkedPhone,
    required this.doctorPhone,
    required this.inviteCode,
    required this.doctorSpecialty,
    required this.doctorWorkplace,
    required this.doctorLicenseNumber,
    required this.diseases,
    required this.diseaseSince,
    required this.medicines,
    required this.allergy,
    required this.allergyTypes,
    required this.surgeries,
    required this.smokingStatus,
    required this.cigarettesPerDay,
    required this.bloodType,
    required this.bloodPressure,
    required this.sugar,
    required this.heartRate,
    required this.remindersEnabled,
    required this.wearableEnabled,
  });

  @override
  State<SignUpStep4> createState() => _SignUpStep4State();
}

class _SignUpStep4State extends State<SignUpStep4> {
  static const Color primaryColor = Color(0xFF1F4168);
  static const Color backgroundColor = Color(0xFFF7F9FC);
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color textColor = Color(0xFF111827);
  static const Color secondaryTextColor = Color(0xFF374151);
  static const Color hintColor = Color(0xFF6B7280);
  static const Color borderColor = Color(0xFFC9D6E2);

  static const Color warningColor = Color(0xFFED6C02);
  static const Color successColor = Color(0xFF2E7D32);
  static const Color errorColor = Color(0xFFD32F2F);

  final TextEditingController emergencyContactController =
      TextEditingController();

  bool allowLocation = false;
  bool allowNotifications = false;
  bool privacyAccepted = false;
  bool isLoading = false;

  @override
  void dispose() {
    emergencyContactController.dispose();
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

  Future<void> showMessage(String message, {Color color = primaryColor}) async {
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

  String mapFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'هذا الحساب موجود مسبقًا';
      case 'weak-password':
        return 'كلمة المرور ضعيفة';
      case 'network-request-failed':
        return 'تحقق من اتصال الإنترنت';
      case 'operation-not-allowed':
        return 'طريقة التسجيل غير مفعلة في Firebase';
      default:
        return 'فشل إنشاء الحساب';
    }
  }

  String mapFirestoreError(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'لا يوجد صلاحية للكتابة داخل Firestore';
      case 'unavailable':
        return 'Firestore غير متاح الآن';
      default:
        return 'حدث خطأ أثناء حفظ البيانات';
    }
  }

  Future<void> createAccount() async {
    if (isLoading) return;

    final String? normalizedPhone = normalizePhoneNumber(widget.phone);
    final String? normalizedEmergency = normalizePhoneNumber(
      emergencyContactController.text.trim(),
    );

    final String? normalizedLinkedPhone = widget.linkedPhone.trim().isEmpty
        ? ''
        : normalizePhoneNumber(widget.linkedPhone.trim());

    final String? normalizedDoctorPhone = widget.doctorPhone.trim().isEmpty
        ? ''
        : normalizePhoneNumber(widget.doctorPhone.trim());

    final String accountEmail = widget.email.trim().toLowerCase();
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    if (accountEmail.isEmpty) {
      showMessage('البريد الإلكتروني مطلوب', color: errorColor);
      return;
    }

    if (!emailRegex.hasMatch(accountEmail)) {
      showMessage('البريد الإلكتروني غير صحيح', color: errorColor);
      return;
    }

    if (accountEmail.endsWith('@test.com')) {
      showMessage(
        'استخدم بريدًا إلكترونيًا حقيقيًا وليس تجريبيًا',
        color: errorColor,
      );
      return;
    }

    if (normalizedPhone == null) {
      showMessage(
        'رقم الهاتف غير صحيح. يجب أن يبدأ بـ 059 أو 056 أو 050 أو 052 أو 053 أو 054 أو 055 أو 058',
        color: errorColor,
      );
      return;
    }

    if (emergencyContactController.text.trim().isEmpty) {
      showMessage('رقم الطوارئ مطلوب', color: errorColor);
      return;
    }

    if (normalizedEmergency == null) {
      showMessage('رقم الطوارئ غير صحيح', color: errorColor);
      return;
    }

    if (widget.linkedPhone.trim().isNotEmpty && normalizedLinkedPhone == null) {
      showMessage('رقم الربط غير صحيح', color: errorColor);
      return;
    }

    if (widget.doctorPhone.trim().isNotEmpty && normalizedDoctorPhone == null) {
      showMessage('رقم الطبيب غير صحيح', color: errorColor);
      return;
    }

    if (!privacyAccepted) {
      showMessage('يجب الموافقة على سياسة الخصوصية', color: warningColor);
      return;
    }

    setState(() => isLoading = true);

    try {
      final existingPhone = await FirebaseFirestore.instance
          .collection('users')
          .where('phone', isEqualTo: normalizedPhone)
          .limit(1)
          .get();

      if (existingPhone.docs.isNotEmpty) {
        showMessage('رقم الهاتف مستخدم مسبقًا', color: errorColor);
        return;
      }

      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: accountEmail,
            password: widget.password.trim(),
          );

      final uid = userCredential.user!.uid;
      final now = FieldValue.serverTimestamp();

      final Map<String, dynamic> userData = {
        'uid': uid,
        'role': widget.role.trim(),
        'fullName': widget.fullName.trim(),
        'phone': normalizedPhone,
        'originalPhone': widget.phone.trim(),
        'email': accountEmail,
        'createdAt': now,
        'linkedPhone': normalizedLinkedPhone ?? '',
        'doctorPhone': normalizedDoctorPhone ?? '',
        'inviteCode': widget.inviteCode.trim(),
        'emergencyContact': normalizedEmergency,
        'allowLocation': allowLocation,
        'allowNotifications': allowNotifications,
        'privacyAccepted': privacyAccepted,
      };

      if (widget.role == 'مريض') {
        userData.addAll({
          'age': widget.age.trim(),
          'gender': widget.gender.trim(),
          'healthProfile': {
            'diseases': widget.diseases.trim(),
            'diseaseSince': widget.diseaseSince.trim(),
            'medicines': widget.medicines.trim(),
            'allergy': widget.allergy.trim(),
            'allergyTypes': widget.allergyTypes.trim(),
            'surgeries': widget.surgeries.trim(),
            'smokingStatus': widget.smokingStatus.trim(),
            'cigarettesPerDay': widget.cigarettesPerDay.trim(),
            'bloodType': widget.bloodType.trim(),
            'bloodPressure': widget.bloodPressure.trim(),
            'sugar': widget.sugar.trim(),
            'heartRate': widget.heartRate.trim(),
            'remindersEnabled': widget.remindersEnabled,
            'wearableEnabled': false,
          },
        });
      }

      if (widget.role == 'مرافق') {
        userData.addAll({'relation': widget.relation.trim()});
      }

      if (widget.role == 'طبيب') {
        userData.addAll({
          'doctorSpecialty': widget.doctorSpecialty.trim(),
          'doctorWorkplace': widget.doctorWorkplace.trim(),
          'doctorLicenseNumber': widget.doctorLicenseNumber.trim(),
          'doctorCode':
              'DR-${normalizedPhone.substring(normalizedPhone.length - 4)}',
        });
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set(userData);

      if (widget.role == 'طبيب') {
        await FirebaseFirestore.instance
            .collection('doctor_profiles')
            .doc(uid)
            .set({
              'doctorId': uid,
              'fullName': widget.fullName.trim(),
              'phone': normalizedPhone,
              'specialty': widget.doctorSpecialty.trim(),
              'workplace': widget.doctorWorkplace.trim(),
              'licenseNumber': widget.doctorLicenseNumber.trim(),
              'doctorCode':
                  'DR-${normalizedPhone.substring(normalizedPhone.length - 4)}',
              'createdAt': now,
            });
      }

      if ((normalizedLinkedPhone ?? '').isNotEmpty ||
          widget.inviteCode.trim().isNotEmpty) {
        await FirebaseFirestore.instance.collection('care_links').add({
          'requesterId': uid,
          'requesterRole': widget.role.trim(),
          'linkedPhone': normalizedLinkedPhone ?? '',
          'inviteCode': widget.inviteCode.trim(),
          'status': 'pending',
          'createdAt': now,
        });
      }

      if (widget.role == 'مريض' && (normalizedDoctorPhone ?? '').isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('doctor_patient_links')
            .add({
              'patientId': uid,
              'patientPhone': normalizedPhone,
              'doctorPhone': normalizedDoctorPhone ?? '',
              'status': 'pending',
              'createdAt': now,
            });
      }

      showMessage('تم إنشاء الحساب بنجاح', color: successColor);

      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      showMessage(mapFirebaseAuthError(e), color: errorColor);
    } on FirebaseException catch (e) {
      showMessage(mapFirestoreError(e), color: errorColor);
    } catch (_) {
      showMessage('حدث خطأ غير متوقع', color: errorColor);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  InputDecoration inputDecoration({required String hint, IconData? icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        fontSize: 19,
        fontFamily: 'Cairo',
        color: hintColor,
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: icon == null
          ? null
          : Icon(icon, color: primaryColor, size: 28),
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
    IconData? icon,
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

  Widget buildPageTitle() {
    return const Text(
      'الطوارئ والصلاحيات',
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
              isPatient ? 'الخطوة 4 من 5' : 'الخطوة 4 من 4',
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
            value: isPatient ? 0.80 : 1.0,
            minHeight: 10,
            backgroundColor: const Color(0xFFE5E7EB),
            valueColor: const AlwaysStoppedAnimation<Color>(primaryColor),
          ),
        ),
      ],
    );
  }

  Widget buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
      child: const Text(
        'أضف جهة اتصال للطوارئ، وفعّل الصلاحيات المهمة للتنبيهات والمساعدة.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 22,
          fontFamily: 'Cairo',
          color: textColor,
          fontWeight: FontWeight.w700,
          height: 1.8,
        ),
      ),
    );
  }

  Widget buildSwitchTile({
    required String title,
    required IconData icon,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
      child: SwitchListTile(
        value: value,
        activeThumbColor: successColor,
        onChanged: onChanged,
        secondary: Icon(icon, color: primaryColor, size: 34),
        title: Text(
          title,
          textAlign: TextAlign.right,
          style: const TextStyle(
            fontSize: 23,
            fontFamily: 'Cairo',
            color: textColor,
            fontWeight: FontWeight.w900,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget buildPrivacyCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
      child: CheckboxListTile(
        value: privacyAccepted,
        activeColor: successColor,
        onChanged: (value) {
          setState(() => privacyAccepted = value ?? false);
        },
        controlAffinity: ListTileControlAffinity.leading,
        title: const Text(
          'أوافق على سياسة الخصوصية',
          textAlign: TextAlign.right,
          style: TextStyle(
            fontSize: 23,
            fontFamily: 'Cairo',
            color: textColor,
            fontWeight: FontWeight.w900,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isPatient = widget.role == 'مريض';

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

                buildStepIndicator(isPatient),

                const SizedBox(height: 28),

                buildInfoCard(),

                const SizedBox(height: 24),

                buildField(
                  controller: emergencyContactController,
                  hint: 'رقم الطوارئ',
                  keyboardType: TextInputType.phone,
                ),

                const SizedBox(height: 18),

                buildSwitchTile(
                  title: 'السماح بالموقع الجغرافي',
                  icon: Icons.location_on,
                  value: allowLocation,
                  onChanged: (value) {
                    setState(() => allowLocation = value);
                  },
                ),

                const SizedBox(height: 18),

                buildSwitchTile(
                  title: 'السماح بالإشعارات',
                  icon: Icons.notifications_active,
                  value: allowNotifications,
                  onChanged: (value) {
                    setState(() => allowNotifications = value);
                  },
                ),

                const SizedBox(height: 18),

                buildPrivacyCard(),

                const SizedBox(height: 40),

                SizedBox(
                  height: 62,
                  child: ElevatedButton.icon(
                    onPressed: isLoading ? null : createAccount,
                    icon: isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.check_circle,
                            color: Colors.white,
                            size: 28,
                          ),
                    label: Text(
                      isLoading ? 'جاري إنشاء الحساب' : 'إنهاء التسجيل',
                      style: const TextStyle(
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
