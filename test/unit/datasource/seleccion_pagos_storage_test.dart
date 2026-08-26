/// Tests de [SeleccionPagosStorage].
///
/// Cubren la (de)serialización con ámbito de ciclo y, sobre todo, la migración
/// del formato anterior: un usuario que actualice la app con pagos ya
/// seleccionados no debe encontrarse el carrito vacío.
library;

import 'package:arjipagos/src/data/dataSource/local/SeleccionPagosStorage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';

/// Clave de prueba: cada emisor fiscal tiene la suya.
const String kClaveTest = 'seleccion_pagos_ef1';

void main() {
  late MockSharedPref mockSharedPref;
  late SeleccionPagosStorage storage;

  setUp(() {
    mockSharedPref = MockSharedPref();
    storage = SeleccionPagosStorage(mockSharedPref, claveSeleccion: kClaveTest);
    when(() => mockSharedPref.save(any(), any())).thenAnswer((_) async {});
  });

  group('SeleccionPagosStorage — cargar', () {
    test('devuelve mapa vacío cuando no hay nada guardado', () async {
      when(() => mockSharedPref.readMap(any())).thenAnswer((_) async => null);

      expect(await storage.cargar(), isEmpty);
    });

    test('devuelve mapa vacío cuando el guardado está vacío', () async {
      when(() => mockSharedPref.readMap(any())).thenAnswer((_) async => {});

      expect(await storage.cargar(), isEmpty);
    });

    test('lee el formato con ciclos', () async {
      when(() => mockSharedPref.readMap(any())).thenAnswer((_) async => {
            '2024': {
              '5': [5358, 5359],
            },
            '2023': {
              '5': [4001],
            },
          });

      expect(await storage.cargar(), {
        2024: {
          5: [5358, 5359],
        },
        2023: {
          5: [4001],
        },
      });
    });

    test('ignora el formato plano anterior en vez de migrarlo', () async {
      // Formato viejo: {alumnoId: [pagoId]}, sin noción de ciclo ni de emisor.
      //
      // Ya no se migra: esa selección se guardaba compartida entre todos los
      // emisores fiscales y aquí no hay forma de saber de cuál es cada pago
      // —haría falta la respuesta del servidor—. Adoptarla entera pondría
      // pagos de un contrato en el carrito de otro, que es justo lo que se
      // quiere evitar. La clave vieja se borra al arrancar; ver
      // `descartarSeleccionCompartidaAntigua`.
      when(() => mockSharedPref.readMap(any())).thenAnswer((_) async => {
            '5': [5358, 5359],
            '7': [6001],
          });

      expect(await storage.cargar(), isEmpty);
    });

    test('cada emisor lee y escribe SOLO su propia clave', () async {
      // Es lo que impide que vaciar un carrito, recargar una lista o completar
      // un pago alcance al otro emisor.
      final ef2 = SeleccionPagosStorage(
        mockSharedPref,
        claveSeleccion: 'seleccion_pagos_ef2',
      );

      when(() => mockSharedPref.readMap('seleccion_pagos_ef1'))
          .thenAnswer((_) async => {
                '2024': {
                  '5': [111],
                },
              });
      when(() => mockSharedPref.readMap('seleccion_pagos_ef2'))
          .thenAnswer((_) async => {
                '2024': {
                  '5': [222],
                },
              });

      expect(await storage.cargar(), {
        2024: {
          5: [111],
        },
      });
      expect(await ef2.cargar(), {
        2024: {
          5: [222],
        },
      });

      // Vaciar el de un emisor solo escribe en su clave.
      when(() => mockSharedPref.save(any(), any())).thenAnswer((_) async {});
      await ef2.guardar({});
      verify(() => mockSharedPref.save('seleccion_pagos_ef2', {})).called(1);
      verifyNever(() => mockSharedPref.save('seleccion_pagos_ef1', any()));
    });

    test('descarta entradas con claves o valores inesperados', () async {
      when(() => mockSharedPref.readMap(any())).thenAnswer((_) async => {
            '2024': {
              'no-es-id': [1],
              '5': 'tampoco es lista',
              '7': [10],
            },
            'ciclo-invalido': {
              '5': [1],
            },
          });

      expect(await storage.cargar(), {
        2024: {
          7: [10],
        },
      });
    });

    test('devuelve mapa vacío si el storage lanza', () async {
      when(() => mockSharedPref.readMap(any())).thenThrow(Exception('corrupto'));

      expect(await storage.cargar(), isEmpty);
    });
  });

  group('SeleccionPagosStorage — guardar', () {
    test('serializa con las claves como String', () async {
      await storage.guardar({
        2024: {
          5: [5358, 5359],
        },
      });

      verify(() => mockSharedPref.save(kClaveTest, {
            '2024': {
              '5': [5358, 5359],
            },
          })).called(1);
    });

    test('no persiste ciclos ni alumnos sin pagos', () async {
      await storage.guardar({
        2024: {
          5: [5358],
          7: [], // alumno sin pagos
        },
        2023: {}, // ciclo sin alumnos
      });

      verify(() => mockSharedPref.save(kClaveTest, {
            '2024': {
              '5': [5358],
            },
          })).called(1);
    });

    test('guardar y volver a cargar conserva la estructura', () async {
      final original = {
        2024: {
          5: [5358, 5359],
        },
        2023: {
          7: [4001],
        },
      };

      Map<String, dynamic>? persistido;
      when(() => mockSharedPref.save(any(), any())).thenAnswer((inv) async {
        persistido = Map<String, dynamic>.from(
          inv.positionalArguments[1] as Map,
        );
      });
      await storage.guardar(original);

      when(() => mockSharedPref.readMap(any()))
          .thenAnswer((_) async => persistido);

      expect(await storage.cargar(), original);
    });
  });
}
