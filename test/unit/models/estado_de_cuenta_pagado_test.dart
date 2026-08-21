/// Tests del modelo [EstadoDeCuenta] aplicado a los pagos ya realizados.
///
/// Blindan tres cosas que, de romperse, fallarían en silencio:
/// 1. `estadoPago: "Pagado"` debe mapear a [EstadoPago.pagado]. Si el valor no
///    estuviera en `estadoPagoValues`, el fallback `?? EstadoPago.pendiente`
///    pintaría los pagos liquidados como "Pendiente" sin lanzar ningún error.
/// 2. Los campos del ticket deben parsearse y llegar a `toJson`.
/// 3. Los pagos pendientes NO deben ganar las claves del ticket, para que
///    `fromJson`/`toJson` sigan siendo inversas en ese flujo.
library;

import 'package:arjipagos/src/domain/models/Alumno.dart';
import 'package:arjipagos/src/domain/models/EstadoDeCuenta.dart';
import 'package:arjipagos/src/domain/models/EstadosDeCuentaResponse.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_data.dart';

/// JSON de un pago **pendiente**, tal como llega en `estado-de-cuenta-sin-pagar`:
/// sin ninguna de las claves del ticket.
Map<String, dynamic> get _pagoPendienteJson => Map<String, dynamic>.from(
      (TestAlumno.activoJson['estado_de_cuenta'] as List).first as Map,
    );

void main() {
  group('EstadoDeCuenta — pagos realizados', () {
    group('estadoPago', () {
      test('mapea "Pagado" a EstadoPago.pagado', () {
        // Act
        final pago = EstadoDeCuenta.fromJson(TestPagoRealizado.conTicketJson);

        // Assert
        expect(pago.estadoPago, equals(EstadoPago.pagado));
      });

      test('un valor desconocido sigue cayendo en pendiente', () {
        // Arrange
        final json = Map<String, dynamic>.from(TestPagoRealizado.conTicketJson)
          ..['estadoPago'] = 'EstadoInventado';

        // Act
        final pago = EstadoDeCuenta.fromJson(json);

        // Assert
        expect(pago.estadoPago, equals(EstadoPago.pendiente));
      });
    });

    group('datos del ticket', () {
      test('parsea fecha de pago, folio y URL', () {
        // Act
        final pago = EstadoDeCuenta.fromJson(TestPagoRealizado.conTicketJson);

        // Assert
        expect(pago.fechaDePago, equals('17-08-2026 10:01:01'));
        expect(pago.ticketFolio, equals('T7672'));
        expect(pago.ticketUrl, startsWith('https://arjipagos.moriah.mx'));
        expect(pago.tieneTicket, isTrue);
      });

      test('tieneTicket es false cuando no llega la URL', () {
        // Arrange: un pago pendiente no trae datos de ticket.
        final json = Map<String, dynamic>.from(_pagoPendienteJson);

        // Act
        final pago = EstadoDeCuenta.fromJson(json);

        // Assert
        expect(pago.tieneTicket, isFalse);
        expect(pago.ticketFolio, isEmpty);
        expect(pago.fechaDePago, isEmpty);
      });

      test('toJson incluye los campos del ticket cuando existen', () {
        // Arrange
        final pago = EstadoDeCuenta.fromJson(TestPagoRealizado.conTicketJson);

        // Act
        final json = pago.toJson();

        // Assert
        expect(json['fecha_de_pago'], equals('17-08-2026 10:01:01'));
        expect(json['ticket_folio'], equals('T7672'));
        expect(json['ticket_url'], isNotEmpty);
      });

      test('toJson omite los campos del ticket en un pago pendiente', () {
        // Arrange
        final pago = EstadoDeCuenta.fromJson(_pagoPendienteJson);

        // Act
        final json = pago.toJson();

        // Assert: si estas claves se colaran, el flujo de pagos pendientes
        // dejaría de tener fromJson/toJson como operaciones inversas.
        expect(json.containsKey('fecha_de_pago'), isFalse);
        expect(json.containsKey('ticket_folio'), isFalse);
        expect(json.containsKey('ticket_url'), isFalse);
      });
    });

    group('fechaDePagoCorta', () {
      test('recorta la hora que manda el backend', () {
        final pago = EstadoDeCuenta.fromJson(TestPagoRealizado.conTicketJson);

        // El backend manda '17-08-2026 10:01:01'; en la lista solo cabe la
        // fecha, y con la hora la línea se recortaba con puntos suspensivos.
        expect(pago.fechaDePago, equals('17-08-2026 10:01:01'));
        expect(pago.fechaDePagoCorta, equals('17-08-2026'));
      });

      test('devuelve cadena vacía cuando no hay fecha de pago', () {
        // Los pagos pendientes no traen `fecha_de_pago`.
        expect(TestEstadoDeCuenta.pendiente.fechaDePagoCorta, equals(''));
      });

      test('deja intacta una fecha que ya viene sin hora', () {
        final json = Map<String, dynamic>.from(TestPagoRealizado.conTicketJson)
          ..['fecha_de_pago'] = '17-08-2026';

        expect(EstadoDeCuenta.fromJson(json).fechaDePagoCorta,
            equals('17-08-2026'));
      });
    });

    group('campos ausentes o nulos en la respuesta real', () {
      test('tolera fecha_vencimiento en null', () {
        // Act
        final pago =
            EstadoDeCuenta.fromJson(TestPagoRealizado.sinVencimientoJson);

        // Assert
        expect(pago.fechaVencimiento, isEmpty);
        expect(pago.id, equals(15173));
      });

      test('tolera la ausencia de factura_pdf y factura_xml', () {
        // Act
        final pago = EstadoDeCuenta.fromJson(TestPagoRealizado.conTicketJson);

        // Assert
        expect(pago.facturaPdf, isEmpty);
        expect(pago.facturaXml, isEmpty);
      });
    });

    group('respuesta completa del endpoint', () {
      test('parsea alumnos con sus pagos realizados', () {
        // Act
        final respuesta =
            EstadosDeCuentaResponse.fromJson(TestPagoRealizado.respuestaJson);

        // Assert
        expect(respuesta.alumnos, hasLength(1));
        expect(respuesta.familia, equals('DAMASCO CANELLA'));

        final Alumno alumno = respuesta.alumnos.first;
        expect(alumno.familiaId, equals(1384));
        expect(alumno.grupo, isEmpty);
        expect(alumno.estadoDeCuenta, hasLength(2));
        expect(
          alumno.estadoDeCuenta.every((p) => p.estadoPago == EstadoPago.pagado),
          isTrue,
        );
      });
    });
  });
}
