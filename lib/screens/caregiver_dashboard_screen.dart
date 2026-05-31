import 'package:flutter/material.dart';

class CaregiverDashboardScreen extends StatelessWidget {
  const CaregiverDashboardScreen({super.key});

  static const Color primaryColor = Color(0xFF1E3A5F);
  static const Color backgroundColor = Color(0xFFF7F8FA);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: primaryColor,
          title: const Text(
            'لوحة المرافق',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        body: const Center(
          child: Text(
            'هنا ستظهر حالة المرضى والتنبيهات وطلبات SOS',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
        ),
      ),
    );
  }
}
