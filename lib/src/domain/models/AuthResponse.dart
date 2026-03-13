// To parse this JSON data, do
//
//     final authResponse = authResponseFromJson(jsonString);

import 'dart:convert';

import 'package:arjipagos/src/domain/models/User.dart';

AuthResponse authResponseFromJson(String str) => AuthResponse.fromJson(json.decode(str));

String authResponseToJson(AuthResponse data) => json.encode(data.toJson());

class AuthResponse {
    int status;
    String msg;
    String accessToken;
    String tokenType;
    User user;
    String apiVersion;
    String appVersion;

    AuthResponse({
        required this.status,
        required this.msg,
        required this.accessToken,
        required this.tokenType,
        required this.user,
        required this.apiVersion,
        required this.appVersion,
    });

    factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
        status: json['status'],
        msg: json['msg'],
        accessToken: json['access_token'],
        tokenType: json['token_type'],
        user: User.fromJson(json['user']),
        apiVersion: json['api_version'],
        appVersion: json['app_version'],
    );

    Map<String, dynamic> toJson() => {
        'status': status,
        'msg': msg,
        'access_token': accessToken,
        'token_type': tokenType,
        'user': user.toJson(),
        'api_version': apiVersion,
        'app_version': appVersion,
    };
}

