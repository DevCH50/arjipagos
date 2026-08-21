/// Tests del formateo de importes.
///
/// Lo usan cinco pantallas —las dos barras de total, la tarjeta del alumno, las
/// facturas y los tickets—, así que un cambio aquí se ve en toda la app. Antes
/// eran tres copias privadas idénticas y las facturas ni siquiera formateaban:
/// pintaban `9770.0000` tal como venía del backend.
library;

import 'package:arjipagos/src/core/utils/formato_monto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatearMonto', () {
    test('pone símbolo, separador de miles y dos decimales', () {
      expect(formatearMonto(9770), r'$9,770.00');
      expect(formatearMonto(23136.5), r'$23,136.50');
    });

    test('conserva los dos decimales aunque la cantidad sea redonda', () {
      // En renglones contiguos, "$100" y "$100.00" se leen como dos formatos
      // distintos del mismo dato.
      expect(formatearMonto(100), r'$100.00');
    });

    test('no mete separador por debajo de mil', () {
      expect(formatearMonto(999.99), r'$999.99');
    });

    test('separa correctamente los millones', () {
      expect(formatearMonto(1234567.89), r'$1,234,567.89');
    });

    test('el cero se formatea como cantidad, no como vacío', () {
      expect(formatearMonto(0), r'$0.00');
    });

    test('redondea a dos decimales', () {
      expect(formatearMonto(10.005), r'$10.01');
      expect(formatearMonto(10.004), r'$10.00');
    });
  });

  group('formatearMontoTexto', () {
    test('convierte los cuatro decimales del timbrado', () {
      // Es el caso real de las facturas: llegaba "9770.0000" a la pantalla.
      expect(formatearMontoTexto('9770.0000'), r'$9,770.00');
    });

    test('tolera espacios alrededor', () {
      expect(formatearMontoTexto('  1500.50  '), r'$1,500.50');
    });

    test('un texto que no es número se devuelve tal cual', () {
      // Mejor enseñar el dato crudo que un "$0.00" que parece una cantidad
      // real y no lo es.
      expect(formatearMontoTexto('N/D'), 'N/D');
      expect(formatearMontoTexto(''), '');
    });
  });
}
