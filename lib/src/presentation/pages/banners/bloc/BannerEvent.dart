import 'package:equatable/equatable.dart';

/// Eventos del BLoC de banners.
///
/// Solo hay carga: la tirilla es de consulta y no guarda estado del usuario.
abstract class BannerEvent extends Equatable {
  const BannerEvent();

  @override
  List<Object?> get props => [];
}

/// Pide los banners del usuario de la sesión.
///
/// La tirilla lo dispara al montarse, ya dentro del Menú Principal, para que
/// siempre se pidan con la sesión recién iniciada. Si el usuario cierra sesión
/// y entra con otra cuenta, la siguiente carga trae los banners correctos.
class BannerCargarEvent extends BannerEvent {
  const BannerCargarEvent();
}
