import 'package:arjipagos/injection.dart';
import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/di/RegistroEmisores.dart';
import 'package:arjipagos/src/domain/models/EstadoDeCuenta.dart';
import 'package:arjipagos/src/presentation/pages/carrito/bloc/CarritoBloc.dart';
import 'package:arjipagos/src/presentation/pages/carrito/bloc/CarritoEvent.dart';
import 'package:arjipagos/src/presentation/pages/carrito/bloc/CarritoState.dart';
import 'package:arjipagos/src/presentation/pages/carrito/carrito_args.dart';
import 'package:arjipagos/src/presentation/pages/carrito/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Página del carrito de compras.
///
/// Muestra los pagos seleccionados agrupados por alumno.
/// Permite quitar items y procesar el pago.
class CarritoPage extends StatefulWidget {
  const CarritoPage({super.key});

  @override
  State<CarritoPage> createState() => _CarritoPageState();
}

class _CarritoPageState extends State<CarritoPage> {
  CarritoBloc? _bloc;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bloc != null) {
      return;
    }

    // Cada emisor tiene su propio carrito, con su almacén y sus reglas. Cuál de
    // ellos se abre lo dice la ruta; el carrito en sí no sabe que hay otros.
    //
    // Va en `didChangeDependencies` y no en `initState` porque hasta aquí no
    // hay `ModalRoute` del que sacar los argumentos.
    final args = ModalRoute.of(context)?.settings.arguments;
    final emisorFiscalId = args is CarritoArgs
        ? args.emisorFiscalId
        : kEmisorFiscalPredeterminado;

    _bloc = locator<CarritoBlocPorEmisor>().de(emisorFiscalId);
    _bloc!.add(const CarritoInitialEvent());
  }

  @override
  Widget build(BuildContext context) {
    // `BlocProvider.value`, no `create`: la instancia vive en el registro y
    // sobrevive a esta pantalla. Cerrarla al salir tiraría el carrito.
    return BlocProvider<CarritoBloc>.value(
      value: _bloc!,
      child: Scaffold(
        appBar: _buildAppBar(),
        body: const CarritoBody(),
        bottomNavigationBar: const CarritoTotalBar(),
      ),
    );
  }

  /// Construye el AppBar con el botón de vaciar el carrito.
  ///
  /// **Aquí se habla con `_bloc`, nunca con `context.read`.** Este método lo
  /// llama `build`, así que su `context` es el del `State`, que está **por
  /// encima** del `BlocProvider.value` que monta el propio `build`: buscar el
  /// BLoC desde ahí revienta con `ProviderNotFoundException`. Es exactamente
  /// lo que le pasó al botón de recargar de `EdoCtaPage` el 08-sep-2026, y
  /// aquí aplica igual porque el carrito también tiene una instancia por
  /// emisor que vive en el registro, no en la raíz de la app.
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(AppStrings.carritoTitle),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        BlocBuilder<CarritoBloc, CarritoState>(
          bloc: _bloc,
          builder: (context, state) {
            if (state.cantidadPagos > 0) {
              return IconButton(
                icon: const Icon(Icons.delete_sweep),
                tooltip: AppStrings.carritoVaciarTitle,
                onPressed: () => _confirmarVaciarCarrito(context),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  /// Pide confirmación antes de vaciar el carrito.
  ///
  /// [context] solo sirve para abrir el diálogo; el evento va directo a
  /// `_bloc` por lo que explica `_buildAppBar`.
  void _confirmarVaciarCarrito(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.carritoVaciarTitle),
        content: const Text(AppStrings.carritoVaciarConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _bloc!.add(const CarritoLimpiarEvent());
            },
            child: const Text(AppStrings.carritoVaciar),
          ),
        ],
      ),
    );
  }
}
