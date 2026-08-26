import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/presentation/pages/carrito/bloc/CarritoBloc.dart';
import 'package:arjipagos/src/presentation/pages/carrito/bloc/CarritoState.dart';
import 'package:arjipagos/src/presentation/pages/carrito/widgets/carrito_alumno_card.dart';
import 'package:arjipagos/src/presentation/pages/carrito/widgets/carrito_empty_widget.dart';
import 'package:arjipagos/src/presentation/pages/carrito/widgets/carrito_loading_widget.dart';
import 'package:arjipagos/src/presentation/pages/pago_webview/pago_webview_args.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Cuerpo principal del carrito.
class CarritoBody extends StatelessWidget {
  const CarritoBody({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CarritoBloc, CarritoState>(
      listener: _onStateChange,
      builder: (context, state) {
        if (state.isLoading) {
          return const CarritoLoadingWidget();
        }

        if (state.itemsCarrito.isEmpty) {
          return const CarritoEmptyWidget();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: state.itemsCarrito.length,
          itemBuilder: (context, index) {
            return CarritoAlumnoCard(item: state.itemsCarrito[index]);
          },
        );
      },
    );
  }

  void _onStateChange(BuildContext context, CarritoState state) {
    // Mostrar diálogo de error si existe
    if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
      _mostrarDialogoError(context, state.errorMessage!);
    }

    // Navegar al WebView de pago
    if (state.pagoData != null) {
      // Ruta NO restaurable a propósito: reabrir sola una sesión de pago con
      // la URL, los parámetros y el token de antes del reciclado es peligroso.
      // Si Android recicla el proceso durante el pago, el usuario vuelve al
      // carrito y decide él si reintenta.
      Navigator.pushNamed(
        context,
        'pago_webview',
        arguments: PagoWebViewArgs(
          url: state.pagoData!['url'] as String,
          params: Map<String, String>.from(state.pagoData!['params']),
          token: state.pagoData!['token'] as String,
          // Para que el WebView avise al carrito correcto y vuelva a la
          // pantalla correcta al terminar.
          emisorFiscalId: state.emisorFiscalActivo,
        ),
      );
    }
  }

  void _mostrarDialogoError(BuildContext context, String mensaje) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(
          Icons.error_outline,
          color: Theme.of(ctx).colorScheme.error,
          size: 48,
        ),
        title: const Text(AppStrings.error),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(AppStrings.accept),
          ),
        ],
      ),
    );
  }
}
