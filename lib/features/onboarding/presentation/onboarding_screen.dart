import 'package:flutter/material.dart';
import 'package:Wemotions/features/auth/presentation/login_screen.dart';
import 'package:Wemotions/common/widgets/custom_button.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             const SizedBox(height: 72),
            const Text(
              'Start the Dialogue with \n Voice & Video',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            Expanded(
              child: Image.asset(
                'assets/images/onboarding_illustration.png', // Add illustration
                height: 200,
              ),
            ),
            const Text(
              'Kick off conversations by sharing your thoughts with voice or video. Move beyond text and express yourself in a way that truly connects.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
           Column(
  crossAxisAlignment: CrossAxisAlignment.stretch, // Ensures full-width buttons
  children: [
    CustomButton(
      text: 'Continue with Email',
      onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
    ),
    const SizedBox(height: 16),
    OutlinedButton.icon(
      onPressed: () {
        // TODO: Implement Apple sign-in logic
      },
      icon: Image.asset('assets/images/apple.png', 
      color: Colors.white,
      height: 28,
      width: 28),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      label: const Text(
        'Continue with Apple',
        style: TextStyle(fontSize: 16, color: Colors.white,fontWeight: FontWeight.bold),
      ),
    ),
    const SizedBox(height: 16),
    OutlinedButton.icon(
      onPressed: () {
        // TODO: Implement Google sign-in logic
      },
      icon: Image.asset('assets/images/google.png', 
      color: Colors.white,
      height: 28,
      width: 28),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      label: const Text(
        'Continue with Google',
        style: TextStyle(fontSize: 16, color: Colors.white,fontWeight: FontWeight.bold),
      ),
    ),
  ],
),
           
            const SizedBox(height: 25),
          ],
        ),
      ),
    );
  }
}