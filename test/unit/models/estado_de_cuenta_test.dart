/// Tests unitarios para el modelo EstadoDeCuenta.
library;

import 'package:arjipagos/src/domain/models/EstadoDeCuenta.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_data.dart';

void main() {
  group('EstadoDeCuenta', () {
    // -------------------------------------------------------------------------
    // fromJson
    // -------------------------------------------------------------------------
    group('fromJson', () {
      test('debe crear un EstadoDeCuenta pendiente desde JSON', () {
        // Arrange
        final json = {
          'id': 1,
          'descripcion_corta': 'Colegiatura Enero 2024',
          'total': 5000.0,
          'total_formatted': '\$5,000.00',
          'fecha_vencimiento': '2024-01-31',
          'estadoPago': 'Pendiente',
          'num_pago': 1,
          'num_pago_activo': true,
          'acepta_pagos_diversos': true,
          'esta_disponible_en_internet': true,
          'esta_disponible_en_la_app_movil': true,
          'factura_pdf': '',
          'factura_xml': '',
        };

        // Act
        final estado = EstadoDeCuenta.fromJson(json);

        // Assert
        expect(estado.id, equals(1));
        expect(estado.descripcionCorta, equals('Colegiatura Enero 2024'));
        expect(estado.total, equals(5000.0));
        expect(estado.totalFormatted, equals('\$5,000.00'));
        expect(estado.fechaVencimiento, equals('2024-01-31'));
        expect(estado.estadoPago, equals(EstadoPago.pendiente));
        expect(estado.numPago, equals(1));
        expect(estado.numPagoActivo, isTrue);
        expect(estado.aceptaPagosDiversos, isTrue);
        expect(estado.estaDisponibleEnInternet, isTrue);
        expect(estado.facturaPdf, isEmpty);
        expect(estado.facturaXml, isEmpty);
      });

      test('debe crear un EstadoDeCuenta vencido desde JSON', () {
        // Arrange
        final json = {
          'id': 2,
          'descripcion_corta': 'Colegiatura Diciembre 2023',
          'total': 4500.0,
          'total_formatted': '\$4,500.00',
          'fecha_vencimiento': '2023-12-31',
          'estadoPago': 'Vencido',
          'num_pago': 2,
          'num_pago_activo': false,
          'acepta_pagos_diversos': true,
          'esta_disponible_en_internet': true,
          'esta_disponible_en_la_app_movil': true,
          'factura_pdf': '',
          'factura_xml': '',
        };

        // Act
        final estado = EstadoDeCuenta.fromJson(json);

        // Assert
        expect(estado.id, equals(2));
        expect(estado.descripcionCorta, equals('Colegiatura Diciembre 2023'));
        expect(estado.total, equals(4500.0));
        expect(estado.estadoPago, equals(EstadoPago.vencido));
        expect(estado.numPagoActivo, isFalse);
      });

      test('debe aplicar valores por defecto cuando los campos son null', () {
        // Arrange: JSON vacío sin ningún campo
        final json = <String, dynamic>{};

        // Act
        final estado = EstadoDeCuenta.fromJson(json);

        // Assert
        expect(estado.id, equals(0));
        expect(estado.descripcionCorta, equals(''));
        expect(estado.total, equals(0.0));
        expect(estado.totalFormatted, equals(''));
        expect(estado.fechaVencimiento, equals(''));
        // estadoPago desconocido cae en pendiente por defecto
        expect(estado.estadoPago, equals(EstadoPago.pendiente));
        expect(estado.numPago, equals(0));
        expect(estado.numPagoActivo, isFalse);
        // Los booleanos de pago/internet tienen true como valor por defecto
        expect(estado.aceptaPagosDiversos, isTrue);
        expect(estado.estaDisponibleEnInternet, isTrue);
        expect(estado.facturaPdf, equals(''));
        expect(estado.facturaXml, equals(''));
      });

      test('debe convertir total entero a double', () {
        // Arrange: total como entero en el JSON
        final json = {'id': 3, 'total': 3000, 'estadoPago': 'Pendiente'};

        // Act
        final estado = EstadoDeCuenta.fromJson(json);

        // Assert
        expect(estado.total, isA<double>());
        expect(estado.total, equals(3000.0));
      });

      test('debe usar pendiente cuando estadoPago no es reconocido', () {
        // Arrange: valor de estadoPago fuera del enum
        final json = {'estadoPago': 'ValorDesconocido'};

        // Act
        final estado = EstadoDeCuenta.fromJson(json);

        // Assert
        expect(estado.estadoPago, equals(EstadoPago.pendiente));
      });

      test('debe leer facturaPdf y facturaXml cuando están presentes', () {
        // Arrange
        final json = {
          'factura_pdf': 'https://example.com/factura.pdf',
          'factura_xml': 'https://example.com/factura.xml',
          'estadoPago': 'Pendiente',
        };

        // Act
        final estado = EstadoDeCuenta.fromJson(json);

        // Assert
        expect(estado.facturaPdf, equals('https://example.com/factura.pdf'));
        expect(estado.facturaXml, equals('https://example.com/factura.xml'));
      });

      // -----------------------------------------------------------------------
      // ciclo_id / nivel_id — el backend no los manda con un tipo consistente,
      // así que el parseo debe aguantar int, String o ausencia sin reventar.
      // -----------------------------------------------------------------------
      test('debe leer ciclo_id y nivel_id cuando llegan como int', () {
        final estado = EstadoDeCuenta.fromJson({
          'ciclo_id': 2024,
          'nivel_id': 3,
          'emisorfiscal_id': 1,
          'estadoPago': 'Pendiente',
        });

        expect(estado.cicloId, equals(2024));
        expect(estado.nivelId, equals(3));
      });

      test('debe leer ciclo_id y nivel_id cuando llegan como String', () {
        final estado = EstadoDeCuenta.fromJson({
          'ciclo_id': '2024',
          'nivel_id': '3',
          'estadoPago': 'Pendiente',
        });

        expect(estado.cicloId, equals(2024));
        expect(estado.nivelId, equals(3));
      });

      test('debe caer a 0 cuando ciclo_id falta, es null o no es numérico', () {
        expect(
          EstadoDeCuenta.fromJson({'estadoPago': 'Pendiente'}).cicloId,
          equals(0),
        );
        expect(
          EstadoDeCuenta.fromJson({
            'ciclo_id': null,
            'estadoPago': 'Pendiente',
          }).cicloId,
          equals(0),
        );
        expect(
          EstadoDeCuenta.fromJson({
            'ciclo_id': 'no-es-numero',
            'estadoPago': 'Pendiente',
          }).cicloId,
          equals(0),
        );
      });
    });

    // -------------------------------------------------------------------------
    // toJson
    // -------------------------------------------------------------------------
    group('toJson', () {
      test(
        'debe serializar un EstadoDeCuenta pendiente a JSON correctamente',
        () {
          // Arrange
          final estado = TestEstadoDeCuenta.pendiente;

          // Act
          final json = estado.toJson();

          // Assert
          expect(json['id'], equals(1));
          expect(json['descripcion_corta'], equals('Colegiatura Enero 2024'));
          expect(json['total'], equals(5000.0));
          expect(json['total_formatted'], equals('\$5,000.00'));
          expect(json['fecha_vencimiento'], equals('2024-01-31'));
          expect(json['estadoPago'], equals('Pendiente'));
          expect(json['num_pago'], equals(1));
          expect(json['num_pago_activo'], isTrue);
          expect(json['acepta_pagos_diversos'], isTrue);
          expect(json['esta_disponible_en_internet'], isTrue);
          expect(json['esta_disponible_en_la_app_movil'], isTrue);
          expect(json['factura_pdf'], equals(''));
          expect(json['factura_xml'], equals(''));
        },
      );

      test(
        'debe serializar un EstadoDeCuenta vencido a JSON correctamente',
        () {
          // Arrange
          final estado = TestEstadoDeCuenta.vencido;

          // Act
          final json = estado.toJson();

          // Assert
          expect(json['id'], equals(2));
          expect(json['estadoPago'], equals('Vencido'));
          expect(json['num_pago_activo'], isFalse);
        },
      );

      test('fromJson y toJson deben ser operaciones inversas (pendiente)', () {
        // Arrange
        final originalJson = {
          'id': 1,
          'ciclo_id': 2024,
          'nivel_id': 1,
          'emisorfiscal_id': 1,
          'descripcion_corta': 'Colegiatura Enero 2024',
          'total': 5000.0,
          'total_formatted': '\$5,000.00',
          'fecha_vencimiento': '2024-01-31',
          'estadoPago': 'Pendiente',
          'num_pago': 1,
          'num_pago_activo': true,
          'acepta_pagos_diversos': true,
          'esta_disponible_en_internet': true,
          'esta_disponible_en_la_app_movil': true,
          'factura_pdf': '',
          'factura_xml': '',
        };

        // Act
        final estado = EstadoDeCuenta.fromJson(originalJson);
        final resultJson = estado.toJson();

        // Assert
        expect(resultJson, equals(originalJson));
      });

      test('fromJson y toJson deben ser operaciones inversas (vencido)', () {
        // Arrange
        final originalJson = {
          'id': 2,
          'ciclo_id': 2024,
          'nivel_id': 1,
          'emisorfiscal_id': 1,
          'descripcion_corta': 'Colegiatura Diciembre 2023',
          'total': 4500.0,
          'total_formatted': '\$4,500.00',
          'fecha_vencimiento': '2023-12-31',
          'estadoPago': 'Vencido',
          'num_pago': 2,
          'num_pago_activo': false,
          'acepta_pagos_diversos': true,
          'esta_disponible_en_internet': true,
          'esta_disponible_en_la_app_movil': true,
          'factura_pdf': '',
          'factura_xml': '',
        };

        // Act
        final estado = EstadoDeCuenta.fromJson(originalJson);
        final resultJson = estado.toJson();

        // Assert
        expect(resultJson, equals(originalJson));
      });
    });

    // -------------------------------------------------------------------------
    // descripcionCompleta
    // -------------------------------------------------------------------------
    group('descripcionCompleta', () {
      /// Crea un [EstadoDeCuenta] mínimo con la descripción dada para probar
      /// el getter [EstadoDeCuenta.descripcionCompleta] de forma aislada.
      EstadoDeCuenta conDescripcion(String descripcion) => EstadoDeCuenta(
        id: 0,
        cicloId: 0,
        nivelId: 0,
        emisorFiscalId: 1,
        descripcionCorta: descripcion,
        total: 0,
        totalFormatted: '',
        fechaVencimiento: '',
        estadoPago: EstadoPago.pendiente,
        numPago: 0,
        numPagoActivo: false,
        aceptaPagosDiversos: false,
        estaDisponibleEnInternet: false,
        estaDisponibleEnLaAppMovil: true,
        facturaPdf: '',
        facturaXml: '',
      );

      test(
        'caso real — colapsa los espacios dobles y sobrantes del backend',
        () {
          // Tal cual llega en la respuesta de pagos realizados: dos espacios
          // antes del ciclo y dos al final. Colapsarlos no quita información y
          // evita que el texto se coma ancho de más en la lista.
          final estado = conDescripcion('REINSCRIPCION SECUNDARIA  26 / 27  ');

          expect(
            estado.descripcionCompleta,
            equals('REINSCRIPCION SECUNDARIA 26 / 27'),
          );
        },
      );

      // Estos cinco casos son los que antes se abreviaban. Se dejan uno por uno
      // —en lugar de un solo test genérico— porque son exactamente los que hay
      // que ver enteros: hasta el 2026-08-28 el usuario leía 'COL SEC ENERO' en
      // vez de saber que estaba pagando la colegiatura de secundaria.

      test('Colegiatura ya NO se abrevia a COL', () {
        final estado = conDescripcion('Colegiatura Enero 2024');

        expect(estado.descripcionCompleta, equals('COLEGIATURA ENERO 2024'));
      });

      test('Colegiatura + Secundaria salen enteras', () {
        final estado = conDescripcion('Colegiatura Secundaria Enero');

        expect(
          estado.descripcionCompleta,
          equals('COLEGIATURA SECUNDARIA ENERO'),
        );
      });

      test('Inscripcion + Preescolar salen enteras', () {
        final estado = conDescripcion('Inscripcion Preescolar');

        expect(estado.descripcionCompleta, equals('INSCRIPCION PREESCOLAR'));
      });

      test('1ro de Ingles ya NO se sustituye por 1º ING', () {
        final estado = conDescripcion('1ro de Ingles Primaria');

        expect(estado.descripcionCompleta, equals('1RO DE INGLES PRIMARIA'));
      });

      test('Seguro Escolar ya NO se sustituye por SEG ESC', () {
        final estado = conDescripcion('Seguro Escolar');

        expect(estado.descripcionCompleta, equals('SEGURO ESCOLAR'));
      });

      test('Cuota Familiar sale entera', () {
        final estado = conDescripcion('Cuota Familiar');

        expect(estado.descripcionCompleta, equals('CUOTA FAMILIAR'));
      });

      test('Guardián: no queda ninguna abreviación en el resultado', () {
        // Si alguien vuelve a meter un mapa de sustituciones, este test cae.
        const abreviaciones = [
          'COL ',
          'SEC ',
          'PRIM ',
          'PREPA ',
          'KIND',
          'INS ',
          'REINS ',
          '1º ING',
          'SEG ESC',
        ];

        final estado = conDescripcion(
          'Colegiatura Secundaria Primaria Preparatoria Preescolar '
          'Inscripcion Reinscripcion 1ro de Ingles Seguro Escolar',
        );

        for (final abreviacion in abreviaciones) {
          expect(
            estado.descripcionCompleta,
            isNot(contains(abreviacion)),
            reason: 'apareció la abreviación "$abreviacion"',
          );
        }
      });

      test('Descripcion vacía retorna cadena vacía', () {
        final estado = conDescripcion('');

        expect(estado.descripcionCompleta, equals(''));
      });

      test('Es insensible a mayúsculas/minúsculas de origen', () {
        // El backend no es constante con las mayúsculas; el getter las unifica
        // para que el renglón no quede a dos estilos.
        final estadoMinus = conDescripcion('colegiatura primaria enero');
        final estadoMayus = conDescripcion('COLEGIATURA PRIMARIA ENERO');

        expect(
          estadoMinus.descripcionCompleta,
          equals(estadoMayus.descripcionCompleta),
        );
        expect(
          estadoMinus.descripcionCompleta,
          equals('COLEGIATURA PRIMARIA ENERO'),
        );
      });
    });

    // -------------------------------------------------------------------------
    // EnumValues
    // -------------------------------------------------------------------------
    group('EnumValues', () {
      test(
        'el mapa map contiene las entradas correctas para pendiente y vencido',
        () {
          // Arrange & Act
          final mapaPago = estadoPagoValues.map;

          // Assert
          expect(mapaPago['Pendiente'], equals(EstadoPago.pendiente));
          expect(mapaPago['Vencido'], equals(EstadoPago.vencido));
        },
      );

      test('el mapa reverse permite obtener la cadena desde el enum', () {
        // Arrange & Act
        final reverso = estadoPagoValues.reverse;

        // Assert
        expect(reverso[EstadoPago.pendiente], equals('Pendiente'));
        expect(reverso[EstadoPago.vencido], equals('Vencido'));
      });

      test('map y reverse son operaciones inversas entre sí', () {
        // Arrange
        final mapa = estadoPagoValues.map;
        final reverso = estadoPagoValues.reverse;

        // Act & Assert
        for (final entry in mapa.entries) {
          expect(reverso[entry.value], equals(entry.key));
        }
      });

      test('EnumValues creado manualmente funciona correctamente', () {
        // Arrange
        final valores = EnumValues({
          'A': EstadoPago.pendiente,
          'B': EstadoPago.vencido,
        });

        // Act
        final reverso = valores.reverse;

        // Assert
        expect(valores.map['A'], equals(EstadoPago.pendiente));
        expect(reverso[EstadoPago.vencido], equals('B'));
      });
    });
  });
}
