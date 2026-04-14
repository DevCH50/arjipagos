import 'package:arjipagos/src/domain/models/Factura.dart';
import 'package:arjipagos/src/domain/models/FacturaResponse.dart';
import 'package:equatable/equatable.dart';

/// Estado del BLoC de facturas.
class FacturaState extends Equatable {
  /// Indica si la carga está en progreso.
  final bool isLoading;

  /// Respuesta completa del servidor (incluye familia y lista de facturas).
  final FacturaResponse? response;

  /// Lista de facturas disponibles (atajo a response.facturas).
  final List<Factura> facturas;

  /// Mensaje de error, null si no hay error.
  final String? errorMessage;

  const FacturaState({
    required this.isLoading,
    this.response,
    required this.facturas,
    this.errorMessage,
  });

  /// Estado inicial antes de cargar datos.
  factory FacturaState.initial() => const FacturaState(
    isLoading: false,
    response: null,
    facturas: [],
    errorMessage: null,
  );

  FacturaState copyWith({
    bool? isLoading,
    FacturaResponse? response,
    List<Factura>? facturas,
    String? errorMessage,
    bool clearError = false,
  }) {
    return FacturaState(
      isLoading: isLoading ?? this.isLoading,
      response: response ?? this.response,
      facturas: facturas ?? this.facturas,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [isLoading, response, facturas, errorMessage];
}
