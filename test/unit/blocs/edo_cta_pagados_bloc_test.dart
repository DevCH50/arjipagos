/// Tests unitarios para EdoCtaPagadosBloc.
///
/// Cubren la carga, el refresco y el manejo de errores de la pantalla de pagos
/// realizados, y verifican que el BLoC NO comparte estado con el flujo de pagos
/// pendientes (no hay selección ni persistencia).
library;

import 'dart:async';

import 'package:arjipagos/src/domain/models/EstadosDeCuentaResponse.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart' as utils;
import 'package:arjipagos/src/presentation/pages/edo_cta_pagados/bloc/EdoCtaPagadosBloc.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta_pagados/bloc/EdoCtaPagadosEvent.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta_pagados/bloc/EdoCtaPagadosState.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';
import '../../helpers/test_data.dart';

void main() {
  late MockGetEstadosDeCuentaPagadosUseCase mockUseCase;
  late EdoCtaPagadosBloc bloc;

  /// Respuesta de éxito construida desde el JSON real del endpoint.
  EstadosDeCuentaResponse respuesta() =>
      EstadosDeCuentaResponse.fromJson(TestPagoRealizado.respuestaJson);

  /// Los streams de FCM se inyectan vacíos por omisión: sin esto el BLoC
  /// pediría `FirebaseMessaging.instance` y el test moriría con
  /// "No Firebase App". Mismo apaño que en `banner_bloc_test`.
  EdoCtaPagadosBloc crearBloc({
    Stream<RemoteMessage>? primerPlano,
    Stream<RemoteMessage>? toque,
    Future<RemoteMessage?> Function()? mensajeInicial,
  }) =>
      EdoCtaPagadosBloc(
        createMockEdoCtaPagadosUseCases(getEstadosDeCuentaPagados: mockUseCase),
        fcmPrimerPlanoStream: primerPlano ?? const Stream.empty(),
        fcmToqueStream: toque ?? const Stream.empty(),
        getInitialMessage: mensajeInicial ?? () async => null,
      );

  /// Un push de pago exitoso tal como lo manda el backend: **todo en texto**,
  /// que es lo único que FCM admite en `data`.
  RemoteMessage pushDePago({String? alumnoId, String? ticketFolio}) =>
      RemoteMessage(
        data: {
          'campania': 'pago',
          'accion': 'pago_exitoso',
          'alumno_id': ?alumnoId,
          'ciclo_id': '2026',
          'pago_ids': '5358,5359',
          'ticket_folio': ?ticketFolio,
          // El backend lo manda, pero la app no lo usa: sus modelos de pago
          // solo conocen el folio. Está aquí para comprobar que no estorba.
          'ticket_id': '7635',
        },
      );

  setUp(() {
    mockUseCase = MockGetEstadosDeCuentaPagadosUseCase();
  });

  tearDown(() async {
    await bloc.close();
  });

  group('EdoCtaPagadosBloc', () {
    test('el estado inicial está vacío y sin cargar', () {
      // Arrange & Act
      bloc = crearBloc();

      // Assert
      expect(bloc.state.alumnos, isNull);
      expect(bloc.state.isLoading, isFalse);
      expect(bloc.state.errorMessage, isNull);
      expect(bloc.state.cantidadPagos, equals(0));
    });

    test('carga inicial emite los alumnos con sus pagos realizados', () async {
      // Arrange
      when(() => mockUseCase.run())
          .thenAnswer((_) async => utils.Success(respuesta()));
      bloc = crearBloc();

      // Act
      bloc.add(const EdoCtaPagadosInitialEvent());
      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<EdoCtaPagadosState>((s) => s.isLoading),
          predicate<EdoCtaPagadosState>(
            (s) => !s.isLoading && s.alumnos?.length == 1,
          ),
        ]),
      );

      // Assert
      expect(bloc.state.errorMessage, isNull);
      expect(bloc.state.cantidadPagos, equals(2));
    });

    test('el refresco vuelve a consultar el servidor', () async {
      // Arrange
      when(() => mockUseCase.run())
          .thenAnswer((_) async => utils.Success(respuesta()));
      bloc = crearBloc();

      // Act
      bloc.add(const EdoCtaPagadosInitialEvent());
      await bloc.stream.firstWhere((s) => !s.isLoading && s.alumnos != null);
      bloc.add(const EdoCtaPagadosRefreshEvent());
      await bloc.stream.firstWhere((s) => !s.isLoading && s.alumnos != null);

      // Assert
      verify(() => mockUseCase.run()).called(2);
    });

    test('un Error del caso de uso llega como mensaje legible', () async {
      // Arrange
      when(() => mockUseCase.run()).thenAnswer(
        (_) async => utils.Error<EstadosDeCuentaResponse>('Sin conexión'),
      );
      bloc = crearBloc();

      // Act
      bloc.add(const EdoCtaPagadosInitialEvent());
      await bloc.stream.firstWhere((s) => !s.isLoading);

      // Assert
      expect(bloc.state.errorMessage, equals('Sin conexión'));
      expect(bloc.state.alumnos, isNull);
    });

    test('una excepción inesperada no se filtra cruda al usuario', () async {
      // Arrange
      when(() => mockUseCase.run()).thenThrow(Exception('fallo interno'));
      bloc = crearBloc();

      // Act
      bloc.add(const EdoCtaPagadosInitialEvent());
      await bloc.stream.firstWhere((s) => !s.isLoading);

      // Assert
      expect(bloc.state.errorMessage, isNotNull);
      expect(bloc.state.errorMessage, isNot(contains('Exception')));
      expect(bloc.state.errorMessage, isNot(contains('fallo interno')));
    });
  });

  /// Push de pago exitoso — los tres canales y el filtrado por campaña.
  ///
  /// El BLoC no navega (vive en la raíz, sin `Navigator`): deja `debeNavegar` en
  /// el estado y `MenuPrincipalPage` lo recoge. Aquí se comprueba justo eso.
  group('EdoCtaPagadosBloc — push de pago exitoso', () {
    setUp(() {
      when(() => mockUseCase.run())
          .thenAnswer((_) async => utils.Success(respuesta()));
    });

    test('app en primer plano: recarga y pide abrir la pantalla', () async {
      final canal = StreamController<RemoteMessage>();
      bloc = crearBloc(primerPlano: canal.stream);

      canal.add(pushDePago(alumnoId: '1'));
      await bloc.stream.firstWhere((s) => s.debeNavegar);

      expect(bloc.state.alumnoDestacadoId, equals(1));
      verify(() => mockUseCase.run()).called(1);
      await canal.close();
    });

    test('toque desde segundo plano: mismo camino', () async {
      final canal = StreamController<RemoteMessage>();
      bloc = crearBloc(toque: canal.stream);

      canal.add(pushDePago(alumnoId: '2'));
      await bloc.stream.firstWhere((s) => s.debeNavegar);

      expect(bloc.state.alumnoDestacadoId, equals(2));
      await canal.close();
    });

    test('app cerrada: el mensaje inicial también abre la pantalla', () async {
      bloc = crearBloc(mensajeInicial: () async => pushDePago(alumnoId: '97'));

      await bloc.stream.firstWhere((s) => s.debeNavegar);

      expect(bloc.state.alumnoDestacadoId, equals(97));
    });

    test('sin alumno_id abre la pantalla sin destacar a nadie', () async {
      // El backend omite `alumno_id` cuando el cobro tocó a varios alumnos:
      // señalar a uno haría pensar que del otro no se cobró.
      final canal = StreamController<RemoteMessage>();
      bloc = crearBloc(primerPlano: canal.stream);

      canal.add(pushDePago());
      await bloc.stream.firstWhere((s) => s.debeNavegar);

      expect(bloc.state.alumnoDestacadoId, isNull);
      await canal.close();
    });

    test('un alumno_id que no es número no destaca a nadie', () async {
      final canal = StreamController<RemoteMessage>();
      bloc = crearBloc(primerPlano: canal.stream);

      canal.add(pushDePago(alumnoId: 'no-es-un-numero'));
      await bloc.stream.firstWhere((s) => s.debeNavegar);

      expect(bloc.state.alumnoDestacadoId, isNull);
      await canal.close();
    });

    test('ignora los push que no son suyos', () async {
      final canal = StreamController<RemoteMessage>();
      bloc = crearBloc(primerPlano: canal.stream);

      canal.add(const RemoteMessage(data: {
        'campania': 'banner',
        'accion': 'refrescar_banners',
      }));
      // Falta `accion`: la convención pide las dos claves.
      canal.add(const RemoteMessage(data: {'campania': 'pago'}));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.debeNavegar, isFalse);
      verifyNever(() => mockUseCase.run());
      await canal.close();
    });

    test('la señal se apaga cuando la app ya navegó', () async {
      final canal = StreamController<RemoteMessage>();
      bloc = crearBloc(primerPlano: canal.stream);

      canal.add(pushDePago(alumnoId: '1'));
      await bloc.stream.firstWhere((s) => s.debeNavegar);

      bloc.add(const EdoCtaPagadosNavegacionAtendidaEvent());
      await bloc.stream.firstWhere((s) => !s.debeNavegar);

      expect(bloc.state.debeNavegar, isFalse);
      // El destacado sigue vivo: la lista todavía tiene que desplazarse.
      expect(bloc.state.alumnoDestacadoId, equals(1));
      await canal.close();
    });

    test('guarda el folio del ticket para señalar sus renglones', () async {
      final canal = StreamController<RemoteMessage>();
      bloc = crearBloc(primerPlano: canal.stream);

      canal.add(pushDePago(alumnoId: '1', ticketFolio: 'T007641'));
      await bloc.stream.firstWhere((s) => s.debeNavegar);

      expect(bloc.state.folioDestacado, equals('T007641'));
      await canal.close();
    });

    test('sin ticket_folio no señala ningún renglón', () async {
      // Pasa cuando el cobro tocó a dos emisores fiscales: hay dos folios y
      // mandar uno haría pensar que del otro no se cobró.
      final canal = StreamController<RemoteMessage>();
      bloc = crearBloc(primerPlano: canal.stream);

      canal.add(pushDePago(alumnoId: '1'));
      await bloc.stream.firstWhere((s) => s.debeNavegar);

      expect(bloc.state.folioDestacado, isNull);
      expect(bloc.state.alumnoDestacadoId, equals(1));
      await canal.close();
    });

    test('un push sin ninguna pista abre la pantalla y no señala nada',
        () async {
      final canal = StreamController<RemoteMessage>();
      bloc = crearBloc(primerPlano: canal.stream);

      // Primero uno con pistas, para que quede algo que limpiar.
      canal.add(pushDePago(alumnoId: '1', ticketFolio: 'T007641'));
      await bloc.stream.firstWhere((s) => s.folioDestacado != null);

      bloc.add(const EdoCtaPagadosNavegacionAtendidaEvent());
      await bloc.stream.firstWhere((s) => !s.debeNavegar);

      canal.add(pushDePago());
      await bloc.stream.firstWhere((s) => s.debeNavegar);

      expect(bloc.state.alumnoDestacadoId, isNull);
      expect(bloc.state.folioDestacado, isNull);
      await canal.close();
    });

    test('el destacado se apaga cuando la lista ya se desplazó', () async {
      final canal = StreamController<RemoteMessage>();
      bloc = crearBloc(primerPlano: canal.stream);

      canal.add(pushDePago(alumnoId: '1'));
      await bloc.stream.firstWhere((s) => s.alumnoDestacadoId != null);

      bloc.add(const EdoCtaPagadosDestacadoAtendidoEvent());
      await bloc.stream.firstWhere((s) => s.alumnoDestacadoId == null);

      expect(bloc.state.alumnoDestacadoId, isNull);
      expect(bloc.state.folioDestacado, isNull);
      await canal.close();
    });
  });
}
