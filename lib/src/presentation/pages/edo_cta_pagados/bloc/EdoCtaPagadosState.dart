import 'package:arjipagos/src/domain/models/Alumno.dart';
import 'package:equatable/equatable.dart';

/// Estado del BLoC de pagos realizados.
///
/// Contiene únicamente la lista de alumnos con sus pagos ya liquidados. A
/// diferencia de `EdoCtaListState`, aquí no hay selección de pagos: la pantalla
/// es de solo lectura y no alimenta al carrito.
class EdoCtaPagadosState extends Equatable {
  /// Lista de alumnos con sus pagos realizados.
  final List<Alumno>? alumnos;

  /// Indica si está cargando datos.
  final bool isLoading;

  /// Mensaje de error, si existe.
  final String? errorMessage;

  const EdoCtaPagadosState({
    this.alumnos,
    this.isLoading = false,
    this.errorMessage,
  });

  /// Estado inicial vacío.
  factory EdoCtaPagadosState.initial() => const EdoCtaPagadosState();

  /// Cantidad total de pagos realizados, sumando los de todos los alumnos.
  int get cantidadPagos {
    if (alumnos == null) {
      return 0;
    }
    return alumnos!.fold(0, (total, a) => total + a.estadoDeCuenta.length);
  }

  EdoCtaPagadosState copyWith({
    List<Alumno>? alumnos,
    bool? isLoading,
    String? errorMessage,
  }) {
    return EdoCtaPagadosState(
      alumnos: alumnos ?? this.alumnos,
      isLoading: isLoading ?? this.isLoading,
      // Igual que en EdoCtaListState: el error no se arrastra entre estados,
      // se pasa explícitamente en cada emisión o se limpia.
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [alumnos, isLoading, errorMessage];
}
