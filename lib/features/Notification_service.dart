import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  final String baseUrl = 'https://api.wemotions.app/user/notification';

  // Retrieve Flic-Token from SharedPreferences
  Future<String> getFlicToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('flic_token') ?? '';
  }

  // Get all notifications
  Future<List<Map<String, dynamic>>> getAllNotifications() async {
    String token = await getFlicToken();
    final headers = {'Flic-Token': token};
    final response = await http.get(Uri.parse('$baseUrl?page=1&page_size=10'), headers: headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      List notifications = data['notifications'] ?? [];
      return notifications.map<Map<String, dynamic>>((notification) {
        // If action type is 'follow', set content_avatar_url to null
        if (notification['action_type'] == 'follow') {
          notification['content_avatar_url'] = null;
        }
        return notification;
      }).toList();
    } else {
      throw Exception('Failed to fetch notifications: ${response.reasonPhrase}');
    }
  }

  // Get unread notifications
  Future<List<Map<String, dynamic>>> getUnreadNotifications() async {
    List<Map<String, dynamic>> allNotifications = await getAllNotifications();
    return allNotifications.where((notification) => notification['has_seen'] == null).toList();
  }
Future<int> getUnreadNotificationCount() async {
    try {
      List<Map<String, dynamic>> unreadNotifications = await getUnreadNotifications();
      return unreadNotifications.length;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching unread notifications count: $e');
      }
      return 0;
    }
  }
  // Mark a notification as read
  Future<void> readNotification(int notificationId) async {
  try {
    // Retrieve the Flic-Token from Shared Preferences
    final prefs = await SharedPreferences.getInstance();
    final flicToken = prefs.getString('flic_token');

    if (flicToken == null) {
      print('Flic-Token not found in SharedPreferences.');
      return;
    }

    // Define headers
    var headers = {
      'Flic-Token': flicToken,
      'Content-Type': 'application/json',
    };

    // Define the request body
    var body = jsonEncode({
      "notification_id": notificationId,
    });

    // Create the HTTP request
    var request = http.Request(
      'PUT',
      Uri.parse('https://api.wemotions.app/user/notification'),
    );
    request.body = body;
    request.headers.addAll(headers);

    // Send the request
    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      // Parse the response
      String responseBody = await response.stream.bytesToString();
      var jsonResponse = jsonDecode(responseBody);

      if (jsonResponse['status'] == 'success') {
        print(jsonResponse['message']);
      } else {
        print('Error: ${jsonResponse['message']}');
      }
    } else {
      print('HTTP Error: ${response.reasonPhrase}');
    }
  } catch (e) {
    print('Error occurred: $e');
  }
}

  // Delete a notification
 Future<void> deleteNotification(int notificationId) async {
  String token = await getFlicToken(); // Get the token
  var headers = {
    'Flic-Token': token,
    'Content-Type': 'application/json',
    };
  var body = jsonEncode({
      "notification_id": notificationId,
    });

  var request = http.Request(
    'DELETE',
    Uri.parse('https://api.wemotions.app/user/notification'),
  );

  request.headers.addAll(headers);
  request.body = body;

  try {
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      if (kDebugMode) {
        print('Notification $notificationId deleted successfully.');
      }
    } else {
      print(token);
      print(notificationId);
      throw Exception(
        'Failed to delete notification: ${response.reasonPhrase}',
      );
    }
  } catch (e) {
    print('Error: $e');
    throw Exception('An error occurred while deleting the notification.');
  }
}
}
