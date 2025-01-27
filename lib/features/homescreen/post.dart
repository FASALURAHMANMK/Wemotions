import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

Future<Map<String, dynamic>> postVideo(String videoPath, String parentVideoId,
    List<String> usernames, String title) async {
  const String baseUrl = 'https://api.wemotions.app';
  const String flicTokenKey = 'flic_token';
  const String usernameKey = 'username';

  try {
    // Step 1: Retrieve Flic-Token from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final flicToken = prefs.getString(flicTokenKey);
    final username = prefs.getString(usernameKey);
    if (flicToken == null || flicToken.isEmpty) {
      throw Exception('Flic-Token is not available in SharedPreferences');
    }

    // Step 2: Generate Upload URL
    final generateUrlHeaders = {'Flic-Token': flicToken};

    final generateUrlResponse = await http.get(
      Uri.parse('$baseUrl/posts/generate-upload-url'),
      headers: generateUrlHeaders,
    );

    if (generateUrlResponse.statusCode != 200) {
      throw Exception(
          'Failed to generate upload URL: ${generateUrlResponse.reasonPhrase}');
    }

    final generateUrlData = jsonDecode(generateUrlResponse.body);
    final uploadUrl = generateUrlData['url'];
    final videoHash = generateUrlData['hash'];

    // Step 3: Upload Video
    final uploadHeaders = {'Content-Type': 'video/mp4'};
    final videoFile = File(videoPath);

    final uploadRequest = http.Request('PUT', Uri.parse(uploadUrl))
      ..headers.addAll(uploadHeaders)
      ..bodyBytes = await videoFile.readAsBytes();

    final uploadResponse = await uploadRequest.send();

    if (uploadResponse.statusCode != 200) {
      throw Exception('Failed to upload video: ${uploadResponse.reasonPhrase}');
    }

    // Step 4: Create Post
    final createPostHeaders = {
      'Flic-Token': flicToken,
      'Content-Type': 'application/json',
    };

    final createPostBody = jsonEncode({
      "title": title,
      "hash": videoHash,
      "is_available_in_public_feed": false,
      "parent_video_id": parentVideoId,
      "category_id": null,
    });

    final createPostResponse = await http.post(
      Uri.parse('$baseUrl/posts'),
      headers: createPostHeaders,
      body: createPostBody,
    );

    if (createPostResponse.statusCode != 200) {
      throw Exception(
          'Failed to create post: ${createPostResponse.reasonPhrase}');
    }

    final createPostData = jsonDecode(createPostResponse.body);
    final postSlug = createPostData['slug'];

    // Step 5: Match Slug to Retrieve Post ID
    final fetchPostsHeaders = {'Flic-Token': flicToken};

    final fetchPostsResponse = await http.get(
      Uri.parse('$baseUrl/users/$username/posts?page=1'),
      headers: fetchPostsHeaders,
    );

    if (fetchPostsResponse.statusCode != 200) {
      throw Exception(
          'Failed to fetch posts: ${fetchPostsResponse.reasonPhrase}');
    }

    final postsData = jsonDecode(fetchPostsResponse.body);
    final posts = postsData['posts'] as List;

    final post =
        posts.firstWhere((p) => p['slug'] == postSlug, orElse: () => null);

    if (post == null) {
      throw Exception('Post not found for slug: $postSlug');
    }

    final postId = post['id'];

    // Step 6: Tag Users
    if (usernames.isNotEmpty) {
      for (String username in usernames) {
        final tagHeaders = {
          'Flic-Token': flicToken,
          'Content-Type': 'application/json',
        };

        final tagBody = jsonEncode({
          "post_id": postId,
          "username": username,
        });

        final tagResponse = await http.post(
          Uri.parse('$baseUrl/posts/tag'),
          headers: tagHeaders,
          body: tagBody,
        );

        if (tagResponse.statusCode != 200) {
          throw Exception(
              'Failed to tag user $username: ${tagResponse.reasonPhrase}');
        }

        final tagData = jsonDecode(tagResponse.body);
        if (tagData['status'] != 'Success') {
          throw Exception('Failed to tag user $username');
        }
      }
    }

    return {
      'status': 'success',
      'message': createPostData['message'],
      'postIdentifier': createPostData['identifier'],
      'postSlug': createPostData['slug'],
    };
  } catch (error) {
    if (kDebugMode) {
      print('Error: $error');
    }
    return {'status': 'error', 'message': error.toString()};
  }
}
