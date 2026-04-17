import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/presentation/pages/carrito/bloc/CarritoBloc.dart';
import 'package:arjipagos/src/presentation/pages/carrito/bloc/CarritoEvent.dart';
import 'package:arjipagos/src/presentation/pages/carrito/bloc/CarritoState.dart';
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
  @override
  void initState() {
    super.initState();
    context.read<CarritoBloc>().add(const CarritoInitialEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: const CarritoBody(),
      bottomNavigationBar: const CarritoTotalBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(AppStrings.carritoTitle),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        BlocBuilder<CarritoBloc, CarritoState>(
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
              context.read<CarritoBloc>().add(const CarritoLimpiarEvent());
            },
            child: const Text(AppStrings.carritoVaciar),
          ),
        ],
      ),
    );
  }
}
