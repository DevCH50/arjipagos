import 'package:flutter/material.dart';

/// Colores de la aplicación ArjiPagos.
///
/// Centraliza todos los colores utilizados en la app para
/// facilitar el mantenimiento y consistencia visual.
class AppColors {
  AppColors._();

  // ============================================================================
  // COLORES PRIMARIOS
  // ============================================================================

  /// Color primario de la marca (marrón)
  static const Color primary = Color(0xFF795548);
  static const Color primaryDark = Color(0xFF5D4037);
  static const Color primaryLight = Color(0xFF8D6E63);

  /// Color secundario (naranja/ámbar)
  static const Color secondary = Color(0xFF8A5101);
  static const Color secondaryLight = Color(0xFFFFB74D);

  // ============================================================================
  // COLORES DE ESTADO
  // ============================================================================

  /// Verde para éxito
  static const Color success = Color(0xFF4CAF50);
  static const Color successLight = Color(0xFFE8F5E9);

  /// Rojo para errores
  static const Color error = Color(0xFFF44336);
  static const Color errorLight = Color(0xFFFFEBEE);

  /// Naranja para advertencias
  static const Color warning = Color(0xFFFF9800);
  static const Color warningLight = Color(0xFFFFF3E0);

  /// Azul para información
  static const Color info = Color(0xFF2196F3);
  static const Color infoLight = Color(0xFFE3F2FD);

  // ============================================================================
  // COLORES DE FONDO
  // ============================================================================

  /// Fondo del splash screen
  static const Color splashGradientStart = Color.fromARGB(255, 93, 43, 2);
  static const Color splashGradientEnd = Color.fromARGB(255, 138, 81, 1);

  /// Fondo de cards y contenedores
  static const Color cardBackground = Colors.white;
  static const Color scaffoldBackground = Color(0xFFF5F5F5);

  // ============================================================================
  // COLORES DE TEXTO
  // ============================================================================

  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFF9E9E9E);
  static const Color textOnPrimary = Colors.white;

  // ============================================================================
  // COLORES DE ALUMNOS (TEMA CLARO)
  // ============================================================================

  /// Colores para alumno activo - Tema Claro
  static Color alumnoActivoBackground = Colors.blue.shade100;
  static Color alumnoActivoText = Colors.blue.shade900;

  /// Colores para alumno dado de baja - Tema Claro
  static Color alumnoBajaBackground = Colors.red.shade100;
  static Color alumnoBajaText = Colors.red.shade900;

  // ============================================================================
  // COLORES DE ALUMNOS (TEMA OSCURO)
  // ============================================================================

  /// Colores para alumno activo - Tema Oscuro
  static Color alumnoActivoBackgroundDark = const Color(0xFF1E3A5F);
  static Color alumnoActivoTextDark = const Color(0xFF90CAF9);

  /// Colores para alumno dado de baja - Tema Oscuro
  static Color alumnoBajaBackgroundDark = const Color(0xFF5C2323);
  static Color alumnoBajaTextDark = const Color(0xFFEF9A9A);

  // ============================================================================
  // COLORES DE HEADER HOME (TEMA CLARO)
  // ============================================================================

  static Color homeHeaderBackground = Colors.blue.shade50;
  static Color homeHeaderIcon = Colors.blue.shade700;
  static Color homeHeaderText = Colors.blue.shade900;

  // ============================================================================
  // COLORES DE HEADER HOME (TEMA OSCURO)
  // ============================================================================

  static const Color homeHeaderBackgroundDark = Color(0xFF1E1E1E);
  static const Color homeHeaderIconDark = Color(0xFF90CAF9);
  static const Color homeHeaderTextDark = Color(0xFFBBDEFB);

  // ============================================================================
  // COLORES DE DIÁLOGOS (TEMA CLARO)
  // ============================================================================

  static Color dialogBackground = Colors.white;
  static Color dialogTitleText = const Color(0xFF212121);
  static Color dialogBodyText = const Color(0xFF757575);

  // ============================================================================
  // COLORES DE DIÁLOGOS (TEMA OSCURO)
  // ============================================================================

  static const Color dialogBackgroundDark = Color(0xFF2C2C2C);
  static const Color dialogTitleTextDark = Colors.white;
  static const Color dialogBodyTextDark = Color(0xFFBDBDBD);

  // ============================================================================
  // UTILIDADES
  // ============================================================================

  /// Obtiene el color de fondo de alumno activo según el tema
  static Color getAlumnoActivoBackground(bool isDark) =>
      isDark ? alumnoActivoBackgroundDark : alumnoActivoBackground;

  /// Obtiene el color de texto de alumno activo según el tema
  static Color getAlumnoActivoText(bool isDark) =>
      isDark ? alumnoActivoTextDark : alumnoActivoText;

  /// Obtiene el color de fondo de alumno baja según el tema
  static Color getAlumnoBajaBackground(bool isDark) =>
      isDark ? alumnoBajaBackgroundDark : alumnoBajaBackground;

  /// Obtiene el color de texto de alumno baja según el tema
  static Color getAlumnoBajaText(bool isDark) =>
      isDark ? alumnoBajaTextDark : alumnoBajaText;

  /// Obtiene el color de fondo del header según el tema
  static Color getHomeHeaderBackground(bool isDark) =>
      isDark ? homeHeaderBackgroundDark : homeHeaderBackground;

  /// Obtiene el color del icono del header según el tema
  static Color getHomeHeaderIcon(bool isDark) =>
      isDark ? homeHeaderIconDark : homeHeaderIcon;

  /// Obtiene el color del texto del header según el tema
  static Color getHomeHeaderText(bool isDark) =>
      isDark ? homeHeaderTextDark : homeHeaderText;
}
