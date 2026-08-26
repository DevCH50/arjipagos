/// Tests del BLoC del cerrojo biométrico.
///
/// El foco está en **cuándo se bloquea y cuándo no**, que es donde vive el
/// riesgo real: bloquear a destiempo deja al usuario tirado a media
/// transacción, y no bloquear cuando toca vacía la función de contenido.
library;

import 'package:arjipagos/src/domain/models/BiometriaDisponible.dart';
import 'package:arjipagos/src/domain/models/EstadoBiometria.dart';
import 'package:arjipagos/src/domain/models/ResultadoBiometria.dart';
import 'package:arjipagos/src/domain/useCases/auth/AuthUseCases.dart';
import 'package:arjipagos/src/domain/useCases/biometria/AutenticarBiometriaUseCase.dart';
import 'package:arjipagos/src/domain/useCases/biometria/BiometriaUseCases.dart';
import 'package:arjipagos/src/domain/useCases/biometria/CambiarBloqueoBiometricoUseCase.dart';
import 'package:arjipagos/src/domain/useCases/biometria/ConsultarBiometriaUseCase.dart';
import 'package:arjipagos/src/presentation/pages/biometria/bloc/BiometriaBloc.dart';
import 'package:arjipagos/src/presentation/pages/biometria/bloc/BiometriaEvent.dart';
import 'package:arjipagos/src/presentation/pages/biometria/bloc/BiometriaState.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';
import '../../helpers/test_data.dart';

