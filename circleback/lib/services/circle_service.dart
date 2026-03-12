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
    required String country,
    required String city,
    required String responsible,
    required String viceResponsible,
    required String meetingPlanning,
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
          'country': country,
          'city': city,
          'responsible': responsible,
          'viceResponsible': viceResponsible,
          'meetingPlanning': meetingPlanning,
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
}
