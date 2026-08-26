/// Tests de la separación de pagos por emisor fiscal.
///
/// La regla de fondo: **un cobro de Adquira entra en una sola cuenta
/// bancaria**. Como cada emisor fiscal es un contrato distinto, los pagos de
/// uno y otro no pueden mezclarse ni en la pantalla, ni en el total, ni en la
/// referencia que se manda a la pasarela.
///
/// Cada emisor tiene su propio almacén, su propio BLoC, su propia política y su
/// propia ruta: no comparten nada. Lo que sí llega compartido es la **respuesta
/// del servidor**, que trae los pagos de todos juntos, y por eso cada pantalla
/// tiene que quedarse solo con los suyos. Estos tests cubren las dos mitades:
/// que se muestre lo que toca y que lo que se escribe no salga de su emisor.
library;

import 'package:arjipagos/src/domain/models/Alumno.dart';
import 'package:arjipagos/src/domain/models/EstadoDeCuenta.dart';
import 'package:arjipagos/src/presentation/pages/carrito/bloc/CarritoState.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta/bloc/EdoCtaListState.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:arjipagos/src/data/api/configuracion_adquira.dart';
import 'package:arjipagos/src/data/dataSource/local/SeleccionPagosStorage.dart';

import '../helpers/test_data.dart';

const int _kCiclo = 2024;
const int _kAlumno = 7;

/// Un alumno con pagos de los dos emisores en el mismo ciclo.
///
/// Es el caso que importa: mismo alumno, mismo ciclo, dos contratos. Si algo
/// mezcla emisores, aquí se ve.
Alumno _alumnoMixto() {
  final ef1 = alumnoConPagosPorCiclo(_kAlumno, {
    _kCiclo: [101, 102],
  }, total: 500.0).estadoDeCuenta;

  final ef2 = alumnoConPagosPorCiclo(
    _kAlumno,
    {
      _kCiclo: [201, 202],
    },
    emisorFiscalId: 2,
    total: 300.0,
  ).estadoDeCuenta;

  return alumnoConPagosPorCiclo(
    _kAlumno,
    const {},
  ).conEstadoDeCuenta([...ef1, ...ef2]);
}

/// Selección con los cuatro pagos marcados: dos de cada emisor.
const Map<int, Map<int, List<int>>> _seleccionCompleta = {
  _kCiclo: {
    _kAlumno: [101, 102, 201, 202],
  },
};

