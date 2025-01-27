import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:Wemotions/features/homescreen/profile_screen_user.dart';
import 'package:Wemotions/features/homescreen/video_provider.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:Wemotions/features/homescreen/video_post.dart';
import 'package:Wemotions/features/homescreen/actions.dart';
import 'package:Wemotions/features/homescreen/video_player.dart'as custom_video_player;
class VideoPostWidget extends StatefulWidget {
  final VideoPost videoPost;

  const VideoPostWidget({super.key, required this.videoPost});

  @override
  State<VideoPostWidget> createState() => _VideoPostWidgetState();
}

class _VideoPostWidgetState extends State<VideoPostWidget> {
  late VideoPlayerController _controller;
  bool _isPlaying = true;
  bool showFullDescription = false;
  bool isToggled = false;
  bool isVideoMode = true;
  List<VideoPost> replys = [];
  List<Map<String, dynamic>?> tagprofiles=[];
  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoPost.videoUrl)
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
        _controller.setLooping(true);
      });

    _controller.addListener(() {
      setState(() {}); // Update UI based on the video progress
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
        _isPlaying = false;
      } else {
        _controller.play();
        _isPlaying = true;
      }
    });
  }
  // Tracks whether the button is toggled

  void toggleColor() {
    setState(() {
      isToggled = !isToggled;
    });
  }
