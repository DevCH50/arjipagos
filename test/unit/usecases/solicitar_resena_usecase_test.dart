/// Tests de [SolicitarResenaUseCase].
///
/// Lo que se protege aquí es la **contención**: ni Apple ni Google avisan de si
/// la hoja de reseña llegó a mostrarse, así que cada llamada gasta cuota a
/// ciegas. Un fallo que deje pasar invitaciones de más no rompe nada visible,
/// pero quema la cuota y se pierde la oportunidad buena.
library;

import 'package:arjipagos/src/domain/models/resena/EstadoResena.dart';
import 'package:arjipagos/src/domain/useCases/resena/SolicitarResenaUseCase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';

void main() {
  late MockResenaRepository repository;
  late SolicitarResenaUseCase useCase;

  /// Momento fijo para que los tests no dependan del reloj real.
  final ahora = DateTime(2026, 8, 23, 12);

  /// Estado que cumple TODAS las condiciones. Cada test rompe solo una, para
  /// que quede claro cuál es la que corta.
  EstadoResena estadoValido() => EstadoResena(
        primerUso: ahora.subtract(const Duration(days: 30)),
        pagosExitosos: 5,
        ultimaInvitacion: null,
        invitacionesUltimoAnio: 0,
      );

  setUp(() {
    repository = MockResenaRepository();
    useCase = SolicitarResenaUseCase(repository);
    when(() => repository.invitacionDisponible()).thenAnswer((_) async => true);
    when(() => repository.mostrarInvitacion()).thenAnswer((_) async {});
    when(() => repository.registrarInvitacion()).thenAnswer((_) async {});
  });

  group('SolicitarResenaUseCase — invita', () {
    test('invita y lo registra cuando se cumple todo', () async {
      when(() => repository.obtenerEstado())
          .thenAnswer((_) async => estadoValido());

      expect(await useCase.run(ahora: ahora), isTrue);

      verify(() => repository.mostrarInvitacion()).called(1);
      verify(() => repository.registrarInvitacion()).called(1);
    });

    test('invita de nuevo si ya pasó el intervalo entre invitaciones', () async {
      when(() => repository.obtenerEstado()).thenAnswer(
        (_) async => EstadoResena(
          primerUso: ahora.subtract(const Duration(days: 400)),
          pagosExitosos: 9,
          ultimaInvitacion: ahora.subtract(const Duration(days: 121)),
          invitacionesUltimoAnio: 1,
        ),
      );

      expect(await useCase.run(ahora: ahora), isTrue);
    });
  });

  group('SolicitarResenaUseCase — se contiene', () {
    /// Comprueba que no se pidió nada al sistema, que es lo que gasta cuota.
    void verificarQueNoInvito() {
      verifyNever(() => repository.mostrarInvitacion());
      verifyNever(() => repository.registrarInvitacion());
    }

    test('no invita si el usuario nunca ha pagado', () async {
      when(() => repository.obtenerEstado())
          .thenAnswer((_) async => EstadoResena.vacio);

      expect(await useCase.run(ahora: ahora), isFalse);
      verificarQueNoInvito();
    });

    test('no invita con menos pagos de los exigidos', () async {
      when(() => repository.obtenerEstado()).thenAnswer(
        (_) async => EstadoResena(
          primerUso: ahora.subtract(const Duration(days: 30)),
          pagosExitosos: SolicitarResenaUseCase.minimoPagosExitosos - 1,
        ),
      );

      expect(await useCase.run(ahora: ahora), isFalse);
      verificarQueNoInvito();
    });

    test('no invita a un usuario recién llegado', () async {
      when(() => repository.obtenerEstado()).thenAnswer(
        (_) async => EstadoResena(
          primerUso: ahora.subtract(const Duration(days: 2)),
          pagosExitosos: 5,
        ),
      );

      expect(await useCase.run(ahora: ahora), isFalse);
      verificarQueNoInvito();
    });

    test('no invita si ya se alcanzó el tope anual', () async {
      when(() => repository.obtenerEstado()).thenAnswer(
        (_) async => EstadoResena(
          primerUso: ahora.subtract(const Duration(days: 400)),
          pagosExitosos: 20,
          ultimaInvitacion: ahora.subtract(const Duration(days: 200)),
          invitacionesUltimoAnio:
              SolicitarResenaUseCase.maximoInvitacionesPorAnio,
        ),
      );

      expect(await useCase.run(ahora: ahora), isFalse);
      verificarQueNoInvito();
    });

    test('no invita si la anterior fue hace poco', () async {
      when(() => repository.obtenerEstado()).thenAnswer(
        (_) async => EstadoResena(
          primerUso: ahora.subtract(const Duration(days: 400)),
          pagosExitosos: 20,
          ultimaInvitacion: ahora.subtract(const Duration(days: 30)),
          invitacionesUltimoAnio: 1,
        ),
      );

      expect(await useCase.run(ahora: ahora), isFalse);
      verificarQueNoInvito();
    });

    test('no invita si el sistema no puede mostrar la hoja', () async {
      // Es el caso real de un APK instalado con `adb install`: Google Play no
      // reconoce la instalación y la API no está disponible.
      when(() => repository.obtenerEstado())
          .thenAnswer((_) async => estadoValido());
      when(() => repository.invitacionDisponible())
          .thenAnswer((_) async => false);

      expect(await useCase.run(ahora: ahora), isFalse);
      verificarQueNoInvito();
    });

    test('no consulta al sistema si la política ya dijo que no', () async {
      // La comprobación nativa es la única que cruza el canal de plataforma:
      // si ya sabemos que no toca, no se paga.
      when(() => repository.obtenerEstado())
          .thenAnswer((_) async => EstadoResena.vacio);

      await useCase.run(ahora: ahora);

      verifyNever(() => repository.invitacionDisponible());
    });
  });

  group('SolicitarResenaUseCase — resistencia a fallos', () {
    test('devuelve false y no propaga si el repositorio revienta', () async {
      // Se llama desde el flujo de pago: un fallo aquí no puede tumbar la
      // pantalla de un pago que ya se cobró.
      when(() => repository.obtenerEstado())
          .thenThrow(Exception('almacenamiento corrupto'));

      expect(await useCase.run(ahora: ahora), isFalse);
    });

    test('devuelve false si falla al mostrar la hoja', () async {
      when(() => repository.obtenerEstado())
          .thenAnswer((_) async => estadoValido());
      when(() => repository.mostrarInvitacion())
          .thenThrow(Exception('canal nativo caído'));

      expect(await useCase.run(ahora: ahora), isFalse);
    });
  });
}
