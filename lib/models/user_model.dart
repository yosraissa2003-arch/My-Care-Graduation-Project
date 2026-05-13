class UserModel {
  // 🔹 بيانات أساسية
  String name;
  String phone;
  String age;

  // 🔹 بيانات صحية
  String weight;
  String height;
  List<String> diseases;
  String allergy;
  String surgery;

  // 🔹 بيانات الطوارئ
  String address;
  String emergencyNumbers;
  String doctorName;
  String doctorPhone;

  // 🔹 المرافقين
  List caregivers;

  UserModel({
    required this.name,
    required this.phone,
    required this.age,
    required this.weight,
    required this.height,
    required this.diseases,
    required this.allergy,
    required this.surgery,
    required this.address,
    required this.emergencyNumbers,
    required this.doctorName,
    required this.doctorPhone,
    required this.caregivers,
  });

  // 🔥 تحويل البيانات إلى Map (عشان Firebase)
  Map<String, dynamic> toMap() {
    return {
      "name": name,
      "phone": phone,
      "age": age,
      "weight": weight,
      "height": height,
      "diseases": diseases,
      "allergy": allergy,
      "surgery": surgery,
      "address": address,
      "emergencyNumbers": emergencyNumbers,
      "doctorName": doctorName,
      "doctorPhone": doctorPhone,
      "caregivers": caregivers,
    };
  }
}