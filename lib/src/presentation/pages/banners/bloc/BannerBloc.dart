import 'package:arjipagos/src/core/utils/app_logger.dart';
import 'package:arjipagos/src/core/utils/network_error_mapper.dart';
import 'package:arjipagos/src/domain/models/banner/BannersResponse.dart';
import 'package:arjipagos/src/domain/useCases/banners/BannerUseCases.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart' as utils;
import 'package:arjipagos/src/presentation/pages/banners/bloc/BannerEvent.dart';
import 'package:arjipagos/src/presentation/pages/banners/bloc/BannerState.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// BLoC de la tirilla de banners del Menú Principal.
///
/// Un fallo aquí **no debe estorbar**: los banners son contenido informativo,
/// no parte del flujo de pago. Por eso el error se guarda en el estado y se
/// registra en el log, pero la pantalla se limita a no mostrar la tirilla; no
/// hay diálogo de error que interrumpa al usuario al entrar al menú.
class BannerBloc extends Bloc<BannerEvent, BannerState> {
  final BannerUseCases bannerUseCases;

  BannerBloc(this.bannerUseCases) : super(BannerState.initial()) {
    on<BannerCargarEvent>(_onCargar);
  }

  /// Consulta los banners y emite el estado correspondiente.
  Future<void> _onCargar(
    BannerCargarEvent event,
    Emitter<BannerState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true, errorMessage: null));

      final result = await bannerUseCases.getBanners.run();

      if (result is utils.Success<BannersResponse>) {
        emit(state.copyWith(
          banners: result.data.banners,
          isLoading: false,
          errorMessage: null,
        ));
      } else if (result is utils.Error<BannersResponse>) {
        // Se conserva la tirilla anterior si ya había uno cargado: al usuario
        // le sirve más el contenido viejo que una franja vacía.
        emit(state.copyWith(
          isLoading: false,
          errorMessage: result.msg,
        ));
      }
    } catch (e) {
      // El detalle técnico va al log; al usuario solo un mensaje legible.
      AppLogger.error('Error inesperado cargando banners: $e', tag: 'Banners');
      emit(state.copyWith(
        isLoading: false,
        errorMessage: mensajeErrorRed(e),
      ));
    }
  }
}
