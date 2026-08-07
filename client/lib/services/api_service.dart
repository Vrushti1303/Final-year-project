import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';


class ApiService {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/api';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000/api';
    }
    return 'http://localhost:3000/api';
  }


  static Future<Map<String, dynamic>> scanDocument(String text) async {
    final response = await http.post(
      Uri.parse('$baseUrl/scan'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'text': text}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 429) {
      throw RateLimitException('Rate limit reached. Please try again later.');
    } else {
      throw Exception('Failed to analyze document');
    }
  }

  static Future<String> explainSnippet(String context, String snippet) async {
    final response = await http.post(
      Uri.parse('$baseUrl/explain'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'context': context, 'snippet': snippet}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['explanation'];
    } else if (response.statusCode == 429) {
      throw RateLimitException('Rate limit reached. Please try again later.');
    } else {
      throw Exception('Failed to explain snippet');
    }
  }

  static Future<List<dynamic>> getLegalNews() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/news/legal-updates'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching legal news: $e');
      return [];
    }
  }

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  static Future<List<dynamic>> fetchAllChecklists() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/checklists'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      }
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load checklists');
    }
  }

  static Future<Map<String, dynamic>> fetchChecklist(String type) async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/checklists/$type'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      }
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load checklist');
    }
  }

  static Future<Map<String, dynamic>> updateChecklistItem(String type, String itemId, bool isCompleted) async {
    final token = await _getToken();
    final response = await http.put(
      Uri.parse('$baseUrl/checklists/$type/items/$itemId'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'isCompleted': isCompleted}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update checklist item');
    }
  }

  static Future<Map<String, dynamic>> addChecklistItem(String type, String title) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/checklists/$type/items'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'title': title}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to add checklist item');
    }
  }

  static Future<Map<String, dynamic>> generateChecklist(String prompt) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/checklists/generate'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'prompt': prompt}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to generate checklist');
    }
  }

  static Future<Map<String, dynamic>> chat(List<Map<String, dynamic>> history) async {
    final sanitizedHistory = history.map((m) => {
      'role': m['role'],
      'text': m['text'],
    }).toList();
    
    final response = await http.post(
      Uri.parse('$baseUrl/chat'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'history': sanitizedHistory}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 429) {
      throw RateLimitException('Rate limit reached. Please wait a moment before sending another message.');
    } else {
      throw Exception('Failed to send chat message');
    }
  }

  // Auth Methods
  static Future<Map<String, dynamic>> sendOtp({
    required String email,
    required String type, // 'login' or 'signup'
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/send-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'type': type,
      }),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body)['error'] ?? 'Failed to send OTP';
      throw Exception(error);
    }
  }

  static Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String otp,
    required String type,
    String? fullName,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/verify-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'otp': otp,
        'type': type,
        if (fullName != null && fullName.isNotEmpty) 'full_name': fullName,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body)['error'] ?? 'Failed to verify OTP';
      throw Exception(error);
    }
  }

  static Future<Map<String, dynamic>> resendOtp(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/resend-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body)['error'] ?? 'Failed to resend OTP';
      throw Exception(error);
    }
  }

  static Future<Map<String, dynamic>> getProfile(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch profile');
    }
  }
}

class RateLimitException implements Exception {
  final String message;
  RateLimitException(this.message);
  
  @override
  String toString() => message;
}
