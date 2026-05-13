import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mycare/screens/logout_screen.dart';
import 'package:mycare/screens/forgot_password_screen.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  static const Color primaryColor = Color(0xFF1E3A5F);
  static const Color backgroundColor = Color(0xFFF7F8FA);
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color textColor = Color(0xFF1F2937);
  static const Color secondaryTextColor = Color(0xFF4B5563);
  static const Color errorColor = Color(0xFFD32F2F);
  static const Color successColor = Color(0xFF2E7D32);

  Map<String, dynamic>? userData;
  bool isLoading = true;
  bool isEditing = false;
  bool isSaving = false;

  final fullNameController = TextEditingController();
  final phoneController = TextEditingController();
  final ageController = TextEditingController();
  final relationController = TextEditingController();
  final emergencyContactController = TextEditingController();

  final diseasesController = TextEditingController();
  final medicinesController = TextEditingController();
  final allergyController = TextEditingController();
  final bloodPressureController = TextEditingController();
  final sugarController = TextEditingController();
  final heartRateController = TextEditingController();

  String? gender;
  String? bloodType;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  @override
  void dispose() {
    fullNameController.dispose();
    phoneController.dispose();
    ageController.dispose();
    relationController.dispose();
    emergencyContactController.dispose();
    diseasesController.dispose();
    medicinesController.dispose();
    allergyController.dispose();
    bloodPressureController.dispose();
    sugarController.dispose();
    heartRateController.dispose();
    super.dispose();
  }

  Future<void> loadUserData() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        setState(() => isLoading = false);
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (doc.exists) {
        userData = doc.data();
        fillControllers();
      }

      setState(() => isLoading = false);
    } catch (e) {
      debugPrint("Profile Error: $e");
      setState(() => isLoading = false);
    }
  }

  void fillControllers() {
    final health = userData?['healthProfile'] ?? {};

    fullNameController.text =
        (userData?['fullName'] ?? userData?['name'] ?? '').toString();

    phoneController.text = (userData?['phone'] ?? '').toString();
    ageController.text = (userData?['age'] ?? '').toString();
    relationController.text = (userData?['relation'] ?? '').toString();
    emergencyContactController.text =
        (userData?['emergencyContact'] ?? '').toString();

    gender = (userData?['gender'] ?? '').toString().isEmpty
        ? null
        : userData?['gender'];

    diseasesController.text = (health['diseases'] ?? '').toString();
    medicinesController.text = (health['medicines'] ?? '').toString();
    allergyController.text = (health['allergy'] ?? '').toString();
    bloodPressureController.text = (health['bloodPressure'] ?? '').toString();
    sugarController.text = (health['sugar'] ?? '').toString();
    heartRateController.text = (health['heartRate'] ?? '').toString();

    bloodType = (health['bloodType'] ?? '').toString().isEmpty
        ? null
        : health['bloodType'];
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

  Future<void> saveChanges() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      showMessage('لم يتم العثور على المستخدم', color: errorColor);
      return;
    }

    if (fullNameController.text.trim().isEmpty) {
      showMessage('الاسم الكامل مطلوب', color: errorColor);
      return;
    }

    if (phoneController.text.trim().isEmpty) {
      showMessage('رقم الهاتف مطلوب', color: errorColor);
      return;
    }

    setState(() => isSaving = true);

    try {
      final role = (userData?['role'] ?? '').toString();

      final Map<String, dynamic> updates = {
        'fullName': fullNameController.text.trim(),
        'phone': phoneController.text.trim(),
        'emergencyContact': emergencyContactController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (role == 'مريض') {
        updates.addAll({
          'age': ageController.text.trim(),
          'gender': gender ?? '',
          'healthProfile.diseases': diseasesController.text.trim(),
          'healthProfile.medicines': medicinesController.text.trim(),
          'healthProfile.allergy': allergyController.text.trim(),
          'healthProfile.bloodType': bloodType ?? '',
          'healthProfile.bloodPressure': bloodPressureController.text.trim(),
          'healthProfile.sugar': sugarController.text.trim(),
          'healthProfile.heartRate': heartRateController.text.trim(),
        });
      }

      if (role == 'مرافق') {
        updates.addAll({
          'relation': relationController.text.trim(),
        });
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .update(updates);

      await loadUserData();

      setState(() => isEditing = false);

      showMessage('تم حفظ التعديلات بنجاح', color: successColor);
    } catch (e) {
      debugPrint("Update Profile Error: $e");
      showMessage('حدث خطأ أثناء حفظ التعديلات', color: errorColor);
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
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

  Widget editField({
    required String title,
    required TextEditingController controller,
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
        decoration: inputDecoration(
          hint: title,
          icon: icon,
        ),
      ),
    );
  }

  Widget infoTile(String title, String value, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: primaryColor),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontFamily: 'Cairo',
          color: secondaryTextColor,
        ),
      ),
      subtitle: Text(
        value.trim().isEmpty ? '-' : value,
        style: const TextStyle(
          fontSize: 18,
          fontFamily: 'Cairo',
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget actionTile({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    Color color = primaryColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontFamily: 'Cairo',
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 18),
      onTap: onTap,
    );
  }

  Widget sectionCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final role = (userData?['role'] ?? '').toString();
    final isPatient = role == 'مريض';
    final isCaregiver = role == 'مرافق';

    final name = (userData?['fullName'] ?? userData?['name'] ?? '').toString();
    final phone = (userData?['phone'] ?? '').toString();
    final email = (userData?['email'] ?? '').toString();
    final emergency = (userData?['emergencyContact'] ?? '').toString();
    final health = userData?['healthProfile'] ?? {};

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          title: const Text(
            'الملف الشخصي',
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
          actions: [
            if (!isLoading && userData != null)
              IconButton(
                onPressed: () {
                  setState(() {
                    isEditing = !isEditing;
                    if (!isEditing) fillControllers();
                  });
                },
                icon: Icon(isEditing ? Icons.close : Icons.edit),
              ),
          ],
        ),
        body: isLoading
            ? const Center(
                child: CircularProgressIndicator(color: primaryColor),
              )
            : userData == null
                ? const Center(
                    child: Text(
                      'لا توجد بيانات للمستخدم',
                      style: TextStyle(
                        fontSize: 18,
                        fontFamily: 'Cairo',
                        color: textColor,
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            children: [
                              const CircleAvatar(
                                radius: 42,
                                backgroundColor: Colors.white,
                                child: Icon(
                                  Icons.person,
                                  size: 52,
                                  color: primaryColor,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                name,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontFamily: 'Cairo',
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                role,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontFamily: 'Cairo',
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        if (!isEditing) ...[
                          sectionCard(
                            children: [
                              infoTile('الاسم', name, Icons.person),
                              infoTile('رقم الهاتف', phone, Icons.phone),
                              infoTile('الإيميل', email, Icons.email),
                              infoTile('رقم الطوارئ', emergency, Icons.emergency),
                              if (isPatient) ...[
                                infoTile('العمر', ageController.text, Icons.cake),
                                infoTile('الجنس', gender ?? '', Icons.wc),
                                infoTile(
                                  'فصيلة الدم',
                                  (health['bloodType'] ?? '').toString(),
                                  Icons.bloodtype,
                                ),
                                infoTile(
                                  'الأمراض المزمنة',
                                  (health['diseases'] ?? '').toString(),
                                  Icons.medical_services,
                                ),
                                infoTile(
                                  'الأدوية الحالية',
                                  (health['medicines'] ?? '').toString(),
                                  Icons.medication,
                                ),
                              ],
                              if (isCaregiver)
                                infoTile(
                                  'صلة القرابة',
                                  relationController.text,
                                  Icons.family_restroom,
                                ),
                            ],
                          ),
                        ] else ...[
                          sectionCard(
                            children: [
                              editField(
                                title: 'الاسم الكامل',
                                controller: fullNameController,
                                icon: Icons.person,
                              ),
                              const SizedBox(height: 16),
                              editField(
                                title: 'رقم الهاتف',
                                controller: phoneController,
                                icon: Icons.phone,
                                keyboardType: TextInputType.phone,
                              ),
                              const SizedBox(height: 16),
                              editField(
                                title: 'رقم الطوارئ',
                                controller: emergencyContactController,
                                icon: Icons.emergency,
                                keyboardType: TextInputType.phone,
                              ),
                              if (isPatient) ...[
                                const SizedBox(height: 16),
                                editField(
                                  title: 'العمر',
                                  controller: ageController,
                                  icon: Icons.cake,
                                  keyboardType: TextInputType.number,
                                ),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<String>(
                                  initialValue: gender,
                                  decoration: inputDecoration(
                                    hint: 'الجنس',
                                    icon: Icons.wc,
                                  ),
                                  items: ['ذكر', 'أنثى']
                                      .map(
                                        (g) => DropdownMenuItem(
                                          value: g,
                                          child: Text(
                                            g,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontFamily: 'Cairo',
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) {
                                    setState(() => gender = value);
                                  },
                                ),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<String>(
                                  initialValue: bloodType,
                                  decoration: inputDecoration(
                                    hint: 'فصيلة الدم',
                                    icon: Icons.bloodtype,
                                  ),
                                  items: [
                                    'A+',
                                    'A-',
                                    'B+',
                                    'B-',
                                    'O+',
                                    'O-',
                                    'AB+',
                                    'AB-'
                                  ]
                                      .map(
                                        (b) => DropdownMenuItem(
                                          value: b,
                                          child: Text(
                                            b,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontFamily: 'Cairo',
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) {
                                    setState(() => bloodType = value);
                                  },
                                ),
                                const SizedBox(height: 16),
                                editField(
                                  title: 'الأمراض المزمنة',
                                  controller: diseasesController,
                                  icon: Icons.medical_services,
                                ),
                                const SizedBox(height: 16),
                                editField(
                                  title: 'الأدوية الحالية',
                                  controller: medicinesController,
                                  icon: Icons.medication,
                                ),
                                const SizedBox(height: 16),
                                editField(
                                  title: 'الحساسية',
                                  controller: allergyController,
                                  icon: Icons.warning,
                                ),
                                const SizedBox(height: 16),
                                editField(
                                  title: 'ضغط الدم',
                                  controller: bloodPressureController,
                                  icon: Icons.favorite,
                                  keyboardType: TextInputType.number,
                                ),
                                const SizedBox(height: 16),
                                editField(
                                  title: 'مستوى السكر',
                                  controller: sugarController,
                                  icon: Icons.water_drop,
                                  keyboardType: TextInputType.number,
                                ),
                                const SizedBox(height: 16),
                                editField(
                                  title: 'نبض القلب',
                                  controller: heartRateController,
                                  icon: Icons.monitor_heart,
                                  keyboardType: TextInputType.number,
                                ),
                              ],
                              if (isCaregiver) ...[
                                const SizedBox(height: 16),
                                editField(
                                  title: 'صلة القرابة',
                                  controller: relationController,
                                  icon: Icons.family_restroom,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 56,
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: isSaving ? null : saveChanges,
                              icon: isSaving
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.save, color: Colors.white),
                              label: Text(
                                isSaving ? 'جاري الحفظ' : 'حفظ التعديلات',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontFamily: 'Cairo',
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: successColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),

                        sectionCard(
                          children: [
                            actionTile(
                              title: 'تغيير كلمة المرور',
                              icon: Icons.lock_reset,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ForgotPasswordScreen(),
                                  ),
                                );
                              },
                            ),
                            const Divider(height: 1),
                            actionTile(
                              title: 'تسجيل الخروج',
                              icon: Icons.logout,
                              color: errorColor,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const LogoutScreen(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}