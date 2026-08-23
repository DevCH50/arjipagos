import 'package:arjipagos/src/core/constants/app_urls.dart';
import 'package:in_app_review/in_app_review.dart';

/// Envoltorio delgado sobre `in_app_review`.
///
/// Existe solo para que el canal nativo sea sustituible por un mock en los
/// tests: `InAppReview.instance` es un singleton que llama a plataforma y no se
/// puede ejercitar en un unit test.
class ResenaNativa {
  final InAppReview _inAppReview;

  ResenaNativa([InAppReview? inAppReview])
      : _inAppReview = inAppReview ?? InAppReview.instance;

  /// Si el sistema puede mostrar la hoja de reseña.
  ///
  /// En Android es `false` cuando la app no se instaló desde Google Play — por
  /// ejemplo con `adb install` —, así que en las pruebas locales por USB esto
  /// siempre corta antes de invitar. Es esperado, no un fallo.
  Future<bool> disponible() => _inAppReview.isAvailable();

  /// Pide al sistema que muestre la hoja de reseña nativa.
  Future<void> solicitar() => _inAppReview.requestReview();

  /// Abre la ficha de la app en la tienda que corresponda.
  ///
  /// `appStoreId` solo lo usa iOS; en Android el plugin resuelve la ficha por
  /// el nombre del paquete.
  Future<void> abrirFicha() =>
      _inAppReview.openStoreListing(appStoreId: AppUrls.appStoreId);
}