void main() {
  group('EdoCtaListState — la pantalla enseña solo su emisor', () {
    test('alumnosDelEmisor deja únicamente los pagos del emisor activo', () {
      final estado = EdoCtaListState(alumnos: [_alumnoMixto()]);

      final soloEf1 = estado.alumnosDelEmisor!;
      expect(
        soloEf1.single.estadoDeCuenta.map((p) => p.id),
        equals([101, 102]),
      );

      final soloEf2 = estado.copyWith(emisorFiscalActivo: 2).alumnosDelEmisor!;
      expect(
        soloEf2.single.estadoDeCuenta.map((p) => p.id),
        equals([201, 202]),
      );
    });

    test('un alumno sin pagos del emisor activo desaparece de la lista', () {
      // Enseñar su tarjeta vacía haría pensar que no debe nada, cuando lo que
      // pasa es que lo suyo está en la otra pantalla.
      final soloEf1 = alumnoConPagosPorCiclo(1, {
        _kCiclo: [101],
      });
      final soloEf2 = alumnoConPagosPorCiclo(2, {
        _kCiclo: [201],
      }, emisorFiscalId: 2);

      final estado = EdoCtaListState(alumnos: [soloEf1, soloEf2]);

      expect(estado.alumnosDelEmisor!.single.alumnoId, equals(1));
      expect(
        estado
            .copyWith(emisorFiscalActivo: 2)
            .alumnosDelEmisor!
            .single
            .alumnoId,
        equals(2),
      );
    });

    test('el total de la barra no suma los pagos del otro emisor', () {
      final estado = EdoCtaListState(
        alumnos: [_alumnoMixto()],
        pagosSeleccionados: _seleccionCompleta,
      );

      // 2 pagos de 500 en el emisor 1; 2 de 300 en el 2. Nunca 1600.
      expect(estado.totalSeleccionado, equals(1000.0));
      expect(
        estado.copyWith(emisorFiscalActivo: 2).totalSeleccionado,
        equals(600.0),
      );
    });

    test('la cuenta de pagos seleccionados es la de esta pantalla', () {
      final estado = EdoCtaListState(
        alumnos: [_alumnoMixto()],
        pagosSeleccionados: _seleccionCompleta,
      );

      expect(estado.cantidadPagosSeleccionados, equals(2));
      expect(
        estado.copyWith(emisorFiscalActivo: 2).cantidadPagosSeleccionados,
        equals(2),
      );
    });
  });

  group('CarritoState — cada carrito cobra solo lo suyo', () {
    test('el importe a pagar excluye al otro emisor', () {
      final carrito = CarritoState(
        alumnos: [_alumnoMixto()],
        pagosSeleccionados: _seleccionCompleta,
      );

      expect(carrito.totalAPagar, equals(1000.0));
      expect(
        carrito.copyWith(emisorFiscalActivo: 2).totalAPagar,
        equals(600.0),
      );
    });

    test('la referencia solo lleva los IDs que ese cobro incluye', () {
      // Mandar a Adquira un ID que la transacción no cobra descuadra la
      // conciliación: el backend daría por pagado algo que no se cobró.
      final carrito = CarritoState(
        alumnos: [_alumnoMixto()],
        pagosSeleccionados: _seleccionCompleta,
      );

      expect(carrito.referenciaPago, isNot(contains('201')));
      expect(carrito.referenciaPago, contains('101'));

      final carritoEf2 = carrito.copyWith(emisorFiscalActivo: 2);
      expect(carritoEf2.referenciaPago, isNot(contains('101')));
      expect(carritoEf2.referenciaPago, contains('201'));
    });

    test('los renglones del carrito son solo los del emisor activo', () {
      final carrito = CarritoState(
        alumnos: [_alumnoMixto()],
        pagosSeleccionados: _seleccionCompleta,
      );

      expect(
        carrito.itemsCarrito.single.pagos.map((p) => p.id),
        equals([101, 102]),
      );
      expect(
        carrito
            .copyWith(emisorFiscalActivo: 2)
            .itemsCarrito
            .single
            .pagos
            .map((p) => p.id),
        equals([201, 202]),
      );
    });

    test('la cantidad de pagos del carrito no cuenta al otro emisor', () {
      final carrito = CarritoState(
        alumnos: [_alumnoMixto()],
        pagosSeleccionados: _seleccionCompleta,
      );

      expect(carrito.cantidadPagos, equals(2));
      expect(carrito.copyWith(emisorFiscalActivo: 2).cantidadPagos, equals(2));
    });
  });

  _pruebasDeIndependencia();

  group('Compatibilidad con el backend actual', () {
    test('un pago sin `emisorfiscal_id` se trata como del emisor 1', () {
      // Mientras el backend no mande el campo, todo debe seguir apareciendo
      // en "Pagos Pendientes" y cobrándose igual que antes.
      final pago = EstadoDeCuenta.fromJson(const {
        'id': 1,
        'ciclo_id': _kCiclo,
        'nivel_id': 1,
        'descripcion_corta': 'Colegiatura',
        'total': 100,
      });

      expect(pago.emisorFiscalId, equals(kEmisorFiscalPredeterminado));
    });

    test('un `emisorfiscal_id` en texto se lee igual que en número', () {
      // `EstadosDeCuentaResponse` ya hacía `.toString()` sobre este campo, así
      // que no se puede dar por hecho que llegue tipado.
      final comoTexto = EstadoDeCuenta.fromJson(const {
        'id': 1,
        'emisorfiscal_id': '2',
        'total': 100,
      });
      final comoNumero = EstadoDeCuenta.fromJson(const {
        'id': 1,
        'emisorfiscal_id': 2,
        'total': 100,
      });

      expect(comoTexto.emisorFiscalId, equals(2));
      expect(comoNumero.emisorFiscalId, equals(2));
    });

    test('un `emisorfiscal_id` ilegible cae en el emisor 1, nunca en 0', () {
      // Un 0 no es ningún emisor real: dejaría el pago fuera de las dos
      // pantallas y sin forma de cobrarse.
      final pago = EstadoDeCuenta.fromJson(const {
        'id': 1,
        'emisorfiscal_id': 'no-es-un-numero',
        'total': 100,
      });

      expect(pago.emisorFiscalId, equals(kEmisorFiscalPredeterminado));
    });
  });
}

// =============================================================================
// INDEPENDENCIA REAL: las operaciones de un emisor no alcanzan al otro
// =============================================================================
//
// Los tests de arriba comprueban lo que se *muestra*. Estos comprueban lo que
// se *escribe*, que es donde estaba el traslape: con una clave compartida,
// vaciar un carrito, recargar una lista o completar un pago borraba también la
// selección del otro emisor. El caso más grave era el pago: liquidar en un
// emisor vaciaba el carrito preparado en el otro.

void _pruebasDeIndependencia() {
  group('Cada emisor tiene su propio almacén', () {
    test('las claves de todos los emisores son distintas entre sí', () {
      // Si dos emisores compartieran clave volvería el traslape entero, y sin
      // ningún síntoma visible hasta que alguien perdiera su carrito.
      final claves = ConfiguracionAdquira.emisoresConocidos
          .map((e) => ConfiguracionAdquira.para(e).claveSeleccion)
          .toList();

      expect(claves.toSet().length, equals(claves.length));
    });

    test('ninguna clave coincide con la compartida de la versión anterior', () {
      // Reutilizar la clave vieja haría que ese emisor heredara la selección
      // mezclada de todos, que es justo lo que se descarta al arrancar.
      for (final emisor in ConfiguracionAdquira.emisoresConocidos) {
        expect(
          ConfiguracionAdquira.para(emisor).claveSeleccion,
          isNot(equals(kSeleccionPagosKeyLegado)),
        );
      }
    });

    test('cada emisor tiene su propia ruta y su propio título', () {
      // La ruta la usa el WebView para volver a la pantalla correcta tras
      // pagar; con una sola, pagar en un emisor devolvía al otro.
      final rutas = ConfiguracionAdquira.emisoresConocidos
          .map((e) => ConfiguracionAdquira.para(e).ruta)
          .toList();

      expect(rutas.toSet().length, equals(rutas.length));
    });

    test('cada emisor trae su propia política, no una global', () {
      // No se exige que sean distintas —hoy coinciden—, sino que cada emisor
      // tenga la suya, para poder cambiar una sin tocar la otra.
      for (final emisor in ConfiguracionAdquira.emisoresConocidos) {
        expect(ConfiguracionAdquira.para(emisor).politica, isNotNull);
      }
    });
  });
}
