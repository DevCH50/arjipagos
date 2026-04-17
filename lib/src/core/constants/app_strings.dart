/// Strings de la aplicación ArjiPagos.
///
/// Centraliza todos los textos utilizados en la app para
/// facilitar el mantenimiento y futura internacionalización.
class AppStrings {
  AppStrings._();

  // ============================================================================
  // GENERAL
  // ============================================================================

  static const String appName = 'Arjí Pagos';
  static const String appDescription = 'Plataforma de Gestión de Pagos';

  // ============================================================================
  // SPLASH
  // ============================================================================

  static const String splashInitializing = 'Inicializando...';
  static const String splashConfiguring = 'Configurando...';
  static const String splashVerifyingSession = 'Verificando sesión...';
  static const String splashReady = 'Listo';
  static const String splashSesionEncontrada = 'Sesión encontrada';
  static const String splashBienvenido = 'Bienvenido';

  // ============================================================================
  // LOGIN
  // ============================================================================

  static const String loginTitle = 'Iniciar Sesión';
  static const String loginUsername = 'Usuario';
  static const String loginPassword = 'Contraseña';
  static const String loginButton = 'Ingresar';
  static const String loginForgotPassword = '¿Olvidaste tu contraseña?';
  static const String loginNoAccount = '¿No tienes cuenta?';
  static const String loginRegister = 'Regístrate';

  // Validaciones
  static const String loginUsernameRequired = 'Escribe el Nombre de Usuario';
  static const String loginPasswordRequired = 'Ingresa la Contraseña';
  static const String loginPasswordMinLength = 'Mínimo 6 caracteres';

  // ============================================================================
  // REGISTRO
  // ============================================================================

  static const String registerTitle = 'REGISTRO';
  static const String registerName = 'Nombre';
  static const String registerLastName = 'Apellido Paterno';
  static const String registerSecondLastName = 'Apellido Materno';
  static const String registerPhone = 'Celular';
  static const String registerEmail = 'Email';
  static const String registerPassword = 'Contraseña';
  static const String registerConfirmPassword = 'Confirmar Contraseña';
  static const String registerButton = 'Guardar';

  // ============================================================================
  // GENERAL — ACCIONES COMUNES
  // ============================================================================

  static const String accept = 'Aceptar';
  static const String cancel = 'Cancelar';
  static const String confirm = 'Confirmar';
  static const String retry = 'Reintentar';
  static const String close = 'Cerrar';
  static const String back = 'Volver';
  static const String send = 'Enviar';
  static const String update = 'Actualizar';
  static const String error = 'Error';
  static const String info = 'Información';
  static const String understood = 'Entendido';
  static const String comingSoon = 'Próximamente';
  static const String mostrarContrasena = 'Mostrar contraseña';
  static const String ocultarContrasena = 'Ocultar contraseña';
  static const String errorAlCargar = 'Error al cargar';

  // ============================================================================
  // HOME
  // ============================================================================

  static const String homeLoading = 'Cargando Alumnos...';
  static const String homeNoStudents = 'No hay Alumnos registrados';
  static const String homeRefresh = 'Actualizar';
  static const String homeRetry = 'Reintentar';
  static const String homeError = 'Error';

  // Labels de información
  static const String homeFamilyId = 'Familia ID';
  static const String homeSchoolYear = 'Ciclo Escolar';
  static const String homeStudent = 'Alumno';
  static const String homeStudents = 'Alumnos';

  // ============================================================================
  // MENÚ PRINCIPAL
  // ============================================================================

  static const String menuPrincipalTitle = 'Menú Principal';
  static const String menuCambiarContrasena = 'Cambiar Contraseña';
  static const String menuTocaCualquierCampo = 'Toca cualquier campo para copiar';
  static const String menuFacturasProximamente = 'La sección de Facturas estará disponible pronto.';
  static const String menuMiCuenta = 'Mi cuenta';
  static const String menuSinAlumnos = 'Sin alumnos';
  static const String menuPagos = 'Pagos';
  static const String menuFacturas = 'Facturas';
  static const String menuCerrando = 'Cerrando sesión...';
  static const String menuNoPudoCargar = 'No se pudo cargar la información del usuario';

