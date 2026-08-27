/// Guardianes de que **toda** notificación se pueda marcar como leída.
///
/// El 2026-08-27 se arreglaron dos fallos que iban juntos:
///
/// 1. Las notificaciones que llegaban con la app abierta se construían con
///    `id: 0`, tirando el `usermessage_id` que el backend manda en el payload.
///    Al abrirlas, el detalle pedía `POST /notificaciones/0/leer`, el servidor
///    lo rechazaba y el usuario recibía un `AlertDialog` de error mientras el
///    contador se quedaba clavado.
/// 2. `_onMarcarLeida` emparejaba por `n.id == event.id`, así que con id 0
///    habría marcado de golpe todas las notificaciones en ese estado.
///
/// Si alguien vuelve a poner un `id` fijo en `_onFcmForegroundMessage`, o quita
/// la guarda del id inválido, estos tests caen.
library;

import 'dart:async';

import 'package:arjipagos/src/domain/utils/Resource.dart';
import 'package:arjipagos/src/presentation/pages/notificaciones/bloc/NotificacionBloc.dart';
import 'package:arjipagos/src/presentation/pages/notificaciones/bloc/NotificacionEvent.dart';
import 'package:arjipagos/src/presentation/pages/notificaciones/bloc/NotificacionState.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';

void main() {
  late MockGetNotificacionesUseCase mockGetNotificaciones;
  late MockGetCountNoLeidasUseCase mockGetCountNoLeidas;
  late MockMarcarLeidaUseCase mockMarcarLeida;
  late MockMarcarTodasLeidasUseCase mockMarcarTodasLeidas;

  NotificacionBloc buildBloc({Stream<RemoteMessage>? foreground}) =>
      NotificacionBloc(
        createMockNotificacionUseCases(
          getNotificaciones: mockGetNotificaciones,
          getCountNoLeidas: mockGetCountNoLeidas,
          marcarLeida: mockMarcarLeida,
          marcarTodasLeidas: mockMarcarTodasLeidas,
        ),
        fcmForegroundStream: foreground ?? const Stream.empty(),
        fcmBackgroundTapStream: const Stream.empty(),
        getInitialMessage: () async => null,
      );

  setUp(() {
    mockGetNotificaciones = MockGetNotificacionesUseCase();
    mockGetCountNoLeidas = MockGetCountNoLeidasUseCase();
    mockMarcarLeida = MockMarcarLeidaUseCase();
    mockMarcarTodasLeidas = MockMarcarTodasLeidasUseCase();
  });

  /// Push tal y como lo manda el backend: `usermessage_id` viaja como texto,
  /// que es lo único que FCM transporta en `data`.
  RemoteMessage push({String? usermessageId, String campania = 'general'}) =>
      RemoteMessage(data: {
        'campania': campania,
        'title': 'Aviso de prueba',
        'message': 'Cuerpo del aviso',
        'usermessage_id': ?usermessageId,
      });

  group('el id del push en primer plano', () {
    test('se toma de usermessage_id y no se pierde', () async {
      final canal = StreamController<RemoteMessage>();
      final bloc = buildBloc(foreground: canal.stream);

      canal.add(push(usermessageId: '4821'));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.notificaciones.first.id, 4821,
          reason: 'el identificador del backend debe conservarse');
      expect(bloc.state.noLeidas, 1);

      await canal.close();
      await bloc.close();
    });

    test('las de prueba también lo traen', () async {
      // `marcarComoPrueba()` en el backend solo antepone "[PRUEBA]" al texto:
      // el aviso sigue creando su fila y mandando su id como cualquier otro.
      final canal = StreamController<RemoteMessage>();
      final bloc = buildBloc(foreground: canal.stream);

      canal.add(push(usermessageId: '99', campania: 'prueba'));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.notificaciones.first.id, 99);

      await canal.close();
      await bloc.close();
    });

    test('si el push no lo trae, queda en 0 y no se inventa', () async {
      final canal = StreamController<RemoteMessage>();
      final bloc = buildBloc(foreground: canal.stream);

      canal.add(push());
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.notificaciones.first.id, 0);

      await canal.close();
      await bloc.close();
    });
  });

  group('marcar como leída', () {
    test('con id válido llama al servidor', () async {
      when(() => mockMarcarLeida.run(any()))
          .thenAnswer((_) async => Success(true));

      final bloc = buildBloc();
      bloc.add(const MarcarLeidaEvent(id: 4821));
      await Future<void>.delayed(Duration.zero);

      verify(() => mockMarcarLeida.run(4821)).called(1);

      await bloc.close();
    });

    test('con id 0 NO llama al servidor ni muestra error', () async {
      final bloc = buildBloc();
      final estados = <NotificacionState>[];
      final sub = bloc.stream.listen(estados.add);

      bloc.add(const MarcarLeidaEvent(id: 0));
      await Future<void>.delayed(Duration.zero);

      // Lo que se protege aquí es al usuario: pedir la notificación 0 devuelve
      // error y le salta un AlertDialog por el simple hecho de abrir un aviso.
      verifyNever(() => mockMarcarLeida.run(any()));
      expect(estados.any((e) => e.errorMessage != null), isFalse,
          reason: 'un id inválido no puede acabar en un diálogo de error');

      await sub.cancel();
      await bloc.close();
    });

    test('un id inválido no arrastra a las demás sin id', () async {
      // Emparejar por `id == 0` marcaría varias de una vez. Con dos avisos sin
      // identificador, ninguno debe cambiar de estado.
      final canal = StreamController<RemoteMessage>();
      final bloc = buildBloc(foreground: canal.stream);

      canal..add(push())..add(push());
      await Future<void>.delayed(Duration.zero);

      bloc.add(const MarcarLeidaEvent(id: 0));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.notificaciones.where((n) => n.isRead), isEmpty,
          reason: 'ninguna debía marcarse: no hay forma de saber cuál era');
      expect(bloc.state.noLeidas, 2);

      await canal.close();
      await bloc.close();
    });
  });
}
