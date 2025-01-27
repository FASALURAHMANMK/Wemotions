import 'package:Wemotions/features/homescreen/video_post.dart';
import 'package:Wemotions/features/homescreen/widgets/custom_app_bar_2.dart';
import 'package:flutter/material.dart';
import 'package:Wemotions/features/homescreen/widgets/video_post_widget.dart';
import 'video_recorder_screen.dart';
class VideoPlayer extends StatefulWidget {
  final VideoPost videoPost;
  const VideoPlayer({super.key ,required this.videoPost});

  @override
  State<VideoPlayer> createState() => _VideoPlayerState();
}

class _VideoPlayerState extends State<VideoPlayer> {
  PageController pageController =
  PageController(initialPage: 0); // For Video/Reply Swipe
  bool isVideoMode = true; // Video mode indicator
  int currentIndex = 0;
  @override
  void initState() {
    super.initState();
    pageController.addListener(() {
      setState(() {
        currentIndex =
            pageController.page?.round() ?? 0; // Update current index
      });
    });
  }

  void _onSwipeRight() {
    setState(() {
      isVideoMode = true;
    });
  }

  void _onSwipeLeft() {
    setState(() {
      isVideoMode = false;
    });
  }

  @override
  void dispose() {
    pageController.dispose(); // Dispose the controller to avoid memory leaks
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main Content (Video/Reply)
          Stack(
            children: [
              Column(
                children: [
                  // Swipeable Video and Reply Views
                  Expanded(
                    child: GestureDetector(
                      onHorizontalDragEnd: (details) {
                        if (details.primaryVelocity! > 0) {
                          // Swipe Right
                          _onSwipeRight();
                        } else if (details.primaryVelocity! < 0) {
                          // Swipe Left
                          _onSwipeLeft();
                        }
                      },
                      child:
                              PageView.builder(
                                  controller: pageController,
                                  scrollDirection: Axis.vertical,
                                  itemCount:1,
                                  itemBuilder: (context, index) {
                                    return VideoPostWidget(
                                        videoPost: widget.videoPost); // Trending Videos
                                  },
                                ),
                    ),
                  ),
                ],
              ),
              if (!isVideoMode)
                Positioned(
                  top: 100,
                  left: 20,
                  right: 20,
                  child: Builder(
                    builder: (context) {
                      return ReplyingToWidget(
                              username:
                                  widget.videoPost.username,
                              thumbnailUrl:
                                  widget.videoPost.thumbUrl,
                              avatarUrl: widget.videoPost.profileImage,
                            );
                    },
                  ),
                ),
            ],
          ),
          // Custom AppBar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.transparent, // Background with opacity
              child: const CustomAppBar_2(),
            ),
          ),
          // Bottom Navigation with Video/Reply Indicator
          Align(
            alignment: Alignment.bottomCenter,
            child: Stack(
              clipBehavior:
                  Clip.none, // Allows the button to overflow above the navbar
              children: [
                // Navigation Bar
                Container(
                  color: const Color.fromRGBO(41, 41, 41, 1),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [    
                      const SizedBox(height: 37),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                isVideoMode = true; // Update state
                              });
                            },
                            child: Text(
                              "Video",
                              style: TextStyle(
                                color: isVideoMode ? Colors.white : Colors.grey,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                isVideoMode = false; // Update state
                              });
                            },
                            child: Text(
                              "Reply",
                              style: TextStyle(
                                color: isVideoMode ? Colors.grey : Colors.white,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
                // Video/Reply Button
                Positioned(
            top: -28, // Adjust this value to move the button vertically
            left: 0,
            right: 0,
            child: GestureDetector(
              onLongPress: () {
                if (!isVideoMode) {
                  Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => VideoRecorderScreen(parentVideoId:widget.videoPost.id)),
                );
                } else {
                  Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) =>  const VideoRecorderScreen(parentVideoId:'')),
                );
                }
              },
              onTap: () {
                if (isVideoMode) {
                  // Handle posting a video
                } else {
                  // Handle posting a reply
                }
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer white circle (ring)
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 4,
                      ),
                    ),
                  ),
                  // Inner container with image/icon
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: isVideoMode
                        ? Image.asset(
                            'assets/icons/video.png',
                            width: 42,
                            height: 42,
                          )
                        : Image.asset(
                            'assets/icons/reply.png',
                            width: 42,
                            height: 42,
                          ),
                  ),
                ],
              ),
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
class ReplyingToWidget extends StatelessWidget {
  final String username;
  final String thumbnailUrl;
  final String avatarUrl;

  const ReplyingToWidget({
    super.key,
    required this.username,
    required this.thumbnailUrl,
    required this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      // Horizontally center the entire container
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color.fromRGBO(255, 255, 255, 0.08),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min, // Shrink the row to its content
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Replying to",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    // Thumbnail Image
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: NetworkImage(avatarUrl),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      username,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(width: 60),
            Container(
              height: 80,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Image.network(
                thumbnailUrl,
                fit: BoxFit.fill, // Ensures the image scales appropriately
              ),
            ),
          ],
        ),
      ),
    );
  }
}
