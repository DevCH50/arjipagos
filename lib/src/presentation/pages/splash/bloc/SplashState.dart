import 'package:equatable/equatable.dart';

/// Estado de navegación del splash.
enum SplashNavigationState {
  /// Estado inicial, aún cargando.
  loading,

  /// Navegar al home (sesión activa).
  navigateToHome,

  /// Navegar al login (sin sesión).
  navigateToLogin,

  /// Error en la inicialización.
  error,
}

/// Estado del BLoC de splash.
///
/// Contiene el progreso de carga, texto de estado y
/// el destino de navegación cuando se completa.
class SplashState extends Equatable {
  /// Progreso de carga (0.0 a 1.0).
  final double progress;

  /// Texto descriptivo del estado actual.
  final String statusText;

  /// Estado de navegación.
  final SplashNavigationState navigationState;

  /// Mensaje de error si aplica.
  final String? errorMessage;

  const SplashState({
    this.progress = 0.0,
    this.statusText = 'Inicializando...',
    this.navigationState = SplashNavigationState.loading,
    this.errorMessage,
  });

  /// Porcentaje de progreso (0 a 100).
  int get progressPercent => (progress * 100).toInt();

  /// Indica si la carga ha completado.
  bool get isComplete => progress >= 1.0;

  /// Indica si debe navegar.
  bool get shouldNavigate =>
      navigationState == SplashNavigationState.navigateToHome ||
      navigationState == SplashNavigationState.navigateToLogin;

  SplashState copyWith({
    double? progress,
    String? statusText,
    SplashNavigationState? navigationState,
    String? errorMessage,
  }) {
    return SplashState(
      progress: progress ?? this.progress,
      statusText: statusText ?? this.statusText,
      navigationState: navigationState ?? this.navigationState,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [progress, statusText, navigationState, errorMessage];
}
