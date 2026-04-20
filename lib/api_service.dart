import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // static const String baseUrl = 'http://10.0.2.2/taller-manager/api/index.php';
  //static const String baseUrl = 'http://localhost/taller-manager/api/index.php';
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost/taller-manager/api/index.php';
    } else {
      return 'http://192.168.1.35/taller-manager/api/index.php'; // tu IP aquí
    }
  }

  // Obtener el token guardado
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Cabeceras con token
  static Future<Map<String, String>> getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<dynamic> get(String endpoint) async {
    final headers = await getHeaders();
    final url = '$baseUrl$endpoint';
    print('GET: $url');
    print('Headers: $headers');
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );
      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');
      return jsonDecode(response.body);
    } catch (e) {
      print('ERROR: $e');
      rethrow;
    }
  }

  // POST
  static Future<dynamic> post(
      String endpoint, Map<String, dynamic> body) async {
    final headers = await getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );
    return jsonDecode(response.body);
  }

  // DELETE
  static Future<dynamic> delete(String endpoint) async {
    final headers = await getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    );
    return jsonDecode(response.body);
  }
}
