/// Clase que centraliza todos los endpoints de la API.
///
/// Uso:
/// ```dart
/// final url = ApiConfig.buildUri(Endpoints.login);
/// ```
abstract class Endpoints {
  // ============================================================================
  // AUTH
  // ============================================================================

  /// POST - Iniciar sesión
  static const String login = '/api/v1/login';

  /// POST - Registrar usuario

  // ============================================================================
  // ALUMNOS
  // ============================================================================


  // ============================================================================
  // ESTADOS DE CUENTA
  // ============================================================================

  /// POST - Obtener estados de cuenta sin pagar
  static const String estadoCuentaSinPagar =
      '/api/v1/alumno/estado-de-cuenta-sin-pagar/';

  /// POST - Obtener estados de cuenta ya pagados
  static const String estadoCuentaPagados =
      '/api/v1/alumno/estado-de-cuenta-pagados/';

  // ============================================================================
  // BANNERS
  // ============================================================================

  /// POST - Obtener los banners informativos del usuario
  static const String banners = '/api/v1/banners';

  // ============================================================================
  // USUARIOS
  // ============================================================================

  /// POST - Cambiar contraseña del usuario autenticado
  static const String cambiarContrasena = '/api/v1/user/change/password/mobile';

  /// POST - Recuperar contraseña (solicitud de restablecimiento)
  static const String recuperarContrasena = '/api/v1/user/recovery/password/mobile';

  // ============================================================================
  // PAGOS
  // ============================================================================

  // La URL de Adquira NO vive aquí: hay una por emisor fiscal, y va siempre
  // acompañada de los parámetros de su contrato (`idexpress` sobre todo). Una
  // constante suelta invitaría a mandar el pago con el endpoint de un emisor y
  // los parámetros de otro, que Adquira acepta sin rechistar cobrando en la
  // cuenta equivocada. Ver `ConfiguracionAdquira`.

  /// Webhook de retorno después del pago
  static const String pagoUrlRetorno =
      'https://arjipagos.moriah.mx/api/v1/pago-realizado/';

  /// POST - Crea el cobro en OpenPay y devuelve la URL de su formulario.
  ///
  /// Lo usa el emisor fiscal 2 ("Otros pagos"). Pide `Authorization: Bearer` y
  /// recibe `{"referencia": "5358A5359A5360"}`; responde
  /// `{"success": true, "url": …, "order_id": …, "importe": …}`.
  ///
  /// **El importe NO se manda.** El backend lo calcula de los cargos que nombra
  /// la referencia, que es lo único que no puede falsear el teléfono.
  ///
  /// Quien llama de verdad a OpenPay es el backend, porque crear el cobro
  /// (`POST /v1/{merchant}/checkouts`) va firmado con la llave privada `sk_…`.
  ///
  /// **El retorno del pago NO se declara aquí, y es a propósito.** A diferencia
  /// de Adquira —donde la app manda su `urlretorno` en el formulario, de ahí
  /// [pagoUrlRetorno]—, en OpenPay el `redirect_url` lo pone el backend al crear
  /// el cobro. La app nunca nombra esa URL: el WebView aterriza en ella por
  /// redirección y lee el `{success, message}` que responde, que es el mismo
  /// contrato que el de Adquira. Una constante aquí sería código muerto y, peor,
  /// podría desincronizarse de la que el servidor use de verdad.
  static const String openpayCrearCargo = '/api/v1/openpay/crear-cargo';

  /// GET - ¿En qué quedó un cobro de OpenPay? `?order_id=…`, con `Bearer`.
  ///
  /// Se consulta al cerrar el WebView de «Otros pagos» si no llegó el retorno:
  /// OpenPay no vuelve solo a la app, y un tutor que cierra con la ✕ después de
  /// pagar no vería nunca el resultado. Responde siempre 200 con
  /// `{success, estado, message}`, y `estado` es uno de `pagado`, `pendiente`,
  /// `rechazado`, `sin_aplicar` o `sin_verificar`. Un `order_id` ajeno da 422.
  ///
  /// Si OpenPay ya cobró y el webhook aún no lo aplicó, **lo aplica esta
  /// misma consulta**, sin duplicarlo.
  static const String openpayEstado = '/api/v1/openpay/estado';

  // ============================================================================
  // NOTIFICACIONES
  // ============================================================================

  /// GET - Historial de notificaciones del usuario (paginado)
  static const String notificaciones = '/api/v1/notificaciones';

  /// GET - Conteo de notificaciones no leídas
  static const String notificacionesNoLeidas = '/api/v1/notificaciones/no-leidas';

  /// POST - Marcar una notificación como leída
  static String notificacionMarcarLeida(int id) => '/api/v1/notificaciones/$id/leer';

  /// POST - Marcar todas las notificaciones como leídas
  static const String notificacionesMarcarTodas = '/api/v1/notificaciones/leer-todas';

  // ============================================================================
  // FACTURAS
  // ============================================================================

  /// POST - Obtener facturas del usuario autenticado (ZIP en base64)
  static const String facturas = '/api/v1/facturas/list';

  // ============================================================================
  // DISPOSITIVO (FCM)
  // ============================================================================

  /// POST - Registrar token FCM del dispositivo al hacer login
  static const String dispositivoRegistrar = '/api/v1/dispositivo/registrar';

  /// DELETE - Desregistrar token FCM del dispositivo al hacer logout
  static const String dispositivoEliminar = '/api/v1/dispositivo/eliminar';

  // ============================================================================
  // VERSIÓN DE LA APP
  // ============================================================================

  /// GET - Política de versión mínima de la plataforma.
  ///
  /// Es el único endpoint **público** (sin Bearer Token): se consulta en el
  /// arranque, antes de que exista una sesión, para poder bloquear una versión
  /// obsoleta aunque el usuario no haya iniciado sesión.
  ///
  /// Espera el parámetro `plataforma` con valor `android` o `ios`.
  static const String appVersion = '/api/v1/app/version';
}