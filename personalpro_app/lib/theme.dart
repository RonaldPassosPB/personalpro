import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static final ValueNotifier<ThemeMode> themeNotifier =
      ValueNotifier<ThemeMode>(ThemeMode.dark);

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static bool get isLight => themeNotifier.value == ThemeMode.light;

  static Future<void> carregarTemaSalvo() async {
    try {
      final salvo = await _storage.read(key: 'personalpro_theme_mode');
      if (salvo == 'light') {
        themeNotifier.value = ThemeMode.light;
      } else {
        themeNotifier.value = ThemeMode.dark;
      }
    } catch (_) {}
  }

  static Future<void> alternarTema() async {
    final novoModo = isLight ? ThemeMode.dark : ThemeMode.light;
    themeNotifier.value = novoModo;
    try {
      await _storage.write(
        key: 'personalpro_theme_mode',
        value: novoModo == ThemeMode.light ? 'light' : 'dark',
      );
    } catch (_) {}
  }

  // Cores de destaque elegantes e atléticas (inspiradas em WHOOP e Apple Fitness)
  static const Color neonGreen = Color(0xFF10B981); // Emerald 500 atlético e moderno
  static const Color primaryGreen = Color(0xFF059669); // Emerald 600 de alto contraste
  static const Color performanceRed = Color(0xFFEF4444);
  static const Color electricBlue = Color(0xFF0EA5E9);
  static const Color warningAmber = Color(0xFFF59E0B);

  // Cores adaptativas dinâmicas (Slate profissional no lugar de cinza escuro genérico)
  static Color get bgDark =>
      isLight ? const Color(0xFFF8FAFC) : const Color(0xFF090D16);

  static Color get surfaceCard =>
      isLight ? const Color(0xFFFFFFFF) : const Color(0xFF111827);

  static Color get surfaceElevated =>
      isLight ? const Color(0xFFF1F5F9) : const Color(0xFF1F2937);

  static Color get textPrimary =>
      isLight ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

  static Color get textSecondary =>
      isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

  static Color get primaryAccent =>
      isLight ? const Color(0xFF059669) : const Color(0xFF10B981);

  static const List<String> fallbackFonts = [
    'Plus Jakarta Sans',
    'Roboto',
    'Segoe UI',
    'Helvetica Neue',
    'Arial',
    'Segoe UI Emoji',
    'Apple Color Emoji',
    'Noto Color Emoji',
    'sans-serif',
  ];

  static TextStyle _withFallback(TextStyle? style, Color defaultColor) {
    final s = style ?? const TextStyle();
    return s.copyWith(
      fontFamilyFallback: fallbackFonts,
      color: s.color ?? defaultColor,
    );
  }

  static ThemeData get darkTheme => _buildTheme(Brightness.dark);
  static ThemeData get lightTheme => _buildTheme(Brightness.light);

  static ThemeData _buildTheme(Brightness brightness) {
    final light = brightness == Brightness.light;
    final bg = light ? const Color(0xFFF8FAFC) : const Color(0xFF090D16);
    final card = light ? const Color(0xFFFFFFFF) : const Color(0xFF111827);
    final elevated = light ? const Color(0xFFF1F5F9) : const Color(0xFF1F2937);
    final txtPrimary = light ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final txtSecondary = light ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
    final appBarBg = light ? const Color(0xFFFFFFFF) : const Color(0xFF0D121F);
    final borderCol = light
        ? const Color(0xFFE2E8F0)
        : const Color(0xFF1E293B);
    final primary = light ? const Color(0xFF059669) : const Color(0xFF10B981);

    final base = light
        ? ThemeData.light(useMaterial3: true)
        : ThemeData.dark(useMaterial3: true);

    final rawTextTheme = GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
      bodyColor: txtPrimary,
      displayColor: txtPrimary,
    );

    final textTheme = rawTextTheme.copyWith(
      displayLarge: _withFallback(rawTextTheme.displayLarge, txtPrimary),
      displayMedium: _withFallback(rawTextTheme.displayMedium, txtPrimary),
      displaySmall: _withFallback(rawTextTheme.displaySmall, txtPrimary),
      headlineLarge: _withFallback(rawTextTheme.headlineLarge, txtPrimary),
      headlineMedium: _withFallback(rawTextTheme.headlineMedium, txtPrimary),
      headlineSmall: _withFallback(rawTextTheme.headlineSmall, txtPrimary),
      titleLarge: _withFallback(rawTextTheme.titleLarge, txtPrimary),
      titleMedium: _withFallback(rawTextTheme.titleMedium, txtPrimary),
      titleSmall: _withFallback(rawTextTheme.titleSmall, txtPrimary),
      bodyLarge: _withFallback(rawTextTheme.bodyLarge, txtPrimary),
      bodyMedium: _withFallback(rawTextTheme.bodyMedium, txtPrimary),
      bodySmall: _withFallback(rawTextTheme.bodySmall, txtPrimary),
      labelLarge: _withFallback(rawTextTheme.labelLarge, txtPrimary),
      labelMedium: _withFallback(rawTextTheme.labelMedium, txtPrimary),
      labelSmall: _withFallback(rawTextTheme.labelSmall, txtPrimary),
    );

    return base.copyWith(
      brightness: brightness,
      scaffoldBackgroundColor: bg,
      primaryColor: primary,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primary,
        onPrimary: Colors.white,
        secondary: performanceRed,
        onSecondary: Colors.white,
        tertiary: electricBlue,
        error: performanceRed,
        onError: Colors.white,
        surface: card,
        onSurface: txtPrimary,
      ),
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: appBarBg,
        foregroundColor: txtPrimary,
        elevation: light ? 1 : 0,
        shadowColor: Colors.black12,
        centerTitle: false,
        titleTextStyle: _withFallback(
          GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: txtPrimary,
          ),
          txtPrimary,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: appBarBg,
        indicatorColor: neonGreen.withValues(alpha: 0.22),
        labelTextStyle: WidgetStateProperty.all(
          _withFallback(
            GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: txtPrimary,
            ),
            txtPrimary,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: appBarBg,
        indicatorColor: neonGreen.withValues(alpha: 0.22),
        selectedLabelTextStyle: _withFallback(
          GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: neonGreen,
          ),
          neonGreen,
        ),
        unselectedLabelTextStyle: _withFallback(
          GoogleFonts.plusJakartaSans(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: txtSecondary,
          ),
          txtSecondary,
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: _withFallback(
          GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: txtPrimary,
          ),
          txtPrimary,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: card,
        titleTextStyle: _withFallback(
          GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: txtPrimary,
          ),
          txtPrimary,
        ),
        contentTextStyle: _withFallback(
          GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: txtPrimary,
          ),
          txtPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: light ? 2 : 0,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: borderCol),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: elevated,
        labelStyle: _withFallback(TextStyle(color: txtSecondary), txtSecondary),
        hintStyle: _withFallback(TextStyle(color: txtSecondary), txtSecondary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderCol),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderCol),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: neonGreen, width: 1.8),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: _withFallback(
            GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14),
            Colors.white,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

/// Botão global para alternar entre Tema Claro (☀️) e Tema Escuro (🌙)
class BotaoAlternarTema extends StatelessWidget {
  final bool mostrarTexto;
  const BotaoAlternarTema({super.key, this.mostrarTexto = false});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppTheme.themeNotifier,
      builder: (context, mode, _) {
        final isClaro = mode == ThemeMode.light;
        if (mostrarTexto) {
          return OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              side: BorderSide(color: AppTheme.neonGreen.withValues(alpha: 0.5)),
            ),
            onPressed: () => AppTheme.alternarTema(),
            icon: Icon(
              isClaro ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              size: 17,
              color: isClaro ? const Color(0xFF0F172A) : Colors.amberAccent,
            ),
            label: Text(
              isClaro ? 'Tema Escuro' : 'Tema Claro',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
          );
        }
        return IconButton(
          tooltip: isClaro ? 'Mudar para Tema Escuro 🌙' : 'Mudar para Tema Claro ☀️',
          onPressed: () => AppTheme.alternarTema(),
          icon: Icon(
            isClaro ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
            color: isClaro ? const Color(0xFF0F172A) : Colors.amberAccent,
          ),
        );
      },
    );
  }
}
