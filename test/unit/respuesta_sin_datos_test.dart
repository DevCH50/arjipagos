/// Tests de «no hay datos» ≠ «error al cargar».
///
/// Cuando el usuario no tiene familia asignada —ni alumnos, ni estados de
/// cuenta, ni facturas— el backend responde `404` con `success: false` en vez de
/// `200` con una lista vacía. Hasta el 2026-08-28 los services metían ese caso
/// en su rama de error y la pantalla mostraba **«Error al cargar»** en rojo, con
/// un `AlertDialog` encima, cuando lo cierto es que no había nada que cargar.
///
/// Estos tests fijan las dos mitades del contrato, y la segunda importa tanto
/// como la primera:
///
/// 1. El `404` con `success: false` llega como **`Success` vacío**, para que
///    cada pantalla caiga en su estado «No hay…».
/// 2. Un `404` **sin** esa clave —el que devuelve Laravel cuando la ruta no
///    existe— sigue siendo **`Error`**. Sin esto, un fallo de despliegue se
///    convertiría en una pantalla vacía y silenciosa, que es peor que el
///    problema original.
library;

import 'dart:convert';

import 'package:arjipagos/src/data/api/RespuestaSinDatos.dart';
import 'package:arjipagos/src/data/dataSource/remote/services/EdoCtaPagadosService.dart';
import 'package:arjipagos/src/data/dataSource/remote/services/EdoCtaService.dart';
import 'package:arjipagos/src/data/dataSource/remote/services/FacturaService.dart';
import 'package:arjipagos/src/data/dataSource/remote/services/HomeService.dart';
import 'package:arjipagos/src/domain/models/AlumnoResponse.dart';
import 'package:arjipagos/src/domain/models/EstadosDeCuentaResponse.dart';
import 'package:arjipagos/src/domain/models/FacturaResponse.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/mocks.dart';
import '../helpers/test_data.dart';

/// Cuerpo que manda el backend cuando el usuario no tiene nada que ver.
const String _sinDatos =
    '{"success":false,"message":"El usuario no tiene una familia asignada."}';

/// Cuerpo del `404` de Laravel cuando la ruta no existe: **sin** `success`.
const String _rutaInexistente =
    '{"message":"The route api/v1/loquesea could not be found."}';

http.Client _responde(String body, int status) =>
    MockClient((_) async => http.Response(body, status));

void main() {
  // ==========================================================================
  // El discriminador, aislado
  // ==========================================================================

  group('esRespuestaSinDatos', () {
    test('cierto con 404 y success:false', () {
      expect(esRespuestaSinDatos(404, json.decode(_sinDatos)), isTrue);
    });

    test('falso con 404 sin la clave success (ruta inexistente)', () {
      expect(esRespuestaSinDatos(404, json.decode(_rutaInexistente)), isFalse);
    });

    test('falso con 404 y success:true', () {
      expect(esRespuestaSinDatos(404, {'success': true}), isFalse);
    });

    test('falso con otros códigos aunque lleven success:false', () {
      // Un 500 o un 401 con success:false son fallos de verdad; solo el 404 es
      // la forma en que este backend dice «no hay nada».
      expect(esRespuestaSinDatos(500, {'success': false}), isFalse);
      expect(esRespuestaSinDatos(401, {'success': false}), isFalse);
    });

    test('falso cuando el cuerpo no es un mapa', () {
      // json.decode puede devolver una lista o un escalar; no debe reventar.
      expect(esRespuestaSinDatos(404, <dynamic>[]), isFalse);
      expect(esRespuestaSinDatos(404, 'texto suelto'), isFalse);
      expect(esRespuestaSinDatos(404, null), isFalse);
    });
  });

  // ==========================================================================
  // Los cuatro services
  // ==========================================================================

  late MockGetUserSessionUseCase mockGetUserSession;

  void conSesionValida() {
    when(
      () => mockGetUserSession.run(),
    ).thenAnswer((_) async => TestAuthResponse.valid);
  }

  setUp(() {
    mockGetUserSession = MockGetUserSessionUseCase();
    conSesionValida();
  });

  group('EdoCtaService', () {
    late EdoCtaService service;

    setUp(() {
      service = EdoCtaService(
        createMockAuthUseCases(getUserSession: mockGetUserSession),
      );
    });

    test('el 404 de «sin familia» da Success sin alumnos', () async {
      final result = await http.runWithClient(
        () => service.getEstadosDeCuenta(),
        () => _responde(_sinDatos, 404),
      );

      expect(result, isA<Success<EstadosDeCuentaResponse>>());
      expect(
        (result as Success<EstadosDeCuentaResponse>).data.alumnos,
        isEmpty,
      );
    });

    test('el 404 de ruta inexistente sigue siendo Error', () async {
      final result = await http.runWithClient(
        () => service.getEstadosDeCuenta(),
        () => _responde(_rutaInexistente, 404),
      );

      expect(result, isA<Error<EstadosDeCuentaResponse>>());
    });
  });

  group('EdoCtaPagadosService', () {
    late EdoCtaPagadosService service;

    setUp(() {
      service = EdoCtaPagadosService(
        createMockAuthUseCases(getUserSession: mockGetUserSession),
      );
    });

    test('el 404 de «sin familia» da Success sin alumnos', () async {
      final result = await http.runWithClient(
        () => service.getEstadosDeCuentaPagados(),
        () => _responde(_sinDatos, 404),
      );

      expect(result, isA<Success<EstadosDeCuentaResponse>>());
      expect(
        (result as Success<EstadosDeCuentaResponse>).data.alumnos,
        isEmpty,
      );
    });

    test('el 404 de ruta inexistente sigue siendo Error', () async {
      final result = await http.runWithClient(
        () => service.getEstadosDeCuentaPagados(),
        () => _responde(_rutaInexistente, 404),
      );

      expect(result, isA<Error<EstadosDeCuentaResponse>>());
    });
  });

  group('FacturaService', () {
    late FacturaService service;

    setUp(() {
      service = FacturaService(
        createMockAuthUseCases(getUserSession: mockGetUserSession),
      );
    });

    test('el 404 de «sin facturas» da Success sin facturas', () async {
      final result = await http.runWithClient(
        () => service.getFacturas(),
        () => _responde(_sinDatos, 404),
      );

      expect(result, isA<Success<FacturaResponse>>());
      expect((result as Success<FacturaResponse>).data.facturas, isEmpty);
    });

    test('el 404 de ruta inexistente sigue siendo Error', () async {
      final result = await http.runWithClient(
        () => service.getFacturas(),
        () => _responde(_rutaInexistente, 404),
      );

      expect(result, isA<Error<FacturaResponse>>());
    });
  });

  group('HomeService', () {
    late HomeService service;

    setUp(() {
      service = HomeService(
        MockSharedPref(),
        createMockAuthUseCases(getUserSession: mockGetUserSession),
      );
    });

    test('el 404 de «sin alumnos» da Success sin alumnos', () async {
      final result = await http.runWithClient(
        () => service.getAlumnos(),
        () => _responde(_sinDatos, 404),
      );

      expect(result, isA<Success<AlumnoResponse>>());
      expect((result as Success<AlumnoResponse>).data.alumnos, isEmpty);
    });

    test('el 404 de ruta inexistente sigue siendo Error', () async {
      final result = await http.runWithClient(
        () => service.getAlumnos(),
        () => _responde(_rutaInexistente, 404),
      );

      expect(result, isA<Error<AlumnoResponse>>());
    });
  });
}
