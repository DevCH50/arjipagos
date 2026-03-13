import 'package:arjipagos/src/domain/utils/Resource.dart';
import 'package:arjipagos/src/presentation/utils/BlocForItem.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Estado del BLoC de registro.
///
/// Contiene todos los campos del formulario de registro
/// con su valor actual y posibles errores de validación.
class RegisterState extends Equatable {
  final BlocForItem nombre;
  final BlocForItem apPaterno;
  final BlocForItem apMaterno;
  final BlocForItem celular;
  final BlocForItem email;
  final BlocForItem password;
  final BlocForItem confirmPassword;
  final GlobalKey<FormState>? formKey;
  final Resource? response;

  const RegisterState({
    this.nombre = const BlocForItem(error: 'Ingresa tu nombre'),
    this.apPaterno = const BlocForItem(error: 'Ingresa tu apellido paterno'),
    this.apMaterno = const BlocForItem(),
    this.celular = const BlocForItem(error: 'Ingresa tu celular'),
    this.email = const BlocForItem(error: 'Ingresa tu email'),
    this.password = const BlocForItem(error: 'Ingresa tu contraseña'),
    this.confirmPassword = const BlocForItem(error: 'Confirma tu contraseña'),
    this.formKey,
    this.response,
  });

  /// Verifica si el formulario es válido para enviar.
  bool get isFormValid =>
      nombre.error == null &&
      apPaterno.error == null &&
      celular.error == null &&
      email.error == null &&
      password.error == null &&
      confirmPassword.error == null &&
      nombre.value.isNotEmpty &&
      apPaterno.value.isNotEmpty &&
      celular.value.isNotEmpty &&
      email.value.isNotEmpty &&
      password.value.isNotEmpty &&
      confirmPassword.value.isNotEmpty;

  RegisterState copyWith({
    BlocForItem? nombre,
    BlocForItem? apPaterno,
    BlocForItem? apMaterno,
    BlocForItem? celular,
    BlocForItem? email,
    BlocForItem? password,
    BlocForItem? confirmPassword,
    GlobalKey<FormState>? formKey,
    Resource? response,
  }) {
    return RegisterState(
      nombre: nombre ?? this.nombre,
      apPaterno: apPaterno ?? this.apPaterno,
      apMaterno: apMaterno ?? this.apMaterno,
      celular: celular ?? this.celular,
      email: email ?? this.email,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      formKey: formKey ?? this.formKey,
      response: response ?? this.response,
    );
  }

  @override
  List<Object?> get props => [
        nombre,
        apPaterno,
        apMaterno,
        celular,
        email,
        password,
        confirmPassword,
        formKey,
        response,
      ];
}
