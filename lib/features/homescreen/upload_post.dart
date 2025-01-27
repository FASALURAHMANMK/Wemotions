import 'dart:io';
import 'package:Wemotions/features/homescreen/home_screen.dart';
import 'package:Wemotions/features/homescreen/post.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:Wemotions/features/homescreen/search.dart';

class UploadReplyScreen extends StatefulWidget {
  final String videoPath;
  final String parentVideoId;

  const UploadReplyScreen(
      {super.key, required this.videoPath, required this.parentVideoId});

  @override
  _UploadReplyScreenState createState() => _UploadReplyScreenState();
}

class _UploadReplyScreenState extends State<UploadReplyScreen> {
  List<String> taggedPeople = [];
  late VideoPlayerController _videoController;
  bool _isLoading = false;
  String title = "video post";
  @override
  void initState() {
    super.initState();
    _videoController = VideoPlayerController.file(File(widget.videoPath))
      ..initialize().then((_) {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  void _openTagOverlay() async {
    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color.fromRGBO(41, 41, 41, 1),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return TagOverlay(
          initiallySelected:
              List<String>.from(taggedPeople), // Ensure a copy is passed
        );
      },
    );

    if (result != null && mounted) {
      // Ensure the widget is still active
      setState(() {
        taggedPeople = List<String>.from(result); // Safely update the list
      });
    }
  }

  void post() async {
    var videoPath = widget.videoPath;
    var parentVideoId = widget.parentVideoId;
    final result =
        await postVideo(videoPath, parentVideoId, taggedPeople, title);
    if (result['status'] == "success") {
      _showDialog();
    } else {
      _showDialog();
    }
    if (kDebugMode) {
      print(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const SizedBox(
                        height: 100), // For space below the "Upload Reply" text
                    Container(
                      height: 380, // Fixed height for the container
                      width: double.infinity, // Fixed width for the container
                      decoration: BoxDecoration(
                        color: Colors.black, // Background color
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          children: [
                            // Video player with preserved aspect ratio
                            Center(
                              child: FittedBox(
                                fit: BoxFit
                                    .contain, // Ensures the video fits inside the container
                                child: SizedBox(
                                  width: _videoController.value.isInitialized
                                      ? _videoController.value.size.width
                                      : 1, // Prevents issues before initialization
                                  height: _videoController.value.isInitialized
                                      ? _videoController.value.size.height
                                      : 1,
                                  child: AspectRatio(
                                    aspectRatio: _videoController
                                            .value.isInitialized
                                        ? _videoController.value.aspectRatio
                                        : 16 /
                                            9, // Default aspect ratio before initialization
                                    child: VideoPlayer(_videoController),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      maxLines: 4,
                      style: const TextStyle(color: Colors.white),
                      textInputAction:
                          TextInputAction.done, // Set the action to "Done"
                      onSubmitted: (value) {
                        setState(() {
                          title = value; // Start the loading animation
                        });
                        // Handle what happens when "Done" is pressed
                        FocusScope.of(context)
                            .unfocus(); // Dismiss the keyboard// Optional: Print the value
                      },
                      decoration: InputDecoration(
                        hintText: 'I hope you like this video',
                        hintStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: const Color.fromRGBO(41, 41, 41, 1),
                        border: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: Color.fromRGBO(147, 54, 231, 1),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _openTagOverlay,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.person_add, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'Tag people',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                          Text(
                            '${taggedPeople.length} people',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: 200,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading
                            ? null // Disable the button while loading
                            : () async {
                                FocusScope.of(context).unfocus();
                                setState(() {
                                  _isLoading =
                                      true; // Start the loading animation
                                });
                                post(); // Call the upload logic
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromRGBO(147, 54, 231, 1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Upload',
                            style:
                                TextStyle(fontSize: 16, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color:
                    Colors.black.withOpacity(0.6), // Semi-transparent overlay
                child: Center(
                  child: LoadingAnimationWidget.waveDots(
                    color: Colors.white,
                    size: 50.0,
                  ),
                ),
              ),
            ),
          Positioned(
            top: 60,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                const Text(
                  'Upload',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 24), // Placeholder for alignment
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding: const EdgeInsets.all(16),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle,
                color: Color.fromARGB(255, 103, 192, 2),
                size: 58,
              ),
              const SizedBox(height: 16),
              const Text(
                'Success',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'The video has been successfully posted.',
                style: TextStyle(fontSize: 16, color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const HomeScreen()),
                      (Route<dynamic> route) =>
                          false, // This removes all previous routes
                    ); // Navigate back to Login screen
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(147, 54, 231, 1),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Go to Home',
                    style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class TagOverlay extends StatefulWidget {
  final List<String> initiallySelected;

  const TagOverlay({super.key, required this.initiallySelected});

  @override
  _TagOverlayState createState() => _TagOverlayState();
}

class _TagOverlayState extends State<TagOverlay> {
  List<Map<String, dynamic>> allPeople = [];
  List<Map<String, dynamic>> filteredPeople = [];
  List<String> selectedPeople = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    selectedPeople = List.from(widget.initiallySelected);
    searchController.addListener(() {
      fetchUsers(searchController.text);
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void fetchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        filteredPeople = [];
      });
      return;
    }

    try {
      // Use SearchLogic to fetch users
      final List<Map<String, dynamic>> users =
          await SearchLogic.searchUsers(query);
      setState(() {
        filteredPeople = users
            .map((user) => {
                  'username': user['username'],
                  'profile_picture_url': user['profile_picture_url'],
                })
            .toList();
      });
    } catch (e) {
      if (kDebugMode) {
        print("Error while fetching users: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 60,
      ),
      child: Container(
        height: 600,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tag someone',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context, selectedPeople),
                ),
              ],
            ),
            TextField(
              controller: searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter name here please',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: filteredPeople.length,
                itemBuilder: (context, index) {
                  final person = filteredPeople[index];
                  final isSelected =
                      selectedPeople.contains(person['username']);
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage:
                          NetworkImage(person['profile_picture_url']),
                    ),
                    title: Text(
                      person['username'],
                      style: const TextStyle(color: Colors.white),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check, color: Colors.purple)
                        : ElevatedButton(
                            onPressed: () {
                              setState(() {
                                if (isSelected) {
                                  selectedPeople.remove(person['username']);
                                } else {
                                  selectedPeople.add(person['username']);
                                }
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                            ),
                            child: const Text('Add'),
                          ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
