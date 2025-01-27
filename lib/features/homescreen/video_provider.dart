import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:Wemotions/features/homescreen/video_post.dart';

class VideoProvider with ChangeNotifier {
  final List<VideoPost> _videos = [];
  final List<VideoPost> _followingFeed = [];
  bool _isLoading = false;
  bool _isSearching = false;
  final Set<int> _fetchedPostIds = {};
  List<VideoPost> get videos => List.unmodifiable(_videos);
  List<VideoPost> get followingFeed => List.unmodifiable(_followingFeed);
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  int page = 1;
  bool hasMoreData = true;
  Future<void> fetchVideos() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? flicToken = prefs.getString('flic_token');

    if (flicToken == null || flicToken.isEmpty) {
      debugPrint("Flic token is not available.");
      return;
    }

    _isLoading = true;
    notifyListeners();

    int page = 1;
    bool hasMoreData = true;

    try {
      while (hasMoreData) {
        final headers = {'Flic-Token': flicToken};
        final response = await http.get(
          Uri.parse('https://api.wemotions.app/feed?page=$page'),
          headers: headers,
        );

        if (response.statusCode == 200) {
          final Map<String, dynamic> data = jsonDecode(response.body);
          final List<dynamic> posts = data['posts'] ?? [];

          if (posts.isEmpty) {
            hasMoreData = false;
          } else {
            for (var post in posts) {
              int postId = post['id'];
              if (!_fetchedPostIds.contains(postId)) {
                _fetchedPostIds.add(postId);
                _videos.add(VideoPost(
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
                ));
              }
            }

            // Stop fetching if the current page is not full
            final int pageSize = data['page_size'] ?? posts.length;
            final int maxPageSize = data['max_page_size'] ?? 0;
            if (pageSize < maxPageSize) {
              hasMoreData = false;
            }
          }
        } else {
          debugPrint("Failed to fetch videos: ${response.reasonPhrase}");
          hasMoreData = false;
        }

        page++;
      }
    } catch (error) {
      debugPrint("Error fetching videos: $error");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchFollowingFeed() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? flicToken = prefs.getString('flic_token');

    if (flicToken == null || flicToken.isEmpty) {
      debugPrint("Flic token is not available.");
      return;
    }
    _isLoading = true;
    notifyListeners();

    try {
      final headers = {'Flic-Token': flicToken};
      final response = await http.get(
        Uri.parse('https://api.wemotions.app/following/posts'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(await response.body);
        final List<dynamic> posts = data['posts'] ?? [];

        _followingFeed.clear();
        _followingFeed.addAll(posts.map((post) {
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
            tags:  (post['tags'] as List<dynamic>?)
              ?.map((tagJson) => Tag.fromJson(tagJson))
              .toList() ??
          [],
          );
        }).toList());
      } else {
        debugPrint("Failed to fetch following feed: ${response.reasonPhrase}");
      }
    } catch (error) {
      debugPrint("Error fetching following feed: $error");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  static Future<List<VideoPost>> getreplys(int id) async {
  final url = Uri.parse('https://api.wemotions.app/posts/$id/replies?page=1&page_size=10');
  final response = await http.get(url);

  if (response.statusCode == 200) {
    // Decode the response as a List
    final Map<String, dynamic> data = jsonDecode(await response.body);
    final List<dynamic> posts = data['post'] ?? [];

    // Convert each post to a VideoPost object
    final List<VideoPost> videos = [];
    final Set<int> fetchedPostIds = {}; // To avoid duplicate posts

    for (var post in posts) {
      int postId = post['id'];
      if (!fetchedPostIds.contains(postId)) {
        fetchedPostIds.add(postId);
        videos.add(VideoPost(
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
          commentCount: post['comment_count'] ?? 0,
          shareCount: post['share_count'] ?? 0,
          upvoted: post['upvoted'] == true ? '1':'0',
          tags:  (post['tags'] as List<dynamic>?)
              ?.map((tagJson) => Tag.fromJson(tagJson))
              .toList() ??
          [],
        ));
      }
    }

    return videos;
  } else {
    debugPrint("Failed to fetch posts: ${response.reasonPhrase}");
    return [];
  }
}
}