import 'package:flutter/material.dart';

/// Esquemas de color "Arji" generados con Material Theme Builder.
///
/// Paleta dorada/ámbar compatible con Material Design 3.
/// Incluye variantes claro, oscuro y contrastes de accesibilidad.
class MaterialTheme {
  final TextTheme textTheme;

  const MaterialTheme(this.textTheme);

  // ============================================================================
  // TEMA CLARO
  // ============================================================================

  static ColorScheme lightScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff765a00),
      surfaceTint: Color(0xff765a00),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xffd9ad30),
      onPrimaryContainer: Color(0xff574200),
      secondary: Color(0xff6f5c2d),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xfffae0a4),
      onSecondaryContainer: Color(0xff756232),
      tertiary: Color(0xff4d6700),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff9fbe56),
      onTertiaryContainer: Color(0xff384b00),
      error: Color(0xffba1a1a),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffffdad6),
      onErrorContainer: Color(0xff93000a),
      surface: Color(0xfffff8f1),
      onSurface: Color(0xff1f1b13),
      onSurfaceVariant: Color(0xff4e4635),
      outline: Color(0xff807663),
      outlineVariant: Color(0xffd1c5af),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff343027),
      onInverseSurface: Color(0xfff6eddf),
      inversePrimary: Color(0xffefc143),
      primaryFixed: Color(0xffffdf95),
      onPrimaryFixed: Color(0xff251a00),
      primaryFixedDim: Color(0xffefc143),
      onPrimaryFixedVariant: Color(0xff594400),
      secondaryFixed: Color(0xfffae0a4),
      onSecondaryFixed: Color(0xff251a00),
      secondaryFixedDim: Color(0xffddc48a),
      onSecondaryFixedVariant: Color(0xff564517),
      tertiaryFixed: Color(0xffceef80),
      onTertiaryFixed: Color(0xff151f00),
      tertiaryFixedDim: Color(0xffb2d268),
      onTertiaryFixedVariant: Color(0xff394d00),
      surfaceDim: Color(0xffe2d9cb),
      surfaceBright: Color(0xfffff8f1),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfffcf2e4),
      surfaceContainer: Color(0xfff6eddf),
      surfaceContainerHigh: Color(0xfff0e7d9),
      surfaceContainerHighest: Color(0xffeae1d3),
    );
  }

  ThemeData light() {
    return theme(lightScheme());
  }

  // ============================================================================
  // TEMA CLARO — CONTRASTE MEDIO
  // ============================================================================

  static ColorScheme lightMediumContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff453400),
      surfaceTint: Color(0xff765a00),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff886900),
      onPrimaryContainer: Color(0xffffffff),
      secondary: Color(0xff443407),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff7f6b3a),
      onSecondaryContainer: Color(0xffffffff),
      tertiary: Color(0xff2b3b00),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff5b7614),
      onTertiaryContainer: Color(0xffffffff),
      error: Color(0xff740006),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffcf2c27),
      onErrorContainer: Color(0xffffffff),
      surface: Color(0xfffff8f1),
      onSurface: Color(0xff141109),
      onSurfaceVariant: Color(0xff3d3525),
      outline: Color(0xff5a5240),
      outlineVariant: Color(0xff756c59),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff343027),
      onInverseSurface: Color(0xfff0e7d9),
      inversePrimary: Color(0xffefc143),
      primaryFixed: Color(0xff886900),
      onPrimaryFixed: Color(0xffffffff),
      primaryFixedDim: Color(0xff6a5100),
      onPrimaryFixedVariant: Color(0xffffffff),
      secondaryFixed: Color(0xff7f6b3a),
      onSecondaryFixed: Color(0xffffffff),
      secondaryFixedDim: Color(0xff655324),
      onSecondaryFixedVariant: Color(0xffffffff),
      tertiaryFixed: Color(0xff5b7614),
      onTertiaryFixed: Color(0xffffffff),
      tertiaryFixedDim: Color(0xff455d00),
      onTertiaryFixedVariant: Color(0xffffffff),
      surfaceDim: Color(0xffcec5b8),
      surfaceBright: Color(0xfffff8f1),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfffcf2e4),
      surfaceContainer: Color(0xfff0e7d9),
      surfaceContainerHigh: Color(0xffe5dcce),
      surfaceContainerHighest: Color(0xffd9d0c3),
    );
  }

  ThemeData lightMediumContrast() {
    return theme(lightMediumContrastScheme());
  }

  // ============================================================================
  // TEMA CLARO — ALTO CONTRASTE
  // ============================================================================

  static ColorScheme lightHighContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff392a00),
      surfaceTint: Color(0xff765a00),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff5c4600),
      onPrimaryContainer: Color(0xffffffff),
      secondary: Color(0xff392a00),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff584719),
      onSecondaryContainer: Color(0xffffffff),
      tertiary: Color(0xff233100),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff3b5000),
      onTertiaryContainer: Color(0xffffffff),
      error: Color(0xff600004),
      onError: Color(0xffffffff),
      errorContainer: Color(0xff98000a),
      onErrorContainer: Color(0xffffffff),
      surface: Color(0xfffff8f1),
      onSurface: Color(0xff000000),
      onSurfaceVariant: Color(0xff000000),
      outline: Color(0xff322b1c),
      outlineVariant: Color(0xff504837),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff343027),
      onInverseSurface: Color(0xffeae1d3),
      inversePrimary: Color(0xffefc143),
      primaryFixed: Color(0xff5c4600),
      onPrimaryFixed: Color(0xffffffff),
      primaryFixedDim: Color(0xff413000),
      onPrimaryFixedVariant: Color(0xffffffff),
      secondaryFixed: Color(0xff584719),
      onSecondaryFixed: Color(0xffffffff),
      secondaryFixedDim: Color(0xff403104),
      onSecondaryFixedVariant: Color(0xffffffff),
      tertiaryFixed: Color(0xff3b5000),
      onTertiaryFixed: Color(0xffffffff),
      tertiaryFixedDim: Color(0xff283800),
      onTertiaryFixedVariant: Color(0xffffffff),
      surfaceDim: Color(0xffc0b8ab),
      surfaceBright: Color(0xfffff8f1),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfff9f0e1),
      surfaceContainer: Color(0xffeae1d3),
      surfaceContainerHigh: Color(0xffdcd3c6),
      surfaceContainerHighest: Color(0xffcec5b8),
    );
  }

  ThemeData lightHighContrast() {
    return theme(lightHighContrastScheme());
  }

  // ============================================================================
  // TEMA OSCURO
  // ============================================================================

  static ColorScheme darkScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xfff7c84a),
      surfaceTint: Color(0xffefc143),
      onPrimary: Color(0xff3e2e00),
      primaryContainer: Color(0xffd9ad30),
      onPrimaryContainer: Color(0xff574200),
      secondary: Color(0xffddc48a),
      onSecondary: Color(0xff3d2e03),
      secondaryContainer: Color(0xff564517),
      onSecondaryContainer: Color(0xffcbb37b),
      tertiary: Color(0xffbada6e),
      onTertiary: Color(0xff263500),
      tertiaryContainer: Color(0xff9fbe56),
      onTertiaryContainer: Color(0xff384b00),
      error: Color(0xffffb4ab),
      onError: Color(0xff690005),
      errorContainer: Color(0xff93000a),
      onErrorContainer: Color(0xffffdad6),
      surface: Color(0xff17130b),
      onSurface: Color(0xffeae1d3),
      onSurfaceVariant: Color(0xffd1c5af),
      outline: Color(0xff9a907b),
      outlineVariant: Color(0xff4e4635),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffeae1d3),
      onInverseSurface: Color(0xff343027),
      inversePrimary: Color(0xff765a00),
      primaryFixed: Color(0xffffdf95),
      onPrimaryFixed: Color(0xff251a00),
      primaryFixedDim: Color(0xffefc143),
      onPrimaryFixedVariant: Color(0xff594400),
      secondaryFixed: Color(0xfffae0a4),
      onSecondaryFixed: Color(0xff251a00),
      secondaryFixedDim: Color(0xffddc48a),
      onSecondaryFixedVariant: Color(0xff564517),
      tertiaryFixed: Color(0xffceef80),
      onTertiaryFixed: Color(0xff151f00),
      tertiaryFixedDim: Color(0xffb2d268),
      onTertiaryFixedVariant: Color(0xff394d00),
      surfaceDim: Color(0xff17130b),
      surfaceBright: Color(0xff3d392f),
      surfaceContainerLowest: Color(0xff110e07),
      surfaceContainerLow: Color(0xff1f1b13),
      surfaceContainer: Color(0xff231f17),
      surfaceContainerHigh: Color(0xff2e2920),
      surfaceContainerHighest: Color(0xff39342b),
    );
  }

  ThemeData dark() {
    return theme(darkScheme());
  }

  // ============================================================================
  // TEMA OSCURO — CONTRASTE MEDIO
  // ============================================================================

  static ColorScheme darkMediumContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xffffd877),
      surfaceTint: Color(0xffefc143),
      onPrimary: Color(0xff312400),
      primaryContainer: Color(0xffd9ad30),
      onPrimaryContainer: Color(0xff332500),
      secondary: Color(0xfff4da9e),
      onSecondary: Color(0xff312400),
      secondaryContainer: Color(0xffa48e5a),
      onSecondaryContainer: Color(0xff000000),
      tertiary: Color(0xffc8e97b),
      onTertiary: Color(0xff1d2a00),
      tertiaryContainer: Color(0xff9fbe56),
      onTertiaryContainer: Color(0xff1f2b00),
      error: Color(0xffffd2cc),
      onError: Color(0xff540003),
      errorContainer: Color(0xffff5449),
      onErrorContainer: Color(0xff000000),
      surface: Color(0xff17130b),
      onSurface: Color(0xffffffff),
      onSurfaceVariant: Color(0xffe8dbc4),
      outline: Color(0xffbcb19b),
      outlineVariant: Color(0xff9a8f7b),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffeae1d3),
      onInverseSurface: Color(0xff2c271e),
      inversePrimary: Color(0xff5b4500),
      primaryFixed: Color(0xffffdf95),
      onPrimaryFixed: Color(0xff181000),
      primaryFixedDim: Color(0xffefc143),
      onPrimaryFixedVariant: Color(0xff453400),
      secondaryFixed: Color(0xfffae0a4),
      onSecondaryFixed: Color(0xff181000),
      secondaryFixedDim: Color(0xffddc48a),
      onSecondaryFixedVariant: Color(0xff443407),
      tertiaryFixed: Color(0xffceef80),
      onTertiaryFixed: Color(0xff0c1400),
      tertiaryFixedDim: Color(0xffb2d268),
      onTertiaryFixedVariant: Color(0xff2b3b00),
      surfaceDim: Color(0xff17130b),
      surfaceBright: Color(0xff49443a),
      surfaceContainerLowest: Color(0xff0a0702),
      surfaceContainerLow: Color(0xff211d15),
      surfaceContainer: Color(0xff2c271e),
      surfaceContainerHigh: Color(0xff373229),
      surfaceContainerHighest: Color(0xff423d33),
    );
  }

  ThemeData darkMediumContrast() {
    return theme(darkMediumContrastScheme());
  }

  // ============================================================================
  // TEMA OSCURO — ALTO CONTRASTE
  // ============================================================================

  static ColorScheme darkHighContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xffffeecd),
      surfaceTint: Color(0xffefc143),
      onPrimary: Color(0xff000000),
      primaryContainer: Color(0xffeabd3f),
      onPrimaryContainer: Color(0xff110a00),
      secondary: Color(0xffffeecd),
      onSecondary: Color(0xff000000),
      secondaryContainer: Color(0xffd9c087),
      onSecondaryContainer: Color(0xff110a00),
      tertiary: Color(0xffdbfd8c),
      onTertiary: Color(0xff000000),
      tertiaryContainer: Color(0xffaece64),
      onTertiaryContainer: Color(0xff070d00),
      error: Color(0xffffece9),
      onError: Color(0xff000000),
      errorContainer: Color(0xffffaea4),
      onErrorContainer: Color(0xff220001),
      surface: Color(0xff17130b),
      onSurface: Color(0xffffffff),
      onSurfaceVariant: Color(0xffffffff),
      outline: Color(0xfffcefd7),
      outlineVariant: Color(0xffcdc1ab),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffeae1d3),
      onInverseSurface: Color(0xff343027),
      inversePrimary: Color(0xff5b4500),
      primaryFixed: Color(0xffffdf95),
      onPrimaryFixed: Color(0xff000000),
      primaryFixedDim: Color(0xffefc143),
      onPrimaryFixedVariant: Color(0xff181000),
      secondaryFixed: Color(0xfffae0a4),
      onSecondaryFixed: Color(0xff000000),
      secondaryFixedDim: Color(0xffddc48a),
      onSecondaryFixedVariant: Color(0xff181000),
      tertiaryFixed: Color(0xffceef80),
      onTertiaryFixed: Color(0xff000000),
      tertiaryFixedDim: Color(0xffb2d268),
      onTertiaryFixedVariant: Color(0xff0c1400),
      surfaceDim: Color(0xff17130b),
      surfaceBright: Color(0xff554f45),
      surfaceContainerLowest: Color(0xff000000),
      surfaceContainerLow: Color(0xff231f17),
      surfaceContainer: Color(0xff343027),
      surfaceContainerHigh: Color(0xff403b31),
      surfaceContainerHighest: Color(0xff4b463c),
    );
  }

  ThemeData darkHighContrast() {
    return theme(darkHighContrastScheme());
  }

  // ============================================================================
  // CONSTRUCTOR BASE
  // ============================================================================

  ThemeData theme(ColorScheme colorScheme) => ThemeData(
        useMaterial3: true,
        brightness: colorScheme.brightness,
        colorScheme: colorScheme,
        textTheme: textTheme.apply(
          bodyColor: colorScheme.onSurface,
          displayColor: colorScheme.onSurface,
        ),
        scaffoldBackgroundColor: colorScheme.surface,
        canvasColor: colorScheme.surface,
      );

  List<ExtendedColor> get extendedColors => [];
}

// ============================================================================
// TIPOS AUXILIARES
// ============================================================================

class ExtendedColor {
  final Color seed, value;
  final ColorFamily light;
  final ColorFamily lightHighContrast;
  final ColorFamily lightMediumContrast;
  final ColorFamily dark;
  final ColorFamily darkHighContrast;
  final ColorFamily darkMediumContrast;

  const ExtendedColor({
    required this.seed,
    required this.value,
    required this.light,
    required this.lightHighContrast,
    required this.lightMediumContrast,
    required this.dark,
    required this.darkHighContrast,
    required this.darkMediumContrast,
  });
}

class ColorFamily {
  const ColorFamily({
    required this.color,
    required this.onColor,
    required this.colorContainer,
    required this.onColorContainer,
  });

  final Color color;
  final Color onColor;
  final Color colorContainer;
  final Color onColorContainer;
}
