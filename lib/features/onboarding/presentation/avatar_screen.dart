import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AvatarScreen extends StatefulWidget {
  final Function(int) updatePage;
  final String username;
  const AvatarScreen({Key? key, required this.updatePage,required this.username}) : super(key: key);

  @override
  State<AvatarScreen> createState() => _AvatarScreenState();
}

class _AvatarScreenState extends State<AvatarScreen> {
  ImageProvider<Object>? _profileImage;
  bool isImageSelected = false;

  Future<void> _selectImage(BuildContext context) async {
    final picker = ImagePicker();
    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => Navigator.pop(context, 'camera'),
                  child: const Column(
                    children: [
                      Icon(Icons.camera_alt, size: 40.0), // Camera Icon
                      SizedBox(height: 2.0), // Spacing between icon and label
                      Text('Camera'), // Optional label
                    ],
                  ),
                ),
                const SizedBox(width: 24.0), // Spacing between icons
                GestureDetector(
                  onTap: () => Navigator.pop(context, 'gallery'),
                  child: const Column(
                    children: [
                      Icon(Icons.photo_library, size: 40.0), // Gallery Icon
                      SizedBox(height: 2.0), // Spacing between icon and label
                      Text('Photos'), // Optional label
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    if (result == 'camera') {
      final pickedFile = await picker.pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        setState(() {
          _profileImage = FileImage(File(pickedFile.path));
          isImageSelected = true;
        });
      }
    } else if (result == 'gallery') {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _profileImage = FileImage(File(pickedFile.path));
          isImageSelected = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            widget.updatePage(0);
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              widget.updatePage(2);
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
          children: [
            const Text(
              'Set Your Profile Picture',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            const Text(
              'Upload a profile picture to represent yourself in the community.',
              style: TextStyle(fontSize: 16, color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // Profile Picture Circle
            const SizedBox(height: 16),
            // Camera Button
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      const CircleAvatar(
                        radius: 85,
                        backgroundColor: Color.fromRGBO(147, 54, 231, 1),
                      ),
                      CircleAvatar(
                        radius: 80,
                        backgroundColor: const Color.fromRGBO(147, 54, 231, 1),
                        backgroundImage: _profileImage,
                        child: _profileImage == null
                            ? const Icon(Icons.person, size: 120, color: Colors.white)
                            : null,
                      ),
                    ],
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () => _selectImage(context),
                      child: const CircleAvatar(
                        radius: 18,
                        backgroundColor: Color.fromRGBO(67, 188, 255, 1),
                        child: Icon(Icons.add, color: Colors.white, size: 35),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.username,
              style: const TextStyle(fontSize: 18,color: Colors.white,fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 272),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Align(
                alignment: Alignment.bottomRight,
                child: SizedBox(
                  width: 130,
                  height: 56,
                  child: FloatingActionButton(
                    backgroundColor:
                        isImageSelected ? const Color.fromRGBO(147, 54, 231, 1) : const Color.fromRGBO(233, 214, 254, 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onPressed: isImageSelected
                        ? () {
                            widget.updatePage(2);
                          }
                        : null,
                    child: const Text(
                      'Next',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
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