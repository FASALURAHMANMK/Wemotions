import 'package:flutter/material.dart';
import 'dart:async';

import 'package:Wemotions/features/auth/presentation/set_new_password.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({Key? key}) : super(key: key);

  @override
  _OtpVerificationScreenState createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _otpControllers =
      List.generate(5, (index) => TextEditingController());
  int _timer = 59; // Countdown timer in seconds
  late Timer _countdownTimer;
  bool _isResendEnabled = false;
  bool _isButtonEnabled = false;

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
          _isResendEnabled = true;
        });
        _countdownTimer.cancel();
      }
    });
  }

  void _checkOtpComplete() {
    final isComplete = _otpControllers.every((controller) => controller.text.isNotEmpty);
    setState(() {
      _isButtonEnabled = isComplete;
    });
  }

  @override
  void dispose() {
    _countdownTimer.cancel();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
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
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: size.width * 0.06),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Verify this account',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Check your email for a verification code to reset password.',
                style: TextStyle(fontSize: 16, color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              // OTP Fields
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  5,
                  (index) => _buildOtpField(index),
                ),
              ),
              const SizedBox(height: 16),
              // Timer
              Text(
                'Remaining time: 00:${_timer.toString().padLeft(2, '0')}s',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Didn't receive a code? ",
                    style: TextStyle(fontSize: 14, color: Colors.white),
                  ),
                  TextButton(
                    onPressed: _isResendEnabled
                        ? () {
                            setState(() {
                              _timer = 59;
                              _isResendEnabled = false;
                              _startCountdown();
                            });
                          }
                        : null,
                    style: TextButton.styleFrom(
                      foregroundColor: _isResendEnabled
                          ? const Color.fromRGBO(147, 54, 231, 1)
                          : Colors.grey,
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text(
                      "Resend",
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // Verify Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isButtonEnabled
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const NewPasswordScreen()),
                          );
                        }
                      : null,
                  style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.disabled)) {
                    return const Color.fromRGBO(233, 214, 254, 1); // Disabled state color
                  }
                  return const Color.fromRGBO(147, 54, 231, 1); // Enabled state color
                }),
                padding: WidgetStateProperty.all(
                  const EdgeInsets.symmetric(vertical: 16),
                ),
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
                  child: const Text(
                    'Verify your account',
                    style: TextStyle(
                      fontSize: 16,
                      color:  Colors.white,
                      fontWeight: FontWeight.bold,
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

  Widget _buildOtpField(int index) {
    return SizedBox(
      width: 48,
      child: TextField(
        controller: _otpControllers[index],
        keyboardType: TextInputType.number,
        maxLength: 1,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white, fontSize: 18),
        decoration: InputDecoration(
          counterText: '',
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.white24),
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Color.fromRGBO(147, 54, 231, 1)),
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: Colors.white10,
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < 4) {
            FocusScope.of(context).nextFocus();
          } else if (value.isEmpty && index > 0) {
            FocusScope.of(context).previousFocus();
          }
          _checkOtpComplete();
        },
      ),
    );
  }
}