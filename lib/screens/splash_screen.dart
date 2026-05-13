import 'package:flutter/material.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoFade;
  late Animation<Offset> _logoSlide;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _logoFade = Tween<double>(begin: 0, end: 1).animate(_controller);

    _logoSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();

    // ⬇️ الانتقال للهوم بعد 3 ثواني
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget buildCircle(double size, Color color, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(opacity),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          color: Colors.white,
          child: Stack(
            children: [
              Positioned(
                top: -140,
                left: -140,
                child: buildCircle(
                  320,
                  const Color.fromARGB(255, 85, 177, 182),
                  0.25,
                ),
              ),
              Positioned(
                top: -100,
                left: -100,
                child: buildCircle(220, const Color(0xFF6BA8A9), 0.25),
              ),
              Positioned(
                bottom: -140,
                right: -140,
                child: buildCircle(
                  300,
                  const Color.fromARGB(255, 90, 189, 191),
                  0.20,
                ),
              ),
              Positioned(
                bottom: -90,
                right: -90,
                child: buildCircle(
                  200,
                  const Color.fromARGB(255, 83, 135, 142),
                  0.20,
                ),
              ),
              Center(
                child: FadeTransition(
                  opacity: _logoFade,
                  child: SlideTransition(
                    position: _logoSlide,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'My',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 46,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Stack(
                                children: [
                                  Image.asset(
                                    'assets/C.png',
                                    width: 92,
                                    height: 92,
                                  ),
                                  Positioned(
                                    top: 34,
                                    left: 25,
                                    child: Image.asset(
                                      'assets/heart.png',
                                      width: 42,
                                      height: 42,
                                    ),
                                  ),
                                ],
                              ),
                              Transform.translate(
                                offset: const Offset(-10, 0),
                                child: const Text(
                                  'are',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 46,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'صحتك أولويتنا',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 30,
                            color: Colors.black,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
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
}