  // ============================================================================
  // DRAWER — DATOS DEL USUARIO
  // ============================================================================

  static const String drawerDatosPersonales = 'Datos personales';
  static const String drawerMiCuenta = 'Mi cuenta';
  static const String drawerIdLabel = 'ID';
  static const String drawerEmail = 'Email';
  static const String drawerCelular = 'Celular';
  static const String drawerFamilia = 'Familia';
  static const String drawerSinRegistrar = 'Sin registrar';

  // ============================================================================
  // LOGOUT
  // ============================================================================

  static const String logoutTitle = 'Cerrar Sesión';
  static const String logoutMessage = '¿Estás seguro que deseas cerrar sesión?';
  static const String logoutConfirm = 'Cerrar Sesión';
  static const String logoutCancel = 'Cancelar';

  // ============================================================================
  // ESTADOS DE CUENTA
  // ============================================================================

  static const String edoCtaTitle = 'Estados de Cuenta';
  static const String edoCtaLoading = 'Cargando estados de cuenta...';
  static const String edoCtaSinPagosPendientes = 'Sin pagos pendientes';
  static const String edoCtaSinPagosEnLinea = 'Sin pagos disponibles para pago en línea';
  static const String edoCtaContinuar = 'Continuar';
  static const String edoCtaVence = 'Vence:';
  static const String edoCtaPagoNum = 'Pago #';
  static const String edoCtaVencido = 'Vencido';
  static const String edoCtaPendiente = 'Pendiente';
  static const String edoCtaInfoDialogMsg =
      'Debes seleccionar primero los pagos anteriores para poder seleccionar este.';
  static const String edoCtaOrdenPagosMsg =
      'Debe seleccionar los pagos en orden (del más antiguo al más reciente)';
  static const String edoCtaGrupo = 'Grupo:';
  static const String edoCtaLimpiarSeleccion = 'Limpiar selección';
  static const String edoCtaReferenciaLimiteAlcanzado =
      'No es posible agregar más pagos a esta transacción.\n\n'
      'El límite de la pasarela de pago ha sido alcanzado. '
      'Realiza el pago con los pagos seleccionados y '
      'después agrega los restantes.';

  // ============================================================================
  // CARRITO
  // ============================================================================

  static const String carritoTitle = 'Carrito';
  static const String carritoLoading = 'Cargando carrito...';
  static const String carritoVaciarTitle = 'Vaciar carrito';
  static const String carritoVaciarConfirm = '¿Estás seguro de que deseas vaciar el carrito?';
  static const String carritoVaciar = 'Vaciar';
  static const String carritoEmpty = 'Selecciona pagos desde Estados de Cuenta';
  static const String carritoSinPagos = 'No hay pagos seleccionados';
  static const String carritoPagar = 'Pagar';
  static const String carritoProcesando = 'Procesando...';
  static const String carritoQuitar = 'Quitar';
  static const String carritoQuitarOrden = 'Debe quitar primero los pagos más recientes';
  static const String carritoReferenciaExcede =
      'La referencia de pago excede el límite permitido por la pasarela.\n\n'
      'Regresa a Estados de Cuenta y reduce la cantidad de pagos seleccionados.';

  // ============================================================================
  // PAGO WEBVIEW
  // ============================================================================

  static const String pagoWebViewTitle = 'Realizar Pago';
  static const String pagoLoading = 'Cargando página de pago...';
  static const String pagoExitosoTitle = 'Pago exitoso';
  static const String pagoExitosoMsg = 'Tu pago ha sido procesado correctamente.';
  static const String pagoErrorTitle = 'Error en el pago';
  static const String pagoCancelarTitle = 'Cancelar pago';
  static const String pagoCancelarMsg = '¿Estás seguro de que deseas cancelar el pago?';
  static const String pagoContinuar = 'Continuar pago';
  static const String pagoNoProcesado = 'El pago no pudo ser procesado';
  static const String pagoProcesadoCorrectamente = 'Pago procesado correctamente';
  static const String pagoRealizadoConExito = 'Pago realizado con éxito';

  // ============================================================================
  // NOTIFICACIONES
  // ============================================================================

