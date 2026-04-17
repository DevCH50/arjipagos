import 'package:arjipagos/src/core/constants/app_constants.dart';
import 'package:arjipagos/src/domain/models/Alumno.dart';
import 'package:arjipagos/src/domain/models/EstadoDeCuenta.dart';
import 'package:equatable/equatable.dart';

/// Estado del BLoC de Carrito.
class CarritoState extends Equatable {
  /// Lista de alumnos con sus estados de cuenta.
  final List<Alumno>? alumnos;

  /// Mapa de pagos seleccionados: {alumnoId: [pagoId1, pagoId2, ...]}.
  final Map<int, List<int>> pagosSeleccionados;

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
    Map<int, List<int>>? pagosSeleccionados,
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

  /// Calcula el total a pagar de todos los pagos seleccionados.
  double get totalAPagar {
    if (alumnos == null) {
      return 0.0;
    }

    double total = 0.0;
    for (final alumno in alumnos!) {
      final pagosIds = pagosSeleccionados[alumno.alumnoId] ?? [];
      for (final pago in alumno.estadoDeCuenta) {
        if (pagosIds.contains(pago.id)) {
          total += pago.total;
        }
      }
    }
    return total;
  }

  /// Obtiene la cantidad de pagos seleccionados.
  int get cantidadPagos {
    return pagosSeleccionados.values.fold(0, (sum, list) => sum + list.length);
  }

  /// Obtiene los items del carrito agrupados por alumno.
  List<CarritoItem> get itemsCarrito {
    if (alumnos == null) {
      return [];
    }

    final items = <CarritoItem>[];
    for (final alumno in alumnos!) {
      final pagosIds = pagosSeleccionados[alumno.alumnoId] ?? [];
      final pagos = alumno.estadoDeCuenta
          .where((pago) => pagosIds.contains(pago.id))
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
    for (final pagosIds in pagosSeleccionados.values) {
      allIds.addAll(pagosIds);
    }
    return allIds.join('D');
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

  /// ID del pago más alto SOLO de los que tienen aceptaPagosDiversos = true.
  /// Los pagos sin pagos diversos se pueden eliminar libremente.
  int? get maxPagoIdConPagosDiversos {
    final pagosConDiversos = pagos.where((p) => p.aceptaPagosDiversos).toList();
    if (pagosConDiversos.isEmpty) {
      return null;
    }
    return pagosConDiversos.map((p) => p.id).reduce((a, b) => a > b ? a : b);
  }

  /// Verifica si un pago específico se puede eliminar.
  /// - Si aceptaPagosDiversos = false: Siempre se puede eliminar
  /// - Si aceptaPagosDiversos = true: Solo si es el ID más alto de los que aceptan pagos diversos
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
    return pagoId == maxPagoIdConPagosDiversos;
  }
}
