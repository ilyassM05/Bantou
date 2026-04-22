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
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.delete(
        Uri.parse('$baseUrl/$postId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode != 200) {
        final data = jsonDecode(response.body);
        throw Exception(data['error'] ?? 'Failed to delete post');
      }
    } catch (e) {
      throw Exception('Delete post failed: $e');
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
}
