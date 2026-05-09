import 'package:arjipagos/injection.dart';
import 'package:arjipagos/src/blocProvider.dart';
import 'package:arjipagos/src/core/theme/arji/arji_theme.dart';
import 'package:arjipagos/src/core/utils/app_logger.dart';
import 'package:arjipagos/src/data/dataSource/remote/services/FcmService.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:arjipagos/src/presentation/pages/auth/login/LoginPage.dart';
import 'package:arjipagos/src/presentation/pages/auth/register/RegisterPage.dart';
import 'package:arjipagos/src/presentation/pages/cambiar_contrasena/CambiarContrasenaPage.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta/EdoCtaPage.dart';
import 'package:arjipagos/src/presentation/pages/carrito/CarritoPage.dart';
import 'package:arjipagos/src/presentation/pages/pago_webview/PagoWebViewPage.dart';
import 'package:arjipagos/src/presentation/pages/home/HomePage.dart';
import 'package:arjipagos/src/presentation/pages/menu_principal/MenuPrincipalPage.dart';
import 'package:arjipagos/src/presentation/pages/aviso_de_privacidad/AvisoDePrivacidadPage.dart';
import 'package:arjipagos/src/presentation/pages/facturas/FacturasPage.dart';
import 'package:arjipagos/src/presentation/pages/notificaciones/NotificacionesPage.dart';
import 'package:arjipagos/src/presentation/pages/splash/SplashPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart' show MultiBlocProvider;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Bloquear orientación a solo vertical
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Barra de estado transparente con iconos claros para el splash/auth (fondo oscuro).
  // Las páginas con AppBar la sobreescriben automáticamente vía AppBarTheme.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light, // Android
      statusBarBrightness: Brightness.dark, // iOS
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarContrastEnforced: false,
    ),
  );

  // Inicializar Firebase (requerido para FCM)
  try {
    await Firebase.initializeApp();
  } catch (e) {
    AppLogger.error('Error al inicializar Firebase: $e', tag: 'Main');
  }

  // Registrar el handler de mensajes en background ANTES de runApp.
  // Firebase docs requieren que esto ocurra antes de que el engine arranque,
  // para que el isolate de background pueda localizar la función en tiempo de ejecución.
  FirebaseMessaging.onBackgroundMessage(handleFcmBackgroundMessage);

  await configureDependencies();
  runApp(const MyApp());

  // Configurar permisos y handlers de FCM después de que la UI esté lista.
  // requestPermission() necesita la UI renderizada para mostrar el diálogo.
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    try {
      await FcmService().configurarHandlers();
    } catch (e) {
      AppLogger.error('Error al configurar FCM: $e', tag: 'Main');
    }
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: blocProviders,
      child: MaterialApp(
        builder: (context, child) {
          // Preservar el tamaño de fuente del sistema (accesibilidad)
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: MediaQuery.of(context).textScaler,
            ),
            child: child!,
          );
        },
        debugShowCheckedModeBanner: false,
        title: 'ArjiPagos',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        routes: {
          'login': (BuildContext context) => const LoginPage(),
          'register': (BuildContext context) => const RegisterPage(),
          'Homes': (BuildContext context) => const HomesPage(),
          'menu_principal': (BuildContext context) => const MenuPrincipalPage(),
          'splash': (BuildContext context) => const SplashPage(),
          'edo_cta': (BuildContext context) => const EdoCtaPage(),
          'carrito': (BuildContext context) => const CarritoPage(),
          'pago_webview': (BuildContext context) => const PagoWebViewPage(),
          'cambiar_contrasena': (BuildContext context) =>
              const CambiarContrasenaPage(),
          'notificaciones': (BuildContext context) =>
              const NotificacionesPage(),
          'facturas': (BuildContext context) => const FacturasPage(),
          'aviso_de_privacidad': (BuildContext context) =>
              const AvisoDePrivacidadPage(),
        },
        initialRoute: 'splash',
      ),
    );
  }
}
