import 'package:flutter/material.dart';

/// Modelo que representa un item del menú principal.
///
/// Contiene la información necesaria para renderizar
/// y navegar a cada sección de la aplicación.
class MenuItem {
  /// Identificador único del item.
  final String id;

  /// Título que se muestra en la UI.
  final String titulo;

  /// Ícono del item.
  final IconData icono;

  /// Ruta de navegación (opcional).
  final String? ruta;

  const MenuItem({
    required this.id,
    required this.titulo,
    required this.icono,
    this.ruta,
  });
}
