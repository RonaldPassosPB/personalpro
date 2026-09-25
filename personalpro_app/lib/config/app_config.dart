import 'package:flutter/foundation.dart';

/// Ambientes suportados pelo PersonalPro SaaS (Padrão FightCenter)
enum AppEnvironment {
  /// Ambiente local/testes (computador de desenvolvimento)
  local,

  /// Ambiente de produção (servidor oficial na nuvem)
  producao,
}

class AppConfig {
  /// Alterne para AppEnvironment.producao quando gerar o APK de produção
  static const AppEnvironment ambiente = AppEnvironment.local;

  /// URL oficial em produção
  static const String producaoUrl = 'https://api.personalpro.com.br';

  /// IP e porta da API C# .NET local
  static const String serverIp = '192.168.1.20';
  static const String serverPort = '5250';

  static String get baseUrl {
    if (ambiente == AppEnvironment.producao) {
      return producaoUrl;
    }

    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux) {
      return 'http://localhost:$serverPort';
    }
    return 'http://$serverIp:$serverPort';
  }

  static bool get isProducao => ambiente == AppEnvironment.producao;
}