void main() {
  late MockBiometriaRepository repositorio;
  late MockGetUserSessionUseCase getUserSession;
  late AuthUseCases authUseCases;
  late BiometriaUseCases biometriaUseCases;

  /// Reloj manejado a mano: así la gracia de 30 s se prueba en microsegundos.
  late DateTime instante;

  /// Si hay una pasarela de pago en pantalla.
  late bool pagoEnCurso;

  const EstadoBiometria activa = EstadoBiometria(
    disponible: BiometriaDisponible.huella,
    activado: true,
  );

  setUp(() {
    repositorio = MockBiometriaRepository();
    getUserSession = MockGetUserSessionUseCase();
    authUseCases = createMockAuthUseCases(getUserSession: getUserSession);

    biometriaUseCases = BiometriaUseCases(
      consultar: ConsultarBiometriaUseCase(repositorio),
      autenticar: AutenticarBiometriaUseCase(repositorio),
      cambiarBloqueo: CambiarBloqueoBiometricoUseCase(repositorio),
    );

    instante = DateTime(2026, 8, 25, 12);
    pagoEnCurso = false;

    when(() => repositorio.guardarBloqueoActivado(any()))
        .thenAnswer((_) async {});
    when(() => repositorio.consultarEstado()).thenAnswer((_) async => activa);
    when(() => repositorio.autenticar(motivo: any(named: 'motivo')))
        .thenAnswer((_) async => ResultadoBiometria.exito);
  });

  BiometriaBloc crearBloc() => BiometriaBloc(
        biometriaUseCases,
        authUseCases,
        ahora: () => instante,
        hayPagoEnCurso: () => pagoEnCurso,
      );

  /// Deja el BLoC con el cerrojo configurado y ya desbloqueado, que es el
  /// estado normal de la app con el usuario dentro.
  Future<BiometriaBloc> blocEnUso() async {
    when(() => getUserSession.run())
        .thenAnswer((_) async => TestAuthResponse.valid);

    final BiometriaBloc bloc = crearBloc();
    bloc.add(const BiometriaIniciada());
    await Future<void>.delayed(Duration.zero);
    return bloc;
  }

  // ==========================================================================
  // ARRANQUE EN FRÍO
  // ==========================================================================

  group('arranque', () {
    test('bloquea al arrancar si el cerrojo está activo y hay sesión',
        () async {
      when(() => getUserSession.run())
          .thenAnswer((_) async => TestAuthResponse.valid);

      final BiometriaBloc bloc = crearBloc();
      bloc.add(const BiometriaIniciada());
      await Future<void>.delayed(Duration.zero);

      // Quedó desbloqueado porque el auto-intento tuvo éxito, pero pasó por el
      // diálogo: eso es lo que se comprueba.
      verify(() => repositorio.autenticar(motivo: any(named: 'motivo')))
          .called(1);
      await bloc.close();
    });

    /// Sin esta guarda, un usuario recién instalado —o recién salido de cerrar
    /// sesión— se encontraría un cerrojo tapando la pantalla de login.
    test('NO bloquea al arrancar si no hay sesión guardada', () async {
      when(() => getUserSession.run()).thenAnswer((_) async => null);

      final BiometriaBloc bloc = crearBloc();
      bloc.add(const BiometriaIniciada());
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.bloqueado, isFalse);
      verifyNever(() => repositorio.autenticar(motivo: any(named: 'motivo')));
      await bloc.close();
    });

    test('NO bloquea si el usuario no activó el cerrojo', () async {
      when(() => repositorio.consultarEstado()).thenAnswer(
        (_) async => const EstadoBiometria(
          disponible: BiometriaDisponible.huella,
          activado: false,
        ),
      );
      when(() => getUserSession.run())
          .thenAnswer((_) async => TestAuthResponse.valid);

      final BiometriaBloc bloc = crearBloc();
      bloc.add(const BiometriaIniciada());
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.bloqueado, isFalse);
      await bloc.close();
    });

    /// El usuario activó el cerrojo y después borró sus huellas. El aparato ya
    /// no puede autenticar, así que el cerrojo no debe echarse: dejaría a la
    /// persona fuera de su propia app sin forma de llegar al interruptor.
    test('NO bloquea si el aparato ya no admite biometría', () async {
      when(() => repositorio.consultarEstado()).thenAnswer(
        (_) async => const EstadoBiometria(
          disponible: BiometriaDisponible.ninguna,
          activado: true,
        ),
      );
      when(() => getUserSession.run())
          .thenAnswer((_) async => TestAuthResponse.valid);

      final BiometriaBloc bloc = crearBloc();
      bloc.add(const BiometriaIniciada());
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.bloqueado, isFalse);
      await bloc.close();
    });
  });

  // ==========================================================================
  // GRACIA AL VOLVER DEL SEGUNDO PLANO
  // ==========================================================================

  group('gracia de 30 segundos', () {
    test('bloquea si estuvo fuera más de la gracia', () async {
      final BiometriaBloc bloc = await blocEnUso();
      clearInteractions(repositorio);

      bloc.add(const BiometriaAppPausada());
      await Future<void>.delayed(Duration.zero);

      instante = instante.add(BiometriaBloc.gracia + const Duration(seconds: 1));
      bloc.add(const BiometriaAppReanudada());
      await Future<void>.delayed(Duration.zero);

      verify(() => repositorio.autenticar(motivo: any(named: 'motivo')))
          .called(1);
      await bloc.close();
    });

    /// REGRESIÓN — el fallo que dejaba el cerrojo sin efecto.
    ///
    /// Encontrado en el Oppo el 2026-08-25: Android manda una pausa **justo
    /// antes** de la reanudación, mientras la ventana vuelve a entrar. Medido:
    /// salida real 12:07:31, pausa espuria 12:08:09, vuelta 12:08:10.
    ///
    /// Con `_instantePausa = ahora()` esa última pausa pisaba el instante bueno,
    /// el tiempo fuera salía 0,1 s en vez de 39 s, y el cerrojo NO se echaba
    /// nunca. Sin crash y sin error: la función simplemente no hacía nada.
    ///
    /// Se conserva la PRIMERA pausa (`??=`).
    test('cuenta desde la primera pausa, no desde la última', () async {
      final BiometriaBloc bloc = await blocEnUso();
      clearInteractions(repositorio);

      // Salida real del usuario.
      bloc.add(const BiometriaAppPausada());
      await Future<void>.delayed(Duration.zero);

      // 39 segundos fuera.
      instante = instante.add(const Duration(seconds: 39));

      // Pausa espuria que manda el sistema al volver a entrar la ventana.
      bloc.add(const BiometriaAppPausada());
      await Future<void>.delayed(Duration.zero);

      instante = instante.add(const Duration(milliseconds: 100));
      bloc.add(const BiometriaAppReanudada());
      await Future<void>.delayed(Duration.zero);

      verify(() => repositorio.autenticar(motivo: any(named: 'motivo')))
          .called(1);
      await bloc.close();
    });

    /// El caso de todos los días: salir a copiar un dato y volver. Si el
    /// cerrojo saltara aquí, la función sería insoportable.
    test('NO bloquea si volvió dentro de la gracia', () async {
      final BiometriaBloc bloc = await blocEnUso();
      clearInteractions(repositorio);

      bloc.add(const BiometriaAppPausada());
      await Future<void>.delayed(Duration.zero);

      instante = instante.add(const Duration(seconds: 5));
      bloc.add(const BiometriaAppReanudada());
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.bloqueado, isFalse);
      verifyNever(() => repositorio.autenticar(motivo: any(named: 'motivo')));
      await bloc.close();
    });

    /// El escenario que motivó la excepción: el banco manda el código por SMS,
    /// el usuario sale a copiarlo y tarda. Bloquear ahí le impide terminar de
    /// pagar.
    test('NO bloquea encima de una pasarela de pago, aunque tarde', () async {
      final BiometriaBloc bloc = await blocEnUso();
      clearInteractions(repositorio);
      pagoEnCurso = true;

      bloc.add(const BiometriaAppPausada());
      await Future<void>.delayed(Duration.zero);

      instante = instante.add(const Duration(minutes: 10));
      bloc.add(const BiometriaAppReanudada());
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.bloqueado, isFalse);
      verifyNever(() => repositorio.autenticar(motivo: any(named: 'motivo')));
      await bloc.close();
    });

    /// En Android el propio BiometricPrompt hace que la app reporte `paused`.
    /// Sin la guarda de `autenticando`, el cerrojo se rebloquearía a sí mismo
    /// en bucle cada vez que le pide la huella al usuario.
    test('ignora el ciclo de vida mientras el diálogo nativo está abierto',
        () async {
      final BiometriaBloc bloc = await blocEnUso();

      // Diálogo que no termina: deja el BLoC en `autenticando`.
      when(() => repositorio.autenticar(motivo: any(named: 'motivo')))
          .thenAnswer((_) => Future<ResultadoBiometria>.delayed(
                const Duration(milliseconds: 50),
                () => ResultadoBiometria.exito,
              ));

      bloc.add(const BiometriaAppPausada());
      await Future<void>.delayed(Duration.zero);
      instante = instante.add(const Duration(minutes: 5));
      bloc.add(const BiometriaAppReanudada());
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.bloqueado, isTrue);
      expect(bloc.state.autenticando, isTrue);
      clearInteractions(repositorio);

      // Con el diálogo abierto, otra pausa/reanudación no debe apuntar nada ni
      // lanzar un segundo diálogo.
      bloc.add(const BiometriaAppPausada());
      bloc.add(const BiometriaAppReanudada());
      await Future<void>.delayed(const Duration(milliseconds: 100));

      verifyNever(() => repositorio.autenticar(motivo: any(named: 'motivo')));
      await bloc.close();
    });
  });

  // ==========================================================================
  // DESBLOQUEO
  // ==========================================================================

  group('desbloqueo', () {
    test('sigue bloqueado y avisa cuando el sensor está bloqueado', () async {
      when(() => repositorio.autenticar(motivo: any(named: 'motivo')))
          .thenAnswer((_) async => ResultadoBiometria.bloqueoTemporal);
      when(() => getUserSession.run())
          .thenAnswer((_) async => TestAuthResponse.valid);

      final BiometriaBloc bloc = crearBloc();
      bloc.add(const BiometriaIniciada());
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.bloqueado, isTrue);
      expect(bloc.state.avisoPendiente, ResultadoBiometria.bloqueoTemporal);
      await bloc.close();
    });

    /// El aparato dejó de admitir biometría a mitad: hay que levantar el
    /// cerrojo y reflejar que la preferencia se apagó sola.
    test('levanta el cerrojo si la biometría desaparece del aparato', () async {
      when(() => repositorio.autenticar(motivo: any(named: 'motivo')))
          .thenAnswer((_) async => ResultadoBiometria.noDisponible);
      when(() => getUserSession.run())
          .thenAnswer((_) async => TestAuthResponse.valid);

      final BiometriaBloc bloc = crearBloc();
      bloc.add(const BiometriaIniciada());
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.bloqueado, isFalse);
      expect(bloc.state.estado.activado, isFalse);
      expect(bloc.state.avisoPendiente, ResultadoBiometria.noDisponible);
      await bloc.close();
    });

    /// La salida de emergencia tiene que dejar la pantalla despejada para que
    /// el widget pueda cerrar sesión y navegar al login.
    test('abandonar la sesión levanta el cerrojo', () async {
      when(() => repositorio.autenticar(motivo: any(named: 'motivo')))
          .thenAnswer((_) async => ResultadoBiometria.cancelada);
      when(() => getUserSession.run())
          .thenAnswer((_) async => TestAuthResponse.valid);

      final BiometriaBloc bloc = crearBloc();
      bloc.add(const BiometriaIniciada());
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.bloqueado, isTrue);

      bloc.add(const BiometriaSesionAbandonada());
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.bloqueado, isFalse);
      await bloc.close();
    });
  });

  // ==========================================================================
  // INTERRUPTOR
  // ==========================================================================

  group('interruptor', () {
    /// El interruptor debe reflejar lo que quedó GUARDADO, no lo que el
    /// usuario intentó: si la comprobación falla, se queda como estaba.
    test('no se enciende si la comprobación falla', () async {
      when(() => repositorio.autenticar(motivo: any(named: 'motivo')))
          .thenAnswer((_) async => ResultadoBiometria.cancelada);
      when(() => repositorio.consultarEstado()).thenAnswer(
        (_) async => const EstadoBiometria(
          disponible: BiometriaDisponible.huella,
          activado: false,
        ),
      );

      final BiometriaBloc bloc = crearBloc();
      bloc.add(const BiometriaBloqueoCambiado(activar: true));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.estado.activado, isFalse);
      expect(bloc.state.avisoPendiente, ResultadoBiometria.cancelada);
      verifyNever(() => repositorio.guardarBloqueoActivado(true));
      await bloc.close();
    });

    test('se enciende cuando la comprobación tiene éxito', () async {
      final BiometriaBloc bloc = crearBloc();
      bloc.add(const BiometriaBloqueoCambiado(activar: true));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.estado.activado, isTrue);
      expect(bloc.state.avisoPendiente, isNull);
      verify(() => repositorio.guardarBloqueoActivado(true)).called(1);
      await bloc.close();
    });
  });

  // ==========================================================================
  // ESTADO
  // ==========================================================================

  test('el estado inicial no bloquea nada', () {
    const BiometriaState estado = BiometriaState();

    expect(estado.bloqueado, isFalse);
    expect(estado.estado.activado, isFalse);
    expect(estado.estado.sePuedeOfrecer, isFalse);
  });
}
