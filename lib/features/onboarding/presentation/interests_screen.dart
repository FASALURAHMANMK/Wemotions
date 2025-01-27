import 'package:flutter/material.dart';
import 'package:Wemotions/features/homescreen/home_screen.dart';

class InterestsScreen extends StatefulWidget {
  final Function(int) updatePage;
  const InterestsScreen({Key? key, required this.updatePage}) : super(key: key);

  @override
  State<InterestsScreen> createState() => _InterestsScreenState();
}

class _InterestsScreenState extends State<InterestsScreen> {
  final List<String> _interests = [
    'Technology',
    'Photography',
    'Books & Literature',
    'Business & Entrepreneurship',
    'Food & Cooking',
    'Travel & Adventure',
    'Gaming',
    'Art & Design',
    'Film & Entertainment',
    'Music',
    'Parenting & Family',
    'Science & Innovation',
    'Education & Learning',
    'Sports',
    'Cars',
    'Pets',
  ];

  final Set<String> _selectedInterests = {};

  void _toggleInterest(String interest) {
    setState(() {
      if (_selectedInterests.contains(interest)) {
        _selectedInterests.remove(interest);
      } else {
        _selectedInterests.add(interest);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    final bool isButtonEnabled = _selectedInterests.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            widget.updatePage(1);
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
              );
            },
            child: const Text(
              'Skip',
            ),
          )
        ],
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: size.width * 0.06),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Your Interests',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose your favorite topics and interests to see the content that matters most to you.',
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _interests.map((interest) {
                final isSelected = _selectedInterests.contains(interest);
                return GestureDetector(
                  onTap: () => _toggleInterest(interest),
                  child: Chip(
                    label: Text(interest),
                    backgroundColor: isSelected ? Colors.purple : Colors.white10,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16), // Increased corner radius
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Align(
                alignment: Alignment.bottomRight,
                child: SizedBox(
                  width: 130,
                  height: 56,
                  child: FloatingActionButton(
                    backgroundColor:
                        isButtonEnabled ? const Color.fromRGBO(147, 54, 231, 1) : const Color.fromRGBO(233, 214, 254, 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onPressed: isButtonEnabled
                        ? () {
                            Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
              );
                          }
                        : null,
                    child: const Text(
                      'Next',
                      style: TextStyle(
                        fontSize: 16,
                        color:Colors.white,
                        fontWeight: FontWeight.bold
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}