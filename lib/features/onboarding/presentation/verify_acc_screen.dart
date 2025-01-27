import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:Wemotions/features/auth/presentation/login_screen.dart';

class VerifyAccountScreen extends StatefulWidget {
  final String email;
  const VerifyAccountScreen({Key? key, required this.email}) : super(key: key);

  @override
  State<VerifyAccountScreen> createState() => _VerifyAccountScreenState();
}

class _VerifyAccountScreenState extends State<VerifyAccountScreen> {
  int _timer = 60; // Countdown timer in seconds
  late Timer _countdownTimer; // Timer instance
  bool _isResendEnabled = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timer > 0) {
        setState(() {
          _timer--;
        });
      } else {
        setState(() {
          _isResendEnabled = true; // Enable "Resend Email" button
        });
        _countdownTimer.cancel(); // Stop the timer
      }
    });
  }

  Future<void> _resendVerificationEmail() async {
    var request = http.Request(
      'POST',
      Uri.parse('https://api.wemotions.app/user/resend-verification-email'),
    );

    request.body = json.encode({"mixed": widget.email});
    request.headers.addAll({'Content-Type': 'application/json'});

    try {
      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final responseJson = json.decode(responseBody);

        if (responseJson['message'] == "This email is already verified.") {
          _showDialog(
            title: "Email Verified",
            content:
                "This email is already verified. You can now log in to your account.",
            showLoginButton: true,
          );
        } else {
          _showDialog(
            title: "Success",
            content: "Verification email sent successfully!",
            showLoginButton: false,
          );
        }
      } else {
        _showDialog(
          title: "Error",
          content: "Failed to send verification email. Please try again.",
          showLoginButton: false,
        );
      }
    } catch (e) {
      _showDialog(
        title: "Error",
        content: "An error occurred. Please try again.",
        showLoginButton: false,
      );
    }
  }

  void _showDialog({
    required String title,
    required String content,
    required bool showLoginButton,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(
            children: [
              Icon(
                showLoginButton ? Icons.info : Icons.check_circle,
                color: Colors.green,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
          content: Text(
            content,
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            if (showLoginButton)
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                child: const Text(
                  "Login",
                  style: TextStyle(color: Colors.green),
                ),
              ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                "OK",
                style: TextStyle(color: Colors.green),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _countdownTimer.cancel(); // Cancel the timer to prevent memory leaks
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: size.width * 0.06),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              const Text(
                'Verify Your Account',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Please verify your account by clicking the link we sent to your email.',
                style: TextStyle(fontSize: 16, color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Expanded(
                child: Image.asset(
                  'assets/images/mail.png', // Add illustration
                  height: 200,
                  width: 200,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '00:${_timer.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    ); // Navigate to Login Screen
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(147, 54, 231, 1),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Login',
                    style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _isResendEnabled ? _resendVerificationEmail : null,
                style: TextButton.styleFrom(
                  foregroundColor:
                      _isResendEnabled ? Colors.white : Colors.grey,
                ),
                child: const Text(
                  'Resend Email',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}