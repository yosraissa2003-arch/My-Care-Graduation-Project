class MedicalCenter {
  final String id;
  final String name;
  final String category;
  final String categoryAr;
  final String facilityType;
  final String ownership;
  final String sector;
  final String city;
  final String governorate;
  final double latitude;
  final double longitude;
  final String emergencyPhone;
  final String source;

  double? distanceKm;

  MedicalCenter({
    required this.id,
    required this.name,
    required this.category,
    required this.categoryAr,
    required this.facilityType,
    required this.ownership,
    required this.sector,
    required this.city,
    required this.governorate,
    required this.latitude,
    required this.longitude,
    required this.emergencyPhone,
    required this.source,
    this.distanceKm,
  });

  factory MedicalCenter.fromJson(Map<String, dynamic> json) {
    return MedicalCenter(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      categoryAr: json['categoryAr']?.toString() ?? '',
      facilityType: json['facilityType']?.toString() ?? '',
      ownership: json['ownership']?.toString() ?? '',
      sector: json['sector']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      governorate: json['governorate']?.toString() ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      emergencyPhone: json['emergencyPhone']?.toString() ?? '101',
      source: json['source']?.toString() ?? '',
    );
  }
}
