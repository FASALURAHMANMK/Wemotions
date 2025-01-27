import 'package:Wemotions/features/Notification_service.dart';
import 'package:Wemotions/features/homescreen/discovery_screen.dart';
import 'package:Wemotions/features/homescreen/home_screen.dart';
import 'package:Wemotions/features/homescreen/notifications_screen.dart';
import 'package:Wemotions/features/homescreen/profile_settings.dart';
import 'package:Wemotions/features/homescreen/video_player.dart';
import 'package:Wemotions/features/homescreen/video_post.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final NotificationService _notificationService = NotificationService();
  late String username;
  late String flicToken;
  Map<String, dynamic>? profileData;
  List<VideoPost> videos = [];
  List<VideoPost> motions = [];
  int selectedNavIndex = 4;
  int notificationCount = 0;

  @override
  void initState() {
    super.initState();
    fetchUnreadCount();
    loadPreferences();
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
  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    username = prefs.getString('username') ?? '';
    flicToken = prefs.getString('flic_token') ?? '';
    fetchProfileData();
    fetchVideos();
  }

  Future<void> fetchProfileData() async {
    final headers = {'Flic-Token': flicToken};
    final response = await http.get(
      Uri.parse('https://api.wemotions.app/profile/$username'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      setState(() {
        profileData = json.decode(response.body);
      });
    }
  }

  Future<void> fetchVideos() async {
    final headers = {'Flic-Token': flicToken};
    final response = await http.get(
      Uri.parse('https://api.wemotions.app/users/$username/posts?page=1'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      if (response.statusCode == 200) {
  final Map<String, dynamic> data = jsonDecode(response.body);
  final List<dynamic> posts = data['posts'] ?? [];

  setState(() {
    motions.clear();
    videos.clear();
    
    for (var post in posts) {
      VideoPost videoPost = VideoPost(
        id: post['id'].toString(),
        parentVideoId: post['parent_video_id'].toString(),
        username: post['username'] ?? 'Unknown',
        profileImage: post['picture_url'] ?? '',
        activityStatus: post['following'] == true ? 'Following' : 'Not Following',
        description: post['title'] ?? '',
        videoUrl: post['video_link'] ?? '',
        thumbUrl: post['thumbnail_url'] ?? '',
        likeCount: post['upvote_count'] ?? 0,
        tagCount: post['tag_count'] ?? 0,
        commentCount: post['voting_count'] ?? 0,
        shareCount: post['share_count'] ?? 0,
        upvoted: post['upvoted'] == true ? '1':'0',
        tags:  (post['tags'] as List<dynamic>?)
              ?.map((tagJson) => Tag.fromJson(tagJson))
              .toList() ??
          [],
      );

      // Add to motions if parentVideoId is not null, otherwise add to videos
      if (videoPost.parentVideoId != 'null') {
        motions.add(videoPost);
      } else {
        videos.add(videoPost);
      }
    }
  });
}
    }
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
          MaterialPageRoute(builder: (context) => const NotificationsScreen()),
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          profileData?['username'] ?? '',
          style: const TextStyle(
              fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color.fromRGBO(41, 41, 41, 1),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: profileData == null
          ? 
          Center(
              child: LoadingAnimationWidget.waveDots(
                color: Colors.white,
                size: 50.0,
              ),
            )
          : Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 16),
                    CircleAvatar(
                      radius: 70,
                      backgroundImage:
                          NetworkImage(profileData!['profile_picture_url']),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      profileData!['name'] ?? '',
                      style: const TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      profileData!['bio'] ?? '',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        statTile('Followers',
                            profileData!['follower_count'] ?? 0),
                        const SizedBox(width: 24),
                        statTile('Following',
                            profileData!['following_count'] ?? 0),
                        const SizedBox(width: 24),
                        statTile('Videos', profileData!['post_count'] ?? 0),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DefaultTabController(
                      length: 2,
                      child: Column(
                        children: [
                          const TabBar(
                            indicatorColor: Color.fromRGBO(147, 54, 231, 1),
                            tabs: [
                              Tab(
                                child: Text(
                                  'Videos',
                                  style: TextStyle(
                                      fontSize: 14.0, color: Colors.white),
                                ),
                              ),
                              Tab(
                                child: Text(
                                  'Motions',
                                  style: TextStyle(
                                      fontSize: 14.0, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: 400,
                            child: TabBarView(
                              children: [
                                buildGrid(videos),
                                buildGrid(motions),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
              ),
              
              Align(
                alignment: Alignment.bottomCenter,
                child: Stack(
                  clipBehavior: Clip
                      .none, // Allows the button to overflow above the navbar
                  children: [
                    // Navigation Bar
                    Container(
                      color: const Color.fromRGBO(41, 41, 41, 1),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceAround,
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
                                "Edit Profile",
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
                      top:
                          -28, // Adjust this value to move the button vertically
                      left: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () {},
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
                                    shape:
                                        BoxShape.circle, // Circular shape
                                  ),
                                  child: Center(
                                    child: Image.asset(
                                      'assets/icons/edit.png',
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
            ],
          ),
      backgroundColor: const Color.fromRGBO(41, 41, 41, 1),
    );
  }

  Widget statTile(String title, int value) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget buildGrid(List<VideoPost> items) {
    return items.isEmpty
        ? const Center(
            child: Text(
              'No items available',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          )
        : GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 2,
              mainAxisSpacing: 3,
              childAspectRatio: 0.68,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return GestureDetector(
                onLongPress: () {
                  _showDiscardDialog(context,item.id);
                },
                onTap: () {
                   Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VideoPlayer(videoPost: item),
                ),
              );
                },
              child:Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(item.thumbUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
        );
            },
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
void _showDiscardDialog(BuildContext context,String postId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20.0)), // Rounded corners
      ),
      backgroundColor: const Color.fromRGBO(41, 41, 41, 1), // Black background
      title: const Center(
        child: Text(
          "Do you want to delete this post ?",
          style: TextStyle(
            color: Colors.white, // White text color for title
            fontSize: 18.0,
          ),
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceAround, // Center the buttons
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
          ),
          child: const Text(
            "Cancel",
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
        TextButton(
          onPressed: () async {
           await deletePost(int.parse(postId),context);
          },
          style: TextButton.styleFrom(
            backgroundColor: Colors.red, // Red background for Discard button
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
          ),
          child: const Text(
            "Delete",
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ],
    ),
    );
  }
  Future<void> deletePost(int postId,context) async {
  try {
    // Retrieve the Flic-Token from shared preferences
    final prefs = await SharedPreferences.getInstance();
    final flicToken = prefs.getString('flic_token');

    if (flicToken == null) {
      print('Flic-Token is not available in SharedPreferences.');
      return;
    }

    // Prepare the headers
    var headers = {
      'Flic-Token': flicToken,
    };

    // Create the DELETE request
    var request = http.Request(
      'DELETE',
      Uri.parse('https://api.wemotions.app/posts/$postId'),
    );

    request.headers.addAll(headers);

    // Send the request
    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const ProfileScreen()),
          (Route<dynamic> route) => false, // This removes all previous routes
        );
    } else {
      print('Failed to delete post. Reason: ${response.reasonPhrase}');
    }
  } catch (e) {
    print('An error occurred: $e');
  }
}