import 'package:arjipagos/src/domain/models/version/EstadoActualizacion.dart';
import 'package:equatable/equatable.dart';

/// Estado del BLoC de actualización.
///
/// No guarda mensajes de error: si la consulta falla, el estado se queda en
/// [EstadoActualizacion.ninguna] y el usuario no se entera de nada. Un aviso de
/// red en el arranque solo estorbaría.
class ActualizacionState extends Equatable {
  /// Veredicto de la última comprobación.
  final ResultadoActualizacion resultado;

  /// `true` mientras el diálogo está en pantalla, para no apilar otro encima
  /// cuando la app vuelve del segundo plano.
  final bool dialogoAbierto;

  const ActualizacionState({
    this.resultado = ResultadoActualizacion.sinCambios,
    this.dialogoAbierto = false,
  });

  /// Estado inicial: nada que mostrar.
  factory ActualizacionState.initial() => const ActualizacionState();

  /// Hay un veredicto pendiente de mostrar en pantalla.
  bool get hayDialogoPendiente => resultado.requiereDialogo && !dialogoAbierto;

  ActualizacionState copyWith({
    ResultadoActualizacion? resultado,
    bool? dialogoAbierto,
  }) {
    return ActualizacionState(
      resultado: resultado ?? this.resultado,
      dialogoAbierto: dialogoAbierto ?? this.dialogoAbierto,
    );
  }

  @override
  List<Object?> get props => [
        resultado.estado,
        resultado.mensaje,
        resultado.urlTienda,
        dialogoAbierto,
      ];
}
