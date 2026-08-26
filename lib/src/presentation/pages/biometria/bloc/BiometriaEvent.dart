import 'package:equatable/equatable.dart';

/// Eventos del bloqueo biométrico.
abstract class BiometriaEvent extends Equatable {
  const BiometriaEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Arranque: consulta qué admite el aparato y qué eligió el usuario.
///
/// Lo dispara `CerrojoBiometrico` tras el primer frame, no el `blocProviders`:
/// hasta entonces no hay árbol montado y el cerrojo no tendría dónde pintarse.
class BiometriaIniciada extends BiometriaEvent {
  const BiometriaIniciada();
}

/// La app pasó a segundo plano. Solo apunta el instante; no bloquea nada.
class BiometriaAppPausada extends BiometriaEvent {
  const BiometriaAppPausada();
}

/// La app volvió al frente. Aquí se decide si toca bloquear.
class BiometriaAppReanudada extends BiometriaEvent {
  const BiometriaAppReanudada();
}

/// El usuario pide levantar el cerrojo. Lanza el diálogo nativo.
class BiometriaDesbloqueoSolicitado extends BiometriaEvent {
  const BiometriaDesbloqueoSolicitado();
}

/// El usuario movió el interruptor del menú.
class BiometriaBloqueoCambiado extends BiometriaEvent {
  final bool activar;

  const BiometriaBloqueoCambiado({required this.activar});

  @override
  List<Object?> get props => <Object?>[activar];
}

/// La pantalla ya mostró el aviso pendiente; se limpia para que no reaparezca.
class BiometriaAvisoMostrado extends BiometriaEvent {
  const BiometriaAvisoMostrado();
}

/// El usuario eligió "Entrar con mi contraseña" en el cerrojo.
///
/// Solo levanta el cerrojo: el cierre de sesión y la navegación los hace la
/// pantalla, igual que en el drawer.
class BiometriaSesionAbandonada extends BiometriaEvent {
  const BiometriaSesionAbandonada();
}
