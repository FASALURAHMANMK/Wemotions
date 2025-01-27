import 'dart:convert';
import 'package:Wemotions/features/Notification_service.dart';
import 'package:Wemotions/features/homescreen/discovery_screen.dart';
import 'package:Wemotions/features/homescreen/home_screen.dart';
import 'package:Wemotions/features/homescreen/profile_screen.dart';
import 'package:Wemotions/features/homescreen/profile_screen_user.dart';
import 'package:Wemotions/features/homescreen/video_player.dart';
import 'package:Wemotions/features/homescreen/video_post.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  List<Map<String, dynamic>> notifications = [];
  List<VideoPost> video = [];
  int selectedNavIndex = 3;
  int notificationCount = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUnreadCount();
    fetchNotifications();
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

  Future<void> fetchNotifications() async {
    setState(() {
      isLoading = true;
    });
    try {
      List<Map<String, dynamic>> fetchedNotifications =
          await _notificationService.getAllNotifications();
      setState(() {
        notifications = fetchedNotifications;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }
  Future<void> getPost(int postId) async {
    try {
      // Retrieve Flic-Token from shared preferences
      final prefs = await SharedPreferences.getInstance();
      final flicToken = prefs.getString('flic_token');

      if (flicToken == null) {
        throw Exception('Flic-Token not found in shared preferences');
      }

      // Construct the request
      var headers = {
        'Flic-Token': flicToken,
      };
      var request = http.Request(
        'GET',
        Uri.parse('https://api.wemotions.app/posts/$postId'),
      );

      request.headers.addAll(headers);

      // Send the request
      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final Map<String, dynamic> data = json.decode(responseBody);
        final List<dynamic> posts = data['post'] ?? [];
        List<VideoPost> tmp = [];
        tmp.clear();
        tmp.addAll(posts.map((post) {
          return VideoPost(
            id: post['id'].toString(),
            parentVideoId: post['parent_video_id'].toString(),
            username: post['username'] ?? 'Unknown',
            profileImage: post['picture_url'] ?? '',
            activityStatus:
            post['following'] == true ? 'Following' : 'Not Following',
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
        }).toList());
        setState(() {
          video = tmp;
        });
      } else {
        throw Exception(
            'Failed to fetch post details: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error: $e');
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
      backgroundColor: const Color.fromRGBO(41, 41, 41, 1),
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(41, 41, 41, 1),
        title: const Text('Notifications',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        centerTitle: true,
      ),
      body: isLoading
          ? Center(
              child: LoadingAnimationWidget.waveDots(
                color: Colors.white,
                size: 50.0,
              ),
            )
          : notifications.isNotEmpty ?
          Stack(
              children: [
                ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    final bool isUnread = notification['has_seen'] == null;
                    final String contentAvatarUrl =
                        notification['action_type'] == 'follow'
                            ? ''
                            : notification['content_avatar_url'];
                    return Dismissible(
                      key: Key(notification['id'].toString()),
                      direction: DismissDirection.endToStart,
                      onDismissed: (direction) async {
                        await _notificationService.deleteNotification(notification['id']);
                        setState(() {
      notifications.removeWhere((n) => n['id'] == notification['id']);
      fetchUnreadCount();
    fetchNotifications();
    });
                      },
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      child: GestureDetector(
                        onTap: () async {
                          if (notification['action_type'] == 'follow') {
                            if(isUnread) {await _notificationService.readNotification(notification['id']);}
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProfileScreenUser(
                                    username: notification['actor']['username']),
                              ),
                            );
                          } else {
                            if(isUnread) {await _notificationService.readNotification(notification['id']);}
                            await getPost(int.parse(notification['target_id']));
                            if (video.isNotEmpty) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      VideoPlayer(videoPost: video[0]),
                                ),
                              );
                            } else {
                              print('Video list is empty!');
                            }
                          }
                        },
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(10),
                          leading: Stack(
                            children: [
                              CircleAvatar(
                                backgroundImage: NetworkImage(
                                    notification['actor']['profile_url']),
                              ),
                              if (isUnread)
                                const Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: CircleAvatar(
                                    radius: 6,
                                    backgroundColor: Colors.red,
                                  ),
                                ),
                            ],
                          ),
                          title: Text(
                            notification['actor']['name'],
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            notification['content'],
                            style: const TextStyle(color: Colors.white70),
                          ),
                          trailing: contentAvatarUrl.isNotEmpty
                              ? Image.network(contentAvatarUrl,
                                  width: 40, height: 40)
                              : null,
                        ),
                      ),
                    );
                  },
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
                                  "Clear All",
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
                                      shape: BoxShape.circle, // Circular shape
                                    ),
                                    child: Center(
                                      child: Image.asset(
                                        'assets/icons/clear.png',
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
            ):Stack(
              children: [
            const Center(
              child: Text("No Notifications"),
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
                                  "Clear All",
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
                                      shape: BoxShape.circle, // Circular shape
                                    ),
                                    child: Center(
                                      child: Image.asset(
                                        'assets/icons/clear.png',
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
