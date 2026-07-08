/// Tests unitarios para FacturaService.
///
/// Blindan el manejo de sesión y errores ante breaking changes de `http` o del
/// contrato del backend. Se mockea `AuthUseCases.getUserSession` y se
/// intercepta HTTP con `http.runWithClient` (sin tocar producción).
library;

import 'dart:convert';
import 'dart:io';

import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/data/dataSource/remote/services/FacturaService.dart';
import 'package:arjipagos/src/domain/models/AuthResponse.dart';
import 'package:arjipagos/src/domain/models/FacturaResponse.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';
import '../../helpers/test_data.dart';

http.Client _responde(String body, int status) =>
    MockClient((_) async => http.Response(body, status));

http.Client _lanza(Object error) => MockClient((_) async => throw error);

/// JSON válido de facturas (lista vacía: no requiere el modelo Factura).
Map<String, dynamic> get _facturaJson => {
      'ciclo_predeterminado_id': 2024,
      'familia_id': 1,
      'familia': 'Familia López García',
      'facturas': <dynamic>[],
      'success': true,
      'message': 'ok',
    };

void main() {
  late MockGetUserSessionUseCase mockGetUserSession;
  late FacturaService service;

  void conSesion(AuthResponse? sesion) {
    when(() => mockGetUserSession.run()).thenAnswer((_) async => sesion);
  }

  setUp(() {
    mockGetUserSession = MockGetUserSessionUseCase();
    service = FacturaService(
      createMockAuthUseCases(getUserSession: mockGetUserSession),
    );
  });

  group('FacturaService.getFacturas', () {
    test('devuelve Error(errorNoSession) cuando no hay sesión', () async {
      conSesion(null);

      final result = await http.runWithClient(
          () => service.getFacturas(), () => _responde('{}', 200));

      expect((result as Error).msg, AppStrings.errorNoSession);
    });

    test('devuelve Error(errorNoToken) cuando el token está vacío', () async {
      conSesion(AuthResponse(
        status: 200,
        msg: 'ok',
        accessToken: '',
        tokenType: 'Bearer',
        user: TestUser.valid,
        apiVersion: '1.0.0',
        appVersion: '1.0.0',
      ));

      final result = await http.runWithClient(
          () => service.getFacturas(), () => _responde('{}', 200));

      expect((result as Error).msg, AppStrings.errorNoToken);
    });

    test('devuelve Success<FacturaResponse> en 200', () async {
      conSesion(TestAuthResponse.valid);
      final client = _responde(json.encode(_facturaJson), 200);

      final result =
          await http.runWithClient(() => service.getFacturas(), () => client);

      final data = (result as Success<FacturaResponse>).data;
      expect(data.facturas, isEmpty);
      expect(data.success, true);
    });

    test('devuelve Error legible cuando el servidor responde HTML', () async {
      conSesion(TestAuthResponse.valid);
      final client = _responde('<html><body>500</body></html>', 500);

      final result =
          await http.runWithClient(() => service.getFacturas(), () => client);

      expect((result as Error).msg, contains('no está disponible'));
    });

    test('mapea SocketException a Error(errorConnection)', () async {
      conSesion(TestAuthResponse.valid);

      final result = await http.runWithClient(() => service.getFacturas(),
          () => _lanza(const SocketException('x')));

      expect((result as Error).msg, AppStrings.errorConnection);
    });
  });
}
