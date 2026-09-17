import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Test guardián: en iOS, `FirebaseMessaging.onMessage` tiene que llegar a Dart
/// con la app abierta.
///
/// Origen: revisión para iOS 27 del 2026-09-17. `AppDelegate.swift` hacía
/// `UNUserNotificationCenter.current().delegate = self` y sobrescribía
/// `userNotificationCenter(_:willPresent:)` para devolver
/// `[.banner, .sound, .badge]` sin llamar a `super`.
///
/// El plugin de Firebase Messaging, al registrarse, ve que el delegate es un
/// `FlutterAppDelegate` y NO lo reemplaza: confía en que `FlutterAppDelegate`
/// le reenvíe `willPresent`. El override cortaba ese reenvío, así que el plugin
/// nunca emitía `Messaging#onMessage`. Con la app abierta, el push de
/// `pago_exitoso` no refrescaba el estado de cuenta y el aviso no entraba en la
/// lista. Los push silenciosos sí llegaban, porque van por
/// `didReceiveRemoteNotification`.
///
/// La forma correcta es la del README del plugin para apps con UIScene:
/// `FLTFirebaseMessagingPlugin.configureNotificationCenterDelegate()` en
/// `didFinishLaunching`, y la presentación del banner desde Dart.
///
/// Este test lee el código fuente nativo: no hay forma de montar el
/// `AppDelegate` desde un test de Flutter, y desde Linux tampoco se compila.
void main() {
  final appDelegate = File('ios/Runner/AppDelegate.swift').readAsStringSync();

  /// Código Swift sin los comentarios de línea, para que el aviso que explica
  /// lo prohibido no cuente como si estuviera escrito.
  final codigoSwift = appDelegate
      .split('\n')
      .where((linea) => !linea.trimLeft().startsWith('//'))
      .join('\n');

  test('el AppDelegate deja el delegate de notificaciones al plugin', () {
    expect(
      codigoSwift,
      contains('FLTFirebaseMessagingPlugin.configureNotificationCenterDelegate()'),
    );
  });

  test('el AppDelegate no se pone a sí mismo de delegate de notificaciones', () {
    expect(
      RegExp(r'\.delegate\s*=\s*self').hasMatch(codigoSwift),
      isFalse,
      reason: 'Con `self` de delegate el plugin no se registra y onMessage '
          'no llega a Dart en primer plano',
    );
  });

  test('el AppDelegate no sobrescribe willPresent', () {
    expect(
      RegExp(r'willPresent\s+notification').hasMatch(codigoSwift),
      isFalse,
      reason: 'Un willPresent propio corta el reenvío al plugin',
    );
  });

  test('el bridging header expone el plugin a Swift con SPM y con CocoaPods', () {
    final cabecera =
        File('ios/Runner/Runner-Bridging-Header.h').readAsStringSync();

    expect(
      cabecera,
      contains('#import <firebase_messaging/FLTFirebaseMessagingPlugin.h>'),
    );
    expect(cabecera, contains('@import firebase_messaging;'));
  });

  test('Dart fija cómo se presenta el banner en primer plano', () {
    final fcm = File(
      'lib/src/data/dataSource/remote/services/FcmService.dart',
    ).readAsStringSync().replaceAll(RegExp(r'\s+'), ' ');

    expect(
      fcm,
      contains(
        'setForegroundNotificationPresentationOptions( alert: true, '
        'badge: true, sound: true, )',
      ),
    );
  });
}
