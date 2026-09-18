import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Test guardián: el login pide cada cosa UNA vez.
///
/// ## Qué protege
///
/// `blocProviders` es perezoso: un BLoC no nace al arrancar la app, sino la
/// primera vez que alguien lo lee. En el primer login tras abrir la app,
/// `MenuPrincipalBloc`, `EdoCtaPagadosBloc` y `FacturaBloc` nacían dentro de
/// `LoginResponse._entrar`. Hasta el 2026-09-18 su `create` llevaba
/// `..add(InitialEvent)`, así que se pedían dos veces —una al crearse y otra la
/// recarga de `_entrar`— y la primera competía además con el guardado de la
/// sesión. Visto en el Oppo: 4/2/2 peticiones (estados de cuenta, pagados,
/// facturas) donde tocaban 3/1/1.
///
/// Ahora nacen vacíos. Los carga `LoginResponse` tras guardar la sesión, y su
/// pantalla si los encuentra vacíos —para cuando se llega sin pasar por el
/// login: arrancar con sesión guardada, o Android restaurando la app—.
///
/// No se puede montar un login real en un test unitario, así que se vigila el
/// código: estas son las piezas cuya ausencia devolvería el fallo, o dejaría
/// una pantalla sin datos.
void main() {
  /// Quita los comentarios: los archivos explican, justamente, lo que NO hay
  /// que volver a escribir, y eso no debe contar como código.
  String soloCodigo(String ruta) => File(ruta)
      .readAsStringSync()
      .split('\n')
      .where((String linea) => !linea.trimLeft().startsWith('//'))
      .join('\n');

  final String blocProvider = soloCodigo('lib/src/blocProvider.dart');

  /// El `create` de un `BlocProvider`, desde su nombre hasta el siguiente.
  String createDe(String bloc) {
    final int inicio = blocProvider.indexOf('BlocProvider<$bloc>');
    expect(inicio, greaterThan(-1), reason: '$bloc ya no está en blocProviders');
    final int fin = blocProvider.indexOf('BlocProvider<', inicio + 1);
    return blocProvider.substring(inicio, fin == -1 ? null : fin);
  }

  group('los BLoC que recarga LoginResponse nacen vacíos', () {
    for (final String bloc in <String>[
      'MenuPrincipalBloc',
      'EdoCtaPagadosBloc',
      'FacturaBloc',
    ]) {
      test(bloc, () {
        expect(
          createDe(bloc).contains('..add('),
          isFalse,
          reason: 'El create de $bloc vuelve a disparar una carga. En el primer '
              'login nace dentro de LoginResponse._entrar, que también lo '
              'recarga: se pediría dos veces, y la primera compitiendo con el '
              'guardado de la sesión.',
        );
      });
    }
  });

  test('LoginResponse los recarga DESPUÉS de guardar la sesión', () {
    final String login = soloCodigo(
      'lib/src/presentation/pages/auth/login/includes/LoginResponse.dart',
    );
    final int guardado = login.indexOf('saveUserSession');
    expect(guardado, greaterThan(-1));

    for (final String evento in <String>[
      'MenuPrincipalInitialEvent',
      'EdoCtaPagadosRefreshEvent',
      'FacturaRefreshEvent',
    ]) {
      final int posicion = login.indexOf(evento);
      expect(posicion, greaterThan(guardado),
          reason: 'LoginResponse ya no manda $evento después del guardado. Es '
              'la única carga del login: sin ella, la pantalla sale vacía.');
    }
  });

  test('el menú carga el menú y Pagos Realizados si están vacíos', () {
    final String menu = soloCodigo(
      'lib/src/presentation/pages/menu_principal/MenuPrincipalPage.dart',
    );

    expect(menu.contains('MenuPrincipalInitialEvent'), isTrue,
        reason: 'Al arrancar con sesión guardada nadie más carga el menú.');
    expect(menu.contains('EdoCtaPagadosInitialEvent'), isTrue,
        reason: 'Pagos Realizados se carga al montarse el menú; sin esto, un '
            'push que abre la app en frío llevaría a una pantalla vacía.');

    // La carga va antes de la navegación por push, que tiene `return`s.
    expect(
      menu.indexOf('_cargarSiHaceFalta(context)'),
      lessThan(menu.indexOf('_irAPagosRealizados(context)')),
      reason: 'La carga tiene que ir antes de los return de la navegación por '
          'push: si no, abrir la app tocando un aviso se la saltaría.',
    );
  });

  test('Facturas se carga al abrirse si está vacía', () {
    final String facturas =
        soloCodigo('lib/src/presentation/pages/facturas/FacturasPage.dart');

    expect(facturas.contains('FacturaInicialEvent'), isTrue,
        reason: 'Al arrancar con sesión guardada nadie más carga Facturas.');
  });
}
