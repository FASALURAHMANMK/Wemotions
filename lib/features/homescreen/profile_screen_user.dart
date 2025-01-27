import 'package:Wemotions/features/homescreen/actions.dart';
import 'package:Wemotions/features/homescreen/video_player.dart';
import 'package:Wemotions/features/homescreen/video_post.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProfileScreenUser extends StatefulWidget {
  final String username;

  const ProfileScreenUser({super.key, required this.username});

  @override
  State<ProfileScreenUser> createState() => _ProfileScreenUserState();
}

class _ProfileScreenUserState extends State<ProfileScreenUser> {
  late String flicToken;
  Map<String, dynamic>? profileData;
  List<VideoPost> videos = [];
  @override
  void initState() {
    super.initState();
    loadPreferences();
  }

  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    flicToken = prefs.getString('flic_token') ?? '';
    fetchProfileData();
    fetchVideos();
  }

  Future<void> fetchProfileData() async {
    final headers = {'Flic-Token': flicToken};
    final response = await http.get(
      Uri.parse('https://api.wemotions.app/profile/${widget.username}'),
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
      Uri.parse('https://api.wemotions.app/users/${widget.username}/posts?page=1'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(await response.body);
      final List<dynamic> posts = data['posts'] ?? [];
      List<VideoPost> tmp = [];
        tmp.clear();
        tmp.addAll(posts.map((post) {
          return VideoPost(
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
            tags: (post['tags'] as List<dynamic>?)
              ?.map((tagJson) => Tag.fromJson(tagJson))
              .toList() ??
          [],
          );
        }).toList());
      setState(() {
        videos = tmp;
      });
    }
  }

  void showOverlayOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          color: Colors.black,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.report, color: Colors.red),
                title: const Text('Report User', style: TextStyle(color: Colors.white)),
                onTap: () {
                  // Add report logic here
                },
              ),
              ListTile(
                leading: const Icon(Icons.block, color: Colors.red),
                title: const Text('Block User', style: TextStyle(color: Colors.white)),
                onTap: () {
                  // Add block logic here
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isFollowing = profileData?['is_following'] == true;
    return Scaffold(
      appBar: AppBar(
        title: Text(profileData?['username'] ?? '',style: const TextStyle(
              fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color.fromRGBO(41, 41, 41, 1),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => showOverlayOptions(context),
          ),
        ],
      ),
      body: profileData == null
          ? Center(
              child: LoadingAnimationWidget.waveDots(
                      color: Colors.white,
                      size: 50.0,
                    ),
            )
          : 
          SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 12),
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
                      statTile('Followers', profileData!['follower_count'] ?? 0),
                      const SizedBox(width: 24),
                      statTile('Following', profileData!['following_count'] ?? 0),
                      const SizedBox(width: 24),
                      statTile('Videos', profileData!['post_count'] ?? 0),
                    ],
                  ),
                  const SizedBox(height: 16),
                 /* ElevatedButton(
                    onPressed: () {
                      // Add follow/unfollow logic later
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      profileData!['is_following'] == true ? 'Following' : 'Follow',
                    ),
                  ),*/
                  
                  StatefulBuilder(
                    
                builder: (context, setStateForButton) {
                  return ElevatedButton(
                    onPressed: () async {
                      setStateForButton(() {
                        isFollowing = !isFollowing;
                      });
                      // Execute your follow/unfollow logic
                      if (isFollowing) {
                        await ApiService.follow(profileData?['username']); // Your follow function
                      } else {
                        await ApiService.unfollow(profileData?['username']); // Your unfollow function
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
                  const SizedBox(height: 16),
                  const Text(
                    'Videos',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  videos.isEmpty
                      ? const Center(
                          child: Text(
                            'No videos yet',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        )
                      : GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 2,
                            mainAxisSpacing: 3,
                            childAspectRatio: 0.68,
                          ),
                          itemCount: videos.length,
                          itemBuilder: (context, index) {
                            final video = videos[index];
                            return GestureDetector(
                              onTap: () {
                                 Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VideoPlayer(videoPost: video),
                ),
              );
                              },
                            child:Container(
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: NetworkImage(video.thumbUrl),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                      );
                          },
                        ),
                ],
              ),
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
}
