import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/core/utils/app_logger.dart';
import 'package:arjipagos/src/domain/models/EstadoBiometria.dart';
import 'package:arjipagos/src/domain/models/ResultadoBiometria.dart';
import 'package:arjipagos/src/domain/useCases/auth/AuthUseCases.dart';
import 'package:arjipagos/src/domain/useCases/biometria/BiometriaUseCases.dart';
import 'package:arjipagos/src/presentation/pages/biometria/bloc/BiometriaEvent.dart';
import 'package:arjipagos/src/presentation/pages/biometria/bloc/BiometriaState.dart';
import 'package:arjipagos/src/presentation/utils/RutaActualObserver.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// BLoC del cerrojo biométrico.
///
/// Decide **cuándo** se tapa la app y qué pasa con cada intento de desbloqueo.
/// No sabe pintar nada ni navegar: eso es de `CerrojoBiometrico`.
class BiometriaBloc extends Bloc<BiometriaEvent, BiometriaState> {
  final BiometriaUseCases biometriaUseCases;
  final AuthUseCases authUseCases;

  /// Reloj inyectable. Existe para poder probar la gracia sin esperar 30 s
  /// reales en el test.
  final DateTime Function() ahora;

  /// Si hay una pasarela de pago en pantalla. Inyectable por el mismo motivo.
  final bool Function() hayPagoEnCurso;

  /// Margen antes de bloquear al volver del segundo plano.
  ///
  /// **No es cosmética.** La app saca al usuario fuera de sí misma en varios
  /// sitios —el ticket con `open_filex`, el compartir de Facturas, el SMS con
  /// el código del banco a media pasarela—. Con gracia cero, el cerrojo saltaría
  /// cada vez que alguien va a copiar un dato y vuelve, que es justo el momento
  /// en el que más estorba.
  ///
  /// Treinta segundos es corto para un ladrón y largo para un despiste.
  static const Duration gracia = Duration(seconds: 30);

  /// Instante en que la app pasó a segundo plano **por primera vez** desde la
  /// última vez que estuvo al frente, o `null` si está al frente.
  ///
  /// Lo de "por primera vez" no es un matiz: ver [_onAppPausada].
  DateTime? _instantePausa;

  BiometriaBloc(
    this.biometriaUseCases,
    this.authUseCases, {
    DateTime Function()? ahora,
    bool Function()? hayPagoEnCurso,
  })  : ahora = ahora ?? DateTime.now,
        hayPagoEnCurso =
            hayPagoEnCurso ?? (() => rutaActualObserver.hayPagoEnCurso),
        super(const BiometriaState()) {
    on<BiometriaIniciada>(_onIniciada);
    on<BiometriaAppPausada>(_onAppPausada);
    on<BiometriaAppReanudada>(_onAppReanudada);
    on<BiometriaDesbloqueoSolicitado>(_onDesbloqueoSolicitado);
    on<BiometriaBloqueoCambiado>(_onBloqueoCambiado);
    on<BiometriaAvisoMostrado>(_onAvisoMostrado);
    on<BiometriaSesionAbandonada>(_onSesionAbandonada);
  }

  // ==========================================================================
  // ARRANQUE
  // ==========================================================================

  /// Consulta el estado y, si procede, bloquea ya en el arranque en frío.
  ///
  /// Se exige que haya sesión guardada: sin ella la app va al login, y taparlo
  /// con un cerrojo dejaría a un usuario recién instalado sin poder entrar.
  Future<void> _onIniciada(
    BiometriaIniciada event,
    Emitter<BiometriaState> emit,
  ) async {
    final EstadoBiometria estado = await biometriaUseCases.consultar.run();
    emit(state.copyWith(estado: estado));

    AppLogger.debug(
      'Arranque. activado=${estado.activado} disponible=${estado.disponible}',
      tag: 'Biometria',
    );

    if (!estado.cerrojoOperativo) {
      return;
    }

    final bool haySesion = await authUseCases.getUserSession.run() != null;
    AppLogger.debug('Arranque. haySesion=$haySesion', tag: 'Biometria');
    if (!haySesion) {
      return;
    }

    emit(state.copyWith(bloqueado: true));
    add(const BiometriaDesbloqueoSolicitado());
  }

  // ==========================================================================
  // CICLO DE VIDA
  // ==========================================================================

  void _onAppPausada(
    BiometriaAppPausada event,
    Emitter<BiometriaState> emit,
  ) {
    // El diálogo nativo hace que Android reporte `paused`. Sin esta guarda, el
    // cerrojo se rebloquearía a sí mismo cada vez que pide la huella.
    if (state.autenticando) {
      AppLogger.debug('Pausa ignorada: diálogo nativo abierto', tag: 'Biometria');
      return;
    }

    // `??=` y NO una asignación directa. Es el arreglo de un fallo que dejaba
    // el cerrojo sin efecto, encontrado en el Oppo el 2026-08-25.
    //
    // Android no manda una sola pausa por salida. Manda `hidden` y `paused`
    // seguidos al irse, y —esto es lo que rompía todo— **manda otra pausa justo
    // antes de la reanudación**, mientras la ventana vuelve a entrar. Medido en
    // dispositivo: salida real a las 12:07:31, pausa espuria a las 12:08:09,
    // vuelta a las 12:08:10.
    //
    // Con una asignación directa, esa última pausa pisaba el instante bueno y
    // el tiempo fuera se calculaba en 0,1 s en vez de 39 s. La gracia nunca se
    // superaba y el cerrojo NO se echaba jamás. Sin crash y sin error: la
    // función simplemente no hacía nada.
    //
    // Lo que hay que medir es cuándo salió el usuario, no cuál fue el último
    // evento del sistema. Se conserva la primera pausa y solo se borra al
    // volver al frente.
    _instantePausa ??= ahora();
    AppLogger.debug('App al fondo desde las $_instantePausa', tag: 'Biometria');
  }

