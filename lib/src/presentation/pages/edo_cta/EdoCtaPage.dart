import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta/bloc/EdoCtaListBloc.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta/bloc/EdoCtaListEvent.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta/bloc/EdoCtaListState.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Página de Estados de Cuenta.
///
/// Muestra los pagos pendientes agrupados por alumno.
/// Permite seleccionar pagos para agregarlos al carrito.
class EdoCtaPage extends StatefulWidget {
  const EdoCtaPage({super.key});

  @override
  State<EdoCtaPage> createState() => _EdoCtaPageState();
}

class _EdoCtaPageState extends State<EdoCtaPage> {
  bool _didCheckReload = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _verificarRecarga();
  }

  /// Verifica si viene con argumento reload=true (después de pago exitoso).
  void _verificarRecarga() {
    if (_didCheckReload) {
      return;
    }
    _didCheckReload = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic> && args['reload'] == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<EdoCtaListBloc>().add(const EdoCtaListRefreshEvent());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: const EdoCtaBody(),
      bottomNavigationBar: const TotalSeleccionadoBar(),
    );
  }

  /// Construye el AppBar con botón de limpiar selección.
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(AppStrings.edoCtaTitle),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        BlocBuilder<EdoCtaListBloc, EdoCtaListState>(
          builder: (context, state) {
            if (state.cantidadPagosSeleccionados > 0) {
              return IconButton(
                icon: const Icon(Icons.clear_all),
                tooltip: AppStrings.edoCtaLimpiarSeleccion,
                onPressed: () {
                  context.read<EdoCtaListBloc>().add(
                    const EdoCtaLimpiarSeleccionEvent(),
                  );
                },
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }
}
