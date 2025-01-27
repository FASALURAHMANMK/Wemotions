import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class UsernameScreen extends StatelessWidget {
  final Function(int) updatePage;
  final Function(String) updateUsername;
  const UsernameScreen({Key? key, required this.updatePage, required this.updateUsername}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final TextEditingController _usernameController = TextEditingController();
    final ValueNotifier<bool> isButtonEnabled = ValueNotifier(false);

    void _checkUsername() {
      isButtonEnabled.value = _usernameController.text.length >= 6;
    }

    _usernameController.addListener(_checkUsername);

    Future<void> _submitUsername(String username) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('flic_token');

  if (token == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Token not found. Please log in again."),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  var headers = {'Flic-Token': token, 'Content-Type': 'application/json'};
  var request = http.Request(
    'POST',
    Uri.parse('https://api.wemotions.app/user/username'),
  );

  request.body = json.encode({"new_username": username});
  request.headers.addAll(headers);

  try {
    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      print(responseBody);

      // Update the username in SharedPreferences
      await prefs.setString('username', username);

      // Update the page and username
      updatePage(1);
      updateUsername(username);
    } else {
      print(response.reasonPhrase);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${response.reasonPhrase}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  } catch (e) {
    print(e);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("An error occurred. Please try again."),
        backgroundColor: Colors.red,
      ),
    );
  }
}

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main content
          Padding(
            padding: EdgeInsets.symmetric(horizontal: size.width * 0.06),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 88),
                const Text(
                  'Choose Your Username',
                  style: TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Create a username that reflects you—make it memorable and stand out.',
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Enter your username',
                    labelStyle: const TextStyle(color: Colors.white70),
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
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          const Spacer(), // Push the button to align with the progress bar
          // Next Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 23.5, vertical: 21),
            child: Align(
              alignment: Alignment.bottomRight,
              child: SizedBox(
                width: 130,
                height: 56,
                child: ValueListenableBuilder<bool>(
                  valueListenable: isButtonEnabled,
                  builder: (context, isEnabled, child) {
                    return FloatingActionButton(
                      backgroundColor: isEnabled
                          ? const Color.fromRGBO(147, 54, 231, 1)
                          : const Color.fromRGBO(233, 214, 254, 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onPressed: isEnabled
                          ? () async {
                              await _submitUsername(_usernameController.text);
                            }
                          : null,
                      child: const Text(
                        'Next',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}