  Future<void> _onAppReanudada(
    BiometriaAppReanudada event,
    Emitter<BiometriaState> emit,
  ) async {
    if (state.autenticando) {
      AppLogger.debug('Vuelta ignorada: diálogo nativo abierto', tag: 'Biometria');
      return;
    }

    final DateTime? pausa = _instantePausa;
    _instantePausa = null;

    AppLogger.debug(
      'Vuelta al frente. pausa=$pausa bloqueado=${state.bloqueado} '
      'activado=${state.estado.activado} disponible=${state.estado.disponible}',
      tag: 'Biometria',
    );

    if (pausa == null || state.bloqueado || !state.estado.cerrojoOperativo) {
      return;
    }

    // Nunca encima de un pago en curso, por mucho que haya tardado: el usuario
    // pudo haber salido a copiar el código que le mandó el banco.
    if (hayPagoEnCurso()) {
      AppLogger.info(
        'Vuelta del segundo plano con un pago en curso: no se bloquea',
        tag: 'Biometria',
      );
      return;
    }

    if (ahora().difference(pausa) < gracia) {
      return;
    }

    emit(state.copyWith(bloqueado: true));
    add(const BiometriaDesbloqueoSolicitado());
  }

  // ==========================================================================
  // DESBLOQUEO
  // ==========================================================================

  Future<void> _onDesbloqueoSolicitado(
    BiometriaDesbloqueoSolicitado event,
    Emitter<BiometriaState> emit,
  ) async {
    // Evita que un doble toque abra dos diálogos nativos a la vez.
    if (state.autenticando || !state.bloqueado) {
      return;
    }

    emit(state.copyWith(autenticando: true, limpiarAviso: true));

    final ResultadoBiometria resultado = await biometriaUseCases.autenticar.run(
      motivo: AppStrings.biometriaMotivoDesbloqueo,
    );

    if (resultado == ResultadoBiometria.exito) {
      emit(state.copyWith(bloqueado: false, autenticando: false));
      return;
    }

    // El aparato dejó de admitir biometría: el caso de uso ya apagó la
    // preferencia, así que se levanta el cerrojo y se refleja el cambio. Si no,
    // el usuario se queda encerrado sin poder llegar al interruptor.
    if (resultado == ResultadoBiometria.noDisponible) {
      emit(state.copyWith(
        estado: EstadoBiometria(
          disponible: state.estado.disponible,
          activado: false,
        ),
        bloqueado: false,
        autenticando: false,
        avisoPendiente: resultado,
      ));
      return;
    }

    // Cancelación o fallo: sigue bloqueado, con el botón de reintentar.
    emit(state.copyWith(autenticando: false, avisoPendiente: resultado));
  }

  // ==========================================================================
  // INTERRUPTOR DEL MENÚ
  // ==========================================================================

  Future<void> _onBloqueoCambiado(
    BiometriaBloqueoCambiado event,
    Emitter<BiometriaState> emit,
  ) async {
    if (state.autenticando) {
      return;
    }

    emit(state.copyWith(autenticando: true, limpiarAviso: true));

    final ResultadoBiometria resultado =
        await biometriaUseCases.cambiarBloqueo.run(
      activar: event.activar,
      motivo: AppStrings.biometriaMotivoDesbloqueo,
    );

    // Se vuelve a consultar en vez de asumir: el caso de uso pudo no guardar
    // nada si la comprobación falló, y el interruptor tiene que reflejar lo que
    // de verdad quedó almacenado, no lo que el usuario intentó.
    final EstadoBiometria estado = await biometriaUseCases.consultar.run();

    emit(state.copyWith(
      estado: estado,
      autenticando: false,
      avisoPendiente:
          resultado == ResultadoBiometria.exito ? null : resultado,
      limpiarAviso: resultado == ResultadoBiometria.exito,
    ));
  }

  // ==========================================================================
  // AVISOS Y SALIDA
  // ==========================================================================

  void _onAvisoMostrado(
    BiometriaAvisoMostrado event,
    Emitter<BiometriaState> emit,
  ) {
    emit(state.copyWith(limpiarAviso: true));
  }

  /// El usuario prefiere entrar con su contraseña: se levanta el cerrojo para
  /// que la pantalla pueda cerrar sesión y navegar al login.
  void _onSesionAbandonada(
    BiometriaSesionAbandonada event,
    Emitter<BiometriaState> emit,
  ) {
    _instantePausa = null;
    emit(state.copyWith(
      bloqueado: false,
      autenticando: false,
      limpiarAviso: true,
    ));
  }
}
