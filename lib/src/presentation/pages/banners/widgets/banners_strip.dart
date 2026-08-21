import 'dart:math' as math;

import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/domain/models/banner/BannerInfo.dart';
import 'package:arjipagos/src/presentation/pages/banners/bloc/BannerBloc.dart';
import 'package:arjipagos/src/presentation/pages/banners/bloc/BannerEvent.dart';
import 'package:arjipagos/src/presentation/pages/banners/bloc/BannerState.dart';
import 'package:arjipagos/src/presentation/pages/banners/widgets/banner_card.dart';
import 'package:arjipagos/src/presentation/pages/banners/widgets/banner_detalle_sheet.dart';
import 'package:arjipagos/src/presentation/pages/banners/widgets/banners_skeleton.dart';
import 'package:arjipagos/src/presentation/pages/banners/widgets/banners_indicador.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Carrusel de avisos informativos del Menú Principal.
///
/// **Por qué un `PageView` y no una lista libre:** con desplazamiento libre el
/// carrusel queda a medio camino entre dos tarjetas. El `PageView` engancha en
/// cada aviso y, con `viewportFraction` menor que 1, deja asomar el siguiente,
/// que es la señal de que hay más contenido.
///
/// **Insets del sistema:** el margen inferior sale de `MediaQuery.viewPaddingOf`
/// y no de un `SafeArea`. Un `SafeArea` devuelve cero si un widget padre ya
/// consumió el padding, y el carrusel terminaría bajo el *home indicator* de
/// iOS o bajo la barra de gestos de Android. `viewPadding` es el inset físico
/// real, sin importar quién lo haya consumido antes.
///
/// **Márgenes laterales:** las tarjetas nunca tocan los bordes. En Android con
/// navegación por gestos, la banda de los bordes izquierdo y derecho es el
/// gesto *atrás*: un carrusel a sangre se arrastraría hacia atrás en vez de
/// pasar de tarjeta.
class BannersStrip extends StatefulWidget {
  const BannersStrip({super.key});

  @override
  State<BannersStrip> createState() => _BannersStripState();
}

class _BannersStripState extends State<BannersStrip> {
  /// Margen a cada lado; libra la banda del gesto atrás de Android.
  static const double _margenLateral = 16;

  /// Separación entre tarjetas.
  static const double _separacion = 12;

  /// Parte de la pantalla que como mucho puede ocupar la tirilla.
  ///
  /// El menú manda: los avisos son un extra al pie, no la pantalla.
  static const double _fraccionMaximaPantalla = 0.28;

  /// Por debajo de esto la portada deja de parecer una foto.
  static const double _altoMinimoPortada = 96;

  PageController? _controller;
  int _paginaActual = 0;

  @override
  void initState() {
    super.initState();
    context.read<BannerBloc>().add(const BannerCargarEvent());
  }

  @override
  void dispose() {
    // Sin esto queda un listener vivo apuntando a una pantalla desmontada.
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BannerBloc, BannerState>(
      builder: (context, state) {
        final medidas = _calcularMedidas(context);

        if (state.isLoading && !state.tieneBanners) {
          return _buildContenedor(
            context,
            BannersSkeleton(ancho: medidas.ancho, alto: medidas.alto),
            mostrarIndicador: false,
            total: 0,
          );
        }

        if (!state.tieneBanners) {
          // Sin avisos la tirilla no ocupa un solo píxel: el menú se ve
          // exactamente igual que antes de que existiera esta función.
          return const SizedBox.shrink();
        }

        final visibles =
            state.banners.where((b) => b.tieneImagen).toList(growable: false);

        return _buildContenedor(
          context,
          _buildCarrusel(visibles, medidas),
          mostrarIndicador: visibles.length > 1,
          total: visibles.length,
        );
      },
    );
  }

