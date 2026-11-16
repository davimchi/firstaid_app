import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000/api/v1';
  static const Duration _timeout = Duration(seconds: 10);

  Future<String> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');
    if (token != null) return token;

    final response = await http.post(
      Uri.parse('$baseUrl/auth/device'),
      headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
      body: jsonEncode({'device_id': '550e8400-e29b-41d4-a716-446655440000', 'platform': 'android'}),
    ).timeout(_timeout);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      token = data['data']['token'];
      await prefs.setString('auth_token', token!);
      return token;
    }
    throw Exception('Failed to register device');
  }

  Future<void> upgradeAccount(String name, String email, String password) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/auth/upgrade'),
      headers: {'Accept': 'application/json', 'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    ).timeout(_timeout);

    if (response.statusCode != 200) {
      String msg = 'Upgrade failed';
      try {
        final error = jsonDecode(response.body);
        msg = error['message'] ?? msg;
      } catch (_) {}
      throw Exception(msg);
    }
  }

  Future<void> backupContacts(List<Map<String, dynamic>> contacts) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/contacts/backup'),
      headers: {'Accept': 'application/json', 'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode({'contacts': contacts}),
    ).timeout(_timeout);

    if (response.statusCode != 200) {
      String msg = 'Backup failed';
      try {
        final error = jsonDecode(response.body);
        msg = error['message'] ?? msg;
      } catch (_) {}
      throw Exception(msg);
    }
  }

  Future<List<dynamic>> restoreContacts() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/contacts/restore'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    ).timeout(_timeout);

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['data'];
    }
    throw Exception('Restore failed');
  }

  Future<Map<String, dynamic>> fetchManifest() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/sync/manifest'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    ).timeout(_timeout);

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['data'];
    } else {
      throw Exception('Failed to load manifest');
    }
  }

  Future<Map<String, dynamic>> fetchContent() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/sync/content'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    ).timeout(_timeout);
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['data'];
    }
    throw Exception('Failed to load content');
  }
}
