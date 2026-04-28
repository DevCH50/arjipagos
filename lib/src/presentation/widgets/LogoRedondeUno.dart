import 'package:arjipagos/src/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

class LogoRedondoUno extends StatelessWidget {
  final double blurRadius;
  final double spreadRadius;
  final double paddingEdgeInsets;
  final double marginBottom;
  final double size;

  const LogoRedondoUno({
    super.key,
    required this.blurRadius,
    required this.spreadRadius,
    required this.paddingEdgeInsets,
    required this.marginBottom,
    this.size = 150, // Tamaño por defecto
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.logoCircleBackgroundAlpha,
        boxShadow: [
          BoxShadow(
            color: AppColors.logoCircleBoxShadow,
            blurRadius: blurRadius,
            spreadRadius: spreadRadius,
          ),
        ],
      ),
      padding: EdgeInsets.all(paddingEdgeInsets),
      margin: EdgeInsets.only(bottom: marginBottom),
      child: ClipOval(
        child: Image.asset(
          'assets/arji/logo_arji.png',
          fit: BoxFit.contain,
          width: size,
          height: size,
        ),
      ),
    );
  }
}
