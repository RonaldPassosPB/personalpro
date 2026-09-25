import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late final Dio dio;
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  ApiService._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await storage.read(key: 'jwt_token');
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
      ),
    );
  }

  Future<Map<String, dynamic>> login(String email, String senha) async {
    final response = await dio.post('/api/auth/login', data: {
      'email': email.trim(),
      'senha': senha,
    });
    final data = Map<String, dynamic>.from(response.data);
    await storage.write(key: 'jwt_token', value: data['token']?.toString() ?? '');
    await storage.write(key: 'user_session', value: jsonEncode(data));
    await storage.write(key: 'saved_email', value: email.trim());
    await storage.write(key: 'saved_password', value: senha);
    return data;
  }

  Future<Map<String, dynamic>?> getSavedSession() async {
    final raw = await storage.read(key: 'user_session');
    if (raw == null || raw.isEmpty) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  Future<void> logout() async {
    await storage.delete(key: 'jwt_token');
    await storage.delete(key: 'user_session');
  }
}
