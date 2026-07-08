/// Tests unitarios para PagoService.
///
/// Blindan el servicio ante breaking changes del paquete `http` y cambios en
/// el contrato del backend de pagos (Adquira). Se usa `http.runWithClient`
/// para interceptar el cliente HTTP sin modificar código de producción.
///
/// Cubre: iniciarPago (URL en body vs fallback, error), verificarPago (GET),
/// buildPagoUrl (codificación de query) y las ramas Timeout/Socket.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/data/api/endpoints.dart';
import 'package:arjipagos/src/data/dataSource/remote/services/PagoService.dart';
import 'package:arjipagos/src/domain/models/PagoRequest.dart';
import 'package:arjipagos/src/domain/models/PagoResponse.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Client _responde(String body, int status) =>
    MockClient((_) async => http.Response(body, status));

http.Client _lanza(Object error) => MockClient((_) async => throw error);

/// Request de prueba con los campos mínimos requeridos.
const PagoRequest _request = PagoRequest(
  token: 'jwt-token',
  userId: 1,
  importe: 1500.5,
  urlRetorno: 'https://arjipagos.mx/retorno',
  referencia: '3399A0',
);

void main() {
  final service = PagoService();

  // ==========================================================================
  // iniciarPago
  // ==========================================================================

  group('PagoService.iniciarPago', () {
    test('devuelve Success con la URL cuando el body trae "url"', () async {
      final client =
          _responde(json.encode({'url': 'https://pago.mx/checkout/123'}), 200);

      final result = await http.runWithClient(
          () => service.iniciarPago(_request), () => client);

      expect((result as Success<String>).data, 'https://pago.mx/checkout/123');
    });

    test('acepta "redirect_url" como alternativa a "url"', () async {
      final client = _responde(
          json.encode({'redirect_url': 'https://pago.mx/r/456'}), 201);

      final result = await http.runWithClient(
          () => service.iniciarPago(_request), () => client);

      expect((result as Success<String>).data, 'https://pago.mx/r/456');
    });

    test('usa la URL base de Adquira como fallback cuando no viene URL',
        () async {
      final client = _responde(json.encode({'ok': true}), 200);

      final result = await http.runWithClient(
          () => service.iniciarPago(_request), () => client);

      expect((result as Success<String>).data, Endpoints.pagoAdquira);
    });

    test('devuelve Error ante status no exitoso', () async {
      final client =
          _responde(json.encode({'msg': 'Monto inválido'}), 400);

      final result = await http.runWithClient(
          () => service.iniciarPago(_request), () => client);

      expect((result as Error).msg, 'Monto inválido');
    });

    test('mapea SocketException a Error(errorConnection)', () async {
      final result = await http.runWithClient(
          () => service.iniciarPago(_request),
          () => _lanza(const SocketException('x')));

      expect((result as Error).msg, AppStrings.errorConnection);
    });
  });

  // ==========================================================================
  // verificarPago
  // ==========================================================================

  group('PagoService.verificarPago', () {
    test('devuelve Success<PagoResponse> en 200', () async {
      final client = _responde(
          json.encode({'success': true, 'message': 'Pago aplicado'}), 200);

      final result = await http.runWithClient(
        () => service.verificarPago(referencia: '3399A0', token: 'jwt'),
        () => client,
      );

      final pago = (result as Success<PagoResponse>).data;
      expect(pago.success, true);
      expect(pago.message, 'Pago aplicado');
    });

    test('devuelve Error ante status distinto de 200', () async {
      final client =
          _responde(json.encode({'message': 'Referencia no existe'}), 404);

      final result = await http.runWithClient(
        () => service.verificarPago(referencia: 'zzz', token: 'jwt'),
        () => client,
      );

      expect((result as Error).msg, 'Referencia no existe');
    });

    test('mapea TimeoutException a Error(errorTimeout)', () async {
      final result = await http.runWithClient(
        () => service.verificarPago(referencia: 'r', token: 't'),
        () => _lanza(TimeoutException('t')),
      );

      expect((result as Error).msg, AppStrings.errorTimeout);
    });
  });

  // ==========================================================================
  // buildPagoUrl (lógica pura, sin HTTP)
  // ==========================================================================

  group('PagoService.buildPagoUrl', () {
    test('incluye el endpoint base y codifica los parámetros', () {
      final url = service.buildPagoUrl(_request);

      expect(url, startsWith('${Endpoints.pagoAdquira}?'));
      expect(url, contains('referencia=3399A0'));
      expect(url, contains('user_id=1'));
      // importe se formatea con 2 decimales en el toMap().
      expect(url, contains('importe=1500.50'));
    });
  });
}
