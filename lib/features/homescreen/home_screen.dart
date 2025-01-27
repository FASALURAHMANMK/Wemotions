import 'package:Wemotions/features/Notification_service.dart';
import 'package:Wemotions/features/homescreen/discovery_screen.dart';
import 'package:Wemotions/features/homescreen/notifications_screen.dart';
import 'package:Wemotions/features/homescreen/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Wemotions/features/homescreen/video_provider.dart';
import 'package:Wemotions/features/homescreen/widgets/custom_app_bar.dart';
import 'package:Wemotions/features/homescreen/widgets/video_post_widget.dart';
import 'video_recorder_screen.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final NotificationService _notificationService = NotificationService();
  int selectedTab = 0; // For Trending and Following tabs
  int selectedNavIndex = 0; // For Bottom Navigation
  PageController pageController =
  PageController(initialPage: 0); // For Video/Reply Swipe
  bool isVideoMode = true; // Video mode indicator
  int notificationCount = 0;
  int currentIndex = 0;
getSelectedScreen(BuildContext context) {
  switch (selectedNavIndex) {
    case 0:
      Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
              (Route<dynamic> route) => false, // This removes all previous routes
            );
      break;
    case 1:
      Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const DiscoveryScreen()),
              (Route<dynamic> route) => false, // This removes all previous routes
            );
      break;
    case 3:
      Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => NotificationsScreen()),
              (Route<dynamic> route) => false, // This removes all previous routes
            );
      break;
    case 4:
      Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
              (Route<dynamic> route) => false, // This removes all previous routes
            );
      break;
    default:
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const Scaffold(
            body: Center(
              child: Text(
                'Screen Not Found',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
      );
      break;
  }
}
  @override
  void initState() {
    super.initState();
    fetchUnreadCount();
    pageController.addListener(() {
      setState(() {
        currentIndex =
            pageController.page?.round() ?? 0; // Update current index
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<VideoProvider>(context, listen: false).fetchVideos();
    });
  }
 Future<void> fetchUnreadCount() async {
    try {
      int count = await _notificationService.getUnreadNotificationCount();
      setState(() {
        notificationCount = count; // Set the fetched count to the variable
      });
    } catch (e) {
      print('Error fetching unread notification count: $e');
    }
  }
  void onTabChanged(int index) {
    setState(() {
      selectedTab = index;
    });

    if (index == 0) {
      Provider.of<VideoProvider>(context, listen: false)
          .fetchVideos(); // Trending Feed
    } else {
      Provider.of<VideoProvider>(context, listen: false)
          .fetchFollowingFeed(); // Following Feed
    }
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
    final videoProvider = Provider.of<VideoProvider>(context);

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
                      child: videoProvider.isLoading
                          ? Center(child: LoadingAnimationWidget.waveDots(
                      color: Colors.white,
                      size: 50.0,
                    ),)
                          : selectedTab == 0 // Check the selected tab
                              ? PageView.builder(
                                  controller: pageController,
                                  scrollDirection: Axis.vertical,
                                  itemCount: videoProvider.videos.length,
                                  itemBuilder: (context, index) {
                                    return VideoPostWidget(
                                        videoPost: videoProvider
                                            .videos[index]); // Trending Videos
                                  },
                                )
                              : PageView.builder(
                                  controller: pageController,
                                  scrollDirection: Axis.vertical,
                                  itemCount: videoProvider.followingFeed
                                      .length, // Assuming separate fetch logic for Following Feed
                                  itemBuilder: (context, index) {
                                    final videoPost = videoProvider
                                                .followingFeed.isNotEmpty &&
                                            index <
                                                videoProvider
                                                    .followingFeed.length
                                        ? videoProvider.followingFeed[index]
                                        : null;

                                    if (videoPost == null) {
                                      return const Center(
                                        child: Text(
                                          'No Post Found',
                                          style: TextStyle(
                                              fontSize: 16, color: Colors.grey),
                                        ),
                                      );
                                    }

                                    return VideoPostWidget(
                                        videoPost:
                                            videoPost); // Render the video widget if it exists
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
                      // Dynamically get the current index from the PageController
                      int currentIndex = pageController.hasClients
                          ? pageController.page?.round() ?? 0
                          : 0;
                      return selectedTab == 0
                          ? ReplyingToWidget(
                              username:
                                  videoProvider.videos[currentIndex].username,
                              thumbnailUrl:
                                  videoProvider.videos[currentIndex].thumbUrl,
                              avatarUrl: videoProvider
                                  .videos[currentIndex].profileImage,
                            )
                          : ReplyingToWidget(
                              username: videoProvider
                                  .followingFeed[currentIndex].username,
                              thumbnailUrl: videoProvider
                                  .followingFeed[currentIndex].thumbUrl,
                              avatarUrl: videoProvider
                                  .followingFeed[currentIndex].profileImage,
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
              child: CustomAppBar(
                selectedTab: selectedTab,
                onTabChanged: onTabChanged,
              ),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _BottomNavItem(
                            icon: Icons.home,
                            isSelected: selectedNavIndex == 0,
                            onTap: () { setState(() => selectedNavIndex = 0);
                            getSelectedScreen(context);
                            },
                          ),
                          _BottomNavItem(
                            icon: Icons.grid_view,
                            isSelected: selectedNavIndex == 1,
                            onTap: () { setState(() => selectedNavIndex = 1);
                            getSelectedScreen(context);
                            }
                          ),
                          const SizedBox(
                              width: 70), // Reserve space for the button
                          _BottomNavItem(
                            icon: Icons.notifications,
                            isSelected: selectedNavIndex == 3,
                            onTap: () { setState(() => selectedNavIndex = 3);
                            getSelectedScreen(context);
                            },
                            notificationCount:
                                notificationCount, // Pass the notification count here
                          ),
                          _BottomNavItem(
                            icon: Icons.person,
                            isSelected: selectedNavIndex == 4,
                            onTap: () { setState(() => selectedNavIndex = 4);
                            getSelectedScreen(context);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 1),
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
                  MaterialPageRoute(builder: (context) => VideoRecorderScreen(parentVideoId:videoProvider.videos[currentIndex].id)),
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

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final int notificationCount; // New property for the notification badge count

  const _BottomNavItem({
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.notificationCount = 0, // Default value is 0 (no badge)
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              Icon(
                icon,
                size: 32,
                color: isSelected
                    ? const Color.fromRGBO(147, 54, 231, 1)
                    : Colors.white,
              ),
              if (notificationCount >
                  0) // Show badge only if there are notifications
                Positioned(
                  right: -0.4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4.2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$notificationCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 5),
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
