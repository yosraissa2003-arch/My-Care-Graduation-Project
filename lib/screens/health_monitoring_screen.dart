import 'package:flutter/material.dart';

class HealthMonitoringScreen extends StatelessWidget {
  const HealthMonitoringScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final readings = [
      {
        'title': 'نبض القلب',
        'value': '78',
        'unit': 'نبضة/دقيقة',
        'icon': Icons.favorite_outline,
        'color': const Color(0xFFD32F2F),
      },
      {
        'title': 'نسبة الأكسجين',
        'value': '96',
        'unit': '%',
        'icon': Icons.air,
        'color': const Color(0xFF1E3A5F),
      },
      {
        'title': 'درجة الحرارة',
        'value': '36.8',
        'unit': '°C',
        'icon': Icons.thermostat_outlined,
        'color': const Color(0xFFED6C02),
      },
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF7F8FA),
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'مراقبة الصحة',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Color(0xFF111827),
              fontFamily: 'Cairo',
            ),
          ),
          iconTheme: const IconThemeData(color: Color(0xFF111827)),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // 🔵 العنوان العلوي
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A5F),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Text(
                  'آخر القراءات الصحية',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 📋 القراءات
              Expanded(
                child: ListView.separated(
                  itemCount: readings.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final item = readings[index];

                    return HealthCard(
                      title: item['title'] as String,
                      value: item['value'] as String,
                      unit: item['unit'] as String,
                      icon: item['icon'] as IconData,
                      color: item['color'] as Color,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HealthCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;

  const HealthCard({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // 🔵 الأيقونة
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: color, size: 32),
          ),

          const SizedBox(width: 16),

          // 📝 النص
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                    fontFamily: 'Cairo',
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  unit,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6B7280),
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
          ),

          // 📊 القيمة
          Text(
            value,
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              color: color,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }
}
