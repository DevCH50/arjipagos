import 'package:equatable/equatable.dart';

/// Estado del BLoC del ticket de pago.
///
/// [rutaArchivo] es la ruta del PDF ya escrito en la carpeta temporal. Cuando
/// deja de estar vacía, el ticket está listo para entregarse al sistema.
class TicketState extends Equatable {
  /// Ruta absoluta del PDF descargado; vacía mientras no haya archivo.
  final String rutaArchivo;

  /// Folio del ticket, usado en el título y en el asunto al compartir.
  final String folio;

  /// URL de origen del ticket; se conserva para poder reintentar la descarga.
  final String url;

  /// Indica si la descarga está en curso.
  final bool isLoading;

  /// Mensaje de error legible, si la descarga falló.
  final String? errorMessage;

  const TicketState({
    this.rutaArchivo = '',
    this.folio = '',
    this.url = '',
    this.isLoading = false,
    this.errorMessage,
  });

  /// Estado inicial vacío.
  factory TicketState.initial() => const TicketState();

  /// El ticket está descargado y disponible en disco.
  bool get tieneArchivo => rutaArchivo.isNotEmpty;

  TicketState copyWith({
    String? rutaArchivo,
    String? folio,
    String? url,
    bool? isLoading,
    String? errorMessage,
  }) {
    return TicketState(
      rutaArchivo: rutaArchivo ?? this.rutaArchivo,
      folio: folio ?? this.folio,
      url: url ?? this.url,
      isLoading: isLoading ?? this.isLoading,
      // Igual que en los demás estados del proyecto: el error no se arrastra,
      // se pasa explícitamente en cada emisión o se limpia.
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [rutaArchivo, folio, url, isLoading, errorMessage];
}
