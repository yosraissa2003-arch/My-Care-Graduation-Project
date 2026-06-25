import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/medical_center.dart';
import '../services/medical_centers_service.dart';

class NearbyMedicalCentersSection extends StatefulWidget {
  final double? patientLat;
  final double? patientLng;
  final int limit;
  final String title;

  const NearbyMedicalCentersSection({
    super.key,
    this.patientLat,
    this.patientLng,
    this.limit = 5,
    this.title = 'أقرب المراكز الطبية',
  });

  @override
  State<NearbyMedicalCentersSection> createState() => _NearbyMedicalCentersSectionState();
}

class _NearbyMedicalCentersSectionState extends State<NearbyMedicalCentersSection> {
  late Future<List<MedicalCenter>> _futureCenters;
  final MedicalCentersService _service = MedicalCentersService();

  @override
  void initState() {
    super.initState();
    _futureCenters = _service.getNearbyCenters(
      patientLat: widget.patientLat,
      patientLng: widget.patientLng,
      limit: widget.limit,
    );
  }

  Future<void> _callEmergency(String phone) async {
    final Uri uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openMap(MedicalCenter center) async {
    final Uri uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${center.latitude},${center.longitude}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.local_hospital, color: Colors.red),
                  const SizedBox(width: 8),
                  Text(
                    widget.title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              FutureBuilder<List<MedicalCenter>>(
                future: _futureCenters,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Text(
                      'تعذر تحديد الموقع أو تحميل المراكز الطبية. تأكدي من تفعيل صلاحية الموقع.',
                      style: TextStyle(color: Colors.red.shade700),
                    );
                  }

                  final centers = snapshot.data ?? [];
                  if (centers.isEmpty) {
                    return const Text('لا يوجد مراكز طبية قريبة متاحة حالياً.');
                  }

                  return Column(
                    children: centers.map((center) => _buildCenterTile(center)).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenterTile(MedicalCenter center) {
    final String distance = center.distanceKm == null
        ? ''
        : '${center.distanceKm!.toStringAsFixed(1)} كم';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                center.category == 'Hospital' ? Icons.local_hospital : Icons.medical_services,
                color: center.category == 'Hospital' ? Colors.red : Colors.blue,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  center.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              Text(distance, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 5),
          Text('${center.categoryAr} • ${center.city} • ${center.governorate}'),
          if (center.sector.isNotEmpty) Text('القطاع: ${center.sector}'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openMap(center),
                  icon: const Icon(Icons.location_on),
                  label: const Text('الموقع'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _callEmergency(center.emergencyPhone),
                  icon: const Icon(Icons.call),
                  label: Text('طوارئ ${center.emergencyPhone}'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
