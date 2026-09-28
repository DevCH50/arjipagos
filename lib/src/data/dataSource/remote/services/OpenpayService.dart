import 'dart:async';
import 'dart:convert';

import 'package:arjipagos/src/core/constants/app_durations.dart';
import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/core/utils/app_logger.dart';
import 'package:arjipagos/src/core/utils/network_error_mapper.dart';
import 'package:arjipagos/src/data/api/ApiConfig.dart';
import 'package:arjipagos/src/data/api/endpoints.dart';
import 'package:arjipagos/src/domain/models/AuthResponse.dart';
import 'package:arjipagos/src/domain/models/OpenpayCheckout.dart';
import 'package:arjipagos/src/domain/useCases/auth/AuthUseCases.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart';
import 'package:http/http.dart' as http;

/// Servicio HTTP del cobro por OpenPay («Otros pagos», emisor fiscal 2).
///
/// Tiene **una sola responsabilidad**: pedirle al backend la URL del formulario
/// de OpenPay para una selección de cargos. A partir de ahí manda el WebView, y
/// el resultado del pago no vuelve por aquí sino por el retorno del backend.
///
/// **No habla con OpenPay.** Crear el cobro (`POST /v1/{merchant}/checkouts`)
/// se firma con la llave privada `sk_…`, y esa llave no puede vivir en la app:
/// se saca del APK con `unzip` y `strings`, y con ella se crean cargos y se
/// hacen devoluciones en el comercio. Por eso llama al backend, que sí la tiene.
///
/// El emisor 1 («Pagos Pendientes») no pasa por aquí: sigue con Adquira, que no
/// se ha tocado.
class OpenpayService {
  final AuthUseCases authUseCases;

  OpenpayService(this.authUseCases);

