import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/presentation/pages/facturas/bloc/FacturaBloc.dart';
import 'package:arjipagos/src/presentation/pages/facturas/bloc/FacturaEvent.dart';
import 'package:arjipagos/src/presentation/pages/facturas/bloc/FacturaState.dart';
import 'package:arjipagos/src/presentation/pages/facturas/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Página de Facturas.
///
/// Muestra la lista de facturas del usuario con opción de compartir
/// el archivo ZIP de cada una. El ZIP viene en base64 desde el servidor
/// y se decodifica de forma lazy solo al presionar compartir.
class FacturasPage extends StatefulWidget {
  const FacturasPage({super.key});

  @override
  State<FacturasPage> createState() => _FacturasPageState();
}

class _FacturasPageState extends State<FacturasPage> {
  @override
  void initState() {
    super.initState();
    _cargarSiHaceFalta();
  }

  /// Pide las facturas **solo si nunca se cargaron y no se están cargando**.
  ///
  /// `FacturaBloc` nace vacío en `blocProviders`: tras un login lo carga
  /// `LoginResponse`, y aquí se cubre el resto —arrancar con la sesión
  /// guardada y abrir Facturas—. Volver a entrar no vuelve a pedir nada; para
  /// releer del servidor están el botón de recargar y el deslizar hacia abajo.
  ///
  /// Mismo patrón que `EdoCtaPage._cargarSiHaceFalta`.
  void _cargarSiHaceFalta() {
    final FacturaBloc bloc = context.read<FacturaBloc>();
    if (_nuncaCargado(bloc.state) && !bloc.state.isLoading) {
      bloc.add(const FacturaInicialEvent());
    }
  }

  /// Ni una respuesta buena ni un error: todavía no se ha pedido nada.
  static bool _nuncaCargado(FacturaState state) =>
      state.response == null && state.errorMessage == null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.facturasTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Siempre visible, igual que en Estados de Cuenta, Pagos Realizados y
          // Home: recargar es la salida que le queda al usuario cuando la
          // pantalla no muestra lo que espera, así que no se esconde en ningún
          // estado.
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: AppStrings.homeRefresh,
            onPressed: () {
              context.read<FacturaBloc>().add(const FacturaRefreshEvent());
            },
          ),
        ],
      ),
      body: BlocBuilder<FacturaBloc, FacturaState>(
        builder: (context, state) {
          // Estado de carga. «Nunca cargado» cuenta como cargando: es el primer
          // frame, antes de que el handler emita `isLoading`, y sin esto se
          // vería un instante «Sin facturas» que no es verdad.
          if (state.isLoading || _nuncaCargado(state)) {
            return const FacturaLoadingWidget();
          }

          // Estado de error
          if (state.errorMessage != null) {
            return FacturaErrorWidget(
              message: state.errorMessage!,
              onRetry: () {
                context.read<FacturaBloc>().add(const FacturaRefreshEvent());
              },
            );
          }

          // Estado vacío
          if (state.facturas.isEmpty) {
            return FacturaEmptyWidget(
              onRetry: () =>
                  context.read<FacturaBloc>().add(const FacturaRefreshEvent()),
            );
          }

          // Lista de facturas con pull-to-refresh
          return RefreshIndicator(
            onRefresh: () async {
              context.read<FacturaBloc>().add(const FacturaRefreshEvent());
              // Esperar a que termine la carga
              await context.read<FacturaBloc>().stream.firstWhere(
                (s) => !s.isLoading,
              );
            },
            child: ListView(
              // Edge-to-edge (Android 15+): sumamos el alto de la barra de
              // navegacion del sistema al padding inferior para que la ultima
              // factura no quede tapada por ella.
              padding: EdgeInsets.only(
                top: 8,
                bottom: 24 + MediaQuery.viewPaddingOf(context).bottom,
              ),
              children: [
                // Header con nombre de familia
                if (state.response != null)
                  _FamiliaHeader(familia: state.response!.familia),

                // Lista de facturas
                ...state.facturas.map(
                  (factura) => FacturaItemWidget(factura: factura),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Encabezado con el nombre de la familia asociada a las facturas.
class _FamiliaHeader extends StatelessWidget {
  final String familia;

  const _FamiliaHeader({required this.familia});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          Icon(Icons.family_restroom, color: colorScheme.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              familia,
              style: textTheme.titleSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
