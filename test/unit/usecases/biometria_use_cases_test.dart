/// Tests unitarios de los casos de uso del bloqueo biométrico.
///
/// Lo que se prueba aquí son las **decisiones de producto**, no el canal
/// nativo: el diálogo del sistema no se puede ejercitar desde un unit test y
/// por eso queda para la verificación en dispositivo.
library;

import 'package:arjipagos/src/domain/models/BiometriaDisponible.dart';
import 'package:arjipagos/src/domain/models/EstadoBiometria.dart';
import 'package:arjipagos/src/domain/models/ResultadoBiometria.dart';
import 'package:arjipagos/src/domain/useCases/biometria/AutenticarBiometriaUseCase.dart';
import 'package:arjipagos/src/domain/useCases/biometria/CambiarBloqueoBiometricoUseCase.dart';
import 'package:arjipagos/src/domain/useCases/biometria/ConsultarBiometriaUseCase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';

void main() {
  late MockBiometriaRepository repositorio;

  setUp(() {
    repositorio = MockBiometriaRepository();
    when(() => repositorio.guardarBloqueoActivado(any()))
        .thenAnswer((_) async {});
  });

  // ==========================================================================
  // CONSULTAR
  // ==========================================================================

  group('ConsultarBiometriaUseCase', () {
    test('devuelve el estado tal cual lo da el repositorio', () async {
      const EstadoBiometria esperado = EstadoBiometria(
        disponible: BiometriaDisponible.rostro,
        activado: true,
      );
      when(() => repositorio.consultarEstado()).thenAnswer((_) async => esperado);

      final EstadoBiometria estado =
          await ConsultarBiometriaUseCase(repositorio).run();

      expect(estado, esperado);
      verify(() => repositorio.consultarEstado()).called(1);
    });
  });

  // ==========================================================================
  // AUTENTICAR
  // ==========================================================================

  group('AutenticarBiometriaUseCase', () {
    /// El caso que da sentido al caso de uso: si el aparato deja de admitir
    /// biometría, el cerrojo se apaga solo. Sin esto, quien borre sus huellas
    /// se queda encerrado fuera de la app, porque el interruptor que lo
    /// apagaría está dentro.
    test('apaga el bloqueo solo cuando la biometría deja de estar disponible',
        () async {
      when(() => repositorio.autenticar(motivo: any(named: 'motivo')))
          .thenAnswer((_) async => ResultadoBiometria.noDisponible);

      final ResultadoBiometria resultado =
          await AutenticarBiometriaUseCase(repositorio).run(motivo: 'x');

      expect(resultado, ResultadoBiometria.noDisponible);
      verify(() => repositorio.guardarBloqueoActivado(false)).called(1);
    });

    test('no toca la preferencia cuando la autenticación tiene éxito',
        () async {
      when(() => repositorio.autenticar(motivo: any(named: 'motivo')))
          .thenAnswer((_) async => ResultadoBiometria.exito);

      final ResultadoBiometria resultado =
          await AutenticarBiometriaUseCase(repositorio).run(motivo: 'x');

      expect(resultado, ResultadoBiometria.exito);
      verifyNever(() => repositorio.guardarBloqueoActivado(any()));
    });

    /// Un bloqueo por reintentos NO apaga el cerrojo: el aparato sigue siendo
    /// capaz, solo hay que esperar. Apagarlo aquí sería regalar la protección
    /// justo a quien está fallando la huella una y otra vez.
    test('los bloqueos por reintentos no apagan la preferencia', () async {
      for (final ResultadoBiometria caso in <ResultadoBiometria>[
        ResultadoBiometria.bloqueoTemporal,
        ResultadoBiometria.bloqueoPermanente,
        ResultadoBiometria.cancelada,
        ResultadoBiometria.error,
      ]) {
        when(() => repositorio.autenticar(motivo: any(named: 'motivo')))
            .thenAnswer((_) async => caso);

        await AutenticarBiometriaUseCase(repositorio).run(motivo: 'x');
      }

      verifyNever(() => repositorio.guardarBloqueoActivado(any()));
    });
  });

  // ==========================================================================
  // CAMBIAR EL INTERRUPTOR
  // ==========================================================================

  group('CambiarBloqueoBiometricoUseCase', () {
    test('encender exige pasar la biometría antes de guardar', () async {
      when(() => repositorio.autenticar(motivo: any(named: 'motivo')))
          .thenAnswer((_) async => ResultadoBiometria.exito);

      final ResultadoBiometria resultado =
          await CambiarBloqueoBiometricoUseCase(repositorio)
              .run(activar: true, motivo: 'x');

      expect(resultado, ResultadoBiometria.exito);
      verify(() => repositorio.autenticar(motivo: 'x')).called(1);
      verify(() => repositorio.guardarBloqueoActivado(true)).called(1);
    });

    /// Si no se comprobara, bastaría con agarrar un teléfono desbloqueado para
    /// activarle a alguien un cerrojo que solo abre la huella del intruso.
    test('encender no guarda nada si la biometría falla', () async {
      when(() => repositorio.autenticar(motivo: any(named: 'motivo')))
          .thenAnswer((_) async => ResultadoBiometria.cancelada);

      final ResultadoBiometria resultado =
          await CambiarBloqueoBiometricoUseCase(repositorio)
              .run(activar: true, motivo: 'x');

      expect(resultado, ResultadoBiometria.cancelada);
      verifyNever(() => repositorio.guardarBloqueoActivado(any()));
    });

    /// Apagar no la exige: quien llega al interruptor ya pasó el cerrojo, y
    /// esta es la salida de emergencia si el sensor empieza a fallar.
    test('apagar no pide biometría y guarda directamente', () async {
      final ResultadoBiometria resultado =
          await CambiarBloqueoBiometricoUseCase(repositorio)
              .run(activar: false, motivo: 'x');

      expect(resultado, ResultadoBiometria.exito);
      verifyNever(() => repositorio.autenticar(motivo: any(named: 'motivo')));
      verify(() => repositorio.guardarBloqueoActivado(false)).called(1);
    });
  });
}
