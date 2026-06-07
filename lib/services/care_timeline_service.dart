import 'package:cloud_firestore/cloud_firestore.dart';

class CareTimelineService {
  static String todayKey([DateTime? date]) {
    final now = date ?? DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  static Future<void> addEvent({
    required String userId,
    required String title,
    required String type,
    String details = '',
    Map<String, dynamic>? extra,
  }) async {
    if (userId.trim().isEmpty) return;

    final now = DateTime.now();

    await FirebaseFirestore.instance.collection('careTimeline').add({
      'userId': userId,
      'patientId': userId,
      'title': title,
      'type': type,
      'details': details,
      'dateKey': todayKey(now),
      'createdAt': FieldValue.serverTimestamp(),
      if (extra != null) ...extra,
    });
  }

  static Future<void> updateLastActivity(String userId) async {
    if (userId.trim().isEmpty) return;

    await FirebaseFirestore.instance.collection('users').doc(userId).set({
      'lastActivityAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
