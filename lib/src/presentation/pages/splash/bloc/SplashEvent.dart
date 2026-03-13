import 'package:equatable/equatable.dart';

/// Eventos del BLoC de splash.
abstract class SplashEvent extends Equatable {
  const SplashEvent();

  @override
  List<Object?> get props => [];
}

/// Evento para iniciar la carga del splash.
class SplashStarted extends SplashEvent {
  const SplashStarted();
}

/// Evento interno para actualizar el progreso.
class SplashProgressUpdated extends SplashEvent {
  final double progress;
  final String statusText;

  const SplashProgressUpdated({
    required this.progress,
    required this.statusText,
  });

  @override
  List<Object?> get props => [progress, statusText];
}

/// Evento cuando la inicialización se completa.
class SplashInitializationCompleted extends SplashEvent {
  const SplashInitializationCompleted();
}

/// Evento cuando se verifica que hay sesión activa.
class SplashSessionFound extends SplashEvent {
  const SplashSessionFound();
}

/// Evento cuando no hay sesión activa.
class SplashNoSessionFound extends SplashEvent {
  const SplashNoSessionFound();
}

/// Evento cuando ocurre un error en la inicialización.
class SplashError extends SplashEvent {
  final String message;

  const SplashError(this.message);

  @override
  List<Object?> get props => [message];
}
