import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mycare/services/notification_service.dart';

import 'notifications_screen.dart';

class AddMedicationScreen extends StatefulWidget {
  const AddMedicationScreen({super.key});

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final FlutterTts _tts = FlutterTts();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController remainingPillsController =
      TextEditingController();
  final TextEditingController notesController = TextEditingController();

  String selectedDose = 'حبة واحدة';
  String selectedFrequency = 'مرة يوميًا';
  String selectedPeriod = 'بعد الأكل';
  String selectedDuration = 'أسبوع';
  String selectedImportance = 'مهم';

  String selectedTime1 = '08:00 صباحًا';
  String selectedTime2 = '08:00 مساءً';
  String selectedTime3 = '02:00 مساءً';

  File? selectedImage;
  bool isLoading = false;

  final List<String> doses = const [
    'نصف حبة',
    'حبة واحدة',
    'حبتان',
    '3 حبات',
    '5 مل',
    '10 مل',
    '15 مل',
    'نقطة واحدة',
    'نقطتان',
    'حقنة واحدة',
  ];

  final List<String> times = const [
    '06:00 صباحًا',
    '06:30 صباحًا',
    '07:00 صباحًا',
    '07:30 صباحًا',
    '08:00 صباحًا',
    '08:30 صباحًا',
    '09:00 صباحًا',
    '09:30 صباحًا',
    '10:00 صباحًا',
    '10:30 صباحًا',
    '11:00 صباحًا',
    '11:30 صباحًا',
    '12:00 ظهرًا',
    '12:30 ظهرًا',
    '01:00 مساءً',
    '01:30 مساءً',
    '02:00 مساءً',
    '02:30 مساءً',
    '03:00 مساءً',
    '03:30 مساءً',
    '04:00 مساءً',
    '04:30 مساءً',
    '05:00 مساءً',
    '05:30 مساءً',
    '06:00 مساءً',
    '06:30 مساءً',
    '07:00 مساءً',
    '07:30 مساءً',
    '08:00 مساءً',
    '08:30 مساءً',
    '09:00 مساءً',
    '09:30 مساءً',
    '10:00 مساءً',
  ];

  final List<String> frequencies = const [
    'مرة يوميًا',
    'مرتين يوميًا',
    'ثلاث مرات يوميًا',
    'عند الحاجة',
  ];

  final List<String> periods = const [
    'قبل الأكل',
    'بعد الأكل',
    'مع الأكل',
    'قبل النوم',
    'عند الاستيقاظ',
  ];

  final List<String> durations = const [
    '3 أيام',
    'أسبوع',
    'أسبوعين',
    'شهر',
    'دائم',
  ];

  final List<String> importanceLevels = const ['عادي', 'مهم', 'ضروري جدًا'];

  @override
  void initState() {
    super.initState();
    _setupTts();
  }

