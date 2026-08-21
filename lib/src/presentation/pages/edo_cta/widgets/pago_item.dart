import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/domain/models/Alumno.dart';
import 'package:arjipagos/src/domain/models/EstadoDeCuenta.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta/bloc/EdoCtaListBloc.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta/bloc/EdoCtaListEvent.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta/bloc/EdoCtaListState.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta/widgets/estado_pago_chip.dart';
import 'package:arjipagos/src/presentation/widgets/ConceptoEscalonado.dart';
import 'package:arjipagos/src/presentation/widgets/FilaAdaptable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Renglón de un pago dentro de la tarjeta del alumno.
///
/// El estado se lee por **tres señales a la vez**, no solo por la casilla: una
/// barra de color en el canto izquierdo, un tinte de fondo y la píldora de
/// estado. Con la casilla sola había que buscarla para saber qué estaba
/// seleccionado; ahora el renglón entero lo dice.
///
/// El pago **bloqueado por orden** muestra un candado en lugar de una casilla
/// apagada: una casilla que no responde parece un fallo, un candado explica que
/// falta liberar los pagos anteriores.
///
/// Los colores salen del `ColorScheme`, así que claro y oscuro se resuelven
/// solos: `secondaryContainer` para el tinte de selección, `errorContainer`
/// para el vencido, y los tokens `on…Container` para el importe encima de cada
/// uno —que es lo que garantiza el contraste en los dos temas.
class PagoItem extends StatelessWidget {
  final Alumno alumno;
  final EstadoDeCuenta pago;
  final List<EstadoDeCuenta> pagosDisponibles;

  const PagoItem({
    super.key,
    required this.alumno,
    required this.pago,
    required this.pagosDisponibles,
  });

  /// Ancho de la barra de estado del canto izquierdo.
  static const double _anchoBarra = 3;

