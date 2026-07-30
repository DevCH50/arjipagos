import 'package:arjipagos/src/core/constants/app_constants.dart';
import 'package:arjipagos/src/domain/models/Alumno.dart';
import 'package:arjipagos/src/domain/models/EstadoDeCuenta.dart';
import 'package:equatable/equatable.dart';

/// Estado del BLoC de Carrito.
class CarritoState extends Equatable {
  /// Lista de alumnos con sus estados de cuenta.
  final List<Alumno>? alumnos;

  /// Pagos seleccionados: {cicloId: {alumnoId: [pagoId1, pagoId2, ...]}}.
  ///
  /// El ciclo delimita las reglas de selección: quitar un pago solo se permite
  /// si es el más alto **de su propio ciclo**, no de toda la lista del alumno.
  final Map<int, Map<int, List<int>>> pagosSeleccionados;

  /// Indica si está cargando.
  final bool isLoading;

  /// Indica si está procesando el pago.
  final bool isProcesandoPago;

  /// Mensaje de error si existe.
  final String? errorMessage;

  /// Datos del pago para el WebView: {url, params, token}.
  final Map<String, dynamic>? pagoData;

  /// Indica si el pago fue exitoso.
  final bool pagoExitoso;

  /// Mensaje de éxito.
  final String? mensajeExito;

  const CarritoState({
    this.alumnos,
    this.pagosSeleccionados = const {},
    this.isLoading = false,
    this.isProcesandoPago = false,
    this.errorMessage,
    this.pagoData,
    this.pagoExitoso = false,
    this.mensajeExito,
  });

  /// Crea una copia del estado con los cambios especificados.
  CarritoState copyWith({
    List<Alumno>? alumnos,
    Map<int, Map<int, List<int>>>? pagosSeleccionados,
    bool? isLoading,
    bool? isProcesandoPago,
    String? errorMessage,
    Map<String, dynamic>? pagoData,
    bool? pagoExitoso,
    String? mensajeExito,
    bool clearError = false,
    bool clearPagoData = false,
  }) {
    return CarritoState(
      alumnos: alumnos ?? this.alumnos,
      pagosSeleccionados: pagosSeleccionados ?? this.pagosSeleccionados,
      isLoading: isLoading ?? this.isLoading,
      isProcesandoPago: isProcesandoPago ?? this.isProcesandoPago,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      pagoData: clearPagoData ? null : (pagoData ?? this.pagoData),
      pagoExitoso: pagoExitoso ?? this.pagoExitoso,
      mensajeExito: mensajeExito ?? this.mensajeExito,
    );
  }

  /// Pagos seleccionados de un alumno dentro de un ciclo concreto.
  List<int> pagosDe(int cicloId, int alumnoId) {
    return pagosSeleccionados[cicloId]?[alumnoId] ?? const [];
  }

  /// Calcula el total a pagar de todos los pagos seleccionados, de todos los ciclos.
  double get totalAPagar {
    if (alumnos == null) {
      return 0.0;
    }

    double total = 0.0;
    for (final alumno in alumnos!) {
      for (final pago in alumno.estadoDeCuenta) {
        if (pagosDe(pago.cicloId, alumno.alumnoId).contains(pago.id)) {
          total += pago.total;
        }
      }
    }
    return total;
  }

  /// Obtiene la cantidad de pagos seleccionados en todos los ciclos.
  int get cantidadPagos {
    return pagosSeleccionados.values.fold(
      0,
      (sum, alumnos) =>
          sum + alumnos.values.fold(0, (s, pagos) => s + pagos.length),
    );
  }

  /// Obtiene los items del carrito agrupados por alumno.
  ///
  /// Un alumno con pagos de varios ciclos produce un único item que los
  /// contiene todos; el ámbito de ciclo se aplica dentro de [CarritoItem].
  List<CarritoItem> get itemsCarrito {
    if (alumnos == null) {
      return [];
    }

    final items = <CarritoItem>[];
    for (final alumno in alumnos!) {
      final pagos = alumno.estadoDeCuenta
          .where((pago) =>
              pagosDe(pago.cicloId, alumno.alumnoId).contains(pago.id))
          .toList();

      if (pagos.isNotEmpty) {
        items.add(CarritoItem(alumno: alumno, pagos: pagos));
      }
    }
    return items;
  }

  /// Genera la referencia para el pago (IDs separados por D).
  /// Ejemplo: "5358D5359D5360"
  String get referenciaPago {
    final allIds = <int>[];
    for (final alumnos in pagosSeleccionados.values) {
      for (final pagosIds in alumnos.values) {
        allIds.addAll(pagosIds);
      }
    }
    return AppConstants.generarReferencia(allIds);
  }

  /// Longitud actual de la referencia de pago.
  int get longitudReferencia => referenciaPago.length;

  /// Indica si la referencia cabe dentro del límite de Adquira México.
  ///
  /// Cuando es `false`, el pago no puede procesarse y el usuario debe
  /// reducir la cantidad de pagos seleccionados.
  bool get referenciaValida =>
      referenciaPago.isEmpty ||
      referenciaPago.length <= AppConstants.maxLongitudReferencia;

  @override
  List<Object?> get props => [
        alumnos,
        pagosSeleccionados,
        isLoading,
        isProcesandoPago,
        errorMessage,
        pagoData,
        pagoExitoso,
        mensajeExito,
      ];
}

/// Representa un item del carrito (alumno con sus pagos seleccionados).
class CarritoItem {
  final Alumno alumno;
  final List<EstadoDeCuenta> pagos;

  const CarritoItem({
    required this.alumno,
    required this.pagos,
  });

  /// Total de los pagos de este alumno.
  double get subtotal {
    return pagos.fold(0.0, (sum, pago) => sum + pago.total);
  }

  /// ID del pago más alto SOLO de los que tienen aceptaPagosDiversos = true,
  /// **dentro del ciclo [cicloId]**.
  ///
  /// El ámbito por ciclo evita que un pago de otro ciclo bloquee la eliminación:
  /// cada ciclo tiene su propio máximo. Los pagos sin pagos diversos se pueden
  /// eliminar libremente.
  int? maxPagoIdConPagosDiversos(int cicloId) {
    final pagosConDiversos = pagos
        .where((p) => p.aceptaPagosDiversos && p.cicloId == cicloId)
        .toList();
    if (pagosConDiversos.isEmpty) {
      return null;
    }
    return pagosConDiversos.map((p) => p.id).reduce((a, b) => a > b ? a : b);
  }

  /// Verifica si un pago específico se puede eliminar.
  /// - Si aceptaPagosDiversos = false: Siempre se puede eliminar
  /// - Si aceptaPagosDiversos = true: Solo si es el ID más alto de los que
  ///   aceptan pagos diversos dentro de su mismo ciclo.
  bool puedeEliminarPago(int pagoId) {
    final pago = pagos.firstWhere(
      (p) => p.id == pagoId,
      orElse: () => throw Exception('Pago no encontrado'),
    );

    // Si no acepta pagos diversos, se puede eliminar libremente
    if (!pago.aceptaPagosDiversos) {
      return true;
    }

    // Si acepta pagos diversos, solo puede eliminarse si es el ID más alto
    // de su propio ciclo
    return pagoId == maxPagoIdConPagosDiversos(pago.cicloId);
  }
}
