import 'package:arjipagos/src/domain/models/EstadoBiometria.dart';
import 'package:arjipagos/src/domain/models/ResultadoBiometria.dart';
import 'package:equatable/equatable.dart';

/// Estado del bloqueo biométrico.
class BiometriaState extends Equatable {
  /// Qué admite el aparato y qué eligió el usuario.
  final EstadoBiometria estado;

  /// Si el cerrojo está tapando la app en este momento.
  final bool bloqueado;

  /// Si el diálogo nativo está abierto.
  ///
  /// No es solo para pintar un spinner: mientras vale `true` se **ignoran los
  /// cambios de ciclo de vida**. En Android el propio `BiometricPrompt` hace
  /// que la app reporte `paused`, y sin esta guarda el cerrojo se rebloquearía
  /// a sí mismo en bucle cada vez que se le pide la huella al usuario.
  final bool autenticando;

  /// Aviso pendiente de mostrar, o `null` si no hay nada que decir.
  ///
  /// Se guarda el resultado y no el texto: así el widget decide el título y el
  /// mensaje con el mapeador, y el BLoC no sabe nada de cadenas de interfaz.
  final ResultadoBiometria? avisoPendiente;

  const BiometriaState({
    this.estado = const EstadoBiometria.inicial(),
    this.bloqueado = false,
    this.autenticando = false,
    this.avisoPendiente,
  });

  BiometriaState copyWith({
    EstadoBiometria? estado,
    bool? bloqueado,
    bool? autenticando,
    ResultadoBiometria? avisoPendiente,
    bool limpiarAviso = false,
  }) {
    return BiometriaState(
      estado: estado ?? this.estado,
      bloqueado: bloqueado ?? this.bloqueado,
      autenticando: autenticando ?? this.autenticando,
      // Sin la bandera explícita no habría forma de volver a `null`: pasar
      // `avisoPendiente: null` es indistinguible de no pasarlo.
      avisoPendiente: limpiarAviso ? null : (avisoPendiente ?? this.avisoPendiente),
    );
  }

  @override
  List<Object?> get props =>
      <Object?>[estado, bloqueado, autenticando, avisoPendiente];
}
