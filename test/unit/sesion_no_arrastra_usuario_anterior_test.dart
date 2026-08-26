import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Tests guardianes: al entrar con otro usuario no puede quedar nada del
/// anterior.
///
/// Origen: incidente del 2026-08-25 en el Oppo. Se entraba con `CATutorM974`,
/// se cerraba sesión, se entraba con `CATutorM820` y la app seguía mostrando la
/// **familia** del primero.
///
/// La causa eran dos piezas que se apoyaban la una en la otra sin garantía:
///
///  1. Los BLoCs de `blocProviders` viven en la raíz de la app y **sobreviven
///     al cierre de sesión** — `MyApp` solo se instancia una vez, en el
///     `runApp`. Al cerrar sesión nadie los vaciaba.
///  2. Tras el login, la recarga de esos BLoCs se lanzaba con un
///     `Future.delayed(500 ms)` a ojo, sin esperar a que la sesión nueva
///     estuviera escrita. Si `flutter_secure_storage` —que cifra contra el
///     keystore— tardaba más que el temporizador, la recarga leía una sesión
///     que aún no existía y no emitía nada.
///
/// Y como los `copyWith` de esos estados nunca vacían un campo
/// (`familia ?? this.familia`), lo del usuario anterior se quedaba en pantalla
/// **para siempre**, sin error ni aviso.
void main() {
  final cierreDeSesion =
      File('lib/src/presentation/utils/CierreDeSesion.dart').readAsStringSync();
  // Sin comentarios: los de este archivo explican justo el fallo que se
  // vigila, y nombran lo que no debe reaparecer en el código.
  final loginResponse = _sinComentarios(
    File(
      'lib/src/presentation/pages/auth/login/includes/LoginResponse.dart',
    ).readAsStringSync(),
  );
  final blocProvider = File('lib/src/blocProvider.dart').readAsStringSync();

  group('Cierre de sesión', () {
    test('vacía los BLoCs de datos que viven en la raíz de la app', () {
      const eventosDeLimpieza = [
        'MenuPrincipalLimpiarSesion',
        'HomeLimpiarSesionEvent',
        'EdoCtaListLimpiarSesionEvent',
        'EdoCtaPagadosLimpiarSesionEvent',
        'FacturaLimpiarSesionEvent',
      ];

      for (final evento in eventosDeLimpieza) {
        expect(
          cierreDeSesion.contains(evento),
          isTrue,
          reason: 'cerrarSesionCompleta ya no manda $evento. Sin eso, los '
              'datos de ese BLoC sobreviven al cierre de sesión y el '
              'siguiente usuario los ve.',
        );
      }
    });

    test('no se olvida ningún BLoC de datos nuevo de blocProviders', () {
      // Los BLoCs que piden datos nada más crearse (`..add(...)`) son los que
      // acumulan información del usuario. Si aparece uno nuevo, hay que
      // vaciarlo en `cerrarSesionCompleta` — o justificarlo aquí.
      const exentos = {
        // No guardan datos del usuario: son formularios o vigilantes.
        'ActualizacionBloc': 'solo comprueba la versión instalada',
        'BiometriaBloc': 'estado del cerrojo, no datos de la cuenta',
        'LoginBloc': 'formulario de acceso',
        'RegisterBloc': 'formulario de alta',
        'CambiarContrasenaBloc': 'formulario',
        'BannerBloc': 'los avisos son los mismos para todos',
        // Estos sí llevan datos, pero se recargan solos en el `initState` de su
        // página, así que nunca se pintan con lo del usuario anterior.
        'CarritoBloc': 'se recarga en el initState de CarritoPage',
        'NotificacionBloc': 'se recarga en el initState de NotificacionesPage',
      };

      final patron = RegExp(
        r'BlocProvider<(\w+)>\s*\(\s*create:.*?\)\s*,\s*(?=BlocProvider|\])',
        dotAll: true,
      );

      final olvidados = <String>[];
      for (final entrada in patron.allMatches(blocProvider)) {
        final nombre = entrada.group(1)!;
        final cuerpo = entrada.group(0)!;
        if (!cuerpo.contains('..add(')) {
          continue; // No carga nada al crearse.
        }
        if (exentos.containsKey(nombre)) {
          continue;
        }
        if (!cierreDeSesion.contains(nombre)) {
          olvidados.add(nombre);
        }
      }

      expect(
        olvidados,
        isEmpty,
        reason: 'Estos BLoCs cargan datos al crearse pero no se vacían en '
            'cerrarSesionCompleta: $olvidados. Añádelos a '
            '_limpiarBlocsDeSesion, o a la lista de exentos si de verdad no '
            'guardan nada del usuario.',
      );
    });
  });

  group('Entrada tras el login', () {
    test('espera a que la sesión esté guardada antes de recargar', () {
      expect(
        loginResponse.contains('await locator<AuthUseCases>()'
            '.saveUserSession.run(data)'),
        isTrue,
        reason: 'LoginResponse tiene que ESPERAR el guardado de la sesión '
            'antes de mandar los eventos de recarga: cada servicio lee el '
            'token y el user_id del almacenamiento.',
      );
    });

    test('no vuelve al temporizador de 500 ms', () {
      expect(
        loginResponse.contains('Future.delayed'),
        isFalse,
        reason: 'Un `Future.delayed` no garantiza que la sesión esté escrita. '
            'Fue justo lo que dejaba la familia del usuario anterior en '
            'pantalla. Secuenciar con `await`, no con un temporizador.',
      );
    });
  });
}

/// Devuelve el código fuente sin sus líneas de comentario.
String _sinComentarios(String fuente) => fuente
    .split('\n')
    .where((linea) => !linea.trimLeft().startsWith('//'))
    .join('\n');
