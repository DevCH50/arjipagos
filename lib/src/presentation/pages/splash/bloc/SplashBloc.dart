import 'dart:async';

import 'package:arjipagos/injection.dart';
import 'package:arjipagos/src/domain/models/AuthResponse.dart';
import 'package:arjipagos/src/domain/useCases/auth/AuthUseCases.dart';
import 'package:arjipagos/src/presentation/pages/splash/bloc/SplashEvent.dart';
import 'package:arjipagos/src/presentation/pages/splash/bloc/SplashState.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// BLoC que gestiona la lógica del splash screen.
///
/// Maneja la inicialización de dependencias, animación de progreso
/// y verificación de sesión para determinar la navegación inicial.
class SplashBloc extends Bloc<SplashEvent, SplashState> {
  Timer? _progressTimer;

  SplashBloc() : super(const SplashState()) {
    on<SplashStarted>(_onSplashStarted);
    on<SplashProgressUpdated>(_onProgressUpdated);
    on<SplashInitializationCompleted>(_onInitializationCompleted);
    on<SplashSessionFound>(_onSessionFound);
    on<SplashNoSessionFound>(_onNoSessionFound);
    on<SplashError>(_onError);
  }

  /// Inicia el proceso de splash.
  Future<void> _onSplashStarted(
    SplashStarted event,
    Emitter<SplashState> emit,
  ) async {
    // Iniciar animación de progreso
    _startProgressAnimation();

    try {
      // Esperar mínimo para que se vea el splash
      await Future.delayed(const Duration(milliseconds: 1500));

      // Completar progreso
      add(const SplashProgressUpdated(progress: 1.0, statusText: 'Listo'));

      // Pequeña pausa al 100%
      await Future.delayed(const Duration(milliseconds: 300));

      // Verificar sesión
      await _checkSession();
    } catch (e) {
      add(SplashError(e.toString()));
    }
  }

  /// Inicia la animación visual de progreso.
  void _startProgressAnimation() {
    double currentProgress = 0.0;

    _progressTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (currentProgress < 0.9) {
        currentProgress += 0.05;

        String statusText;
        if (currentProgress < 0.3) {
          statusText = 'Inicializando...';
        } else if (currentProgress < 0.6) {
          statusText = 'Configurando...';
        } else {
          statusText = 'Verificando sesión...';
        }

        add(SplashProgressUpdated(progress: currentProgress, statusText: statusText));
      } else {
        timer.cancel();
      }
    });
  }

  /// Verifica si existe una sesión activa.
  Future<void> _checkSession() async {
    try {
      final authUseCases = locator<AuthUseCases>();
      final AuthResponse? session = await authUseCases.getUserSession.run();

      if (session != null) {
        add(const SplashSessionFound());
      } else {
        add(const SplashNoSessionFound());
      }
    } catch (e) {
      add(const SplashNoSessionFound());
    }
  }

  /// Actualiza el progreso visual.
  void _onProgressUpdated(
    SplashProgressUpdated event,
    Emitter<SplashState> emit,
  ) {
    emit(state.copyWith(
      progress: event.progress,
      statusText: event.statusText,
    ));
  }

  /// Marca la inicialización como completada.
  void _onInitializationCompleted(
    SplashInitializationCompleted event,
    Emitter<SplashState> emit,
  ) {
    emit(state.copyWith(
      progress: 1.0,
      statusText: 'Listo',
    ));
  }

  /// Navega al home cuando hay sesión.
  void _onSessionFound(
    SplashSessionFound event,
    Emitter<SplashState> emit,
  ) {
    _progressTimer?.cancel();
    emit(state.copyWith(
      progress: 1.0,
      statusText: 'Sesión encontrada',
      navigationState: SplashNavigationState.navigateToHome,
    ));
  }

  /// Navega al login cuando no hay sesión.
  void _onNoSessionFound(
    SplashNoSessionFound event,
    Emitter<SplashState> emit,
  ) {
    _progressTimer?.cancel();
    emit(state.copyWith(
      progress: 1.0,
      statusText: 'Bienvenido',
      navigationState: SplashNavigationState.navigateToLogin,
    ));
  }

  /// Maneja errores de inicialización.
  void _onError(
    SplashError event,
    Emitter<SplashState> emit,
  ) {
    _progressTimer?.cancel();
    emit(state.copyWith(
      navigationState: SplashNavigationState.navigateToLogin,
      errorMessage: event.message,
    ));
  }

  @override
  Future<void> close() {
    _progressTimer?.cancel();
    return super.close();
  }
}
