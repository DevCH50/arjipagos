import 'package:equatable/equatable.dart';

/// Eventos del BLoC de banners.
///
/// La tirilla es de consulta y no guarda estado del usuario: todo se reduce a
/// pedir la lista al servidor. Lo único que cambia entre eventos es **si el
/// usuario debe notarlo**.
abstract class BannerEvent extends Equatable {
  const BannerEvent();

  @override
  List<Object?> get props => [];
}

/// Pide los banners del usuario de la sesión, mostrando el esqueleto.
///
/// La tirilla lo dispara al montarse, ya dentro del Menú Principal, para que
/// siempre se pidan con la sesión recién iniciada. Si el usuario cierra sesión
/// y entra con otra cuenta, la siguiente carga trae los banners correctos.
class BannerCargarEvent extends BannerEvent {
  const BannerCargarEvent();
}

/// Vuelve a pedir la lista **sin** mostrar el esqueleto.
///
/// Es la recarga que dispara un aviso del servidor o la vuelta desde segundo
/// plano. No pasa por `isLoading` a propósito: el usuario está mirando la
/// pantalla y no ha pedido nada, así que ver la tirilla parpadear a siluetas
/// grises y volver sería un salto injustificado. Si la petición falla, se queda
/// lo que ya había.
///
/// Se recarga la lista **entera**; nunca se parchea la local con lo que trae el
/// push. El servidor manda el catálogo ya vigente y ya ordenado, y aplicar
/// cambios sueltos por encima es la forma segura de acabar con dos verdades
/// distintas.
class BannerRefrescarEvent extends BannerEvent {
  const BannerRefrescarEvent();
}

/// Marca que hay que abrir la nota [bannerId] en cuanto esté disponible.
///
/// Llega de tocar la notificación de un aviso nuevo. Se pide también la lista,
/// porque el aviso recién publicado puede no estar todavía en la que se cargó
/// al entrar.
class BannerAbrirDetalleEvent extends BannerEvent {
  const BannerAbrirDetalleEvent(this.bannerId);

  /// Id del banner tal como lo manda el push, en texto.
  final String bannerId;

  @override
  List<Object?> get props => [bannerId];
}

/// Limpia la petición de apertura una vez que la pantalla ya la atendió.
///
/// Sin esto, cualquier reconstrucción posterior volvería a abrir el modal.
class BannerDetalleAtendidoEvent extends BannerEvent {
  const BannerDetalleAtendidoEvent();
}
