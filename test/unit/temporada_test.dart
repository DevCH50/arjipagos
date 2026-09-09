/// La regla de calendario de la decoración estacional.
///
/// Se prueba **la función pura**, no los widgets: [temporadaDe] recibe la fecha
/// por parámetro justamente para que estos tests no dependan del mes en que se
/// ejecuten. Un test que llamara a `DateTime.now()` pasaría en septiembre y
/// fallaría solo en octubre, y nadie sabría por qué.
library;

import 'package:arjipagos/src/core/theme/estacional/temporada.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// Un día cualquiera del mes [mes] de un año cualquiera.
  DateTime dia(int mes, [int dia = 15]) => DateTime(2026, mes, dia);

  group('temporadaDe — qué se celebra cada mes', () {
    test('los siete meses decorados devuelven su temporada', () {
      expect(temporadaDe(dia(DateTime.february)), Temporada.amistad);
      expect(temporadaDe(dia(DateTime.march)), Temporada.primavera);
      expect(temporadaDe(dia(DateTime.april)), Temporada.ninez);
      expect(temporadaDe(dia(DateTime.may)), Temporada.madres);
      expect(temporadaDe(dia(DateTime.september)), Temporada.patria);
      expect(temporadaDe(dia(DateTime.november)), Temporada.muertos);
      expect(temporadaDe(dia(DateTime.december)), Temporada.navidad);
    });

    test('los cinco meses sin fiesta no decoran', () {
      for (final int mes in <int>[
        DateTime.january,
        DateTime.june,
        DateTime.july,
        DateTime.august,
        DateTime.october,
      ]) {
        expect(
          temporadaDe(dia(mes)),
          Temporada.ninguna,
          reason: 'el mes $mes no debería decorar',
        );
      }
    });

    test('los doce meses están contemplados', () {
      // Un `switch` al que se le olvide un mes devolvería null o reventaría.
      // Recorrer los doce es la forma barata de que eso no pase inadvertido.
      for (int mes = DateTime.january; mes <= DateTime.december; mes++) {
        expect(temporadaDe(dia(mes)), isA<Temporada>());
      }
    });
  });

  group('temporadaDe — fronteras', () {
    // La regla es por mes completo, así que el día 1 y el último día tienen que
    // decorar igual que el 15. Si algún día se acota a las fechas exactas de
    // cada festividad, estos son los tests que hay que cambiar a conciencia.
    test('el primer día del mes ya decora', () {
      expect(temporadaDe(dia(DateTime.september, 1)), Temporada.patria);
      expect(temporadaDe(dia(DateTime.december, 1)), Temporada.navidad);
    });

    test('el último día del mes todavía decora', () {
      expect(temporadaDe(dia(DateTime.september, 30)), Temporada.patria);
      expect(temporadaDe(dia(DateTime.december, 31)), Temporada.navidad);
    });

    test('el día siguiente al último ya no', () {
      expect(temporadaDe(dia(DateTime.october, 1)), Temporada.ninguna);
      expect(temporadaDe(DateTime(2027, DateTime.january, 1)),
          Temporada.ninguna);
    });

    test('el año no influye: la regla es del mes', () {
      expect(temporadaDe(DateTime(2030, DateTime.september, 16)),
          Temporada.patria);
      expect(temporadaDe(DateTime(1999, DateTime.september, 16)),
          Temporada.patria);
    });
  });

  group('el interruptor general', () {
    test('apagado, NINGÚN mes decora', () {
      // Es la marcha atrás de una línea que documenta `temporada.dart`. Si
      // alguna vez deja de funcionar, apagar la decoración en producción no
      // apagaría nada, que es justo cuando más falta haría.
      for (int mes = DateTime.january; mes <= DateTime.december; mes++) {
        expect(
          temporadaDe(dia(mes), activada: false),
          Temporada.ninguna,
          reason: 'el mes $mes decora con el interruptor apagado',
        );
      }
    });

    test('encendido en el repositorio', () {
      // Si alguien lo apaga para probar y se le olvida devolverlo, este test lo
      // dice antes de que se publique una versión sin decoración por descuido.
      expect(kDecoracionEstacionalActivada, isTrue);
    });
  });

  test('kTemporadaForzada está en null', () {
    // Solo sirve para mirar diciembre en septiembre durante el desarrollo.
    // Dejarlo puesto haría que quien arrancara la app viera un mes que no es y
    // perdiera un rato averiguando por qué.
    expect(kTemporadaForzada, isNull);
  });
}
