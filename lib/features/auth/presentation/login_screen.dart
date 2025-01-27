import 'package:Wemotions/features/homescreen/home_screen.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:Wemotions/features/auth/presentation/forgot_password.dart';
import 'package:Wemotions/features/onboarding/presentation/onboarding_flow.dart';
import 'package:Wemotions/features/onboarding/presentation/onboarding_screen.dart';
import 'package:Wemotions/features/onboarding/presentation/sign_up_screen.dart';
import 'package:Wemotions/features/onboarding/presentation/verify_acc_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  bool _isButtonEnabled = false;
  bool _isPasswordVisible = false;
  bool _isError = false;

  void _updateButtonState() {
    setState(() {
      _isButtonEnabled =
          _emailController.text.isNotEmpty && _passwordController.text.isNotEmpty;
    });
  }

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_updateButtonState);
    _passwordController.addListener(_updateButtonState);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _saveTokenAndState(String token,String username) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('flic_token', token);
    await prefs.setString('username', username);  // Save the token
    await prefs.setBool('is_logged_in', true); // Save the logged-in state
  }

  Future<void> _login() async {
    setState(() {
      _isError = false;
    });

    var request = http.Request(
      'POST',
      Uri.parse('https://api.wemotions.app/user/login'),
    );

    request.body = json.encode({
      "mixed": _emailController.text,
      "password": _passwordController.text,
      "app_name": "wemotions"
    });

    request.headers.addAll({'Content-Type': 'application/json'});

    try {
      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final responseJson = json.decode(responseBody);

        String token = responseJson["token"];
        String username = responseJson["username"] ?? "";
        bool isVerified = true;
        //bool isVerified = responseJson["isVerified"] ?? false;

        // Save token and logged-in state
        await _saveTokenAndState(token,username);

        if (username.startsWith("New_") && isVerified) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const OnboardingFlow()),
          );
        } else if (username.startsWith("New_") && !isVerified) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => VerifyAccountScreen(email: responseJson["email"]),
            ),
          );
        } else {
         Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
              (Route<dynamic> route) => false, // This removes all previous routes
            );
        }
      } else {
        setState(() {
          _isError = true;
        });
      }
    } catch (e) {
      setState(() {
        _isError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OnboardingScreen()),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SignUpScreen()),
              );
            },
            child: const Text(
              'Sign up',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: size.width * 0.06),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Login',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Log in to join the conversation and connect with your community',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            // Email/Username Input Field
            TextField(
              controller: _emailController,
              focusNode: _emailFocus,
              decoration: InputDecoration(
                labelText: 'Email or Username',
                labelStyle: TextStyle(
                  color: _emailFocus.hasFocus ? Colors.grey : Colors.grey,
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: _isError ? Colors.red : const Color.fromRGBO(147, 54, 231, 1), width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: _isError ? Colors.red : Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Password Input Field
            TextField(
              controller: _passwordController,
              focusNode: _passwordFocus,
              obscureText: !_isPasswordVisible,
              decoration: InputDecoration(
                labelText: 'Password',
                labelStyle: TextStyle(
                  color: _passwordFocus.hasFocus ? Colors.grey : Colors.grey,
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: _isError ? Colors.red : const Color.fromRGBO(147, 54, 231, 1), width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: _isError ? Colors.red : Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                  );
                },
                child: const Text(
                  'Forgot password?',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Continue Button
            ElevatedButton(
              onPressed: _isButtonEnabled ? _login : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isButtonEnabled
                    ? const Color.fromRGBO(147, 54, 231, 1)
                    : const Color.fromRGBO(233, 214, 254, 1),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Center(
                child: Text(
                  'Continue',
                  style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}