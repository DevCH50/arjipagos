import 'package:arjipagos/src/domain/models/BiometriaDisponible.dart';
import 'package:equatable/equatable.dart';

/// Foto del estado del bloqueo biométrico: qué admite el aparato y qué eligió
/// el usuario.
///
/// Van juntos porque la interfaz siempre necesita los dos a la vez: el
/// interruptor se dibuja encendido o apagado según [activado], pero se
/// deshabilita —con su explicación— según [disponible].
class EstadoBiometria extends Equatable {
  /// Qué método de desbloqueo admite este aparato.
  final BiometriaDisponible disponible;

  /// Si el usuario activó el bloqueo al abrir la app.
  final bool activado;

  const EstadoBiometria({
    required this.disponible,
    required this.activado,
  });

  /// Estado de partida, antes de consultar nada: sin bloqueo y sin saber qué
  /// admite el aparato. Nunca deja el interruptor encendido por omisión.
  const EstadoBiometria.inicial()
      : disponible = BiometriaDisponible.ninguna,
        activado = false;

  /// Si se puede ofrecer el bloqueo en este aparato.
  ///
  /// [BiometriaDisponible.soloCredencial] cuenta: el PIN o patrón del
  /// dispositivo sirve igual para el cerrojo.
  bool get sePuedeOfrecer => disponible != BiometriaDisponible.ninguna;

  /// El cerrojo solo actúa si además de estar activado el aparato sigue
  /// pudiendo autenticar. Comprobar solo [activado] dejaría a alguien
  /// encerrado si borró sus huellas después de activarlo.
  bool get cerrojoOperativo => activado && sePuedeOfrecer;

  @override
  List<Object?> get props => <Object?>[disponible, activado];
}
