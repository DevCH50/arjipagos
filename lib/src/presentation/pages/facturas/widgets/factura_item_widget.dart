import 'dart:io';

import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/domain/models/Factura.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Tarjeta que representa una factura con opción de compartir el ZIP.
///
/// Al presionar el botón de compartir se descarga el archivo desde [Factura.zipUrl]
/// y se abre el menú nativo del sistema operativo para compartirlo.
/// La descarga es lazy: ocurre solo cuando el usuario presiona compartir.
class FacturaItemWidget extends StatefulWidget {
  final Factura factura;

  const FacturaItemWidget({super.key, required this.factura});

  @override
  State<FacturaItemWidget> createState() => _FacturaItemWidgetState();
}

class _FacturaItemWidgetState extends State<FacturaItemWidget> {
  /// Indica si se está descargando o preparando el archivo para compartir.
  bool _compartiendo = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Encabezado: folio + botón compartir ---
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.facturasFolio,
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        widget.factura.folio,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Botón de compartir o indicador de descarga
                _compartiendo
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.share_outlined),
                        tooltip: AppStrings.facturasCompartir,
                        onPressed: () => _compartirFactura(context),
                      ),
              ],
            ),

            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // --- Datos de la factura ---
            _InfoRow(
              label: AppStrings.facturasFecha,
              value: widget.factura.fecha,
            ),
            const SizedBox(height: 4),
            _InfoRow(
              label: AppStrings.facturasFechaTimbrado,
              value: widget.factura.fechaTimbrado,
            ),
            const SizedBox(height: 4),
            _InfoRow(
              label: AppStrings.facturasReferencia,
              value: widget.factura.referencia,
            ),

            const SizedBox(height: 8),
            // --- Total destacado ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppStrings.facturasTotal,
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    widget.factura.total,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Descarga el ZIP desde [Factura.zipUrl], lo guarda en directorio temporal
  /// y abre el menú nativo de compartir del sistema operativo.
  Future<void> _compartirFactura(BuildContext context) async {
    if (widget.factura.zipUrl.isEmpty) {
      if (!context.mounted) {
        return;
      }
      showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Sin datos'),
          content: const Text(AppStrings.facturasZipSinDatos),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Aceptar'),
            ),
          ],
        ),
      );
      return;
    }

    // En iPad la hoja de compartir es un popover y iOS exige el rectángulo
    // desde el que sale; sin esto la app truena al abrirla. Se calcula aquí,
    // antes de cualquier await, para no usar el context tras la descarga.
    final caja = context.findRenderObject() as RenderBox?;
    final Rect? origenCompartir = caja == null || !caja.hasSize
        ? null
        : caja.localToGlobal(Offset.zero) & caja.size;

    setState(() {
      _compartiendo = true;
    });

    try {
      // Descargar el archivo ZIP desde la URL
      final response = await http.get(Uri.parse(widget.factura.zipUrl));

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      // Guardar en directorio temporal del dispositivo
      final tempDir = await getTemporaryDirectory();
      final fileName = widget.factura.zipNombre.isNotEmpty
          ? widget.factura.zipNombre
          : 'factura_${widget.factura.folio}.zip';

      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(response.bodyBytes);

      // Abrir menú nativo de compartir
      final shareParams = ShareParams(
        files: [XFile(file.path, mimeType: 'application/zip')],
        subject: 'Factura ${widget.factura.folio}',
        sharePositionOrigin: origenCompartir,
      );
      await SharePlus.instance.share(shareParams);
    } catch (e) {
      if (!context.mounted) {
        return;
      }
      showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Error'),
          content: const Text(AppStrings.facturasErrorCompartir),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Aceptar'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _compartiendo = false;
        });
      }
    }
  }
}

/// Fila de información etiqueta–valor para los datos de la factura.
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}
