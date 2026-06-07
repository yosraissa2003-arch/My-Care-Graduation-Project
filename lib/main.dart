import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/notification_service.dart';

import 'screens/splash_screen.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

Future<void> saveFcmTokenForCurrentUser() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final token = await FirebaseMessaging.instance.getToken();
  if (token == null || token.isEmpty) return;

  await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
    'fcmToken': token,
    'fcmTokens': FieldValue.arrayUnion([token]),
    'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
}

Future<void> rescheduleMedicationRemindersForCurrentUser() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('medications')
        .where('userId', isEqualTo: user.uid)
        .where('isActive', isEqualTo: true)
        .get();

    int scheduledCount = 0;

    for (final doc in snapshot.docs) {
      final data = doc.data();

      final medicationName = (data['name'] ?? 'دواء').toString();
      final rawTimes = data['times'];

      final selectedTimes = rawTimes is List
          ? rawTimes
                .map((time) => time.toString())
                .where((time) => time.trim().isNotEmpty)
                .toList()
          : <String>[];

      if (selectedTimes.isEmpty) {
        continue;
      }

      await NotificationService.scheduleMedicationReminders(
        medicationId: doc.id,
        medicationName: medicationName,
        selectedTimes: selectedTimes,
      );

      scheduledCount += selectedTimes.length;
    }

    debugPrint(
      'Medication reminders rescheduled for ${snapshot.docs.length} medicines. Scheduled times: $scheduledCount',
    );
  } catch (e) {
    debugPrint('Reschedule medication reminders error: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  await NotificationService.init();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  FirebaseAuth.instance.authStateChanges().listen((user) async {
    if (user != null) {
      await saveFcmTokenForCurrentUser();
      await rescheduleMedicationRemindersForCurrentUser();
    }
  });

  FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || token.isEmpty) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'fcmToken': token,
      'fcmTokens': FieldValue.arrayUnion([token]),
      'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  });

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    NotificationService.showNotification(message);
  });

  runApp(const MyCareApp());
}

class MyCareApp extends StatelessWidget {
  const MyCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MyCare',
      theme: ThemeData(fontFamily: 'Cairo'),
      home: const SplashScreen(),
    );
  }
}