Future<void> showReplys(int id) async {
  setState(() {
  });
  replys = await VideoProvider.getreplys(id);
 showContentOverlay(
                    context,
                    "Video Replys",
                    SizedBox(
                      height: 300, 
                child: GridView.builder(
                  itemCount: replys.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 2,
                    mainAxisSpacing: 3,
                    childAspectRatio: 0.68,
                  ),
                  itemBuilder: (context, index) {
                    final video = replys[index];
                    return PostTile(video: video);
                  },
                ),
              
                    ),
                  );
}
Future<List<Map<String, dynamic>?>> fetchtagged(List<Tag> tags) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final flicToken = prefs.getString('flic_token') ?? '';
    final headers = {'Flic-Token': flicToken};

    // Use Future.wait to fetch data concurrently for all tags
    final results = await Future.wait(tags.map((tag) async {
      try {
        final response = await http.get(
          Uri.parse('https://api.wemotions.app/profile/${tag.username}'),
          headers: headers,
        );
        if (response.statusCode == 200) {
          return json.decode(response.body) as Map<String, dynamic>;
        } else {
          if (kDebugMode) {
            print('Failed to fetch profile data for ${tag.username}. Status code: ${response.statusCode}');
          }
          return null;
        }
      } catch (e) {
        if (kDebugMode) {
          print('An error occurred while fetching profile data for ${tag.username}: $e');
        }
        return null;
      }
    }).toList());

    return results;
  } catch (e) {
    print('An error occurred while fetching multiple profiles: $e');
    return [];
  }
}
Future<void> showTaggedPeople() async {
  setState(() {}); // Optional, may be removed if not necessary for triggering rebuilds

  tagprofiles = await fetchtagged(widget.videoPost.tags);

  showContentOverlay(
    context,
    "Tagged Users",
    SizedBox(
      height: 300, // Constrain the height of the ListView
      child: ListView.builder(
        itemCount: tagprofiles.length,
        itemBuilder: (context, index) {
          final user = tagprofiles[index];
          bool isFollowing = user?['is_following'] == true;

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ProfileScreenUser(username: user?['username']),
                ),
              );
            },
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage(user?['profile_picture_url']),
              ),
              title: Text(
                '${user?['first_name']} ${user?['last_name']}',
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                user?['username'],
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
                        await ApiService.follow(user?['username']); // Your follow function
                      } else {
                        await ApiService.unfollow(user?['username']); // Your unfollow function
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
    ),
  );
}
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Full-Screen Video
        Stack(
          children: [
            GestureDetector(
              onTap: _togglePlayPause,
              child: _controller.value.isInitialized
                  ? Padding(
                      padding:
                          const EdgeInsets.only(top: 0), // Adjust top padding
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height -
                            88.8, // Adjust height dynamically
                        width: MediaQuery.of(context).size.width, // Full width
                        child: VideoPlayer(_controller),
                      ),
                    )
                  : Center(
                      child: LoadingAnimationWidget.waveDots(
                        color: Colors.white,
                        size: 50.0,
                      ),
                    ),
            ),

            // Play Button when Paused with Custom Vertical Position
            if (!_isPlaying)
              Align(
                alignment:
                    const Alignment(0.0, -0.18), // Adjust vertical position
                child: Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.grey.shade300.withOpacity(0.4),
                  size: 80,
                ),
              ),
          ],
        ),
        // Right Vertical Icons
        Positioned(
          right: 16,
          bottom: 220,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Like Button
              _VerticalIconButton(
                  icon: Image.asset(
                    'assets/icons/motion.png',
                    width: 42, // Optional: Specify width for better control
                    height: 42,
                    color: isToggled || widget.videoPost.upvoted == '1'
                        ? const Color.fromRGBO(147, 54, 231, 1)
                        : Colors.white, // Tint the image red
                    colorBlendMode: BlendMode
                        .srcIn, // Optional: Specify height for better control
                  ),
                  label: widget.videoPost.likeCount.toString(),
                  color: Colors.white,
                  onTap: () async {
                  toggleColor();
                  widget.videoPost.upvoted == '1'
                      ? await ApiService.removeUpvote(
                          int.parse(widget.videoPost.id))
                      : await ApiService.addUpvote(
                          int.parse(widget.videoPost.id));
                },
                ),
              const SizedBox(height: 20),
              // Comment Button
              _VerticalIconButton(
                icon: Image.asset(
                  'assets/icons/comment.png',
                  width: 32, // Optional: Specify width for better control
                  height: 32,
                ),
                label: widget.videoPost.commentCount.toString(),
                color: Colors.white,
                onTap: () {
                  showReplys(int.parse(widget.videoPost.id));
                },
              ),
              const SizedBox(height: 20),
              // Comment Button
              _VerticalIconButton(
                icon: Image.asset('assets/icons/tag.png',
                    width: 36, // Optional: Specify width for better control
                    height: 36),
                label: widget.videoPost.tagCount.toString(),
                color: Colors.white,
                onTap: () async {
                 await showTaggedPeople();
                },
              ),
              const SizedBox(height: 20),
              // Share Button
              _VerticalIconButton(
                icon: Image.asset('assets/icons/share.png',
                    width: 32, // Optional: Specify width for better control
                    height: 32),
                label: widget.videoPost.shareCount.toString(),
                color: Colors.white,
                onTap: () {
                  showShareOverlay(context);
                },
              ),
              const SizedBox(height: 20),
              // More Options Button
              IconButton(
                icon:
                    const Icon(Icons.more_vert, color: Colors.white, size: 30),
                onPressed: () {
                  showMoreActionsOverlay(context);
                },
              ),
            ],
          ),
        ),

        // Bottom Overlay with User Info
        Positioned(
          left: 10,
          bottom: 120,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage(widget.videoPost.profileImage),
                radius: 26,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfileScreenUser(
                              username: widget.videoPost.username),
                        ),
                      );
                    },
                    child: Text(
                      widget.videoPost.username,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        showFullDescription = !showFullDescription;
                      });
                    },
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.6,
                      ),
                      child: Text(
                        widget.videoPost.description,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12),
                        overflow: showFullDescription
                            ? TextOverflow.visible
                            : TextOverflow.ellipsis,
                        maxLines: showFullDescription ? null : 1,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Video Progress Bar
        Positioned(
          bottom: 86,
          left: 0,
          right: 0,
          child: _controller.value.isInitialized &&
                  _controller.value.duration.inSeconds > 0
              ? SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: const Color.fromRGBO(147, 54, 231, 1),
                    inactiveTrackColor: Colors.white,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 0),
                    thumbColor: const Color.fromRGBO(147, 54, 231, 1),
                    overlayShape:
                        const RoundSliderOverlayShape(overlayRadius: 0),
                    overlayColor: const Color.fromRGBO(147, 54, 231, 1),
                  ),
                  child: Slider(
                    min: 0,
                    max: _controller.value.duration.inSeconds.toDouble(),
                    value:
                        _controller.value.position.inSeconds.toDouble().clamp(
                              0.0,
                              _controller.value.duration.inSeconds.toDouble(),
                            ),
                    onChanged: (value) {
                      _controller.seekTo(Duration(seconds: value.toInt()));
                    },
                  ),
                )
              : const SizedBox(),
        ),
      ],
    );
  }

  void showContentOverlay(BuildContext context, String title, Widget content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, controller) {
            return Container(
              decoration: const BoxDecoration(
                color: Color.fromRGBO(41, 41, 41, 1),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  // Scrollable Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      controller: controller,
                      child: content,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Bottom Sheet for Share Overlay
  void showShareOverlay(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Color.fromRGBO(41, 41, 41, 1),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Share on",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Share Options
              GridView.count(
                crossAxisCount: 5,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildShareOption(Image.asset('assets/icons/inst.png',
                    width: 32, 
                    height: 32), "Instagram"),
                  _buildShareOption(Image.asset('assets/icons/fb.png',
                    width: 32, 
                    height: 32), "Facebook"),
                  _buildShareOption(Image.asset('assets/icons/tlg.png',
                    width: 32, 
                    height: 32), "Telegram"),
                  _buildShareOption(Image.asset('assets/icons/wtp.png',
                    width: 32, 
                    height: 32), "WhatsApp"),
                  _buildShareOption(Image.asset('assets/icons/x.png',
                    width: 32,
                    height: 32), "Twitter"),
                ],
              ),
              const Divider(color: Colors.white),
              ListTile(
                leading: const Icon(Icons.link, color: Colors.white),
                title: const Text("Copy link",
                    style: TextStyle(color: Colors.white)),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.download, color: Colors.white),
                title: const Text("Download",
                    style: TextStyle(color: Colors.white)),
                onTap: () {},
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  /// Bottom Sheet for More Actions Overlay
  void showMoreActionsOverlay(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Color.fromRGBO(41, 41, 41, 1),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.link, color: Colors.white),
                title: const Text("Copy link",
                    style: TextStyle(color: Colors.white)),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.download, color: Colors.white),
                title: const Text("Download",
                    style: TextStyle(color: Colors.white)),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.report, color: Colors.white),
                title:
                    const Text("Report", style: TextStyle(color: Colors.white)),
                onTap: () {},
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  /// Helper Function for Share Option
  Widget _buildShareOption(Widget icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white)),
      ],
    );
  }
}

class _VerticalIconButton extends StatelessWidget {
  final Widget icon; // Changed from IconData to Widget to support Image.asset
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _VerticalIconButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: icon, // Use the passed widget directly
        ),
        const SizedBox(height: 4), // Optional spacing
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ],
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
                  builder: (context) => custom_video_player.VideoPlayer(videoPost:video),
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