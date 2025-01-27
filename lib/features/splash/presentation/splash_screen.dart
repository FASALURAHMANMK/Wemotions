import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:Wemotions/features/homescreen/home_screen.dart';
import 'package:Wemotions/features/onboarding/presentation/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animationW;
  late Animation<Offset> _animationM;

  @override
  void initState() {
    super.initState();

    // Initialize the animation controller
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1), // Duration of the animation
    );

    // Define animations for the W and M images
    _animationW = Tween<Offset>(
      begin: const Offset(0.0, -1.5), // Start outside the screen
      end: Offset.zero, // End at the center
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _animationM = Tween<Offset>(
      begin: const Offset(0.0, 1.5), // Start outside the screen
      end: Offset.zero, // End at the center
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // Start the animation
    _controller.forward();

    // Navigate to the next screen after a delay
    Future.delayed(const Duration(seconds: 2), () {
      _checkLoginStatus(context);
    });
  }

  Future<void> _checkLoginStatus(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? flicToken = prefs.getString('flic_token');
    bool isLoggedIn = prefs.getBool('is_logged_in') ?? false;

    if (flicToken != null && isLoggedIn) {
      // Navigate to HomeScreen if the user is logged in
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      // Navigate to OnboardingScreen if not logged in
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: Stack(
              children: [
                SlideTransition(
                  position: _animationW,
                  child: Image.asset(
                    'assets/images/w.png', // Place your "W" logo here
                    height: 124,
                    width: 226,
                  ),
                ),
                SlideTransition(
                  position: _animationM,
                  child: Image.asset(
                    'assets/images/m.png', // Place your "M" logo here
                    height: 124,
                    width: 226,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}