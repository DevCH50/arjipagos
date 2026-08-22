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
import 'package:arjipagos/src/presentation/pages/edo_cta_pagados/EdoCtaPagadosPage.dart';
import 'package:arjipagos/src/presentation/pages/ticket/TicketPage.dart';
import 'package:arjipagos/src/presentation/pages/carrito/CarritoPage.dart';
import 'package:arjipagos/src/presentation/pages/pago_webview/PagoWebViewPage.dart';
import 'package:arjipagos/src/presentation/pages/home/HomePage.dart';
import 'package:arjipagos/src/presentation/pages/menu_principal/MenuPrincipalPage.dart';
import 'package:arjipagos/src/presentation/pages/aviso_de_privacidad/AvisoDePrivacidadPage.dart';
import 'package:arjipagos/src/presentation/pages/facturas/FacturasPage.dart';
import 'package:arjipagos/src/presentation/pages/notificaciones/NotificacionesPage.dart';
import 'package:arjipagos/src/presentation/pages/splash/SplashPage.dart';
import 'package:arjipagos/src/presentation/utils/AppNavigatorKey.dart';
import 'package:arjipagos/src/presentation/widgets/ActualizacionObserver.dart';
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

  // Android 15 (SDK 35): activar edge-to-edge explícitamente.
  // Equivale a enableEdgeToEdge() nativo; resuelve la advertencia de Play Store
  // y asegura que el contenido se dibuje de borde a borde correctamente.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

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
        // Necesaria para que ActualizacionObserver pueda abrir su diálogo: el
        // `builder` se inserta por encima del Navigator y su contexto no sirve
        // para `showDialog`.
        navigatorKey: appNavigatorKey,
        builder: (context, child) {
          // Preservar el tamaño de fuente del sistema (accesibilidad)
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: MediaQuery.of(context).textScaler,
            ),
            // Vigila que la versión instalada no haya quedado obsoleta. Envuelve
            // toda la app para que el bloqueo aparezca sobre cualquier pantalla.
            child: ActualizacionObserver(child: child!),
          );
        },
        debugShowCheckedModeBanner: false,
        // Restauración de estado: Android guarda la pila de rutas y la
        // devuelve si recicla el proceso o la actividad mientras el usuario
        // está en otra app. Sin esto la app volvía siempre al Menú Principal y
        // el atrás salía de la aplicación, que era el fallo reportado al
        // regresar de ver un ticket.
        restorationScopeId: 'arjipagos',
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
          'edo_cta_pagados': (BuildContext context) =>
              const EdoCtaPagadosPage(),
          'ticket': (BuildContext context) => const TicketPage(),
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
