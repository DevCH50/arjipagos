import 'package:arjipagos/injection.dart';
import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/di/RegistroEmisores.dart';
import 'package:arjipagos/src/domain/models/EstadoDeCuenta.dart';
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
///
/// La misma página sirve a las dos entradas del menú: "Pagos Pendientes" la
/// monta con [emisorFiscalId] 1 y "Otros pagos" con el 2. Lo único que cambia
/// es el título y qué pagos se enseñan; el resto del comportamiento —orden de
/// selección, tope de la referencia, barra del total— es idéntico, y por eso
/// no se duplica la pantalla.
class EdoCtaPage extends StatefulWidget {
  /// Emisor fiscal cuyos pagos muestra esta instancia de la página.
  final int emisorFiscalId;

  /// Título de la barra superior. Cambia con el emisor porque las dos
  /// pantallas son, para el usuario, dos sitios distintos.
  final String titulo;

  const EdoCtaPage({
    super.key,
    this.emisorFiscalId = kEmisorFiscalPredeterminado,
    this.titulo = AppStrings.edoCtaTitle,
  });

  @override
  State<EdoCtaPage> createState() => _EdoCtaPageState();
}

class _EdoCtaPageState extends State<EdoCtaPage> {
  bool _didCheckReload = false;
  EdoCtaListBloc? _bloc;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // El BLoC de este emisor vive en el registro y sobrevive a la pantalla:
    // aquí solo se toma, no se crea.
    _bloc ??= locator<EdoCtaListBlocPorEmisor>().de(widget.emisorFiscalId);
    _cargarSiHaceFalta();
    _verificarRecarga();
  }

  /// Pide los datos la primera vez que se abre esta pantalla.
  ///
  /// Antes lo hacía `blocProviders` al crear el BLoC, pero ya no cuelga de la
  /// raíz: hay uno por emisor y quien sabe cuál hace falta es su pantalla.
  ///
  /// Solo carga si el BLoC está vacío. Volver a entrar no vuelve a pedir nada
  /// —los datos y la selección siguen ahí—; para releer del servidor está el
  /// gesto de deslizar hacia abajo.
  void _cargarSiHaceFalta() {
    final EdoCtaListState estado = _bloc!.state;
    if (estado.alumnos == null && !estado.isLoading) {
      _bloc!.add(const EdoCtaListInitialEvent());
    }
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
        _bloc!.add(const EdoCtaListRefreshEvent());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // `BlocProvider.value` para que los widgets de dentro sigan usando
    // `context.read<EdoCtaListBloc>()` sin enterarse de que hay uno por emisor.
    return BlocProvider<EdoCtaListBloc>.value(
      value: _bloc!,
      child: Scaffold(
        appBar: _buildAppBar(),
        body: const EdoCtaBody(),
        bottomNavigationBar: const TotalSeleccionadoBar(),
      ),
    );
  }

  /// Construye el AppBar con botón de limpiar selección y el de recargar.
  ///
  /// El de recargar va **siempre visible**, sin condición de estado: es la vía
  /// que le queda al usuario para volver a pedir sus datos cuando la pantalla no
  /// muestra nada. El de limpiar selección sigue apareciendo solo si hay algo
  /// seleccionado, que es cuando significa algo.
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(widget.titulo),
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
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: AppStrings.edoCtaActualizar,
          onPressed: () {
            context.read<EdoCtaListBloc>().add(const EdoCtaListRefreshEvent());
          },
        ),
      ],
    );
  }
}