  static const String notificacionesTitle = 'Notificaciones';
  static const String notificacionesMarcarLeidas = 'Marcar todas leídas';
  static const String notificacionesSinNotif = 'Sin notificaciones';
  static const String notificacionesAquiApareceran =
      'Cuando tengas notificaciones aparecerán aquí';

  // Canal de notificaciones Android — nombre y descripción visibles en Ajustes del sistema
  static const String fcmChannelNombre = 'Arjipagos';
  static const String fcmChannelDescripcion =
      'Notificaciones de pagos y estados de cuenta';

  // ============================================================================
  // CAMBIAR CONTRASEÑA
  // ============================================================================

  static const String cambiarContrasenaTitle = 'Cambiar Contraseña';
  static const String cambiarContrasenaActual = 'Contraseña actual';
  static const String cambiarContrasenaNueva = 'Nueva contraseña';
  static const String cambiarContrasenaConfirmar = 'Confirmar nueva contraseña';
  static const String cambiarContrasenaButton = 'Cambiar Contraseña';
  static const String cambiarContrasenaActualizada = 'Contraseña actualizada';
  static const String cambiarContrasenaDescripcion =
      'Ingresa tu contraseña actual y la nueva contraseña que deseas establecer.';
  static const String cambiarContrasenaExitosoMsg =
      'Tu contraseña ha sido actualizada correctamente.';
  static const String cambiarContrasenaCamposMsg =
      'Por favor, completa todos los campos correctamente.';

  // Validaciones inline
  static const String cambiarContrasenaIngresaActual = 'Ingresa tu contraseña actual';
  static const String cambiarContrasenaIngresaNueva = 'Ingresa la nueva contraseña';
  static const String cambiarContrasenaConfirmaError = 'Confirma la nueva contraseña';
  static const String cambiarContrasenaNoCoinciden = 'Las contraseñas no coinciden';

  // ============================================================================
  // REGISTRO
  // ============================================================================

  static const String registerExitosoTitle = 'Registro exitoso';
  static const String registerExitosoMsg = 'Ahora puedes iniciar sesión con tu cuenta.';
  static const String registerIrLogin = 'Iniciar sesión';
  static const String registerCamposIncompletos = 'Campos incompletos';

  // ============================================================================
  // VALIDACIONES COMUNES
  // ============================================================================

  static const String validacionCamposIncompletos = 'Campos incompletos';

  // ============================================================================
  // ERRORES
  // ============================================================================

  static const String errorNoSession = 'No hay sesión activa';
  static const String errorSesionInvalida = 'Sesión no válida';
  static const String errorNoUserId = 'No se encontró el ID de usuario en la sesión';
  static const String errorNoToken = 'No se encontró el token de autenticación';
  static const String errorConnection = 'Sin conexión, intente más tarde';
  static const String errorUnexpected = 'Error inesperado';
  static const String errorInvalidCredentials = 'Credenciales incorrectas';
  static const String errorTimeout = 'La solicitud tardó demasiado. Intenta de nuevo.';
  static const String errorUnauthorized = 'No autorizado. Inicia sesión de nuevo.';

  // ============================================================================
  // ALUMNO
  // ============================================================================

  static const String alumnoDetails = 'Detalles del Alumno';
  static const String alumnoGroup = 'Grupo';
  static const String alumnoGroupLabel = 'Grupo:';
  static const String alumnoScholarships = 'Becas';
  static const String alumnoStatus = 'Estado';
  static const String alumnoActive = 'Activo';
  static const String alumnoInactive = 'Dado de baja';
  static const String alumnoBaja = 'Baja';
  // Forma en minúscula para usarse dentro de oraciones
  static const String alumnoSingular = 'alumno';
  static const String alumnoPlural = 'alumnos';

  // ============================================================================
  // HOME — ERRORES
  // ============================================================================

  static const String homeDatosInesperados = 'Datos inesperados';

  // ============================================================================
  // RECUPERAR CONTRASEÑA
  // ============================================================================

