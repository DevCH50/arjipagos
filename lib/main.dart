import 'package:arjipagos/src/blocProvider.dart';
import 'package:arjipagos/src/core/theme/app_theme.dart';
import 'package:arjipagos/src/presentation/pages/auth/login/LoginPage.dart';
import 'package:arjipagos/src/presentation/pages/auth/register/RegisterPage.dart';
import 'package:arjipagos/src/presentation/pages/cambiar_contrasena/CambiarContrasenaPage.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta/EdoCtaPage.dart';
import 'package:arjipagos/src/presentation/pages/carrito/CarritoPage.dart';
import 'package:arjipagos/src/presentation/pages/pago_webview/PagoWebViewPage.dart';
import 'package:arjipagos/src/presentation/pages/home/HomePage.dart';
import 'package:arjipagos/src/presentation/pages/menu_principal/MenuPrincipalPage.dart';
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

  // await configureDependencies();
  runApp(const MyApp());
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
        },
        initialRoute: 'splash',
      ),
    );
  }
}
