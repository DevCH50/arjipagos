import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/presentation/pages/carrito/bloc/CarritoBloc.dart';
import 'package:arjipagos/src/presentation/pages/carrito/bloc/CarritoEvent.dart';
import 'package:arjipagos/src/presentation/pages/carrito/bloc/CarritoState.dart';
import 'package:arjipagos/src/presentation/pages/carrito/tras_fallo_cobro.dart';
import 'package:arjipagos/src/presentation/pages/carrito/widgets/carrito_alumno_card.dart';
import 'package:arjipagos/src/presentation/pages/carrito/widgets/carrito_empty_widget.dart';
import 'package:arjipagos/src/presentation/pages/carrito/widgets/carrito_loading_widget.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta/widgets/error_widget.dart';
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
          // Sin cargos del servidor no se sabe qué hay en el carrito: decir
          // «Carrito vacío» sería mentir a quien sí seleccionó pagos.
          if (state.errorDeCarga != null) {
            return EdoCtaErrorWidget(
              message: state.errorDeCarga!,
              onRetry: () =>
                  context.read<CarritoBloc>().add(const CarritoInitialEvent()),
            );
          }
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
      _mostrarDialogoError(context, state);
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
          // Solo lo trae OpenPay; en Adquira no existe y queda en null.
          orderId: state.pagoData!['orderId'] as String?,
        ),
      );
    }
  }

  void _mostrarDialogoError(BuildContext context, CarritoState state) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(
          Icons.error_outline,
          color: Theme.of(ctx).colorScheme.error,
          size: 48,
        ),
        title: const Text(AppStrings.error),
        content: Text(state.errorMessage!),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Se descarta al cerrarlo, no al mostrarlo: mientras el error
              // siga en el estado, cualquier cambio posterior del carrito
              // volvería a sacar este mismo aviso.
              context.read<CarritoBloc>().add(const CarritoLimpiarErrorEvent());
              // Si el cobro de OpenPay no se pudo crear, puede tocar ir al
              // login (401) o recargar los cargos (422).
              actuarTrasFalloCobro(
                context,
                motivo: state.motivoFallo,
                emisorFiscalId: state.emisorFiscalActivo,
              );
            },
            child: const Text(AppStrings.accept),
          ),
        ],
      ),
    );
  }
}
