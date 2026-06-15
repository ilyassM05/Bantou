import 'dart:convert';
import 'package:http/http.dart' as http;
import 'biometric_service.dart';

class CircleService {
  static const String baseUrl = 'http://10.0.2.2:3000/api/circles';

  Future<String?> _getToken() async {
    return await BiometricService.getToken();
  }

  Future<Map<String, dynamic>> createCircle({
    required String name,
    String? description,
    required String country,
    required String city,
    required String responsible,
    required String viceResponsible,
    required String meetingPlanning,
    String visibilityType = 'Public',
    List<int> initialMembers = const [],
    double? meetingLat,
    double? meetingLng,
    String? meetingAddress,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': name,
          if (description != null && description.isNotEmpty) 'description': description,
          'country': country,
          'city': city,
          'responsible': responsible,
          'viceResponsible': viceResponsible,
          'meetingPlanning': meetingPlanning,
          'visibilityType': visibilityType,
          'initialMembers': initialMembers,
          if (meetingLat != null) 'meetingLat': meetingLat,
          if (meetingLng != null) 'meetingLng': meetingLng,
          if (meetingAddress != null) 'meetingAddress': meetingAddress,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return data; // { message, circleId }
      } else {
        throw Exception(data['error'] ?? 'Failed to create circle');
      }
    } catch (e) {
      throw Exception('Create circle failed: $e');
    }
  }

  Future<Map<String, dynamic>> getCircles() async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data; // { associationName, circles: [...] }
      } else {
        throw Exception(data['error'] ?? 'Failed to fetch circles');
      }
    } catch (e) {
      throw Exception('Fetch circles failed: $e');
    }
  }

  Future<List<dynamic>> getCircleParticipants(int circleId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.get(
        Uri.parse('$baseUrl/$circleId/participants'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return data['participants'] as List<dynamic>;
      } else {
        throw Exception(data['error'] ?? 'Failed to fetch circle participants');
      }
    } catch (e) {
      throw Exception('Fetch participants failed: $e');
    }
  }

  Future<List<dynamic>> getCirclePhotos(int circleId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.get(
        Uri.parse('$baseUrl/$circleId/photos'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return data['photos'] as List<dynamic>;
      } else {
        throw Exception(data['error'] ?? 'Failed to fetch circle photos');
      }
    } catch (e) {
      throw Exception('Fetch photos failed: $e');
    }
  }

  Future<Map<String, dynamic>> uploadCirclePhoto(int circleId, String filePath) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/$circleId/photos'));
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('photo', filePath));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 201) return data;
      throw Exception(data['error'] ?? 'Failed to upload photo');
    } catch (e) {
      throw Exception('Upload photo failed: $e');
    }
  }

  Future<Map<String, dynamic>> updateCircle(
    int circleId, {
    required String name,
    String? description,
    required String country,
    required String city,
    required String responsible,
    required String viceResponsible,
    required String meetingPlanning,
    double? meetingLat,
    double? meetingLng,
    String? meetingAddress,
    bool clearLocation = false,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final body = <String, dynamic>{
        'name': name,
        'description': description,
        'country': country,
        'city': city,
        'responsible': responsible,
        'viceResponsible': viceResponsible,
        'meetingPlanning': meetingPlanning,
      };

      if (clearLocation) {
        body['meetingLat'] = null;
        body['meetingLng'] = null;
        body['meetingAddress'] = null;
      } else if (meetingLat != null) {
        body['meetingLat'] = meetingLat;
        body['meetingLng'] = meetingLng;
        body['meetingAddress'] = meetingAddress;
      }

      final response = await http.put(
        Uri.parse('$baseUrl/$circleId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data; 
      } else {
        throw Exception(data['error'] ?? 'Failed to update circle');
      }
    } catch (e) {
      throw Exception('Update circle failed: $e');
    }
  }

  Future<void> deleteCircle(int circleId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.delete(
        Uri.parse('$baseUrl/$circleId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        final data = jsonDecode(response.body);
        throw Exception(data['error'] ?? 'Failed to delete circle');
      }
    } catch (e) {
      throw Exception('Delete circle failed: $e');
    }
  }

  Future<Map<String, dynamic>> requestCircleAccess(int circleId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.post(
        Uri.parse('$baseUrl/$circleId/request-access'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 201) return data;
      throw Exception(data['error'] ?? 'Failed to request access');
    } catch (e) {
      throw Exception('Request access failed: $e');
    }
  }

  Future<Map<String, dynamic>> getPendingRequests() async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.get(
        Uri.parse('$baseUrl/requests/pending'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) return data;
      throw Exception(data['error'] ?? 'Failed to fetch pending requests');
    } catch (e) {
      throw Exception('Fetch pending requests failed: $e');
    }
  }

  Future<Map<String, dynamic>> respondToRequest(int requestId, String status, {String requestType = 'circle'}) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.put(
        Uri.parse('$baseUrl/requests/$requestId/respond'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'status': status, 'requestType': requestType}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) return data;
      throw Exception(data['error'] ?? 'Failed to respond to request');
    } catch (e) {
      throw Exception('Respond to request failed: $e');
    }
  }

  /// Member joins a circle.
  Future<void> joinCircle(int circleId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.post(
        Uri.parse('$baseUrl/$circleId/join'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode != 200) {
        final data = jsonDecode(response.body);
        throw Exception(data['error'] ?? 'Failed to join circle');
      }
    } catch (e) {
      throw Exception('Join circle failed: $e');
    }
  }

  /// Member leaves a circle.
  Future<void> leaveCircle(int circleId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.delete(
        Uri.parse('$baseUrl/$circleId/join'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode != 200) {
        final data = jsonDecode(response.body);
        throw Exception(data['error'] ?? 'Failed to leave circle');
      }
    } catch (e) {
      throw Exception('Leave circle failed: $e');
    }
  }

  /// Invites someone to a specific circle by email.
  Future<String> inviteToCircle(int circleId, String email) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.post(
        Uri.parse('$baseUrl/$circleId/invite'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'email': email}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) return data['message'] as String;
      throw Exception(data['error'] ?? 'Failed to invite');
    } catch (e) {
      throw Exception('Invite to circle failed: $e');
    }
  }

  /// Searches for members in the user's association.
  Future<List<dynamic>> searchAssociationMembers(String query) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final uri = Uri.parse('$baseUrl/association/members').replace(queryParameters: {
        if (query.isNotEmpty) 'search': query,
      });

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return data['members'] as List<dynamic>;
      } else {
        throw Exception(data['error'] ?? 'Failed to search members');
      }
    } catch (e) {
      throw Exception('Search members failed: $e');
    }
  }

  /// Approves a pending circle photo. Admin/SA only.
  Future<void> approveCirclePhoto(int circleId, int photoId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.put(
        Uri.parse('$baseUrl/$circleId/photos/$photoId/approve'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode != 200) {
        final data = jsonDecode(response.body);
        throw Exception(data['error'] ?? 'Failed to approve photo');
      }
    } catch (e) {
      throw Exception('Approve photo failed: $e');
    }
  }

  /// Rejects (deletes) a circle photo. Admin/SA only.
  Future<void> rejectCirclePhoto(int circleId, int photoId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.delete(
        Uri.parse('$baseUrl/$circleId/photos/$photoId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode != 200) {
        final data = jsonDecode(response.body);
        throw Exception(data['error'] ?? 'Failed to reject photo');
      }
    } catch (e) {
      throw Exception('Reject photo failed: $e');
    }
  }
}

