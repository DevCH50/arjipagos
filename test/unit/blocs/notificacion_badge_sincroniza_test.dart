/// Guardianes de que el globo del icono lleve el conteo REAL de no leídas.
///
/// La primera versión del badge (2026-08-27) solo sabía apagarlo, y lo hacía
/// desde la pantalla: `BadgeIconoApp.limpiar()` en el `initState` de
/// `NotificacionesPage` y en el botón de marcar todas. Eso tenía dos fallos:
///
/// 1. **Mentía.** Asomarse a la lista sin leer nada dejaba el icono a cero
///    mientras el servidor seguía contando avisos pendientes.
/// 2. **Era fácil de olvidar.** `noLeidas` cambia desde siete sitios del BLoC;
///    solo dos de ellos pasaban por la pantalla.
///
/// Ahora lo lleva `NotificacionBloc.onChange`, que espeja `noLeidas` en el globo
/// pase lo que pase. Estos tests caen si alguien quita esa sincronización, la
/// devuelve a la capa de presentación, o hace que dispare de más.
library;

import 'dart:async';

import 'package:arjipagos/src/domain/utils/Resource.dart';
import 'package:arjipagos/src/presentation/pages/notificaciones/bloc/NotificacionBloc.dart';
import 'package:arjipagos/src/presentation/pages/notificaciones/bloc/NotificacionEvent.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';

void main() {
  late MockGetNotificacionesUseCase mockGetNotificaciones;
  late MockGetCountNoLeidasUseCase mockGetCountNoLeidas;
  late MockMarcarLeidaUseCase mockMarcarLeida;
  late MockMarcarTodasLeidasUseCase mockMarcarTodasLeidas;

  /// Lo que habría llegado al globo del icono, en orden.
  late List<int> globo;

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
        // El original habla por un `MethodChannel` que solo existe en iOS.
        sincronizarBadge: (cantidad) async => globo.add(cantidad),
      );

  setUp(() {
    mockGetNotificaciones = MockGetNotificacionesUseCase();
    mockGetCountNoLeidas = MockGetCountNoLeidasUseCase();
    mockMarcarLeida = MockMarcarLeidaUseCase();
    mockMarcarTodasLeidas = MockMarcarTodasLeidasUseCase();
    globo = <int>[];
  });

  /// Push tal y como lo manda el backend: todo `data` viaja como texto.
  RemoteMessage push(String usermessageId) => RemoteMessage(data: {
        'campania': 'general',
        'title': 'Aviso',
        'message': 'Cuerpo',
        'usermessage_id': usermessageId,
      });

  group('el globo sigue al conteo', () {
    test('un push en primer plano lo sube', () async {
      final canal = StreamController<RemoteMessage>();
      final bloc = buildBloc(foreground: canal.stream);

      canal.add(push('4821'));
      await Future<void>.delayed(Duration.zero);

      expect(globo, [1]);
      expect(bloc.state.noLeidas, 1, reason: 'el globo debe copiar al estado');

      await canal.close();
      await bloc.close();
    });

    test('al refrescar el contador toma el número del servidor', () async {
      when(() => mockGetCountNoLeidas.run()).thenAnswer((_) async => Success(6));
      final bloc = buildBloc();

      bloc.add(const ActualizarContadorEvent());
      await Future<void>.delayed(Duration.zero);

      expect(globo, [6],
          reason: 'no vale un 0 ni un 1 fijo: es el conteo real');

      await bloc.close();
    });

    test('marcar UNA leída deja el resto encendido, no apaga el globo',
        () async {
      // Este es el caso que la versión anterior hacía mal: bajaba a cero en
      // cuanto el usuario tocaba la pantalla, con avisos todavía pendientes.
      when(() => mockGetCountNoLeidas.run()).thenAnswer((_) async => Success(3));
      when(() => mockMarcarLeida.run(any()))
          .thenAnswer((_) async => Success(true));

      final canal = StreamController<RemoteMessage>();
      final bloc = buildBloc(foreground: canal.stream);

      canal.add(push('4821'));
      await Future<void>.delayed(Duration.zero);

      bloc.add(const ActualizarContadorEvent());
      await Future<void>.delayed(Duration.zero);

      bloc.add(const MarcarLeidaEvent(id: 4821));
      await Future<void>.delayed(Duration.zero);

      expect(globo.last, 2,
          reason: 'quedaban tres sin leer y se leyó una: el globo dice 2');
      expect(globo, isNot(contains(0)));

      await canal.close();
      await bloc.close();
    });

    test('marcar TODAS leídas sí lo apaga', () async {
      when(() => mockGetCountNoLeidas.run()).thenAnswer((_) async => Success(4));
      when(() => mockMarcarTodasLeidas.run())
          .thenAnswer((_) async => Success(true));

      final bloc = buildBloc();

      bloc.add(const ActualizarContadorEvent());
      await Future<void>.delayed(Duration.zero);

      bloc.add(const MarcarTodasLeidasEvent());
      await Future<void>.delayed(Duration.zero);

      expect(globo.last, 0);

      await bloc.close();
    });
  });

  group('no molesta al canal nativo de más', () {
    test('un cambio de estado que no toca el conteo no llega al globo',
        () async {
      final bloc = buildBloc();

      // `hayNueva` es solo la animación de pulso del punto rojo; el conteo no
      // se mueve, así que el icono tampoco.
      bloc.add(const ResetNuevaNotificacionEvent());
      await Future<void>.delayed(Duration.zero);

      expect(globo, isEmpty);

      await bloc.close();
    });

    test('el mismo conteo dos veces seguidas solo se manda una vez', () async {
      when(() => mockGetCountNoLeidas.run()).thenAnswer((_) async => Success(2));
      final bloc = buildBloc();

      bloc.add(const ActualizarContadorEvent());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const ActualizarContadorEvent());
      await Future<void>.delayed(Duration.zero);

      expect(globo, [2]);

      await bloc.close();
    });
  });
}
