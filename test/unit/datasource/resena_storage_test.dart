/// Tests de [ResenaStorage].
///
/// Cubren la ventana deslizante del tope anual y la tolerancia a datos
/// corruptos: el estado se lee desde la pantalla de pago, así que un dato malo
/// debe degradarse a "no invitar", nunca a una excepción.
library;

import 'package:arjipagos/src/data/dataSource/local/ResenaStorage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';

void main() {
  late MockSharedPref sharedPref;
  late ResenaStorage storage;

  final ahora = DateTime(2026, 8, 23, 12);

  /// Deja todas las claves vacías; cada test sobrescribe las que le interesan.
  void sinDatos() {
    when(() => sharedPref.readString(any())).thenAnswer((_) async => null);
    when(() => sharedPref.read(any())).thenAnswer((_) async => null);
  }

  setUp(() {
    sharedPref = MockSharedPref();
    storage = ResenaStorage(sharedPref);
    when(() => sharedPref.save(any(), any())).thenAnswer((_) async {});
    sinDatos();
  });

  group('ResenaStorage — cargar', () {
    test('devuelve el estado vacío cuando no hay nada guardado', () async {
      final estado = await storage.cargar(ahora: ahora);

      expect(estado.primerUso, isNull);
      expect(estado.pagosExitosos, 0);
      expect(estado.ultimaInvitacion, isNull);
      expect(estado.invitacionesUltimoAnio, 0);
    });

    test('cuenta solo las invitaciones dentro de la ventana de 365 días',
        () async {
      when(() => sharedPref.read(kResenaHistorialKey)).thenAnswer(
        (_) async => [
          ahora.subtract(const Duration(days: 400)).toIso8601String(), // fuera
          ahora.subtract(const Duration(days: 300)).toIso8601String(), // dentro
          ahora.subtract(const Duration(days: 10)).toIso8601String(), // dentro
        ],
      );

      final estado = await storage.cargar(ahora: ahora);

      expect(estado.invitacionesUltimoAnio, 2);
    });

    test('ignora las entradas ilegibles del historial', () async {
      when(() => sharedPref.read(kResenaHistorialKey)).thenAnswer(
        (_) async => [
          'no-es-una-fecha',
          '',
          ahora.subtract(const Duration(days: 5)).toIso8601String(),
        ],
      );

      expect((await storage.cargar(ahora: ahora)).invitacionesUltimoAnio, 1);
    });

    test('devuelve el estado vacío si el almacenamiento revienta', () async {
      when(() => sharedPref.readString(any()))
          .thenThrow(Exception('preferencias corruptas'));

      final estado = await storage.cargar(ahora: ahora);

      expect(estado.pagosExitosos, 0);
      expect(estado.primerUso, isNull);
    });
  });

  group('ResenaStorage — registrarPagoExitoso', () {
    test('fija el primer uso solo la primera vez', () async {
      await storage.registrarPagoExitoso(ahora: ahora);

      verify(() => sharedPref.save(
            kResenaPrimerUsoKey,
            ahora.toIso8601String(),
          )).called(1);
    });

    test('no reescribe el primer uso si ya existía', () async {
      final original = ahora.subtract(const Duration(days: 90));
      when(() => sharedPref.readString(kResenaPrimerUsoKey))
          .thenAnswer((_) async => original.toIso8601String());

      await storage.registrarPagoExitoso(ahora: ahora);

      verifyNever(() => sharedPref.save(kResenaPrimerUsoKey, any()));
    });

    test('incrementa el contador de pagos', () async {
      when(() => sharedPref.read(kResenaPagosExitososKey))
          .thenAnswer((_) async => 4);

      await storage.registrarPagoExitoso(ahora: ahora);

      verify(() => sharedPref.save(kResenaPagosExitososKey, 5)).called(1);
    });

    test('arranca el contador en 1 si el valor guardado no es un entero',
        () async {
      when(() => sharedPref.read(kResenaPagosExitososKey))
          .thenAnswer((_) async => 'basura');

      await storage.registrarPagoExitoso(ahora: ahora);

      verify(() => sharedPref.save(kResenaPagosExitososKey, 1)).called(1);
    });
  });

  group('ResenaStorage — registrarInvitacion', () {
    test('poda del historial lo que ya salió de la ventana', () async {
      when(() => sharedPref.read(kResenaHistorialKey)).thenAnswer(
        (_) async => [
          ahora.subtract(const Duration(days: 500)).toIso8601String(),
          ahora.subtract(const Duration(days: 100)).toIso8601String(),
        ],
      );

      await storage.registrarInvitacion(ahora: ahora);

      final guardado = verify(
        () => sharedPref.save(kResenaHistorialKey, captureAny()),
      ).captured.single as List<dynamic>;

      // Queda la de hace 100 días más la recién añadida; la de 500 se cae.
      expect(guardado, hasLength(2));
      expect(guardado.last, ahora.toIso8601String());
    });

    test('guarda también la fecha de la última invitación', () async {
      await storage.registrarInvitacion(ahora: ahora);

      verify(() => sharedPref.save(
            kResenaUltimaInvitacionKey,
            ahora.toIso8601String(),
          )).called(1);
    });
  });
}
