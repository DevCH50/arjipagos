/// Strings de la aplicación ArjiPagos.
///
/// Centraliza todos los textos utilizados en la app para
/// facilitar el mantenimiento y futura internacionalización.
class AppStrings {
  AppStrings._();

  // ============================================================================
  // GENERAL
  // ============================================================================

  static const String appName = 'ArjiPagos';
  static const String appDescription = 'Plataforma de Gestión de Pagos';

  // ============================================================================
  // SPLASH
  // ============================================================================

  static const String splashInitializing = 'Inicializando...';
  static const String splashConfiguring = 'Configurando...';
  static const String splashVerifyingSession = 'Verificando sesión...';
  static const String splashReady = 'Listo';

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
  // LOGOUT
  // ============================================================================

  static const String logoutTitle = 'Cerrar Sesión';
  static const String logoutMessage = '¿Estás seguro que deseas cerrar sesión?';
  static const String logoutConfirm = 'Cerrar Sesión';
  static const String logoutCancel = 'Cancelar';

  // ============================================================================
  // ERRORES
  // ============================================================================

  static const String errorNoSession = 'No hay sesión activa';
  static const String errorNoUserId = 'No se encontró el ID de usuario en la sesión';
  static const String errorNoToken = 'No se encontró el token de autenticación';
  static const String errorConnection = 'Sin conexión, intente más tarde';
  static const String errorUnexpected = 'Error inesperado';
  static const String errorInvalidCredentials = 'Credenciales incorrectas';
  static const String errorTimeout = 'La solicitud tardó demasiado. Intenta de nuevo.';

  // ============================================================================
  // ALUMNO
  // ============================================================================

  static const String alumnoDetails = 'Detalles del Alumno';
  static const String alumnoGroup = 'Grupo';
  static const String alumnoScholarships = 'Becas';
  static const String alumnoStatus = 'Estado';
  static const String alumnoActive = 'Activo';
  static const String alumnoInactive = 'Dado de baja';
}
