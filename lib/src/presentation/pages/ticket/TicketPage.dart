import 'package:arjipagos/injection.dart';
import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/domain/useCases/ticket/TicketUseCases.dart';
import 'package:arjipagos/src/presentation/pages/ticket/bloc/TicketBloc.dart';
import 'package:arjipagos/src/presentation/pages/ticket/bloc/TicketEvent.dart';
import 'package:arjipagos/src/presentation/pages/ticket/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Argumentos de navegación de [TicketPage].
///
/// [url] es la URL absoluta que envía el backend en `ticket_url`.
/// [folio] nombra el archivo descargado y titula la pantalla.
class TicketArgs {
  final String url;
  final String folio;

  const TicketArgs({
    required this.url,
    this.folio = '',
  });

  /// Forma serializable de los argumentos.
  ///
  /// Los argumentos de una ruta restaurable los guarda el sistema operativo,
  /// así que solo admiten tipos primitivos: una instancia de esta clase no
  /// sobreviviría al reciclado del proceso. Por eso la ruta viaja con este
  /// mapa y la pantalla lo vuelve a leer con [TicketArgs.desdeRuta].
  Map<String, String> aMapa() => <String, String>{
        'url': url,
        'folio': folio,
      };

  /// Reconstruye los argumentos tal como llegan de la ruta.
  ///
  /// Tolera que no venga nada: la pantalla ya sabe mostrar el error de
  /// "ticket no disponible" cuando la URL está vacía.
  factory TicketArgs.desdeRuta(Object? argumentos) {
    if (argumentos is Map) {
      return TicketArgs(
        url: argumentos['url']?.toString() ?? '',
        folio: argumentos['folio']?.toString() ?? '',
      );
    }
    return const TicketArgs(url: '');
  }
}

/// Página del ticket de un pago realizado.
///
/// El ticket es un PDF detrás del guard de API, así que no basta con abrir la
/// URL: hay que descargarlo con el Bearer token de la sesión. El archivo se
/// guarda en la carpeta temporal y se entrega al sistema, que lo abre con el
/// visor de PDF del dispositivo o permite guardarlo y compartirlo.
///
/// Se descarga en vez de mostrarse en un WebView porque el WebView de Android
/// no renderiza PDFs: dejaría la pantalla en blanco.
class TicketPage extends StatelessWidget {
  const TicketPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ticketArgs = TicketArgs.desdeRuta(
      ModalRoute.of(context)?.settings.arguments,
    );

    return BlocProvider<TicketBloc>(
      create: (_) => _crearBloc(ticketArgs),
      child: Scaffold(
        appBar: _buildAppBar(ticketArgs.folio),
        // Edge-to-edge (Android 15+): el AppBar cubre el inset superior y el
        // SafeArea reserva el de la barra inferior de navegación.
        body: const SafeArea(
          top: false,
          child: TicketBody(),
        ),
      ),
    );
  }

  /// Crea el BLoC y dispara la descarga, o el error si no hay URL.
  ///
  /// El BLoC se provee aquí y no en `blocProviders` a propósito: depende de
  /// los argumentos de la ruta y debe morir con la pantalla, para que el
  /// siguiente ticket no herede el archivo del anterior.
  TicketBloc _crearBloc(TicketArgs args) {
    final bloc = TicketBloc(locator<TicketUseCases>());
    bloc.add(TicketDescargarEvent(
      url: args.url,
      folio: args.folio,
    ));
    return bloc;
  }

  /// AppBar con el folio del ticket cuando el backend lo envía.
  PreferredSizeWidget _buildAppBar(String folio) {
    final titulo = folio.isEmpty
        ? AppStrings.ticketTitle
        : '${AppStrings.ticketTitle} $folio';

    return AppBar(title: Text(titulo));
  }
}
