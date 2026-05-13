import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'signup_step4.dart';

class SignUpStep3 extends StatefulWidget {
  final String role;
  final String fullName;
  final String phone;
  final String password;

  final String age;
  final String gender;
  final String relation;

  final String linkedPhone;
  final String inviteCode;

  const SignUpStep3({
    super.key,
    required this.role,
    required this.fullName,
    required this.phone,
    required this.password,
    required this.age,
    required this.gender,
    required this.relation,
    required this.linkedPhone,
    required this.inviteCode,
  });

  @override
  State<SignUpStep3> createState() =>
      _SignUpStep3State();
}

class _SignUpStep3State
    extends State<SignUpStep3> {
  // ================= COLORS =================

  static const Color primaryColor =
      Color(0xFF1E3A5F);

  static const Color backgroundColor =
      Color(0xFFF7F8FA);

  static const Color cardColor =
      Color(0xFFFFFFFF);

  static const Color textColor =
      Color(0xFF1F2937);

  static const Color secondaryTextColor =
      Color(0xFF4B5563);

  static const Color warningColor =
      Color(0xFFED6C02);

  static const Color successColor =
      Color(0xFF2E7D32);

  static const Color errorColor =
      Color(0xFFD32F2F);

  // ================= CONTROLLERS =================

  final TextEditingController
      diseasesController =
      TextEditingController();

  final TextEditingController
      medicinesController =
      TextEditingController();

  final TextEditingController
      allergyController =
      TextEditingController();

  final TextEditingController
      bloodPressureController =
      TextEditingController();

  final TextEditingController
      sugarController =
      TextEditingController();

  final TextEditingController
      heartRateController =
      TextEditingController();

  // ================= VARIABLES =================

  String? bloodType;

  bool remindersEnabled = true;
  bool wearableEnabled = false;

  final List<String> bloodTypes = [
    "A+",
    "A-",
    "B+",
    "B-",
    "O+",
    "O-",
    "AB+",
    "AB-",
  ];

  // ================= DISPOSE =================

  @override
  void dispose() {
    diseasesController.dispose();
    medicinesController.dispose();
    allergyController.dispose();
    bloodPressureController.dispose();
    sugarController.dispose();
    heartRateController.dispose();
    super.dispose();
  }

  // ================= MESSAGE =================

  void showMessage(
    String message, {
    Color color = primaryColor,
  }) async {
    await SystemSound.play(
      SystemSoundType.alert,
    );

    HapticFeedback.mediumImpact();

    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        backgroundColor: color,
        behavior:
            SnackBarBehavior.floating,
        margin:
            const EdgeInsets.all(20),
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(16),
        ),
        content: Text(
          message,
          textAlign: TextAlign.right,
          style: const TextStyle(
            fontSize: 18,
            fontFamily: 'Cairo',
            fontWeight:
                FontWeight.bold,
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
    if (widget.role == "مريض") {
      if (bloodType == null) {
        showMessage(
          "اختاري فصيلة الدم",
          color: warningColor,
        );
        return;
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SignUpStep4(
          role: widget.role,
          fullName: widget.fullName,
          phone: widget.phone,
          password: widget.password,

          age: widget.age,
          gender: widget.gender,
          relation: widget.relation,

          linkedPhone:
              widget.linkedPhone,

          inviteCode:
              widget.inviteCode,

          diseases:
              diseasesController.text
                  .trim(),

          medicines:
              medicinesController.text
                  .trim(),

          allergy:
              allergyController.text
                  .trim(),

          bloodType:
              bloodType ?? "",

          bloodPressure:
              bloodPressureController
                  .text
                  .trim(),

          sugar:
              sugarController.text
                  .trim(),

          heartRate:
              heartRateController.text
                  .trim(),

          remindersEnabled:
              remindersEnabled,

          wearableEnabled:
              wearableEnabled,
        ),
      ),
    );
  }

  // ================= INPUT =================

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
          const EdgeInsets.symmetric(
        horizontal: 16,
      ),
      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );
  }

  // ================= FIELD =================

  Widget buildField({
    required TextEditingController
        controller,
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

    // ================= CAREGIVER SKIP =================

    if (!isPatient) {
      Future.microtask(() {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SignUpStep4(
              role: widget.role,
              fullName:
                  widget.fullName,
              phone: widget.phone,
              password:
                  widget.password,
              age: widget.age,
              gender:
                  widget.gender,
              relation:
                  widget.relation,
              linkedPhone:
                  widget.linkedPhone,
              inviteCode:
                  widget.inviteCode,
              diseases: "",
              medicines: "",
              allergy: "",
              bloodType: "",
              bloodPressure: "",
              sugar: "",
              heartRate: "",
              remindersEnabled:
                  false,
              wearableEnabled:
                  false,
            ),
          ),
        );
      });

      return const Scaffold(
        body: Center(
          child:
              CircularProgressIndicator(),
        ),
      );
    }

    return Directionality(
      textDirection:
          TextDirection.rtl,
      child: Scaffold(
        backgroundColor:
            backgroundColor,
        body: SafeArea(
          child:
              SingleChildScrollView(
            padding:
                const EdgeInsets.all(
                    20),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .stretch,
              children: [
                const SizedBox(
                    height: 16),

                // ================= TITLE =================

                const Text(
                  'رعايتي ❤️',
                  textAlign:
                      TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontFamily:
                        'Cairo',
                    fontWeight:
                        FontWeight.bold,
                    color: textColor,
                  ),
                ),

                const SizedBox(
                    height: 8),

                const Text(
                  'المعلومات الصحية',
                  textAlign:
                      TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontFamily:
                        'Cairo',
                    fontWeight:
                        FontWeight.bold,
                    color:
                        primaryColor,
                  ),
                ),

                const SizedBox(
                    height: 4),

                const Text(
                  'الخطوة 3 من 5',
                  textAlign:
                      TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily:
                        'Cairo',
                    color:
                        secondaryTextColor,
                  ),
                ),

                const SizedBox(
                    height: 24),

                // ================= PROGRESS =================

                LinearProgressIndicator(
                  value: 0.6,
                  minHeight: 8,
                  borderRadius:
                      BorderRadius
                          .circular(
                              20),
                  backgroundColor:
                      Colors.grey
                          .shade300,
                  color:
                      primaryColor,
                ),

                const SizedBox(
                    height: 32),

                // ================= DISEASES =================

                buildField(
                  controller:
                      diseasesController,
                  hint:
                      'الأمراض المزمنة',
                  icon:
                      Icons.medical_services,
                ),

                const SizedBox(
                    height: 16),

                buildField(
                  controller:
                      medicinesController,
                  hint:
                      'الأدوية الحالية',
                  icon:
                      Icons.medication,
                ),

                const SizedBox(
                    height: 16),

                buildField(
                  controller:
                      allergyController,
                  hint: 'الحساسية',
                  icon:
                      Icons.warning,
                ),

                const SizedBox(
                    height: 16),

                // ================= BLOOD TYPE =================

                DropdownButtonFormField<
                    String>(
                  initialValue: bloodType,
                  decoration:
                      inputDecoration(
                    hint:
                        'فصيلة الدم',
                    icon:
                        Icons.bloodtype,
                  ),
                  style:
                      const TextStyle(
                    fontSize: 18,
                    fontFamily:
                        'Cairo',
                    color:
                        textColor,
                  ),
                  items: bloodTypes
                      .map(
                        (type) =>
                            DropdownMenuItem(
                          value: type,
                          child:
                              Text(type),
                        ),
                      )
                      .toList(),
                  onChanged:
                      (value) {
                    setState(() {
                      bloodType =
                          value;
                    });
                  },
                ),

                const SizedBox(
                    height: 24),

                // ================= MEASUREMENTS =================

                buildField(
                  controller:
                      bloodPressureController,
                  hint:
                      'ضغط الدم',
                  icon:
                      Icons.favorite,
                  keyboardType:
                      TextInputType
                          .number,
                ),

                const SizedBox(
                    height: 16),

                buildField(
                  controller:
                      sugarController,
                  hint:
                      'مستوى السكر',
                  icon:
                      Icons.water_drop,
                  keyboardType:
                      TextInputType
                          .number,
                ),

                const SizedBox(
                    height: 16),

                buildField(
                  controller:
                      heartRateController,
                  hint:
                      'نبض القلب',
                  icon:
                      Icons.monitor_heart,
                  keyboardType:
                      TextInputType
                          .number,
                ),

                const SizedBox(
                    height: 24),

                // ================= SETTINGS =================

                Container(
                  padding:
                      const EdgeInsets
                          .all(20),
                  decoration:
                      BoxDecoration(
                    color: cardColor,
                    borderRadius:
                        BorderRadius
                            .circular(
                                20),
                  ),
                  child: Column(
                    children: [
                      SwitchListTile(
                        value:
                            remindersEnabled,
                        activeThumbColor:
                            successColor,
                        title:
                            const Text(
                          'تفعيل التذكيرات',
                          style:
                              TextStyle(
                            fontSize:
                                18,
                            fontFamily:
                                'Cairo',
                            color:
                                textColor,
                          ),
                        ),
                        onChanged:
                            (value) {
                          setState(() {
                            remindersEnabled =
                                value;
                          });
                        },
                      ),

                      SwitchListTile(
                        value:
                            wearableEnabled,
                        activeThumbColor:
                            successColor,
                        title:
                            const Text(
                          'ربط ساعة ذكية',
                          style:
                              TextStyle(
                            fontSize:
                                18,
                            fontFamily:
                                'Cairo',
                            color:
                                textColor,
                          ),
                        ),
                        onChanged:
                            (value) {
                          setState(() {
                            wearableEnabled =
                                value;
                          });
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                    height: 40),

                // ================= NEXT =================

                SizedBox(
                  height: 56,
                  child:
                      ElevatedButton
                          .icon(
                    onPressed:
                        goNext,
                    icon: const Icon(
                      Icons
                          .arrow_forward,
                      color: Colors
                          .white,
                    ),
                    label:
                        const Text(
                      'التالي',
                      style:
                          TextStyle(
                        fontSize:
                            18,
                        fontFamily:
                            'Cairo',
                        fontWeight:
                            FontWeight
                                .bold,
                        color: Colors
                            .white,
                      ),
                    ),
                    style:
                        ElevatedButton
                            .styleFrom(
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

                const SizedBox(
                    height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}