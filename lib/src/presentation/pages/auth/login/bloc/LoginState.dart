// import 'package:arjipagos/src/domain/models/AuthResponse.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart';
import 'package:arjipagos/src/presentation/utils/BlocForItem.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class LoginState extends Equatable {
  final BlocForItem email;
  final BlocForItem password;
  final GlobalKey<FormState>? formKey;
  final Resource? response;

  const LoginState({
    this.email = const BlocForItem(error: 'Ingresa el Username'),
    this.password = const BlocForItem(error: 'Ingresa la Contraseña'),
    this.formKey,
    this.response,
  });


  // LoginState({
  //   this.email = const BlocForItem(error: 'Ingresa el Username'),
  //   this.password = const BlocForItem(error: 'Ingresa la Contraseña'),
  //   GlobalKey<FormState>? formKey,
  //   this.response,
  // }) : formKey = formKey ?? GlobalKey<FormState>();


  LoginState copyWith({
    BlocForItem? email,
    BlocForItem? password,
    GlobalKey<FormState>? formKey,
    Resource? response,
  }) {
    return LoginState(
      email: email ?? this.email,
      password: password ?? this.password,
      formKey: formKey ?? this.formKey,
      response: response ?? this.response,
    );
  }

  @override
  List<Object?> get props => [email, password, formKey, response];

}

// class LoginInitial extends LoginState {}
// class RegisterInitial extends LoginState {}
