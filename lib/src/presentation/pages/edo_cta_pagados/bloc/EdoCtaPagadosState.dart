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

  /// Señal para que la app abra esta pantalla: llegó un push de pago exitoso.
  ///
  /// El BLoC no navega —vive en la raíz y no tiene `Navigator`—, así que deja
  /// aquí la señal y `MenuPrincipalPage` la recoge. Es el mismo mecanismo que
  /// usa `NotificacionBloc` con su `debeNavegar`.
  final bool debeNavegar;

  /// Alumno al que hay que desplazarse al abrir, si el push lo trae.
  ///
  /// Puede ser `null` con toda normalidad: el backend **omite `alumno_id`
  /// cuando un mismo cobro toca a varios alumnos**, porque señalar a uno solo
  /// haría pensar que del otro no se cobró. En ese caso se abre la pantalla sin
  /// destacar a nadie.
  final int? alumnoDestacadoId;

  /// Folio del ticket que acaba de pagarse, para señalar sus renglones.
  ///
  /// Un mismo folio cubre **varios pagos** —en la pantalla se ve: cinco
  /// renglones comparten `T7672`—, así que se resaltan todos los que coincidan.
  ///
  /// También puede faltar: el backend lo omite cuando el cobro tocó a dos
  /// emisores fiscales, porque entonces hay dos folios y mandar uno haría pensar
  /// que el otro no se cobró.
  final String? folioDestacado;

  const EdoCtaPagadosState({
    this.alumnos,
    this.isLoading = false,
    this.errorMessage,
    this.debeNavegar = false,
    this.alumnoDestacadoId,
    this.folioDestacado,
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
    bool? debeNavegar,
    int? alumnoDestacadoId,
    String? folioDestacado,
    bool limpiarDestacado = false,
  }) {
    return EdoCtaPagadosState(
      alumnos: alumnos ?? this.alumnos,
      isLoading: isLoading ?? this.isLoading,
      // Igual que en EdoCtaListState: el error no se arrastra entre estados,
      // se pasa explícitamente en cada emisión o se limpia.
      errorMessage: errorMessage,
      debeNavegar: debeNavegar ?? this.debeNavegar,
      // `alumnoDestacadoId` es nullable, así que el `??` no puede vaciarlo:
      // hace falta la bandera para apagar el destacado cuando ya se atendió.
      alumnoDestacadoId:
          limpiarDestacado ? null : (alumnoDestacadoId ?? this.alumnoDestacadoId),
      folioDestacado:
          limpiarDestacado ? null : (folioDestacado ?? this.folioDestacado),
    );
  }

  @override
  List<Object?> get props => [
        alumnos,
        isLoading,
        errorMessage,
        debeNavegar,
        alumnoDestacadoId,
        folioDestacado,
      ];
}
