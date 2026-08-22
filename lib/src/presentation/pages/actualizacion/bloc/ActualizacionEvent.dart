import 'package:equatable/equatable.dart';

/// Eventos del BLoC de actualización de la app.
abstract class ActualizacionEvent extends Equatable {
  const ActualizacionEvent();

  @override
  List<Object?> get props => [];
}

/// Pide comprobar la versión contra el backend.
///
/// [forzar] salta el intervalo mínimo entre consultas. Se usa en el arranque,
/// donde siempre interesa revisar; al volver del segundo plano se deja en
/// `false` para no consultar en cada cambio de app.
class ActualizacionVerificarEvent extends ActualizacionEvent {
  final bool forzar;

  const ActualizacionVerificarEvent({this.forzar = false});

  @override
  List<Object?> get props => [forzar];
}

/// El usuario pulsó "Reintentar": cerrar el aviso y volver a preguntar.
///
/// Es un evento propio y no la suma de un cierre más una comprobación, porque
/// `bloc` no garantiza el orden entre handlers de eventos distintos y esa
/// carrera dejaba la pantalla sin aviso y sin consulta.
class ActualizacionReintentarEvent extends ActualizacionEvent {
  const ActualizacionReintentarEvent();
}

/// La pantalla ya abrió el diálogo: el BLoC deja de proponerlo.
class ActualizacionDialogoMostradoEvent extends ActualizacionEvent {
  const ActualizacionDialogoMostradoEvent();
}

/// El usuario descartó un aviso sugerido: se vuelve al estado neutro.
class ActualizacionDialogoCerradoEvent extends ActualizacionEvent {
  const ActualizacionDialogoCerradoEvent();
}
