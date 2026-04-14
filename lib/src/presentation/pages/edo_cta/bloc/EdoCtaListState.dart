import 'package:equatable/equatable.dart';
import 'package:arjipagos/src/domain/models/Alumno.dart';
import 'package:arjipagos/src/domain/models/EstadosDeCuentaResponse.dart';

/// Estado del BLoC de estados de cuenta.
///
/// Contiene la lista de alumnos con sus pagos pendientes
/// y el mapa de pagos seleccionados por alumno.
class EdoCtaListState extends Equatable {
  /// Lista de alumnos con sus estados de cuenta.
  final List<Alumno>? alumnos;

  /// Respuesta completa del servidor.
  final EstadosDeCuentaResponse? response;

  /// Indica si está cargando datos.
  final bool isLoading;

  /// Mensaje de error, si existe.
  final String? errorMessage;

  /// Mapa de pagos seleccionados: {alumnoId: [pagoId1, pagoId2, ...]}
  /// Los IDs de pagos están ordenados de menor a mayor.
  final Map<int, List<int>> pagosSeleccionados;

  const EdoCtaListState({
    this.alumnos,
    this.response,
    this.isLoading = false,
    this.errorMessage,
    this.pagosSeleccionados = const {},
  });

  /// Estado inicial vacío.
  factory EdoCtaListState.initial() => const EdoCtaListState();

  /// Calcula el total de todos los pagos seleccionados.
  /// Solo considera pagos que estén disponibles en internet.
  double get totalSeleccionado {
    if (alumnos == null) {
      return 0.0;
    }

    double total = 0.0;
    for (final alumno in alumnos!) {
      final pagosAlumno = pagosSeleccionados[alumno.alumnoId] ?? [];
      for (final pago in alumno.estadoDeCuenta) {
        // Solo contar si está disponible en internet y está seleccionado
        if (pago.estaDisponibleEnInternet && pagosAlumno.contains(pago.id)) {
          total += pago.total;
        }
      }
    }
    return total;
  }

  /// Cuenta el total de pagos seleccionados.
  int get cantidadPagosSeleccionados {
    int total = 0;
    for (final pagos in pagosSeleccionados.values) {
      total += pagos.length;
    }
    return total;
  }

  /// Verifica si un pago específico está seleccionado.
  bool isPagoSeleccionado(int alumnoId, int pagoId) {
    return pagosSeleccionados[alumnoId]?.contains(pagoId) ?? false;
  }

  /// Verifica si un pago puede ser seleccionado (respetando el orden).
  ///
  /// Un pago solo puede seleccionarse si todos los pagos con ID menor
  /// ya están seleccionados.
  bool puedeSelecionarPago(int alumnoId, int pagoId, List<int> todosLosPagosIds) {
    final pagosAlumno = pagosSeleccionados[alumnoId] ?? [];

    // Ordenar todos los IDs de pagos del alumno
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
    Map<int, List<int>>? pagosSeleccionados,
  }) {
    return EdoCtaListState(
      alumnos: alumnos ?? this.alumnos,
      response: response ?? this.response,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      pagosSeleccionados: pagosSeleccionados ?? this.pagosSeleccionados,
    );
  }

  @override
  List<Object?> get props => [
        alumnos,
        response,
        isLoading,
        errorMessage,
        pagosSeleccionados,
      ];
}