  static const String recuperarContrasenaTitle = 'Recuperar contraseña';
  static const String recuperarContrasenaCorreoEnviado = 'Correo enviado';
  static const String recuperarContrasenaInstrucciones =
      'Ingresa tu usuario y correo registrado. Te enviaremos instrucciones para restablecer tu contraseña.';
  static const String recuperarContrasenaRevisa = 'Revisa tu bandeja de entrada';
  static const String recuperarContrasenaMensajeEnviado =
      'Hemos enviado las instrucciones para recuperar tu contraseña al correo proporcionado.';
  static const String recuperarContrasenaCorreoLabel = 'Correo electrónico';
  static const String recuperarContrasenaIngresaCorreo = 'Ingresa tu correo electrónico';
  static const String recuperarContrasenaCorreoInvalido = 'Ingresa un correo válido';
  static const String recuperarContrasenaIngresaUsuario = 'Ingresa tu nombre de usuario';

  // ============================================================================
  // LOGIN — EXTRAS
  // ============================================================================

  static const String loginIngresar = 'Ingresar';
  static const String loginIniciarSesion = 'Iniciar Sesión';
  static const String loginCamposIncompletosMsg =
      'Por favor, completa todos los campos para continuar.';

  // ============================================================================
  // REGISTRO — EXTRAS
  // ============================================================================

  static const String registerApellidoMaterno = 'Apellido Materno (opcional)';
  static const String registerYaTienesCuenta = '¿Ya tienes cuenta? Inicia sesión';
  static const String registerRegistrarse = 'Registrarse';

  // ============================================================================
  // CARRITO — EXTRAS
  // ============================================================================

  static const String carritoVacio = 'Carrito vacío';

  // ============================================================================
  // PAGOS — PLURALIZACIÓN
  // ============================================================================

  static const String pagoSingular = 'pago';
  static const String pagoPlural = 'pagos';
  static const String pagosSeleccionadosLabel = 'seleccionados';

  // ============================================================================
  // GENERAL — EXTRAS
  // ============================================================================

  static const String noTienesCuentaAtencion = '¡Atención!';
  static const String homeCargando = 'Cargando...';

  // ============================================================================
  // ALUMNO — ETIQUETAS DE DETALLE
  // ============================================================================

  static const String alumnoIdLabel = 'ID:';
  static const String alumnoBecasLabel = 'Becas:';
  static const String alumnoSepLabel = 'SEP:';
  static const String alumnoArjiLabel = 'ARJI:';
  static const String alumnoBachLabel = 'Bach:';
  static const String alumnoSpLabel = 'SP:';
  static const String alumnoEstadoLabel = 'Estado:';
  static const String alumnoEstadoBaja = '❌ Baja';
  static const String alumnoEstadoActivo = '✅ Activo';

  // ============================================================================
  // ESTADOS DE CUENTA — EMPTY
  // ============================================================================

  static const String edoCtaSinEstadosCuenta = 'No tienes estados de cuenta por pagar';

  // ============================================================================
  // AVISO DE PRIVACIDAD / VERSIÓN
  // ============================================================================

  static const String drawerAvisoPrivacidad = 'Aviso de Privacidad';
  static const String drawerVersionAndroid = 'Android';
  static const String drawerVersionIos = 'iOS';
  static const String drawerAvisoPrivacidadError =
      'No se pudo abrir el Aviso de Privacidad';
  static const String avisoDePrivacidadActualizar = 'Actualizar';
  static const String avisoDePrivacidadCargando =
      'Cargando aviso de privacidad...';
  static const String avisoDePrivacidadErrorCarga =
      'No se pudo cargar el Aviso de Privacidad';
  static const String avisoDePrivacidadReintentar = 'Reintentar';

  // ============================================================================
  // FACTURAS
  // ============================================================================

  static const String facturasTitle = 'Facturas';
  static const String facturasLoading = 'Cargando facturas...';
  static const String facturasSinFacturas = 'No tienes facturas disponibles';
  static const String facturasFolio = 'Folio:';
  static const String facturasFecha = 'Fecha:';
  static const String facturasFechaTimbrado = 'Timbrado:';
  static const String facturasReferencia = 'Referencia:';
  static const String facturasTotal = 'Total:';
  static const String facturasCompartir = 'Compartir factura';
  static const String facturasDescargando = 'Descargando archivo ZIP...';
  static const String facturasErrorCompartir =
      'No se pudo descargar el archivo para compartir';
  static const String facturasZipSinDatos = 'Esta factura no tiene archivo adjunto';
  static const String facturasErrorDescarga = 'Error al descargar el archivo ZIP';
}