  Future<void> _setupTts() async {
    await _tts.setLanguage('ar');
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  Future<void> _speak(String text) async {
    if (text.trim().isEmpty) return;
    await _tts.stop();
    await _tts.speak(text);
  }

  String _selectedMedicationVoiceText() {
    final name = nameController.text.trim().isEmpty
        ? 'اسم الدواء غير مدخل بعد'
        : nameController.text.trim();

    final timesText = getSelectedTimes().isEmpty
        ? 'عند الحاجة'
        : getSelectedTimes().join('، ');

    final remaining = remainingPillsController.text.trim().isEmpty
        ? ''
        : 'عدد الحبات المتبقية ${remainingPillsController.text.trim()}.';

    final notes = notesController.text.trim().isEmpty
        ? ''
        : 'ملاحظات: ${notesController.text.trim()}.';

    return 'ملخص الدواء. اسم الدواء $name. الجرعة $selectedDose. '
        'عدد مرات الاستخدام $selectedFrequency. موعد الدواء $timesText. '
        'طريقة الاستخدام $selectedPeriod. مدة الاستخدام $selectedDuration. '
        'الأهمية $selectedImportance. $remaining $notes';
  }

  Widget buildVoiceAssistantCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8FC),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD7E6F5), width: 1.2),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xFF1E3A5F),
            child: IconButton(
              icon: const Icon(
                Icons.volume_up_rounded,
                color: Colors.white,
                size: 30,
              ),
              onPressed: () => _speak(_selectedMedicationVoiceText()),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'اضغطي على الصوت ليسمع المريض ملخص الدواء وموعده قبل الحفظ.',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E3A5F),
                height: 1.5,
                fontFamily: 'Cairo',
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tts.stop();
    nameController.dispose();
    remainingPillsController.dispose();
    notesController.dispose();
    super.dispose();
  }

  List<String> getSelectedTimes() {
    if (selectedFrequency == 'عند الحاجة') return [];
    if (selectedFrequency == 'مرة يوميًا') return [selectedTime1];
    if (selectedFrequency == 'مرتين يوميًا') {
      return [selectedTime1, selectedTime2];
    }
    return [selectedTime1, selectedTime3, selectedTime2];
  }

  String getReminderPreviewText() {
    if (selectedFrequency == 'عند الحاجة') {
      return 'لن يتم تحديد وقت ثابت، يمكن استخدام الدواء عند الحاجة.';
    }

    final selectedTimes = getSelectedTimes().join('، ');
    return 'سيتم تذكيرك $selectedFrequency في الأوقات: $selectedTimes';
  }

  Future<void> pickMedicationImage() async {
    final ImagePicker picker = ImagePicker();

    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );

    if (image == null) return;

    setState(() {
      selectedImage = File(image.path);
    });
  }

  Future<String?> uploadMedicationImage() async {
    if (selectedImage == null) return null;

    try {
      final String fileName = DateTime.now().millisecondsSinceEpoch.toString();

      final Reference ref = FirebaseStorage.instance
          .ref()
          .child('medication_images')
          .child('$fileName.jpg');

      await ref.putFile(selectedImage!);

      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Medication image upload error: $e');
      return null;
    }
  }

  String _normalizeText(String value) {
    return value
        .toLowerCase()
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ى', 'ي')
        .replaceAll('ة', 'ه')
        .replaceAll(RegExp(r'[^a-z0-9\u0600-\u06FF]+'), ' ')
        .trim();
  }

  List<String> _splitMedicalText(dynamic value) {
    if (value == null) return [];

    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }

    return value
        .toString()
        .split(RegExp(r'[,،/\n]+'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  List<String> _getPatientAllergies(Map<String, dynamic> userData) {
    final healthProfile = userData['healthProfile'];
    final allergies = <String>[];

    if (healthProfile is Map) {
      allergies.addAll(_splitMedicalText(healthProfile['allergy']));
      allergies.addAll(_splitMedicalText(healthProfile['allergies']));
      allergies.addAll(_splitMedicalText(healthProfile['allergyTypes']));
    }

    allergies.addAll(_splitMedicalText(userData['allergy']));
    allergies.addAll(_splitMedicalText(userData['allergies']));

    return allergies
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty && item != 'لا يوجد')
        .toSet()
        .toList();
  }

  Map<String, dynamic>? checkMedicationAllergy({
    required String medicationName,
    required List<String> allergies,
  }) {
    final med = _normalizeText(medicationName);
    final cleanAllergies = allergies
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty && item != 'لا يوجد')
        .toList();

    if (med.isEmpty || cleanAllergies.isEmpty) return null;

    final allergyText = cleanAllergies.map(_normalizeText).join(' ');

    bool hasAnyAllergy(List<String> keywords) {
      return keywords.any(
        (keyword) => allergyText.contains(_normalizeText(keyword)),
      );
    }

    bool medContains(List<String> keywords) {
      return keywords.any((keyword) => med.contains(_normalizeText(keyword)));
    }

    final rules = <Map<String, dynamic>>[
      {
        'allergyName': 'Penicillin / البنسلين',
        'allergyKeywords': [
          'penicillin',
          'بنسلين',
          'البنسلين',
          'حساسية البنسلين',
        ],
        'medicationKeywords': [
          'penicillin',
          'amoxicillin',
          'amoxil',
          'augmentin',
          'ampicillin',
          'cloxacillin',
          'flucloxacillin',
          'phenoxymethylpenicillin',
          'piperacillin',
          'tazocin',
          'اموكسيسيلين',
          'اوجمنتين',
          'امبيسيلين',
          'بنسلين',
        ],
        'message': 'هذا الدواء قد لا يناسب المريض لأنه من عائلة البنسلين.',
      },
      {
        'allergyName': 'Sulfa / السلفا',
        'allergyKeywords': [
          'sulfa',
          'sulfonamide',
          'sulphonamide',
          'سلفا',
          'السلفا',
        ],
        'medicationKeywords': [
          'sulfa',
          'sulfamethoxazole',
          'sulphamethoxazole',
          'bactrim',
          'septrin',
          'co trimoxazole',
          'co-trimoxazole',
          'cotrimoxazole',
          'trimethoprim',
          'sulfasalazine',
          'باكتريم',
          'سبترين',
          'سلفاميثوكسازول',
        ],
        'message': 'هذا الدواء قد يتعارض مع حساسية السلفا.',
      },
      {
        'allergyName': 'Aspirin / الأسبرين',
        'allergyKeywords': ['aspirin', 'اسبرين', 'الاسبرين', 'أسبرين'],
        'medicationKeywords': [
          'aspirin',
          'aspocid',
          'aspocard',
          'aspegic',
          'اسبرين',
          'أسبرين',
          'اسبوكارد',
          'اسبيجيك',
        ],
        'message':
            'هذا الدواء قد يسبب مشكلة لأن المريض لديه حساسية من الأسبرين.',
      },
      {
        'allergyName': 'Ibuprofen / الإيبوبروفين',
        'allergyKeywords': [
          'ibuprofen',
          'ايبوبروفين',
          'إيبوبروفين',
          'بروفين',
          'brufen',
        ],
        'medicationKeywords': [
          'ibuprofen',
          'brufen',
          'advil',
          'nurofen',
          'prof',
          'ايبوبروفين',
          'إيبوبروفين',
          'بروفين',
          'ادفيل',
        ],
        'message': 'هذا الدواء قد يتعارض مع حساسية الإيبوبروفين أو البروفين.',
      },
      {
        'allergyName': 'حساسية تخدير',
        'allergyKeywords': [
          'حساسية تخدير',
          'حساسية التخدير',
          'تخدير',
          'anesthesia',
          'anaesthesia',
        ],
        'medicationKeywords': [
          'lidocaine',
          'xylocaine',
          'bupivacaine',
          'marcaine',
          'propofol',
          'ketamine',
          'thiopental',
          'midazolam',
          'fentanyl',
          'ليدوكايين',
          'زيلوكايين',
          'بوبيفاكايين',
          'بروبو فول',
          'بروبوفول',
          'كيتامين',
        ],
        'message':
            'هذا الدواء قد يكون مرتبطاً بأدوية التخدير، يجب الانتباه لحساسية المريض.',
      },
      {
        'allergyName': 'حساسية أدوية الصرع',
        'allergyKeywords': [
          'حساسية أدوية الصرع',
          'حساسية ادويه الصرع',
          'ادوية الصرع',
          'أدوية الصرع',
          'صرع',
          'antiepileptic',
          'anti epileptic',
        ],
        'medicationKeywords': [
          'carbamazepine',
          'tegretol',
          'valproate',
          'valproic acid',
          'depakine',
          'depakote',
          'levetiracetam',
          'keppra',
          'lamotrigine',
          'lamictal',
          'phenytoin',
          'epanutin',
          'phenobarbital',
          'topiramate',
          'topamax',
          'كاربامازيبين',
          'تيجريتول',
          'فالبروات',
          'ديباكين',
          'كيبرا',
          'لاموتريجين',
          'فيني توين',
          'فينيتوين',
          'توبيراميت',
        ],
        'message': 'هذا الدواء من أدوية الصرع وقد لا يناسب حساسية المريض.',
      },
      {
        'allergyName': 'حساسية أدوية الأعصاب',
        'allergyKeywords': [
          'حساسية أدوية الأعصاب',
          'حساسية ادويه الاعصاب',
          'ادوية الاعصاب',
          'أدوية الأعصاب',
          'اعصاب',
          'أعصاب',
        ],
        'medicationKeywords': [
          'gabapentin',
          'neurontin',
          'pregabalin',
          'lyrica',
          'duloxetine',
          'cymbalta',
          'amitriptyline',
          'nortriptyline',
          'جابتين',
          'جابابنتين',
          'نيورونتين',
          'بريجابالين',
          'ليريكا',
          'دولوكستين',
          'اميتريبتيلين',
        ],
        'message': 'هذا الدواء من أدوية الأعصاب وقد لا يناسب حساسية المريض.',
      },
      {
        'allergyName': 'حساسية طعام',
        'allergyKeywords': [
          'حساسية طعام',
          'حساسيه طعام',
          'food allergy',
          'طعام',
        ],
        'medicationKeywords': [
          'gelatin',
          'lactose',
          'egg',
          'soy',
          'peanut',
          'nuts',
          'fish oil',
          'زيت السمك',
          'جيلاتين',
          'لاكتوز',
          'بيض',
          'صويا',
          'فول سوداني',
          'مكسرات',
        ],
        'message':
            'المريض لديه حساسية طعام، وقد يحتوي هذا الدواء على مواد مساعدة تحتاج مراجعة الطبيب أو الصيدلي.',
      },
    ];

    for (final rule in rules) {
      final allergyKeywords = List<String>.from(
        rule['allergyKeywords'] as List,
      );
      final medicationKeywords = List<String>.from(
        rule['medicationKeywords'] as List,
      );

      if (hasAnyAllergy(allergyKeywords) && medContains(medicationKeywords)) {
        return rule;
      }
    }

    return null;
  }

  Future<bool> showAllergyWarningDialog(Map<String, dynamic> warning) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: const Text(
              'تحذير حساسية دواء',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                color: Color(0xFFD32F2F),
              ),
            ),
            content: Text(
              '${warning['message']}\n\nنوع الحساسية: ${warning['allergyName']}\n\nيفضل مراجعة الطبيب قبل استخدام الدواء.',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 18,
                fontFamily: 'Cairo',
                height: 1.6,
                color: Colors.black,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'إلغاء الحفظ',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    color: Color(0xFFD32F2F),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF1E3A5F),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'حفظ رغم التحذير',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    return result == true;
  }

  String _digitsOnly(String value) {
    return value.replaceAll(RegExp(r'[^0-9]'), '');
  }

  Set<String> _phoneVariants(String phone) {
    final cleaned = _digitsOnly(phone);
    final variants = <String>{};

    if (cleaned.isEmpty) return variants;

    variants.add(cleaned);

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

  Future<String> findUserIdByPhone(String phone, String role) async {
    final variants = _phoneVariants(phone);
    if (variants.isEmpty) return '';

    final allowedRoles = role == 'مرافق' ? ['مرافق', 'معتني'] : [role];

    for (final variant in variants) {
      final byPhone = await FirebaseFirestore.instance
          .collection('users')
          .where('phone', isEqualTo: variant)
          .limit(5)
          .get();

      for (final doc in byPhone.docs) {
        final data = doc.data();
        final userRole = (data['role'] ?? '').toString().trim();

        if (allowedRoles.contains(userRole)) {
          return doc.id;
        }
      }

      final byOriginalPhone = await FirebaseFirestore.instance
          .collection('users')
          .where('originalPhone', isEqualTo: variant)
          .limit(5)
          .get();

      for (final doc in byOriginalPhone.docs) {
        final data = doc.data();
        final userRole = (data['role'] ?? '').toString().trim();

        if (allowedRoles.contains(userRole)) {
          return doc.id;
        }
      }
    }

    return '';
  }

  Future<void> addNotification({
    required String title,
    required String message,
    required String type,
    required String patientId,
    required String patientName,
    required String patientPhone,
    String caregiverId = '',
    String doctorId = '',
    String recipientId = '',
    Map<String, dynamic>? extra,
  }) async {
    await FirebaseFirestore.instance.collection('notifications').add({
      'title': title,
      'message': message,
      'type': type,
      'time': type == 'allergy_warning' ? 'تحذير حساسية' : 'تنبيه',
      'isRead': false,
      'userId': patientId,
      'patientId': patientId,
      'patientName': patientName,
      'patientPhone': patientPhone,
      'caregiverId': caregiverId,
      'doctorId': doctorId,
      'recipientId': recipientId,
      if (extra != null) ...extra,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> saveMedication() async {
    final name = nameController.text.trim();
    final remainingPills = remainingPillsController.text.trim();
    final notes = notesController.text.trim();

    if (name.isEmpty) {
      showMessage('يرجى إدخال اسم الدواء', false);
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      showMessage('يجب تسجيل الدخول أولاً', false);
      return;
    }

    try {
      setState(() => isLoading = true);

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      final userData = userDoc.data() ?? {};
      final patientName = (userData['fullName'] ?? userData['name'] ?? 'المريض')
          .toString();
      final patientPhone = (userData['phone'] ?? '').toString();
      final caregiverPhone =
          (userData['emergencyContact'] ?? userData['linkedPhone'] ?? '')
              .toString();
      final doctorPhone = (userData['doctorPhone'] ?? '').toString();

      final caregiverId = await findUserIdByPhone(caregiverPhone, 'مرافق');
      final doctorId = await findUserIdByPhone(doctorPhone, 'طبيب');

      final allergies = _getPatientAllergies(userData);
      final allergyWarning = checkMedicationAllergy(
        medicationName: name,
        allergies: allergies,
      );

      if (allergyWarning != null) {
        if (!mounted) return;
        final continueSaving = await showAllergyWarningDialog(allergyWarning);

        if (!continueSaving) {
          if (mounted) setState(() => isLoading = false);
          return;
        }
      }

      final String? imageUrl = await uploadMedicationImage();
      final List<String> selectedTimes = getSelectedTimes();

      final medicationData = {
        'userId': currentUser.uid,
        'patientId': currentUser.uid,
        'patientName': patientName,
        'patientPhone': patientPhone,
        'caregiverId': caregiverId,
        'doctorId': doctorId,
        'name': name,
        'dose': selectedDose,
        'frequency': selectedFrequency,
        'usagePeriod': selectedPeriod,
        'duration': selectedDuration,
        'importance': selectedImportance,
        'remainingPills': remainingPills,
        'notes': notes,
        'imageUrl': imageUrl,
        'times': selectedTimes,
        'time1': selectedTime1,
        'time2':
            selectedFrequency == 'مرتين يوميًا' ||
                selectedFrequency == 'ثلاث مرات يوميًا'
            ? selectedTime2
            : null,
        'time3': selectedFrequency == 'ثلاث مرات يوميًا' ? selectedTime3 : null,
        'isActive': true,
        'isTaken': false,
        'taken': false,
        'lastTakenDateKey': '',
        'createdDateKey': _todayKey(),
        'allergyWarning': allergyWarning != null,
        'allergyWarningMessage': allergyWarning?['message'],
        'allergyWarningName': allergyWarning?['allergyName'],
        'createdAt': FieldValue.serverTimestamp(),
      };

      final medicationRef = await FirebaseFirestore.instance
          .collection('medications')
          .add(medicationData);

      await NotificationService.scheduleMedicationReminders(
        medicationId: medicationRef.id,
        medicationName: name,
        selectedTimes: selectedTimes,
      );

      try {
        await addNotification(
          title: 'موعد الدواء',
          message: selectedTimes.isEmpty
              ? 'تمت إضافة دواء $name ويستخدم عند الحاجة'
              : 'تمت إضافة دواء $name، موعده: ${selectedTimes.join('، ')}',
          type: 'medication',
          patientId: currentUser.uid,
          patientName: patientName,
          patientPhone: patientPhone,
          caregiverId: caregiverId,
          doctorId: doctorId,
          recipientId: currentUser.uid,
          extra: {
            'time': selectedTimes.isEmpty ? 'عند الحاجة' : selectedTimes.first,
            'medicationName': name,
          },
        );

        if (caregiverId.isNotEmpty) {
          await addNotification(
            title: 'دواء جديد للمريض',
            message: 'تمت إضافة دواء $name للمريض $patientName',
            type: 'medication',
            patientId: currentUser.uid,
            patientName: patientName,
            patientPhone: patientPhone,
            caregiverId: caregiverId,
            doctorId: doctorId,
            recipientId: caregiverId,
            extra: {'medicationName': name},
          );
        }

        if (allergyWarning != null) {
          final warningMessage =
              '${allergyWarning['message']} المريض لديه حساسية: ${allergyWarning['allergyName']}.';

          await addNotification(
            title: 'تحذير حساسية دواء',
            message: warningMessage,
            type: 'allergy_warning',
            patientId: currentUser.uid,
            patientName: patientName,
            patientPhone: patientPhone,
            caregiverId: caregiverId,
            doctorId: doctorId,
            recipientId: currentUser.uid,
            extra: {
              'medicationName': name,
              'allergyName': allergyWarning['allergyName'],
              'allergyMessage': allergyWarning['message'],
            },
          );

          if (caregiverId.isNotEmpty) {
            await addNotification(
              title: 'تحذير حساسية دواء',
              message: 'تنبيه للمريض $patientName: $warningMessage',
              type: 'allergy_warning',
              patientId: currentUser.uid,
              patientName: patientName,
              patientPhone: patientPhone,
              caregiverId: caregiverId,
              doctorId: doctorId,
              recipientId: caregiverId,
              extra: {
                'medicationName': name,
                'allergyName': allergyWarning['allergyName'],
                'allergyMessage': allergyWarning['message'],
              },
            );
          }

          if (doctorId.isNotEmpty) {
            await addNotification(
              title: 'تحذير حساسية دواء',
              message:
                  'المريض $patientName أضاف دواء قد يتعارض مع الحساسية: $name',
              type: 'allergy_warning',
              patientId: currentUser.uid,
              patientName: patientName,
              patientPhone: patientPhone,
              caregiverId: caregiverId,
              doctorId: doctorId,
              recipientId: doctorId,
              extra: {
                'medicationName': name,
                'allergyName': allergyWarning['allergyName'],
                'allergyMessage': allergyWarning['message'],
              },
            );
          }
        }
      } catch (e) {
        debugPrint('Medication notification document error: $e');
      }

      if (!mounted) return;

      showMessage(
        allergyWarning == null
            ? 'تم حفظ الدواء وإضافة التنبيه بنجاح 💙'
            : 'تم حفظ الدواء مع وجود تحذير حساسية ⚠️',
        allergyWarning == null,
      );

      Navigator.pop(context);
    } catch (e) {
      debugPrint('Save medication error: $e');
      if (!mounted) return;
      showMessage('حدث خطأ أثناء الحفظ، تأكد من الإنترنت و Firebase', false);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void showMessage(String message, bool success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.right,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Cairo',
          ),
        ),
        backgroundColor: success
            ? const Color(0xFF2E7D32)
            : const Color(0xFFD32F2F),
      ),
    );
  }

  InputDecoration inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w900,
        color: Colors.black,
        fontFamily: 'Cairo',
      ),
      floatingLabelStyle: const TextStyle(
        fontSize: 21,
        fontWeight: FontWeight.w900,
        color: Color(0xFF1E3A5F),
        fontFamily: 'Cairo',
      ),
      prefixIcon: Icon(icon, color: const Color(0xFF1E3A5F), size: 31),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.4),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: const BorderSide(color: Color(0xFF1E3A5F), width: 2),
      ),
    );
  }

  Widget buildDropdown({
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      dropdownColor: Colors.white,
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: Color(0xFF1E3A5F),
        size: 34,
      ),
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w900,
        color: Colors.black,
        fontFamily: 'Cairo',
      ),
      decoration: inputDecoration(label: label, icon: icon),
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(
            item,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w900,
              color: Colors.black,
              fontFamily: 'Cairo',
            ),
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w900,
        color: Colors.black,
        fontFamily: 'Cairo',
      ),
      decoration: inputDecoration(label: label, icon: icon),
    );
  }

  Widget buildTipCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2FA),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD7E6F5), width: 1.2),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تذكير ذكي وآمن 💙',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A5F),
                    fontFamily: 'Cairo',
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'قم بإضافة تفاصيل الدواء ليقوم تطبيق MyCare بتذكيرك بموعد الدواء بكل سهولة وأمان.',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                    height: 1.6,
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 14),
          CircleAvatar(
            radius: 25,
            backgroundColor: Color(0xFF1E3A5F),
            child: Icon(
              Icons.health_and_safety_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildImagePickerCard() {
    return InkWell(
      onTap: pickMedicationImage,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1.4),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: const Color(0xFFEAF2FA),
              backgroundImage: selectedImage != null
                  ? FileImage(selectedImage!)
                  : null,
              child: selectedImage == null
                  ? const Icon(
                      Icons.add_a_photo_rounded,
                      color: Color(0xFF1E3A5F),
                      size: 32,
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                'إضافة صورة الدواء',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                  fontFamily: 'Cairo',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildReminderPreview() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundColor: Color(0xFFEAF2FA),
            child: Icon(
              Icons.notifications_active_rounded,
              color: Color(0xFF1E3A5F),
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              getReminderPreviewText(),
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                height: 1.7,
                fontFamily: 'Cairo',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTimeFields() {
    if (selectedFrequency == 'عند الحاجة') {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        buildDropdown(
          label: selectedFrequency == 'مرة يوميًا'
              ? 'وقت الدواء'
              : 'وقت الجرعة الأولى',
          icon: Icons.wb_sunny_rounded,
          value: selectedTime1,
          items: times,
          onChanged: (value) {
            setState(() => selectedTime1 = value!);
          },
        ),
        if (selectedFrequency == 'ثلاث مرات يوميًا') ...[
          const SizedBox(height: 16),
          buildDropdown(
            label: 'وقت الجرعة الثانية',
            icon: Icons.wb_twilight_rounded,
            value: selectedTime3,
            items: times,
            onChanged: (value) {
              setState(() => selectedTime3 = value!);
            },
          ),
        ],
        if (selectedFrequency == 'مرتين يوميًا' ||
            selectedFrequency == 'ثلاث مرات يوميًا') ...[
          const SizedBox(height: 16),
          buildDropdown(
            label: selectedFrequency == 'مرتين يوميًا'
                ? 'وقت الجرعة الثانية'
                : 'وقت الجرعة الثالثة',
            icon: Icons.nightlight_round,
            value: selectedTime2,
            items: times,
            onChanged: (value) {
              setState(() => selectedTime2 = value!);
            },
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF7F8FA),
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'إضافة دواء',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
              fontFamily: 'Cairo',
            ),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                buildTipCard(),
                const SizedBox(height: 16),
                buildVoiceAssistantCard(),
                const SizedBox(height: 20),
                buildImagePickerCard(),
                const SizedBox(height: 16),
                buildTextField(
                  controller: nameController,
                  label: 'اسم الدواء',
                  icon: Icons.medication_outlined,
                ),
                const SizedBox(height: 16),
                buildDropdown(
                  label: 'الجرعة',
                  icon: Icons.medical_services_outlined,
                  value: selectedDose,
                  items: doses,
                  onChanged: (value) {
                    setState(() => selectedDose = value!);
                  },
                ),
                const SizedBox(height: 16),
                buildDropdown(
                  label: 'عدد مرات الاستخدام',
                  icon: Icons.repeat_rounded,
                  value: selectedFrequency,
                  items: frequencies,
                  onChanged: (value) {
                    setState(() => selectedFrequency = value!);
                  },
                ),
                const SizedBox(height: 16),
                buildTimeFields(),
                if (selectedFrequency != 'عند الحاجة')
                  const SizedBox(height: 16),
                buildDropdown(
                  label: 'طريقة الاستخدام',
                  icon: Icons.restaurant_rounded,
                  value: selectedPeriod,
                  items: periods,
                  onChanged: (value) {
                    setState(() => selectedPeriod = value!);
                  },
                ),
                const SizedBox(height: 16),
                buildDropdown(
                  label: 'مدة الاستخدام',
                  icon: Icons.calendar_month_rounded,
                  value: selectedDuration,
                  items: durations,
                  onChanged: (value) {
                    setState(() => selectedDuration = value!);
                  },
                ),
                const SizedBox(height: 16),
                buildDropdown(
                  label: 'أهمية الدواء',
                  icon: Icons.priority_high_rounded,
                  value: selectedImportance,
                  items: importanceLevels,
                  onChanged: (value) {
                    setState(() => selectedImportance = value!);
                  },
                ),
                const SizedBox(height: 16),
                buildTextField(
                  controller: remainingPillsController,
                  label: 'عدد الحبات المتبقية',
                  icon: Icons.inventory_2_rounded,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                buildTextField(
                  controller: notesController,
                  label: 'ملاحظات الدواء',
                  icon: Icons.notes_rounded,
                  maxLines: 3,
                ),
                const SizedBox(height: 20),
                buildReminderPreview(),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 62,
                  child: ElevatedButton.icon(
                    onPressed: isLoading ? null : saveMedication,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A5F),
                      disabledBackgroundColor: Colors.grey,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    icon: isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Icon(
                            Icons.save_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                    label: Text(
                      isLoading ? 'جاري الحفظ...' : 'حفظ الدواء',
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
