/// Tests de `emisorfiscal_id` en `POST /api/v1/alumno/estado-de-cuenta-sin-pagar/`.
///
/// **El contrato:** "Pagos Pendientes" pide con `emisorfiscal_id = 1` y "Otros
/// pagos" con `emisorfiscal_id = 2`, para que el servidor devuelva solo lo de
/// esa pantalla.
///
/// **Y la mitad que importa igual:** cuando no se pasa emisor, la clave **no
/// viaja**. `MenuPrincipalBloc` usa este mismo endpoint para la familia y los
/// alumnos, que no son de ningún emisor; si allí se colara un filtro, los
/// alumnos que solo tuvieran pagos del emisor 2 desaparecerían del menú sin que
/// nada fallara. Por eso el parámetro es opcional y omitirlo significa «todos».
library;

import 'dart:convert';

import 'package:arjipagos/src/data/dataSource/remote/services/EdoCtaService.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';
import '../../helpers/test_data.dart';

/// Respuesta mínima válida: lo que importa aquí es la petición, no la vuelta.
const String _respuestaVacia =
    '{"ciclo_predeterminado_id":0,"familia_id":0,"familia":"",'
    '"alumnos":[],"success":true,"message":"ok"}';

void main() {
  late MockGetUserSessionUseCase mockGetUserSession;
  late EdoCtaService service;

  /// Ejecuta la consulta y devuelve el body decodificado que se mandó.
  Future<Map<String, dynamic>> bodyEnviado({int? emisorFiscalId}) async {
    Map<String, dynamic>? capturado;

    final client = MockClient((request) async {
      capturado = json.decode(request.body) as Map<String, dynamic>;
      return http.Response(_respuestaVacia, 200);
    });

    await http.runWithClient(
      () => service.getEstadosDeCuenta(emisorFiscalId: emisorFiscalId),
      () => client,
    );

    return capturado!;
  }

  setUp(() {
    mockGetUserSession = MockGetUserSessionUseCase();
    when(
      () => mockGetUserSession.run(),
    ).thenAnswer((_) async => TestAuthResponse.valid);
    service = EdoCtaService(
      createMockAuthUseCases(getUserSession: mockGetUserSession),
    );
  });

  group('estado-de-cuenta-sin-pagar — emisorfiscal_id', () {
    test('"Pagos Pendientes" pide con emisorfiscal_id = 1', () async {
      final body = await bodyEnviado(emisorFiscalId: 1);

      expect(body['emisorfiscal_id'], equals(1));
    });

    test('"Otros pagos" pide con emisorfiscal_id = 2', () async {
      final body = await bodyEnviado(emisorFiscalId: 2);

      expect(body['emisorfiscal_id'], equals(2));
    });

    test('sin emisor, la clave NO viaja', () async {
      // No es lo mismo mandar `emisorfiscal_id: null` que no mandarlo: el
      // primero es un filtro vacío, el segundo es «dame todos».
      final body = await bodyEnviado();

      expect(body.containsKey('emisorfiscal_id'), isFalse);
    });

    test('el user_id sigue viajando en los tres casos', () async {
      final conEmisor = await bodyEnviado(emisorFiscalId: 2);
      final sinEmisor = await bodyEnviado();

      expect(conEmisor['user_id'], equals(TestAuthResponse.valid.user.id));
      expect(sinEmisor['user_id'], equals(TestAuthResponse.valid.user.id));
    });

    test('va como número, no como texto', () async {
      // El body de este endpoint es JSON —a diferencia del form-data de
      // Adquira—, así que el emisor viaja como entero.
      final body = await bodyEnviado(emisorFiscalId: 2);

      expect(body['emisorfiscal_id'], isA<int>());
    });
  });
}
