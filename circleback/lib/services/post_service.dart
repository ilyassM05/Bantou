import 'dart:convert';
import 'package:http/http.dart' as http;
import 'biometric_service.dart';
import '../models/post.dart';
import '../models/post_comment.dart';
import '../models/association_member.dart';
import '../models/user_profile.dart';

class PostService {
  static const String baseUrl = 'http://10.0.2.2:3000/api/posts';

  Future<String?> _getToken() async {
    return await BiometricService.getToken();
  }

  // ── Posts ────────────────────────────────────────────────────────────────

  Future<List<Post>> getPosts() async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {'Authorization': 'Bearer $token'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final List<dynamic> postsData = data['posts'];
        return postsData.map((p) => Post.fromJson(p)).toList();
      } else {
        throw Exception(data['error'] ?? 'Failed to fetch posts');
      }
    } catch (e) {
      throw Exception('Fetch posts failed: $e');
    }
  }

  Future<void> createPost(String content, String? imagePath) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      var request = http.MultipartRequest('POST', Uri.parse(baseUrl));
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['content'] = content;

      if (imagePath != null && imagePath.isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath('image', imagePath));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode != 201) {
        throw Exception(data['error'] ?? 'Failed to create post');
      }
    } catch (e) {
      throw Exception('Create post failed: $e');
    }
  }

  Future<void> deletePost(int postId) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final http.Response response;
    try {
      response = await http.delete(
        Uri.parse('$baseUrl/$postId'),
        headers: {'Authorization': 'Bearer $token'},
      );
    } catch (e) {
      throw Exception('Network error: could not reach the server.');
    }

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['error'] ?? 'Failed to delete post.');
    }
  }

  /// Toggles like on a post. Returns {liked: bool, likesCount: int}.
  Future<Map<String, dynamic>> toggleLike(int postId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.post(
        Uri.parse('$baseUrl/$postId/like'),
        headers: {'Authorization': 'Bearer $token'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'liked': data['liked'] as bool,
          'likesCount': data['likesCount'] as int,
        };
      } else {
        throw Exception(data['error'] ?? 'Failed to toggle like');
      }
    } catch (e) {
      throw Exception('Toggle like failed: $e');
    }
  }

  /// Fetches a user's public profile data.
  Future<UserProfile> getUserProfile(int userId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.get(
        Uri.parse('$baseUrl/user/$userId/profile'),
        headers: {'Authorization': 'Bearer $token'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return UserProfile.fromJson(data);
      } else {
        throw Exception(data['error'] ?? 'Failed to fetch profile');
      }
    } catch (e) {
      throw Exception('Get profile failed: $e');
    }
  }

  // ── Comments ─────────────────────────────────────────────────────────────

  /// Fetches all comments for [postId] in chronological order.
  Future<List<PostComment>> getComments(int postId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.get(
        Uri.parse('$baseUrl/$postId/comments'),
        headers: {'Authorization': 'Bearer $token'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final List<dynamic> list = data['comments'];
        return list.map((c) => PostComment.fromJson(c)).toList();
      } else {
        throw Exception(data['error'] ?? 'Failed to fetch comments');
      }
    } catch (e) {
      throw Exception('Get comments failed: $e');
    }
  }

  /// Adds a comment to [postId] and returns the newly created comment.
  Future<PostComment> addComment(int postId, String content) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.post(
        Uri.parse('$baseUrl/$postId/comments'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'content': content}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return PostComment.fromJson(data['comment']);
      } else {
        throw Exception(data['error'] ?? 'Failed to add comment');
      }
    } catch (e) {
      throw Exception('Add comment failed: $e');
    }
  }

  // ── Sharing ──────────────────────────────────────────────────────────────

  /// Returns all association members (excluding self) for the share picker.
  Future<List<AssociationMember>> getAssociationMembers() async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.get(
        Uri.parse('$baseUrl/members'),
        headers: {'Authorization': 'Bearer $token'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final List<dynamic> list = data['members'];
        return list.map((m) => AssociationMember.fromJson(m)).toList();
      } else {
        throw Exception(data['error'] ?? 'Failed to fetch members');
      }
    } catch (e) {
      throw Exception('Get members failed: $e');
    }
  }

  /// Shares [postId] with all [recipientIds] (any number of association members).
  Future<void> sharePost(int postId, List<int> recipientIds) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.post(
        Uri.parse('$baseUrl/$postId/share'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'recipientIds': recipientIds}),
      );

      if (response.statusCode != 200) {
        final data = jsonDecode(response.body);
        throw Exception(data['error'] ?? 'Failed to share post');
      }
    } catch (e) {
      throw Exception('Share post failed: $e');
    }
  }

  // ── Friend Requests ──────────────────────────────────────────────────────

  static const String _friendBaseUrl = 'http://10.0.2.2:3000/api/friends';

  /// Returns relationship status with [userId]:
  /// 'none' | 'pending_sent' | 'pending_received' | 'friends' | 'self'
  Future<String> getFriendStatus(int userId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.get(
        Uri.parse('$_friendBaseUrl/status/$userId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data['status'] as String? ?? 'none';
      } else {
        throw Exception(data['error'] ?? 'Failed to get friend status');
      }
    } catch (e) {
      throw Exception('Get friend status failed: $e');
    }
  }

  /// Sends a friend request to [userId].
  Future<void> sendFriendRequest(int userId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.post(
        Uri.parse('$_friendBaseUrl/request/$userId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        final data = jsonDecode(response.body);
        throw Exception(data['error'] ?? 'Failed to send friend request');
      }
    } catch (e) {
      throw Exception('Send friend request failed: $e');
    }
  }

  /// Returns pending incoming friend requests.
  Future<List<dynamic>> getPendingFriendRequests() async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.get(
        Uri.parse('$_friendBaseUrl/requests/pending'),
        headers: {'Authorization': 'Bearer $token'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data['requests'] as List<dynamic>? ?? [];
      } else {
        throw Exception(data['error'] ?? 'Failed to get pending friend requests');
      }
    } catch (e) {
      throw Exception('Get pending friend requests failed: $e');
    }
  }

  /// Returns pending outgoing friend requests (sent by current user).
  Future<List<dynamic>> getSentFriendRequests() async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.get(
        Uri.parse('$_friendBaseUrl/requests/sent'),
        headers: {'Authorization': 'Bearer $token'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data['requests'] as List<dynamic>? ?? [];
      } else {
        throw Exception(data['error'] ?? 'Failed to get sent friend requests');
      }
    } catch (e) {
      throw Exception('Get sent friend requests failed: $e');
    }
  }

  /// Responds to a friend request (action: 'accept' or 'decline').
  Future<void> respondToFriendRequest(int requestId, String action) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.put(
        Uri.parse('$_friendBaseUrl/respond/$requestId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'action': action}),
      );

      if (response.statusCode != 200) {
        final data = jsonDecode(response.body);
        throw Exception(data['error'] ?? 'Failed to respond to friend request');
      }
    } catch (e) {
      throw Exception('Respond to friend request failed: $e');
    }
  }

  /// Returns the list of accepted friends for the current user.
  Future<List<dynamic>> getFriends() async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.get(
        Uri.parse(_friendBaseUrl),
        headers: {'Authorization': 'Bearer $token'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data['friends'] as List<dynamic>? ?? [];
      } else {
        throw Exception(data['error'] ?? 'Failed to get friends');
      }
    } catch (e) {
      throw Exception('Get friends failed: $e');
    }
  }

  /// Removes a friend (bidirectional). After this call the status reverts to 'none'.
  Future<void> removeFriend(int targetUserId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.delete(
        Uri.parse('$_friendBaseUrl/$targetUserId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode != 200) {
        final data = jsonDecode(response.body);
        throw Exception(data['error'] ?? 'Failed to remove friend');
      }
    } catch (e) {
      throw Exception('Remove friend failed: $e');
    }
  }
}
