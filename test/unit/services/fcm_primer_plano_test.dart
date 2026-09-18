/// Tests de `textoVisibleDelPush`, que decide qué ve el usuario de un push.
///
/// Es la misma regla en segundo plano y en primer plano, y en primer plano es
/// además lo único que separa un aviso de verdad de un push de puro refresco:
/// si `hayContenido` fallara hacia `true`, cada refresco de la tirilla de
/// avisos pintaría una notificación vacía con el nombre de la app.
library;

import 'dart:io';

import 'package:arjipagos/src/data/dataSource/remote/services/FcmService.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('textoVisibleDelPush', () {
    test('data manda sobre notification', () {
      const RemoteMessage push = RemoteMessage(
        data: <String, dynamic>{'title': 'Pago recibido', 'message': 'Gracias'},
        notification: RemoteNotification(title: 'Otro', body: 'Otro cuerpo'),
      );

      final TextoPush texto = textoVisibleDelPush(push);

      expect(texto.titulo, 'Pago recibido');
      expect(texto.cuerpo, 'Gracias');
      expect(texto.hayContenido, isTrue);
    });

    test('sin data, usa el bloque notification', () {
      const RemoteMessage push = RemoteMessage(
        notification: RemoteNotification(title: 'Aviso', body: 'Cuerpo'),
      );

      final TextoPush texto = textoVisibleDelPush(push);

      expect(texto.titulo, 'Aviso');
      expect(texto.cuerpo, 'Cuerpo');
      expect(texto.hayContenido, isTrue);
    });

    test('el título genérico de la app no cuenta como título propio', () {
      const RemoteMessage push = RemoteMessage(
        data: <String, dynamic>{'title': 'ArjiPagos', 'message': 'Hola'},
      );

      final TextoPush texto = textoVisibleDelPush(push);

      expect(texto.titulo, 'ArjiPagos');
      expect(texto.cuerpo, 'Hola');
      expect(texto.hayContenido, isTrue,
          reason: 'Hay cuerpo, así que sí es un aviso aunque el título sea '
              'el genérico.');
    });

    test('limpia el HTML de message', () {
      const RemoteMessage push = RemoteMessage(
        data: <String, dynamic>{
          'title': 'Aviso',
          'message': '<p>Pago <b>vencido</b></p>',
        },
      );

      expect(textoVisibleDelPush(push).cuerpo, isNot(contains('<')));
    });

    test('un push de puro refresco no tiene nada que enseñar', () {
      const RemoteMessage push = RemoteMessage(
        data: <String, dynamic>{
          'campania': 'banner',
          'accion': 'refrescar_banners',
        },
      );

      final TextoPush texto = textoVisibleDelPush(push);

      expect(texto.hayContenido, isFalse,
          reason: 'Sin título ni mensaje propios, no debe pintarse una '
              'notificación vacía con el nombre de la app.');
      expect(texto.titulo, 'ArjiPagos',
          reason: 'El relleno del título sigue ahí, pero hayContenido no se '
              'deja engañar por él.');
    });

    test('solo el título genérico, sin cuerpo, tampoco es un aviso', () {
      const RemoteMessage push = RemoteMessage(
        notification: RemoteNotification(title: 'ArjiPagos'),
      );

      expect(textoVisibleDelPush(push).hayContenido, isFalse);
    });
  });

  group('aviso en primer plano — guardián del código', () {
    // No se puede disparar `FirebaseMessaging.onMessage` en un test unitario,
    // así que se vigila el código: estas dos cosas son las que harían que el
    // aviso volviera a perderse o saliera duplicado.
    final String fuente = File(
      'lib/src/data/dataSource/remote/services/FcmService.dart',
    ).readAsStringSync();

    final int inicio = fuente.indexOf('mostrarAvisosEnPrimerPlano()');
    final String metodo = fuente.substring(inicio);

    test('no exige data-only: en primer plano Android no pinta nada solo', () {
      expect(inicio, greaterThan(-1));
      expect(metodo.contains('esDataOnly'), isFalse,
          reason: 'Con la app abierta Android no muestra el push aunque traiga '
              'bloque notification. Exigir data-only aquí volvería a perder '
              'los avisos normales.');
    });

    test('solo actúa en Android: en iOS el banner ya lo saca el sistema', () {
      expect(metodo.contains('Platform.isAndroid'), isTrue,
          reason: 'En iOS setForegroundNotificationPresentationOptions ya '
              'enseña el banner; pintar otro aquí saldría duplicado.');
    });

    test('main.dart lo arranca', () {
      expect(
        File('lib/main.dart')
            .readAsStringSync()
            .contains('mostrarAvisosEnPrimerPlano()'),
        isTrue,
      );
    });
  });
}
