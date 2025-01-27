import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:Wemotions/features/homescreen/video_post.dart'; // Assuming VideoPost is defined

class SearchLogic {
  static Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    final url = Uri.parse('https://api.wemotions.app/search?type=user&query=$query');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Failed to load users');
    }
  }

  static Future<List<VideoPost>> searchPosts(String query) async {
  final url = Uri.parse('https://api.wemotions.app/search?type=post&query=$query');
  final response = await http.get(url);

  if (response.statusCode == 200) {
    // Decode the response as a List
    final List<dynamic> posts = jsonDecode(response.body);

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