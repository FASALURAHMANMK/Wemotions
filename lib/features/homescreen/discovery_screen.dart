import 'dart:convert';

import 'package:Wemotions/features/Notification_service.dart';
import 'package:Wemotions/features/homescreen/actions.dart';
import 'package:Wemotions/features/homescreen/home_screen.dart';
import 'package:Wemotions/features/homescreen/notifications_screen.dart';
import 'package:Wemotions/features/homescreen/profile_screen.dart';
import 'package:Wemotions/features/homescreen/profile_screen_user.dart';
import 'package:Wemotions/features/homescreen/search.dart';
import 'package:Wemotions/features/homescreen/video_player.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'video_provider.dart';
import 'package:Wemotions/features/homescreen/video_post.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:http/http.dart' as http;
class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  _DiscoveryScreenState createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  final NotificationService _notificationService = NotificationService();
  int selectedNavIndex = 1;
  int notificationCount = 0;
  bool showSearchOverlay = false;
  String searchQuery = '';
  bool isUserTab = true; // To toggle between Users and Posts tabs
  List<Map<String, dynamic>> userResults = [];
  List<VideoPost> postResults = [];
  bool isLoading = false;
  @override
  void initState() {
    super.initState();
    fetchUnreadCount();
    }

  void search(String query) async {
  setState(() {
    searchQuery = query;
    isLoading = true;
  });

  try {
    if (isUserTab) {
      // Fetch user results
      userResults = await SearchLogic.searchUsers(query);

      // Iterate through user results and fetch profile data for each user
      for (var user in userResults) {
        try {
          final profileData = await fetchProfileData(user['username']);
          user['is_following'] = profileData?['is_following'] ?? false;
        } catch (e) {
          if (kDebugMode) {
            print('Error fetching profile data for ${user['username']}: $e');
          }
          // If fetching profile data fails, set is_following to false by default
          user['is_following'] = false;
        }
      }
    } else {
      // Fetch post results
      postResults = await SearchLogic.searchPosts(query);
    }
  } catch (e) {
    if (kDebugMode) {
      print('Search error: $e');
    }
  }

  setState(() {
    isLoading = false;
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
  Future<Map<String, dynamic>?> fetchProfileData(String username) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final flicToken = prefs.getString('flic_token') ?? '';
    final headers = {'Flic-Token': flicToken};
    final response = await http.get(
      Uri.parse('https://api.wemotions.app/profile/$username'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      print('Failed to fetch profile data. Status code: ${response.statusCode}');
      return null;
    }
  } catch (e) {
    print('An error occurred while fetching profile data: $e');
    return null;
  }
}
  Widget buildSearchOverlay() {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 0),
      curve: Curves.easeOut,
      bottom: 0,
      left: 0,
      right: 0,
      height: MediaQuery.of(context).size.height * 0.8 -
          MediaQuery.of(context).viewInsets.bottom, // Adjust height as needed
      child: Material(
        color: const Color.fromRGBO(41, 41, 41, 1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        child: Column(
          children: [
            // Drag handle
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => setState(() => showSearchOverlay = false),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search...',
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.grey[900],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) => search(value),
              ),
            ),
            DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  TabBar(
                    onTap: (index) {
                      if (index == 0) {
                        setState(() => isUserTab = true);
                        // Add your custom logic here for the "Users" tab
                      } else if (index == 1) {
                        setState(() => isUserTab = false);
                        // Add your custom logic here for the "Posts" tab
                      }
                    },
                    indicatorColor: const Color.fromRGBO(147, 54, 231, 1),
                    tabs: const [
                      Tab(
                        child: Text(
                          'Users',
                          style: TextStyle(fontSize: 14.0, color: Colors.white),
                        ),
                      ),
                      Tab(
                        child: Text(
                          'Posts',
                          style: TextStyle(fontSize: 14.0, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isLoading)
              LoadingAnimationWidget.waveDots(
                      color: Colors.white,
                      size: 30.0,
                    )
            else if (isUserTab)
              Expanded(
                child: ListView.builder(
                  itemCount: userResults.length,
                  itemBuilder: (context, index) {
                    final user = userResults[index];
                    bool isFollowing = user['is_following'] == true;
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ProfileScreenUser(username: user['username']),
                          ),
                        );
                      },
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage:
                              NetworkImage(user['profile_picture_url']),
                        ),
                        title: Text(
                          '${user['first_name']} ${user['last_name']}',
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          user['username'],
                          style: const TextStyle(color: Colors.white54),
                        ),
                        trailing: StatefulBuilder(
                builder: (context, setStateForButton) {
                  return ElevatedButton(
                    onPressed: () async {
                      setStateForButton(() {
                        isFollowing = !isFollowing;
                      });
                      // Execute your follow/unfollow logic
                      if (isFollowing) {
                        await ApiService.follow(user['username']); // Your follow function
                      } else {
                        await ApiService.unfollow(user['username']); // Your unfollow function
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                    ),
                    child: Text(
                      isFollowing ? 'Following' : 'Follow',
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                },
              ),
                      ),
                    );
                  },
                ),
              )
            else
              Expanded(
                child: GridView.builder(
                  itemCount: postResults.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 2,
                    mainAxisSpacing: 2,
                    childAspectRatio: 0.68,
                  ),
                  itemBuilder: (context, index) {
                    final video = postResults[index];
                    return PostTile(video: video);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

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
  } // Move mutable state here.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          "Discover",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color.fromRGBO(41, 41, 41, 1),
        elevation: 0,
      ),
      body: Container(
        color: const Color.fromRGBO(41, 41, 41, 1),
        child: Stack(
          children: [
            Column(
              children: [
                const SizedBox(
                  height: 2,
                ),
                // Grid of posts
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: Consumer<VideoProvider>(
                      builder: (context, videoProvider, child) {
                        if (videoProvider.isLoading) {
                          return Center(
                              child: LoadingAnimationWidget.waveDots(
                      color: Colors.white,
                      size: 50.0,
                    ));
                        }
                        if (videoProvider.videos.isEmpty) {
                          return const Center(
                            child: Text(
                              "No videos available",
                              style: TextStyle(color: Colors.white),
                            ),
                          );
                        }

                        return GridView.builder(
                          itemCount: videoProvider.videos.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 2,
                            mainAxisSpacing: 2,
                            childAspectRatio: 0.68,
                          ),
                          itemBuilder: (context, index) {
                            final video = videoProvider.videos[index];
                            return PostTile(video: video);
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
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
                              onTap: () {
                                setState(() => selectedNavIndex = 0);
                                getSelectedScreen(context);
                              },
                            ),
                            _BottomNavItem(
                                icon: Icons.grid_view,
                                isSelected: selectedNavIndex == 1,
                                onTap: () {
                                  setState(() => selectedNavIndex = 1);
                                  getSelectedScreen(context);
                                }),
                            const SizedBox(width: 70),
                            _BottomNavItem(
                              icon: Icons.notifications,
                              isSelected: selectedNavIndex == 3,
                              onTap: () {
                                setState(() => selectedNavIndex = 3);
                                getSelectedScreen(context);
                              },
                              notificationCount:
                                  notificationCount, // Pass the notification count here
                            ),
                            _BottomNavItem(
                              icon: Icons.person,
                              isSelected: selectedNavIndex == 4,
                              onTap: () {
                                setState(() => selectedNavIndex = 4);
                                getSelectedScreen(context);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 1),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(width: 10),
                            Text(
                              "Search",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
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
                      onTap: () => setState(() => showSearchOverlay = true),
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
                              color: Colors
                                  .transparent, // Keep the outer container transparent
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Center(
                              child: Container(
                                width: 48, // Inner purple circle size
                                height: 48,
                                decoration: const BoxDecoration(
                                  color: Color.fromRGBO(147, 54, 231,
                                      1), // Purple circular background
                                  shape: BoxShape.circle, // Circular shape
                                ),
                                child: Center(
                                  child: Image.asset(
                                    'assets/icons/search.png',
                                    width: 32,
                                    height: 322,
                                    fit: BoxFit
                                        .contain, // Ensures the image fits well
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (showSearchOverlay) buildSearchOverlay(),
          ],
        ),
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

class PostTile extends StatelessWidget {
  final VideoPost video; // Assuming a `Video` class exists

  const PostTile({super.key, required this.video});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child:
      GestureDetector(
      onTap: () {
        Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VideoPlayer(videoPost: video),
                ),
              );
      },
       child:Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(video.thumbUrl), // Thumbnail URL from video
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Overlay with user information
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: const BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 10,
                    backgroundImage:
                        NetworkImage(video.profileImage), // User avatar
                  ),
                  const SizedBox(width: 4),
                  Text(
                    video.username, // Username
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }
}