  /// Pide al backend que cree el cobro de [referencia] y devuelve su URL.
  ///
  /// [referencia] es la misma cadena de siempre —los ids de los cargos unidos
  /// por el separador del canal, `5358A5359A5360` en Android y `…I…` en iOS—,
  /// generada por `PoliticaEmisor.generarReferencia`. El separador es lo que le
  /// dice al backend por dónde entró el pago.
  ///
  /// **El importe no se manda.** Lo calcula el servidor a partir de los cargos
  /// que nombra la referencia: es el único dato que el teléfono no puede
  /// falsear, y con él se evita que una app manipulada pida cobrar un peso por
  /// una colegiatura.
  ///
  /// Devuelve [Success] con el [OpenpayCheckout] o [Error] con un mensaje ya
  /// redactado para el usuario.
  Future<Resource<OpenpayCheckout>> crearCargo(String referencia) async {
    try {
      final AuthResponse? authResponse = await authUseCases.getUserSession
          .run();

      if (authResponse == null) {
        AppLogger.warning('Intento de cobrar sin sesión', tag: 'OpenPay');
        return Error<OpenpayCheckout>(AppStrings.errorNoSession);
      }

      final String token = authResponse.accessToken;

      if (token.isEmpty) {
        AppLogger.warning('Token vacío al cobrar', tag: 'OpenPay');
        return Error<OpenpayCheckout>(AppStrings.errorNoToken);
      }

      if (referencia.trim().isEmpty) {
        AppLogger.warning('Referencia vacía al cobrar', tag: 'OpenPay');
        return Error<OpenpayCheckout>(AppStrings.openpaySinReferencia);
      }

      final Uri url = ApiConfig.buildUri(Endpoints.openpayCrearCargo);

      AppLogger.httpRequest('POST', url.toString());

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode({'referencia': referencia}),
          )
          .timeout(AppDurations.httpTimeout);

      AppLogger.httpResponse(response.statusCode, url.toString());

      return _interpretar(response, referencia);
    } catch (e) {
      // El detalle técnico va al log; al usuario, un mensaje entendible.
      // Nunca `e.toString()`: el 2026-08-13 un HandshakeException llegó literal
      // a la pantalla. Hay test guardián sobre esta regla.
      AppLogger.error('Error al crear el cobro', error: e, tag: 'OpenPay');
      return Error<OpenpayCheckout>(mensajeErrorRed(e));
    }
  }

  /// Traduce la respuesta del backend a [Success] o [Error].
  ///
  /// **El código HTTP no decide solo.** El backend contesta 422, 401, 502 o 503
  /// según qué falló, y en todos esos casos manda un `message` ya escrito para
  /// el tutor («Estos cargos ya no están pendientes…», «El pago con tarjeta no
  /// está disponible…»). Ese texto es mejor que cualquiera que se invente aquí,
  /// así que se muestra tal cual y solo se recurre a un mensaje genérico cuando
  /// no viene ninguno.
  Resource<OpenpayCheckout> _interpretar(
    http.Response response,
    String referencia,
  ) {
    final String cuerpo = response.body.trim();

    // Un servidor caído devuelve la página de error de Laravel, no JSON.
    // Intentar parsearla daría un FormatException que no le dice nada a nadie.
    if (cuerpo.startsWith('<!DOCTYPE') || cuerpo.startsWith('<html')) {
      AppLogger.error(
        'El servidor devolvió HTML en lugar de JSON (${response.statusCode})',
        tag: 'OpenPay',
      );
      return Error<OpenpayCheckout>(AppStrings.errorRespuestaInvalida);
    }

    final Map<String, dynamic> datos;
    try {
      final decodificado = json.decode(cuerpo);
      if (decodificado is! Map<String, dynamic>) {
        throw const FormatException('La respuesta no es un objeto JSON');
      }
      datos = decodificado;
    } catch (e) {
      AppLogger.error(
        'Respuesta ilegible del backend',
        error: e,
        tag: 'OpenPay',
      );
      return Error<OpenpayCheckout>(AppStrings.errorRespuestaInvalida);
    }

    // 🔴 Sin la clave `success` NO es una respuesta nuestra.
    //
    // Laravel contesta los errores de framework —ruta inexistente, método no
    // permitido, excepción no capturada— con `{"message": "..."}` y nada más, y
    // ese texto está escrito para un programador: «The POST method is not
    // supported for route api/v1/openpay/crear-cargo». Enseñárselo a un padre
    // que quiere pagar la colegiatura no le dice nada y parece un fallo suyo.
    //
    // El controlador de OpenPay manda SIEMPRE `success`, en el acierto y en
    // cada uno de sus rechazos. Así que su ausencia distingue «el backend me
    // rechazó y me explicó por qué» de «aquí no hay backend».
    if (!datos.containsKey('success')) {
      AppLogger.error(
        'Respuesta sin "success" (${response.statusCode}) — ref $referencia — '
        '¿está desplegada la ruta de OpenPay? — ${datos['message']}',
        tag: 'OpenPay',
      );
      return Error<OpenpayCheckout>(AppStrings.openpayNoSePudoIniciar);
    }

    final String mensaje = (datos['message'] ?? '').toString().trim();

    if (datos['success'] != true) {
      AppLogger.warning(
        'Cobro rechazado por el backend (${response.statusCode}) — '
        'ref $referencia — $mensaje',
        tag: 'OpenPay',
      );
      return Error<OpenpayCheckout>(
        mensaje.isNotEmpty ? mensaje : AppStrings.openpayNoSePudoIniciar,
      );
    }

    final checkout = OpenpayCheckout.fromJson(datos);

    // `success: true` sin URL no es un cobro: es una respuesta rota. Dejar
    // pasar esto abriría el WebView en una cadena vacía y el usuario vería una
    // pantalla en blanco sin saber si le cobraron.
    if (!checkout.urlValida) {
      AppLogger.error(
        'El backend aceptó el cobro pero no mandó una URL usable — '
        'ref $referencia — url "${checkout.url}"',
        tag: 'OpenPay',
      );
      return Error<OpenpayCheckout>(AppStrings.openpayNoSePudoIniciar);
    }

    AppLogger.debug(
      'Cobro creado — ref $referencia | order_id ${checkout.orderId} | '
      'importe ${checkout.importe}',
      tag: 'OpenPay',
    );

    return Success<OpenpayCheckout>(checkout);
  }
}
