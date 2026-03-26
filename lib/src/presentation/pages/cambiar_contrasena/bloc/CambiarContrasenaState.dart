import 'package:arjipagos/src/domain/utils/Resource.dart';
import 'package:arjipagos/src/presentation/utils/BlocForItem.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Estado del módulo de cambio de contraseña.
///
/// Contiene los campos del formulario con sus errores de validación
/// y la respuesta de la operación HTTP.
class CambiarContrasenaState extends Equatable {
  /// Campo de contraseña actual.
  final BlocForItem passwordActual;

  /// Campo de contraseña nueva.
  final BlocForItem passwordNuevo;

  /// Campo de confirmación de contraseña nueva.
  final BlocForItem passwordConfirmar;

  /// Clave global del formulario para validación.
  final GlobalKey<FormState>? formKey;

  /// Respuesta de la operación (Success, Error, Loading, null).
  final Resource? response;

  const CambiarContrasenaState({
    this.passwordActual = const BlocForItem(error: 'Ingresa tu contraseña actual'),
    this.passwordNuevo = const BlocForItem(error: 'Ingresa la nueva contraseña'),
    this.passwordConfirmar = const BlocForItem(error: 'Confirma la nueva contraseña'),
    this.formKey,
    this.response,
  });

  CambiarContrasenaState copyWith({
    BlocForItem? passwordActual,
    BlocForItem? passwordNuevo,
    BlocForItem? passwordConfirmar,
    GlobalKey<FormState>? formKey,
    Resource? response,
    bool clearResponse = false,
  }) {
    return CambiarContrasenaState(
      passwordActual: passwordActual ?? this.passwordActual,
      passwordNuevo: passwordNuevo ?? this.passwordNuevo,
      passwordConfirmar: passwordConfirmar ?? this.passwordConfirmar,
      formKey: formKey ?? this.formKey,
      response: clearResponse ? null : (response ?? this.response),
    );
  }

  @override
  List<Object?> get props =>
      [passwordActual, passwordNuevo, passwordConfirmar, formKey, response];
}
