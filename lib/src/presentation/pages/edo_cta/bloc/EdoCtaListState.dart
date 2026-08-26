import 'package:equatable/equatable.dart';
import 'package:arjipagos/src/domain/models/Alumno.dart';
import 'package:arjipagos/src/domain/models/EstadosDeCuentaResponse.dart';
import 'package:arjipagos/src/domain/models/EstadoDeCuenta.dart';

/// Estado del BLoC de estados de cuenta.
///
/// Contiene la lista de alumnos con sus pagos pendientes
/// y los pagos seleccionados, agrupados por ciclo escolar.
class EdoCtaListState extends Equatable {
  /// Lista de alumnos con sus estados de cuenta.
  final List<Alumno>? alumnos;

  /// Respuesta completa del servidor.
  final EstadosDeCuentaResponse? response;

  /// Indica si está cargando datos.
  final bool isLoading;

  /// Mensaje de error, si existe.
  final String? errorMessage;

  /// Pagos seleccionados: {cicloId: {alumnoId: [pagoId1, pagoId2, ...]}}
  ///
  /// El ámbito del ciclo es lo que delimita las reglas de selección: el orden
  /// ascendente se evalúa solo entre pagos del mismo ciclo, de modo que los
  /// pagos de un ciclo nunca condicionan la selección de otro.
  /// Los IDs de pagos están ordenados de menor a mayor.
  final Map<int, Map<int, List<int>>> pagosSeleccionados;

  /// Emisor fiscal de esta lista.
  ///
  /// El servidor manda de una vez los pagos de todos los emisores; cada BLoC
  /// se queda con los suyos y descarta el resto. No cambia nunca durante la
  /// vida del BLoC: hay una instancia por emisor.
  final int emisorFiscalActivo;

  const EdoCtaListState({
    this.alumnos,
    this.response,
    this.isLoading = false,
    this.errorMessage,
    this.pagosSeleccionados = const {},
    this.emisorFiscalActivo = kEmisorFiscalPredeterminado,
  });

  /// Estado inicial vacío para [emisorFiscalId].
  factory EdoCtaListState.initial(int emisorFiscalId) =>
      EdoCtaListState(emisorFiscalActivo: emisorFiscalId);

  /// Pagos seleccionados de un alumno dentro de un ciclo concreto.
  List<int> pagosDe(int cicloId, int alumnoId) {
    return pagosSeleccionados[cicloId]?[alumnoId] ?? const [];
  }

  /// Los alumnos, pero con solo los pagos del emisor que se está mostrando.
  ///
  /// Un alumno que no tenga ningún pago de ese emisor desaparece de la lista:
  /// enseñar su tarjeta vacía haría pensar que no debe nada, cuando lo que
  /// pasa es que lo suyo está en la otra pantalla.
  List<Alumno>? get alumnosDelEmisor {
    if (alumnos == null) {
      return null;
    }

    final resultado = <Alumno>[];
    for (final alumno in alumnos!) {
      final pagos = alumno.estadoDeCuenta
          .where((pago) => pago.emisorFiscalId == emisorFiscalActivo)
          .toList();
      if (pagos.isNotEmpty) {
        resultado.add(alumno.conEstadoDeCuenta(pagos));
      }
    }
    return resultado;
  }

  /// `true` si un pago cuenta para la pantalla actual: es del emisor que se
  /// está mostrando y el colegio lo tiene publicado para pagarse por internet.
  bool _cuentaEnPantalla(EstadoDeCuenta pago) =>
      pago.emisorFiscalId == emisorFiscalActivo && pago.estaDisponibleEnInternet;

  /// Calcula el total de todos los pagos seleccionados, de todos los ciclos.
  /// Solo considera pagos que estén disponibles en internet.
  double get totalSeleccionado {
    if (alumnos == null) {
      return 0.0;
    }

    double total = 0.0;
    for (final alumno in alumnos!) {
      for (final pago in alumno.estadoDeCuenta) {
        // Solo contar si cuenta en esta pantalla —emisor activo y publicado en
        // internet— y está seleccionado dentro de su propio ciclo.
        if (_cuentaEnPantalla(pago) &&
            pagosDe(pago.cicloId, alumno.alumnoId).contains(pago.id)) {
          total += pago.total;
        }
      }
    }
    return total;
  }

  /// Cuenta los pagos seleccionados en todos los ciclos **de esta pantalla**.
  ///
  /// No se puede contar recorriendo `pagosSeleccionados` a secas: ese mapa
  /// guarda la selección de los dos emisores junta, así que estando en "Otros
  /// pagos" sumaría también lo elegido en "Pagos Pendientes" y la barra del
  /// total enseñaría un importe que esta pantalla no va a cobrar.
  int get cantidadPagosSeleccionados {
    if (alumnos == null) {
      return 0;
    }

    int total = 0;
    for (final alumno in alumnos!) {
      for (final pago in alumno.estadoDeCuenta) {
        if (_cuentaEnPantalla(pago) &&
            pagosDe(pago.cicloId, alumno.alumnoId).contains(pago.id)) {
          total++;
        }
      }
    }
    return total;
  }

  /// Verifica si un pago específico está seleccionado dentro de su ciclo.
  bool isPagoSeleccionado(int cicloId, int alumnoId, int pagoId) {
    return pagosDe(cicloId, alumnoId).contains(pagoId);
  }

  /// Verifica si un pago puede ser seleccionado (respetando el orden).
  ///
  /// Un pago solo puede seleccionarse si todos los pagos con ID menor
  /// **del mismo ciclo** ya están seleccionados. [todosLosPagosIds] debe venir
  /// filtrado al ciclo de [pagoId].
  bool puedeSelecionarPago(
    int cicloId,
    int alumnoId,
    int pagoId,
    List<int> todosLosPagosIds,
  ) {
    final pagosAlumno = pagosDe(cicloId, alumnoId);

    // Ordenar todos los IDs de pagos del alumno en ese ciclo
    final idsOrdenados = List<int>.from(todosLosPagosIds)..sort();

    // Encontrar el índice del pago que queremos seleccionar
    final indicePago = idsOrdenados.indexOf(pagoId);
    if (indicePago == -1) {
      return false;
    }

    // Verificar que todos los pagos anteriores estén seleccionados
    for (int i = 0; i < indicePago; i++) {
      if (!pagosAlumno.contains(idsOrdenados[i])) {
        return false;
      }
    }
    return true;
  }

  EdoCtaListState copyWith({
    List<Alumno>? alumnos,
    EstadosDeCuentaResponse? response,
    bool? isLoading,
    String? errorMessage,
    Map<int, Map<int, List<int>>>? pagosSeleccionados,
    int? emisorFiscalActivo,
  }) {
    return EdoCtaListState(
      alumnos: alumnos ?? this.alumnos,
      response: response ?? this.response,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      pagosSeleccionados: pagosSeleccionados ?? this.pagosSeleccionados,
      emisorFiscalActivo: emisorFiscalActivo ?? this.emisorFiscalActivo,
    );
  }

  @override
  List<Object?> get props => [
        alumnos,
        response,
        isLoading,
        errorMessage,
        pagosSeleccionados,
        emisorFiscalActivo,
      ];
}
