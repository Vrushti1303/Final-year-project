import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;


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
    } else {
      throw Exception('Failed to explain snippet');
    }
  }

  static Future<Map<String, dynamic>> fetchChecklist(String type) async {
    final response = await http.get(Uri.parse('$baseUrl/checklists/$type'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load checklist');
    }
  }

  static Future<Map<String, dynamic>> chat(List<Map<String, dynamic>> history) async {
    final response = await http.post(
      Uri.parse('$baseUrl/chat'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'history': history}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to send chat message');
    }
  }
}
