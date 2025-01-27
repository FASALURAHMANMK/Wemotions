import 'package:flutter/material.dart';
import 'username_screen.dart';
import 'avatar_screen.dart';
import 'interests_screen.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({Key? key}) : super(key: key);

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  int _currentPage = 0;
  String _currentusername = "";

  /// This function updates the progress bar by setting the current page index.
  void updatePage(int pageIndex) {
    setState(() {
      _currentPage = pageIndex;
    });
  }
   void updateUsername(String name) {
    setState(() {
      _currentusername = name;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
      if (_currentPage == 0)
            UsernameScreen(updatePage: updatePage,updateUsername:updateUsername),
          if (_currentPage == 1)
            AvatarScreen(updatePage: updatePage,username: _currentusername,),
          if (_currentPage == 2)
            InterestsScreen(updatePage: updatePage),
          Positioned(
            bottom: 50,
            left: 30,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildProgressIndicator(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                value: (_currentPage + 1) / 3,
                backgroundColor: Colors.white,
                strokeWidth: 8,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Color.fromRGBO(147, 54, 231, 1)),
              ),
            ),
            Text(
              '${_currentPage + 1} / 3',
              style: const TextStyle(fontSize: 12, color: Colors.white),
            ),
          ],
        ),
      ],
    );
  }
}