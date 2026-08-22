import 'package:arjipagos/src/core/constants/app_durations.dart';
import 'package:arjipagos/src/core/utils/app_logger.dart';
import 'package:arjipagos/src/data/dataSource/local/SharedPref.dart';
import 'package:arjipagos/src/domain/models/version/EstadoActualizacion.dart';
import 'package:arjipagos/src/domain/useCases/version/VersionUseCases.dart';
import 'package:arjipagos/src/presentation/pages/actualizacion/bloc/ActualizacionEvent.dart';
import 'package:arjipagos/src/presentation/pages/actualizacion/bloc/ActualizacionState.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// BLoC que decide si hay que obligar al usuario a actualizar la app.
///
/// Lo dispara `ActualizacionObserver` en dos momentos: al primer frame y cada
/// vez que la app vuelve del segundo plano. Esa segunda revisión es la que
/// atrapa las sesiones que quedan abiertas días sin cerrar la app.
///
/// **Un fallo aquí nunca bloquea.** Si la consulta no llega, el veredicto es
/// [EstadoActualizacion.ninguna] y la app sigue como si nada: dejar fuera a un
/// usuario por un problema de red sería peor que permitirle usar una versión
/// vieja un rato más.
class ActualizacionBloc extends Bloc<ActualizacionEvent, ActualizacionState> {
  final VersionUseCases versionUseCases;
  final SharedPref sharedPref;

  /// Reloj inyectable: los tests necesitan mover el tiempo para comprobar el
  /// intervalo entre consultas sin esperar quince minutos reales.
  final DateTime Function() _ahora;

  /// Marca de tiempo (epoch en milisegundos) de la última consulta.
  static const String _claveUltimaRevision = 'ultima_revision_version';

  ActualizacionBloc(
    this.versionUseCases,
    this.sharedPref, {
    DateTime Function()? ahora,
  })  : _ahora = ahora ?? DateTime.now,
        super(ActualizacionState.initial()) {
    on<ActualizacionVerificarEvent>(_onVerificar);
    on<ActualizacionReintentarEvent>(_onReintentar);
    on<ActualizacionDialogoMostradoEvent>(_onDialogoMostrado);
    on<ActualizacionDialogoCerradoEvent>(_onDialogoCerrado);
  }

  /// Comprueba la versión, respetando el intervalo mínimo entre consultas.
  Future<void> _onVerificar(
    ActualizacionVerificarEvent event,
    Emitter<ActualizacionState> emit,
  ) async {
    // Con el diálogo en pantalla no hay nada que recalcular: el usuario ya
    // está viendo el veredicto.
    if (state.dialogoAbierto) {
      return;
    }

    if (!event.forzar && !await _tocaRevisar()) {
      return;
    }

    await _consultar(emit);
  }

  /// Cierra el diálogo y vuelve a preguntar al servidor, en ese orden.
  ///
  /// Tiene que ser **un solo evento**. Mandar por separado un cierre y una
  /// comprobación es una carrera: `bloc` no garantiza el orden entre handlers
  /// de eventos distintos, así que la comprobación podía ejecutarse primero,
  /// encontrarse el diálogo todavía marcado como abierto y salirse sin
  /// consultar. Resultado: el aviso de mantenimiento desaparecía al pulsar
  /// "Reintentar" y no volvía nada. Visto en el Oppo el 2026-08-21.
  Future<void> _onReintentar(
    ActualizacionReintentarEvent event,
    Emitter<ActualizacionState> emit,
  ) async {
    emit(const ActualizacionState());

    await _consultar(emit);
  }

  /// Pregunta al servidor y publica el veredicto.
  ///
  /// Un fallo aquí no se le enseña al usuario: se queda en el log y la app
  /// sigue funcionando con normalidad.
  Future<void> _consultar(Emitter<ActualizacionState> emit) async {
    try {
      await _guardarMarcaDeRevision();

      final resultado = await versionUseCases.verificarActualizacion.run();

      if (isClosed) {
        return;
      }

      emit(state.copyWith(resultado: resultado));
    } catch (e) {
      AppLogger.error('Error verificando la actualización: $e', tag: 'Version');
    }
  }

  /// La pantalla ya mostró el diálogo.
  void _onDialogoMostrado(
    ActualizacionDialogoMostradoEvent event,
    Emitter<ActualizacionState> emit,
  ) {
    emit(state.copyWith(dialogoAbierto: true));
  }

  /// El usuario cerró un aviso descartable: se vuelve al estado neutro para no
  /// reabrirlo en la siguiente reconstrucción.
  void _onDialogoCerrado(
    ActualizacionDialogoCerradoEvent event,
    Emitter<ActualizacionState> emit,
  ) {
    emit(const ActualizacionState());
  }

  /// `true` si ya pasó el intervalo mínimo desde la última consulta.
  ///
  /// Si la preferencia no se puede leer se devuelve `true`: ante la duda, se
  /// prefiere consultar de más antes que dejar de revisar.
  Future<bool> _tocaRevisar() async {
    try {
      final dynamic guardado = await sharedPref.read(_claveUltimaRevision);

      if (guardado is! int) {
        return true;
      }

      final transcurrido = _ahora().millisecondsSinceEpoch - guardado;

      // Un valor futuro solo puede venir de que el usuario movió el reloj del
      // dispositivo; se trata como si nunca se hubiera revisado.
      if (transcurrido < 0) {
        return true;
      }

      return transcurrido >= AppDurations.intervaloRevisionVersion.inMilliseconds;
    } catch (e) {
      AppLogger.warning(
        'No se pudo leer la última revisión de versión: $e',
        tag: 'Version',
      );
      return true;
    }
  }

  /// Anota que se acaba de consultar.
  ///
  /// Se guarda **antes** de saber el resultado, y también cuando la consulta
  /// falla: si el servidor está caído, no tiene sentido reintentar en cada
  /// regreso del segundo plano.
  Future<void> _guardarMarcaDeRevision() async {
    try {
      await sharedPref.save(
        _claveUltimaRevision,
        _ahora().millisecondsSinceEpoch,
      );
    } catch (e) {
      AppLogger.warning(
        'No se pudo guardar la última revisión de versión: $e',
        tag: 'Version',
      );
    }
  }
}