  /// Encabezado, contenido y puntos, ya con el inset del sistema descontado.
  Widget _buildContenedor(
    BuildContext context,
    Widget contenido, {
    required bool mostrarIndicador,
    required int total,
  }) {
    // Inset físico real del sistema operativo. Se le suma un margen propio
    // para que el carrusel no quede pegado a la barra de gestos.
    final double margenInferior = 12 + MediaQuery.viewPaddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(top: 12, bottom: margenInferior),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEncabezado(context),
          const SizedBox(height: 8),
          contenido,
          if (mostrarIndicador) const SizedBox(height: 10),
          if (mostrarIndicador)
            BannersIndicador(total: total, actual: _paginaActual),
        ],
      ),
    );
  }

  /// Título de sección: sin él, un carrusel de fotos en un menú de pagos
  /// desconcierta más de lo que informa.
  Widget _buildEncabezado(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _margenLateral),
      child: Text(
        AppStrings.bannersSeccion,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
      ),
    );
  }

  /// Carrusel con enganche por tarjeta y asomo de la siguiente.
  Widget _buildCarrusel(List<BannerInfo> banners, _MedidasCarrusel medidas) {
    _asegurarController(medidas.fraccionViewport);

    return SizedBox(
      height: medidas.alto,
      child: PageView.builder(
        controller: _controller,
        itemCount: banners.length,
        padEnds: false,
        onPageChanged: (indice) => setState(() => _paginaActual = indice),
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(
            left: _margenLateral,
            right: _separacion,
          ),
          child: BannerCard(
            banner: banners[index],
            ancho: medidas.ancho,
            onTap: () => mostrarBannerDetalle(context, banners[index]),
          ),
        ),
      ),
    );
  }

  /// Crea o recrea el controlador cuando cambia el ancho útil.
  ///
  /// El ancho cambia al girar el teléfono o al abrir la app en pantalla
  /// dividida, y `viewportFraction` no se puede modificar en caliente.
  void _asegurarController(double fraccion) {
    if (_controller != null && _controller!.viewportFraction == fraccion) {
      return;
    }
    _controller?.dispose();
    _controller = PageController(
      viewportFraction: fraccion,
      initialPage: _paginaActual,
    );
  }

  /// Calcula el tamaño de la tarjeta a partir del ancho disponible.
  _MedidasCarrusel _calcularMedidas(BuildContext context) {
    final double anchoPantalla = MediaQuery.sizeOf(context).width;

    // El asomo de la siguiente tarjeta es el 12% del ancho: suficiente para
    // que se vea, sin robarle espacio a la portada.
    final double anchoUtil = anchoPantalla - _margenLateral - _separacion;
    // Tope en tablets: una tarjeta de 700 px de ancho se ve desproporcionada.
    final double ancho = math.min(anchoUtil * 0.88, 420);

    final double altoTexto = _altoBloqueTexto(context);

    // Tope de la tirilla entera: los avisos son un extra al pie del menú, no la
    // pantalla. Lo que se encoge es la **portada**, nunca el bloque de texto,
    // que es justo lo que hay que poder leer.
    final double topeTirilla =
        MediaQuery.sizeOf(context).height * _fraccionMaximaPantalla;
    final double topePortada =
        math.max(_altoMinimoPortada, topeTirilla - altoTexto);

    // Alto de la portada, derivado de la relación de aspecto y no de la
    // pantalla: el encuadre de la foto es idéntico en todos los dispositivos.
    final double altoPortada = (ancho / BannerCard.relacionAspecto)
        .clamp(110.0, 190.0)
        .clamp(_altoMinimoPortada, topePortada);

    final double fraccion =
        ((ancho + _separacion) / anchoPantalla).clamp(0.1, 1.0);

    return _MedidasCarrusel(
      ancho: ancho,
      // La tarjeta es portada MÁS bloque de texto: si se le reserva solo la
      // portada, el título queda cortado por abajo.
      alto: altoPortada + altoTexto,
      fraccionViewport: fraccion,
    );
  }

  /// Alto que necesita el bloque de texto de la tarjeta.
  ///
  /// Se calcula con los tamaños del tema y con la escala de fuente del sistema,
  /// no con un número fijo: quien tenga la letra grande necesita más alto, y si
  /// no se le da, el título se recorta. Las constantes de hueco y padding salen
  /// de `BannerCard`, para que la medida y lo que se pinta no se separen.
  double _altoBloqueTexto(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final escalador = MediaQuery.textScalerOf(context);

    final estiloFecha = textTheme.labelSmall;
    final estiloTitulo = textTheme.titleSmall;

    final double altoFecha = escalador.scale(estiloFecha?.fontSize ?? 11) *
        (estiloFecha?.height ?? 1.45);
    final double altoTitulo = escalador.scale(estiloTitulo?.fontSize ?? 14) *
        BannerCard.altoLineaTitulo *
        BannerCard.lineasTitulo;

    return altoFecha +
        BannerCard.huecoTexto +
        altoTitulo +
        BannerCard.paddingTexto.vertical;
  }
}

/// Medidas calculadas del carrusel para el ancho actual de pantalla.
class _MedidasCarrusel {
  const _MedidasCarrusel({
    required this.ancho,
    required this.alto,
    required this.fraccionViewport,
  });

  final double ancho;
  final double alto;
  final double fraccionViewport;
}
