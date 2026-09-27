import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late final Dio dio;
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  /// Corrige automaticamente qualquer texto que tenha sofrido dupla codificação
  /// UTF-8 / Windows-1252 (ex: "MÃ¡quina" -> "Máquina", "â€”" -> "—")
  static String limparMojibake(String input) {
    if (input.isEmpty) return input;
    var s = input;
    const map = <String, String>{
      'â€”': '—',
      'â€“': '–',
      'â€¢': '•',
      'Â°': '°',
      'Âº': 'º',
      'Âª': 'ª',
      'Ã¡': 'á',
      'Ã ': 'à',
      'Ã¢': 'â',
      'Ã£': 'ã',
      'Ã©': 'é',
      'Ãª': 'ê',
      'Ã­': 'í',
      'Ã³': 'ó',
      'Ã´': 'ô',
      'Ãµ': 'õ',
      'Ãº': 'ú',
      'Ã¼': 'ü',
      'Ã§': 'ç',
      'Ã\u0081': 'Á',
      'Ã€': 'À',
      'Ã‚': 'Â',
      'Ãƒ': 'Ã',
      'Ã‰': 'É',
      'ÃŠ': 'Ê',
      'Ã\u008d': 'Í',
      'Ã“': 'Ó',
      'Ã”': 'Ô',
      'Ã•': 'Õ',
      'Ãš': 'Ú',
      'Ã‡': 'Ç',
    };
    map.forEach((k, v) {
      if (s.contains(k)) {
        s = s.replaceAll(k, v);
      }
    });
    return s;
  }

  static dynamic sanitizarDadosJson(dynamic data) {
    if (data is String) {
      return limparMojibake(data);
    } else if (data is List) {
      return data.map(sanitizarDadosJson).toList();
    } else if (data is Map) {
      return data.map(
        (key, value) => MapEntry(key, sanitizarDadosJson(value)),
      );
    }
    return data;
  }

  ApiService._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
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
        onResponse: (response, handler) {
          response.data = sanitizarDadosJson(response.data);
          return handler.next(response);
        },
      ),
    );
  }

  Future<Map<String, dynamic>> login(String email, String senha) async {
    final response = await dio.post('/api/auth/login', data: {
      'email': email.trim(),
      'senha': senha,
    });
    final data = Map<String, dynamic>.from(sanitizarDadosJson(response.data));
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
      final decoded = jsonDecode(limparMojibake(raw));
      return Map<String, dynamic>.from(sanitizarDadosJson(decoded));
    } catch (_) {
      return null;
    }
  }

  Future<void> logout() async {
    await storage.delete(key: 'jwt_token');
    await storage.delete(key: 'user_session');
  }
}