  /// Lado del hueco de la casilla; es también el mínimo de área táctil.
  static const double _ladoCasilla = 44;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EdoCtaListBloc, EdoCtaListState>(
      builder: (context, state) {
        final seleccionado =
            state.isPagoSeleccionado(pago.cicloId, alumno.alumnoId, pago.id);
        final puedeSeleccionar = _calcularPuedeSeleccionar(state);
        final bloqueado = !puedeSeleccionar && !seleccionado;

        return _buildRenglon(context, seleccionado, puedeSeleccionar, bloqueado);
      },
    );
  }

  /// Cuerpo del renglón, con la barra de estado pintada en su canto izquierdo.
  ///
  /// La barra es un **borde** del propio renglón, no un hermano al que haya que
  /// estirar. Un `Row` con `CrossAxisAlignment.stretch` parecía la forma
  /// natural, pero la lista mete los renglones en un `Column` dentro de un
  /// scroll: ahí el alto llega sin acotar, `stretch` lo convierte en una
  /// restricción infinita y el renglón no se pinta. Como borde no hay nada que
  /// medir y funciona con cualquier alto.
  Widget _buildRenglon(
    BuildContext context,
    bool seleccionado,
    bool puedeSeleccionar,
    bool bloqueado,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      // El tinte va en el `Material` y no en un `Container` encima: así la onda
      // del toque se pinta sobre el color, no debajo de él.
      color: _colorFondo(colorScheme, seleccionado),
      child: InkWell(
        onTap: () => _onTap(context, puedeSeleccionar, seleccionado),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: _colorBarra(colorScheme, seleccionado),
                width: _anchoBarra,
              ),
            ),
          ),
          child: _buildCuerpo(context, seleccionado, bloqueado),
        ),
      ),
    );
  }

  /// Casilla —o candado— y la columna de datos.
  Widget _buildCuerpo(BuildContext context, bool seleccionado, bool bloqueado) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: _ladoCasilla,
            height: _ladoCasilla,
            // El hueco es de 44 pero la casilla y el candado miden menos: sin
            // centrarlos quedarían pegados a una esquina del hueco.
            child: Center(
              child: _buildMarca(context, seleccionado, bloqueado),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Opacity(
              // El pago bloqueado se atenúa entero: se ve que está ahí y que
              // todavía no toca.
              opacity: bloqueado ? 0.55 : 1,
              child: _buildDatos(context, seleccionado),
            ),
          ),
        ],
      ),
    );
  }

  /// Candado si el pago está bloqueado por orden; casilla en cualquier otro caso.
  Widget _buildMarca(BuildContext context, bool seleccionado, bool bloqueado) {
    final colorScheme = Theme.of(context).colorScheme;

    if (bloqueado) {
      return Icon(
        Icons.lock_outline,
        size: 20,
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
        semanticLabel: AppStrings.edoCtaInfoDialogMsg,
      );
    }

    return Checkbox(
      value: seleccionado,
      onChanged: (_) => _togglePago(context),
      // Sin esto el propio Checkbox reclama su área táctil de 48 y desalinea
      // la columna respecto al hueco de 44 que ya le reserva el renglón.
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  /// Concepto, y debajo los datos de apoyo emparejados de dos en dos.
  Widget _buildDatos(BuildContext context, bool seleccionado) {
    final theme = Theme.of(context);
    final estiloMonto = _estiloMonto(theme, seleccionado);
    final vencido = pago.estadoPago == EstadoPago.vencido;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ConceptoEscalonado(texto: pago.descripcionAbreviada),
        const SizedBox(height: 6),
        FilaAdaptable(
          izquierda: _buildFecha(theme),
          derecha: Text(pago.totalFormatted, maxLines: 1, style: estiloMonto),
          textoDerecha: pago.totalFormatted,
          estiloDerecha: estiloMonto,
        ),
        const SizedBox(height: 6),
        FilaAdaptable(
          // La píldora se ancla a la izquierda: dentro del `Expanded` de la
          // fila se estiraría a todo el ancho.
          izquierda: Align(
            alignment: Alignment.centerLeft,
            child: EstadoPagoChip(
              estadoPago: pago.estadoPago,
              sobreTinte: seleccionado || vencido,
            ),
          ),
          derecha: Text(_textoNumPago(), style: _estiloApoyo(theme)),
          textoDerecha: _textoNumPago(),
          estiloDerecha: _estiloApoyo(theme),
        ),
      ],
    );
  }

  /// Fecha de vencimiento con su icono; se lee siempre completa.
  Widget _buildFecha(ThemeData theme) {
    return Row(
      children: [
        Icon(
          Icons.calendar_today,
          size: 14,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 5),
        // Todas las fechas del backend traen el mismo formato y miden lo mismo,
        // así que si una se encoge se encogen todas y la lista sigue pareja.
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '${AppStrings.edoCtaVence} ${pago.fechaVencimiento}',
              maxLines: 1,
              softWrap: false,
              style: _estiloApoyo(theme),
            ),
          ),
        ),
      ],
    );
  }

  /// Color de la barra del canto: solo la pintan los estados que importan.
  Color _colorBarra(ColorScheme colorScheme, bool seleccionado) {
    if (seleccionado) {
      return colorScheme.primary;
    }
    if (pago.estadoPago == EstadoPago.vencido) {
      return colorScheme.error;
    }
    return Colors.transparent;
  }

  /// Tinte de fondo del renglón.
  Color _colorFondo(ColorScheme colorScheme, bool seleccionado) {
    if (seleccionado) {
      return colorScheme.secondaryContainer;
    }
    if (pago.estadoPago == EstadoPago.vencido) {
      return colorScheme.errorContainer;
    }
    return Colors.transparent;
  }

  /// Estilo del importe; se comparte con la medición de la fila adaptable.
  ///
  /// Mismo tamaño que el escalón grande del concepto y en negrita: destaca por
  /// peso y color, no por ser más grande. El color es el token de contenido de
  /// la superficie sobre la que cae, que es lo que sostiene el contraste en
  /// claro y en oscuro sin escribir un solo hex.
  TextStyle _estiloMonto(ThemeData theme, bool seleccionado) {
    final colorScheme = theme.colorScheme;

    final color = seleccionado
        ? colorScheme.onSecondaryContainer
        : pago.estadoPago == EstadoPago.vencido
            ? colorScheme.onErrorContainer
            : colorScheme.primary;

    return theme.textTheme.bodyLarge!.copyWith(
      fontWeight: FontWeight.bold,
      color: color,
      // Cifras de ancho fijo: los importes de la lista alinean en columna en
      // vez de bailar según los dígitos que le toquen a cada uno.
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  /// Estilo de los datos de apoyo: fecha y número de pago.
  TextStyle _estiloApoyo(ThemeData theme) {
    return theme.textTheme.bodySmall!.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  String _textoNumPago() => '${AppStrings.edoCtaPagoNum}${pago.numPago}';

  /// Calcula si el pago puede ser seleccionado según las reglas.
  ///
  /// El orden ascendente se evalúa solo entre pagos del mismo ciclo, por eso
  /// [pagosDisponibles] se filtra por `cicloId` antes de consultar al estado.
  bool _calcularPuedeSeleccionar(EdoCtaListState state) {
    if (pago.aceptaPagosDiversos) {
      final idsDisponibles = pagosDisponibles
          .where((e) => e.cicloId == pago.cicloId)
          .map((e) => e.id)
          .toList();
      return state.puedeSelecionarPago(
        pago.cicloId,
        alumno.alumnoId,
        pago.id,
        idsDisponibles,
      );
    }
    return true; // Sin restricción de orden
  }

  /// Maneja el tap en el renglón.
  void _onTap(BuildContext context, bool puedeSeleccionar, bool seleccionado) {
    if (puedeSeleccionar || seleccionado) {
      _togglePago(context);
    } else {
      _mostrarDialogoInfo(context);
    }
  }

  /// Alterna la selección del pago.
  void _togglePago(BuildContext context) {
    context.read<EdoCtaListBloc>().add(
      EdoCtaTogglePagoEvent(
        alumnoId: alumno.alumnoId,
        pagoId: pago.id,
      ),
    );
  }

  /// Muestra diálogo informativo sobre orden de selección.
  void _mostrarDialogoInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(
          Icons.info_outline,
          color: Theme.of(ctx).colorScheme.primary,
          size: 48,
        ),
        title: const Text(AppStrings.info),
        content: const Text(AppStrings.edoCtaInfoDialogMsg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(AppStrings.understood),
          ),
        ],
      ),
    );
  }
}
