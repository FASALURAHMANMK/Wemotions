import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static Future<String?> _getFlicToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('flic_token');
  }

  static Future<void> _handleResponse(http.Response response) async {
    if (response.statusCode == 200) {
      print("Response: ${response.body}");
    } else {
      debugPrint("Error: ${response.statusCode} ${response.body}");
    }
  }

  static Future<void> addUpvote(int postId) async {
    final token = await _getFlicToken();
    if (token == null || token.isEmpty) {
      debugPrint("Token is missing. Unable to upvote.");
      return;
    }

    final headers = {
      'Flic-Token': token,
    };
    final uri = Uri.parse('https://api.wemotions.app/posts/$postId/upvote');

    final response = await http.post(uri, headers: headers);
    await _handleResponse(response);
  }

  static Future<void> removeUpvote(int postId) async {
    final token = await _getFlicToken();
    if (token == null || token.isEmpty) {
      debugPrint("Token is missing. Unable to remove upvote.");
      return;
    }

    final headers = {
      'Flic-Token': token,
    };
    final uri = Uri.parse('https://api.wemotions.app/posts/$postId/upvote');

    final response = await http.delete(uri, headers: headers);
    await _handleResponse(response);
  }
  static Future<void> getVotes() async {
    final uri = Uri.parse('https://api.wemotions.app/get/votings');
    final response = await http.get(uri);
    await _handleResponse(response);
  }

  static Future<void> addVote(String postId, String votingIcon) async {
    final token = await _getFlicToken();
    if (token == null || token.isEmpty) {
      debugPrint("Token is missing. Unable to add vote.");
      return;
    }

    final headers = {
      'Flic-Token': token,
      'Content-Type': 'application/json',
    };
    final uri = Uri.parse('https://api.wemotions.app/posts/add/votings');
    final body = jsonEncode({'post_id': postId, 'votingIcon': votingIcon});

    final response = await http.post(uri, headers: headers, body: body);
    await _handleResponse(response);
  }

  static Future<void> removeVote(String postId) async {
    final token = await _getFlicToken();
    if (token == null || token.isEmpty) {
      debugPrint("Token is missing. Unable to remove vote.");
      return;
    }

    final headers = {
      'Flic-Token': token,
      'Content-Type': 'application/json',
    };
    final uri = Uri.parse('https://api.wemotions.app/posts/remove/votings');
    final body = jsonEncode({'post_id': postId});

    final response = await http.post(uri, headers: headers, body: body);
    await _handleResponse(response);
  }

  static Future<void> follow(String username) async {
    final token = await _getFlicToken();
    if (token == null || token.isEmpty) {
      debugPrint("Token is missing. Unable to follow.");
      return;
    }

    final headers = {
      'Flic-Token': token,
    };
    final uri = Uri.parse('https://api.wemotions.app/profile/follow/$username');

    final response = await http.post(uri, headers: headers);
    await _handleResponse(response);
  }

  static Future<void> unfollow(String username) async {
    final token = await _getFlicToken();
    if (token == null || token.isEmpty) {
      debugPrint("Token is missing. Unable to unfollow.");
      return;
    }

    final headers = {
      'Flic-Token': token,
    };
    final uri = Uri.parse('https://api.wemotions.app/profile/unfollow/$username');

    final response = await http.post(uri, headers: headers);
    await _handleResponse(response);
  }
  
}