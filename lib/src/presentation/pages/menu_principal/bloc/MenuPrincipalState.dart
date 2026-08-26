import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/domain/models/Alumno.dart';
import 'package:arjipagos/src/domain/models/User.dart';
import 'package:arjipagos/src/presentation/pages/menu_principal/widgets/menu_item_model.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

// Re-export MenuItem para mantener compatibilidad
export 'package:arjipagos/src/presentation/pages/menu_principal/widgets/menu_item_model.dart';

/// Id del item que abre la ficha de la app en la tienda.
///
/// Lo comparten el estado (que crea el item) y la página (que lo intercepta
/// antes de tratarlo como una ruta), así que vive aquí y no duplicado.
const String kMenuCalificarAppId = 'calificar_app';

/// Estado del BLoC de Menú Principal.
class MenuPrincipalState extends Equatable {
  /// Nombre del usuario logueado.
  final String? nombreUsuario;

  /// Email del usuario logueado.
  final String? emailUsuario;

  /// Datos completos del usuario.
  final User? user;

  /// Versión de la API.
  final String? apiVersion;

  /// Versión de la aplicación.
  final String? appVersion;

  /// Nombre de la familia.
  final String? familia;

  /// Lista de alumnos de la familia.
  final List<Alumno> alumnos;

  /// Lista de items del menú.
  final List<MenuItem> menuItems;

  /// Indica si está cargando datos.
  final bool isLoading;

  /// Mensaje de error si ocurre alguno.
  final String? errorMessage;

  /// ID del item seleccionado para navegación.
  final String? selectedItemId;

  const MenuPrincipalState({
    this.nombreUsuario,
    this.emailUsuario,
    this.user,
    this.apiVersion,
    this.appVersion,
    this.familia,
    this.alumnos = const [],
    this.menuItems = const [],
    this.isLoading = false,
    this.errorMessage,
    this.selectedItemId,
  });

  /// Resumen de alumnos para mostrar en el drawer.
  /// Ejemplo: "2 alumnos: Juan, María"
  String get resumenAlumnos {
    if (alumnos.isEmpty) {
      return AppStrings.menuSinAlumnos;
    }
    final nombres = alumnos.map((a) => a.nombre).join(', ');
    final cantidad = alumnos.length;
    return '$cantidad ${cantidad == 1 ? AppStrings.alumnoSingular : AppStrings.alumnoPlural}: $nombres';
  }

  /// Items predeterminados del menú.
  static List<MenuItem> get defaultMenuItems => [
    const MenuItem(
      id: 'pagos_pendientes',
      titulo: AppStrings.menuPagosPendientes,
      icono: Icons.payment,
      ruta: 'edo_cta',
    ),
    const MenuItem(
      id: 'otros_pagos',
      titulo: AppStrings.menuOtrosPagos,
      icono: Icons.receipt,
      ruta: 'edo_cta_otros',
    ),
    const MenuItem(
      id: 'pagos_realizados',
      titulo: AppStrings.menuPagosRealizados,
      icono: Icons.check_circle_outline,
      ruta: 'edo_cta_pagados',
    ),
    const MenuItem(
      id: 'facturas',
      titulo: AppStrings.menuFacturas,
      icono: Icons.receipt_long,
      ruta: 'facturas',
    ),
    // Sin `ruta`: no navega dentro de la app, abre la ficha de la tienda.
    // Lo maneja MenuPrincipalPage antes de mirar la ruta.
    const MenuItem(
      id: kMenuCalificarAppId,
      titulo: AppStrings.menuCalificarApp,
      icono: Icons.star_outline,
    ),
  ];

  MenuPrincipalState copyWith({
    String? nombreUsuario,
    String? emailUsuario,
    User? user,
    String? apiVersion,
    String? appVersion,
    String? familia,
    List<Alumno>? alumnos,
    List<MenuItem>? menuItems,
    bool? isLoading,
    String? errorMessage,
    String? selectedItemId,
  }) {
    return MenuPrincipalState(
      nombreUsuario: nombreUsuario ?? this.nombreUsuario,
      emailUsuario: emailUsuario ?? this.emailUsuario,
      user: user ?? this.user,
      apiVersion: apiVersion ?? this.apiVersion,
      appVersion: appVersion ?? this.appVersion,
      familia: familia ?? this.familia,
      alumnos: alumnos ?? this.alumnos,
      menuItems: menuItems ?? this.menuItems,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      selectedItemId: selectedItemId,
    );
  }

  @override
  List<Object?> get props => [
    nombreUsuario,
    emailUsuario,
    user,
    apiVersion,
    appVersion,
    familia,
    alumnos,
    menuItems,
    isLoading,
    errorMessage,
    selectedItemId,
  ];
}
