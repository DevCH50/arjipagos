import "package:flutter/material.dart";

class MaterialTheme {
  final TextTheme textTheme;

  const MaterialTheme(this.textTheme);

  static ColorScheme lightScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff734c35),
      surfaceTint: Color(0xff7d553d),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff8e644b),
      onPrimaryContainer: Color(0xffffede5),
      secondary: Color(0xff6f5a4e),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xfff7dacb),
      onSecondaryContainer: Color(0xff745e52),
      tertiary: Color(0xff675f34),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xffb6ac7a),
      onTertiaryContainer: Color(0xff474018),
      error: Color(0xffba1a1a),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffffdad6),
      onErrorContainer: Color(0xff93000a),
      surface: Color(0xfffff8f5),
      onSurface: Color(0xff1f1b19),
      onSurfaceVariant: Color(0xff50443e),
      outline: Color(0xff83746d),
      outlineVariant: Color(0xffd5c3ba),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff342f2d),
      inversePrimary: Color(0xfff0bb9e),
      primaryFixed: Color(0xffffdbc8),
      onPrimaryFixed: Color(0xff2f1403),
      primaryFixedDim: Color(0xfff0bb9e),
      onPrimaryFixedVariant: Color(0xff623e28),
      secondaryFixed: Color(0xfffaddce),
      onSecondaryFixed: Color(0xff27180f),
      secondaryFixedDim: Color(0xffddc1b3),
      onSecondaryFixedVariant: Color(0xff564338),
      tertiaryFixed: Color(0xffefe3ad),
      onTertiaryFixed: Color(0xff201c00),
      tertiaryFixedDim: Color(0xffd2c793),
      onTertiaryFixedVariant: Color(0xff4e471f),
      surfaceDim: Color(0xffe1d8d4),
      surfaceBright: Color(0xfffff8f5),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfffcf2ee),
      surfaceContainer: Color(0xfff6ece8),
      surfaceContainerHigh: Color(0xfff0e6e2),
      surfaceContainerHighest: Color(0xffeae1dd),
    );
  }

  ThemeData light() {
    return theme(lightScheme());
  }

  static ColorScheme lightMediumContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff4f2e19),
      surfaceTint: Color(0xff7d553d),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff8e644b),
      onPrimaryContainer: Color(0xffffffff),
      secondary: Color(0xff443228),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff7f685c),
      onSecondaryContainer: Color(0xffffffff),
      tertiary: Color(0xff3d360f),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff766e41),
      onTertiaryContainer: Color(0xffffffff),
      error: Color(0xff740006),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffcf2c27),
      onErrorContainer: Color(0xffffffff),
      surface: Color(0xfffff8f5),
      onSurface: Color(0xff14100e),
      onSurfaceVariant: Color(0xff3f342e),
      outline: Color(0xff5d5049),
      outlineVariant: Color(0xff786a63),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff342f2d),
      inversePrimary: Color(0xfff0bb9e),
      primaryFixed: Color(0xff8e644b),
      onPrimaryFixed: Color(0xffffffff),
      primaryFixedDim: Color(0xff724c34),
      onPrimaryFixedVariant: Color(0xffffffff),
      secondaryFixed: Color(0xff7f685c),
      onSecondaryFixed: Color(0xffffffff),
      secondaryFixedDim: Color(0xff655045),
      onSecondaryFixedVariant: Color(0xffffffff),
      tertiaryFixed: Color(0xff766e41),
      onTertiaryFixed: Color(0xffffffff),
      tertiaryFixedDim: Color(0xff5d552b),
      onTertiaryFixedVariant: Color(0xffffffff),
      surfaceDim: Color(0xffcec5c1),
      surfaceBright: Color(0xfffff8f5),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfffcf2ee),
      surfaceContainer: Color(0xfff0e6e2),
      surfaceContainerHigh: Color(0xffe4dbd7),
      surfaceContainerHighest: Color(0xffd9d0cc),
    );
  }

  ThemeData lightMediumContrast() {
    return theme(lightMediumContrastScheme());
  }

  static ColorScheme lightHighContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff432410),
      surfaceTint: Color(0xff7d553d),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff65412a),
      onPrimaryContainer: Color(0xffffffff),
      secondary: Color(0xff39281f),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff59453a),
      onSecondaryContainer: Color(0xffffffff),
      tertiary: Color(0xff322c06),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff514a21),
      onTertiaryContainer: Color(0xffffffff),
      error: Color(0xff600004),
      onError: Color(0xffffffff),
      errorContainer: Color(0xff98000a),
      onErrorContainer: Color(0xffffffff),
      surface: Color(0xfffff8f5),
      onSurface: Color(0xff000000),
      onSurfaceVariant: Color(0xff000000),
      outline: Color(0xff352a24),
      outlineVariant: Color(0xff534740),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff342f2d),
      inversePrimary: Color(0xfff0bb9e),
      primaryFixed: Color(0xff65412a),
      onPrimaryFixed: Color(0xffffffff),
      primaryFixedDim: Color(0xff4b2b16),
      onPrimaryFixedVariant: Color(0xffffffff),
      secondaryFixed: Color(0xff59453a),
      onSecondaryFixed: Color(0xffffffff),
      secondaryFixedDim: Color(0xff402f25),
      onSecondaryFixedVariant: Color(0xffffffff),
      tertiaryFixed: Color(0xff514a21),
      onTertiaryFixed: Color(0xffffffff),
      tertiaryFixedDim: Color(0xff39330c),
      onTertiaryFixedVariant: Color(0xffffffff),
      surfaceDim: Color(0xffc0b7b3),
      surfaceBright: Color(0xfffff8f5),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfff9efeb),
      surfaceContainer: Color(0xffeae1dd),
      surfaceContainerHigh: Color(0xffdcd2cf),
      surfaceContainerHighest: Color(0xffcec5c1),
    );
  }

  ThemeData lightHighContrast() {
    return theme(lightHighContrastScheme());
  }

  static ColorScheme darkScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xfff0bb9e),
      surfaceTint: Color(0xfff0bb9e),
      onPrimary: Color(0xff482814),
      primaryContainer: Color(0xff8e644b),
      onPrimaryContainer: Color(0xffffede5),
      secondary: Color(0xffddc1b3),
      onSecondary: Color(0xff3e2d23),
      secondaryContainer: Color(0xff58453a),
      onSecondaryContainer: Color(0xffceb3a5),
      tertiary: Color(0xffd2c793),
      onTertiary: Color(0xff37310a),
      tertiaryContainer: Color(0xffb6ac7a),
      onTertiaryContainer: Color(0xff474018),
      error: Color(0xffffb4ab),
      onError: Color(0xff690005),
      errorContainer: Color(0xff93000a),
      onErrorContainer: Color(0xffffdad6),
      surface: Color(0xff161311),
      onSurface: Color(0xffeae1dd),
      onSurfaceVariant: Color(0xffd5c3ba),
      outline: Color(0xff9d8e86),
      outlineVariant: Color(0xff50443e),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffeae1dd),
      inversePrimary: Color(0xff7d553d),
      primaryFixed: Color(0xffffdbc8),
      onPrimaryFixed: Color(0xff2f1403),
      primaryFixedDim: Color(0xfff0bb9e),
      onPrimaryFixedVariant: Color(0xff623e28),
      secondaryFixed: Color(0xfffaddce),
      onSecondaryFixed: Color(0xff27180f),
      secondaryFixedDim: Color(0xffddc1b3),
      onSecondaryFixedVariant: Color(0xff564338),
      tertiaryFixed: Color(0xffefe3ad),
      onTertiaryFixed: Color(0xff201c00),
      tertiaryFixedDim: Color(0xffd2c793),
      onTertiaryFixedVariant: Color(0xff4e471f),
      surfaceDim: Color(0xff161311),
      surfaceBright: Color(0xff3d3836),
      surfaceContainerLowest: Color(0xff110d0b),
      surfaceContainerLow: Color(0xff1f1b19),
      surfaceContainer: Color(0xff231f1d),
      surfaceContainerHigh: Color(0xff2e2927),
      surfaceContainerHighest: Color(0xff393431),
    );
  }

  ThemeData dark() {
    return theme(darkScheme());
  }

  static ColorScheme darkMediumContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xffffd3bc),
      surfaceTint: Color(0xfff0bb9e),
      onPrimary: Color(0xff3c1e0a),
      primaryContainer: Color(0xffb5876c),
      onPrimaryContainer: Color(0xff000000),
      secondary: Color(0xfff3d7c8),
      onSecondary: Color(0xff322219),
      secondaryContainer: Color(0xffa48c7f),
      onSecondaryContainer: Color(0xff000000),
      tertiary: Color(0xffe8dda7),
      onTertiary: Color(0xff2b2602),
      tertiaryContainer: Color(0xffb6ac7a),
      onTertiaryContainer: Color(0xff262100),
      error: Color(0xffffd2cc),
      onError: Color(0xff540003),
      errorContainer: Color(0xffff5449),
      onErrorContainer: Color(0xff000000),
      surface: Color(0xff161311),
      onSurface: Color(0xffffffff),
      onSurfaceVariant: Color(0xffebd9d0),
      outline: Color(0xffc0afa6),
      outlineVariant: Color(0xff9d8d85),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffeae1dd),
      inversePrimary: Color(0xff643f29),
      primaryFixed: Color(0xffffdbc8),
      onPrimaryFixed: Color(0xff220a00),
      primaryFixedDim: Color(0xfff0bb9e),
      onPrimaryFixedVariant: Color(0xff4f2e19),
      secondaryFixed: Color(0xfffaddce),
      onSecondaryFixed: Color(0xff1b0e06),
      secondaryFixedDim: Color(0xffddc1b3),
      onSecondaryFixedVariant: Color(0xff443228),
      tertiaryFixed: Color(0xffefe3ad),
      onTertiaryFixed: Color(0xff151100),
      tertiaryFixedDim: Color(0xffd2c793),
      onTertiaryFixedVariant: Color(0xff3d360f),
      surfaceDim: Color(0xff161311),
      surfaceBright: Color(0xff494341),
      surfaceContainerLowest: Color(0xff0a0705),
      surfaceContainerLow: Color(0xff211d1b),
      surfaceContainer: Color(0xff2c2725),
      surfaceContainerHigh: Color(0xff37322f),
      surfaceContainerHighest: Color(0xff423d3a),
    );
  }

  ThemeData darkMediumContrast() {
    return theme(darkMediumContrastScheme());
  }

  static ColorScheme darkHighContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xffffece3),
      surfaceTint: Color(0xfff0bb9e),
      onPrimary: Color(0xff000000),
      primaryContainer: Color(0xffecb89a),
      onPrimaryContainer: Color(0xff190600),
      secondary: Color(0xffffece3),
      onSecondary: Color(0xff000000),
      secondaryContainer: Color(0xffd9bdaf),
      onSecondaryContainer: Color(0xff150803),
      tertiary: Color(0xfffcf1b9),
      onTertiary: Color(0xff000000),
      tertiaryContainer: Color(0xffcec38f),
      onTertiaryContainer: Color(0xff0e0b00),
      error: Color(0xffffece9),
      onError: Color(0xff000000),
      errorContainer: Color(0xffffaea4),
      onErrorContainer: Color(0xff220001),
      surface: Color(0xff161311),
      onSurface: Color(0xffffffff),
      onSurfaceVariant: Color(0xffffffff),
      outline: Color(0xffffece3),
      outlineVariant: Color(0xffd1bfb6),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffeae1dd),
      inversePrimary: Color(0xff643f29),
      primaryFixed: Color(0xffffdbc8),
      onPrimaryFixed: Color(0xff000000),
      primaryFixedDim: Color(0xfff0bb9e),
      onPrimaryFixedVariant: Color(0xff220a00),
      secondaryFixed: Color(0xfffaddce),
      onSecondaryFixed: Color(0xff000000),
      secondaryFixedDim: Color(0xffddc1b3),
      onSecondaryFixedVariant: Color(0xff1b0e06),
      tertiaryFixed: Color(0xffefe3ad),
      onTertiaryFixed: Color(0xff000000),
      tertiaryFixedDim: Color(0xffd2c793),
      onTertiaryFixedVariant: Color(0xff151100),
      surfaceDim: Color(0xff161311),
      surfaceBright: Color(0xff554f4c),
      surfaceContainerLowest: Color(0xff000000),
      surfaceContainerLow: Color(0xff231f1d),
      surfaceContainer: Color(0xff342f2d),
      surfaceContainerHigh: Color(0xff403a38),
      surfaceContainerHighest: Color(0xff4b4643),
    );
  }

  ThemeData darkHighContrast() {
    return theme(darkHighContrastScheme());
  }


  ThemeData theme(ColorScheme colorScheme) => ThemeData(
     useMaterial3: true,
     brightness: colorScheme.brightness,
     colorScheme: colorScheme,
     textTheme: textTheme.apply(
       bodyColor: colorScheme.onSurface,
       displayColor: colorScheme.onSurface,
     ),
     scaffoldBackgroundColor: colorScheme.background,
     canvasColor: colorScheme.surface,
  );


  List<ExtendedColor> get extendedColors => [
  ];
}

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
