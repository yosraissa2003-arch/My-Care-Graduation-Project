import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:geolocator/geolocator.dart';
import '../models/medical_center.dart';

class MedicalCentersService {
  static const String _assetPath = 'assets/data/medical_centers.json';

  Future<List<MedicalCenter>> loadCenters() async {
    final String jsonString = await rootBundle.loadString(_assetPath);
    final List<dynamic> decoded = jsonDecode(jsonString);
    return decoded
        .map((item) => MedicalCenter.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Position> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location service is disabled');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('Location permission denied');
    }

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<List<MedicalCenter>> getNearbyCenters({
    double? patientLat,
    double? patientLng,
    int limit = 10,
    double? maxDistanceKm,
  }) async {
    double lat;
    double lng;

    if (patientLat != null && patientLng != null) {
      lat = patientLat;
      lng = patientLng;
    } else {
      final Position position = await getCurrentPosition();
      lat = position.latitude;
      lng = position.longitude;
    }

    final centers = await loadCenters();

    for (final center in centers) {
      final double meters = Geolocator.distanceBetween(
        lat,
        lng,
        center.latitude,
        center.longitude,
      );
      center.distanceKm = meters / 1000.0;
    }

    centers.sort((a, b) => (a.distanceKm ?? 999999).compareTo(b.distanceKm ?? 999999));

    final filtered = maxDistanceKm == null
        ? centers
        : centers.where((center) => (center.distanceKm ?? 999999) <= maxDistanceKm).toList();

    return filtered.take(limit).toList();
  }
}
