import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddHealthDataScreen extends StatefulWidget {
  const AddHealthDataScreen({super.key});

  @override
  State<AddHealthDataScreen> createState() => _AddHealthDataScreenState();
}

class _AddHealthDataScreenState extends State<AddHealthDataScreen> {
  final String uid = "1sxPcUvNOJRS88X7xtDlx4Te5v62";

  final heartRateController = TextEditingController();

  final systolicController = TextEditingController();

  final diastolicController = TextEditingController();

  final glucoseController = TextEditingController();

  final temperatureController = TextEditingController();

  bool isLoading = false;

  static const Color dark = Color(0xff172638);

  static const Color green = Color(0xff2E8B57);

  static const Color border = Color(0xffD8D8D8);

  static const Color fieldBg = Color(0xffF8F8F8);

  @override
  void dispose() {
    heartRateController.dispose();
    systolicController.dispose();
    diastolicController.dispose();
    glucoseController.dispose();
    temperatureController.dispose();
    super.dispose();
  }

  Future<void> saveHealthData() async {
    if (heartRateController.text.trim().isEmpty ||
        systolicController.text.trim().isEmpty ||
        diastolicController.text.trim().isEmpty ||
        glucoseController.text.trim().isEmpty ||
        temperatureController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'الرجاء تعبئة جميع الحقول',
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: 18),
          ),
        ),
      );

      return;
    }

    setState(() {
      isLoading = true;
    });

    await FirebaseFirestore.instance.collection('healthLogs').add({
      'userId': uid,

      'heartRate': int.parse(heartRateController.text.trim()),

      'bloodPressureSystolic': int.parse(systolicController.text.trim()),

      'bloodPressureDiastolic': int.parse(diastolicController.text.trim()),

      'glucose': int.parse(glucoseController.text.trim()),

      'temperature': double.parse(temperatureController.text.trim()),

      'createdAt': Timestamp.now(),
    });

    setState(() {
      isLoading = false;
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'تم حفظ القراءة بنجاح',
          textAlign: TextAlign.right,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,

      child: Scaffold(
        backgroundColor: Colors.white,

        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,

          automaticallyImplyLeading: false,

          leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: dark,
              size: 28,
            ),
          ),

          title: const Text(
            'إضافة قراءة صحية',

            style: TextStyle(
              color: dark,
              fontSize: 34,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),

        body: SingleChildScrollView(
          padding: const EdgeInsets.all(18),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,

            children: [
              const Text(
                'سيتم حفظ القراءة بتاريخ اليوم',

                textAlign: TextAlign.right,

                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: dark,
                ),
              ),

              const SizedBox(height: 28),

              _inputField(
                controller: heartRateController,
                label: 'نبض القلب',
                hint: 'مثال: 75',
              ),

              const SizedBox(height: 18),

              _inputField(
                controller: systolicController,
                label: 'الضغط الانقباضي',
                hint: 'مثال: 120',
              ),

              const SizedBox(height: 18),

              _inputField(
                controller: diastolicController,
                label: 'الضغط الانبساطي',
                hint: 'مثال: 80',
              ),

              const SizedBox(height: 18),

              _inputField(
                controller: glucoseController,
                label: 'مستوى السكر',
                hint: 'مثال: 100',
              ),

              const SizedBox(height: 18),

              _inputField(
                controller: temperatureController,
                label: 'درجة الحرارة',
                hint: 'مثال: 37',
              ),

              const SizedBox(height: 36),

              SizedBox(
                width: double.infinity,

                child: ElevatedButton(
                  onPressed: isLoading ? null : saveHealthData,

                  style: ElevatedButton.styleFrom(
                    backgroundColor: green,

                    minimumSize: const Size(double.infinity, 76),

                    elevation: 4,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),

                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'حفظ القراءة',

                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
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

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return TextField(
      controller: controller,

      keyboardType: TextInputType.number,

      textAlign: TextAlign.right,

      style: const TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w900,
        color: dark,
      ),

      decoration: InputDecoration(
        labelText: label,
        hintText: hint,

        floatingLabelBehavior: FloatingLabelBehavior.always,

        labelStyle: const TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w900,
          color: dark,
        ),

        hintStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w500,
          color: dark.withOpacity(0.35),
        ),

        filled: true,
        fillColor: fieldBg,

        contentPadding: const EdgeInsets.symmetric(
          vertical: 32,
          horizontal: 24,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),

          borderSide: const BorderSide(color: border, width: 2),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),

          borderSide: const BorderSide(color: border, width: 2),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),

          borderSide: const BorderSide(color: green, width: 3),
        ),
      ),
    );
  }
}
