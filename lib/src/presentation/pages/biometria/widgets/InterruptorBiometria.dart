import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/data/dataSource/local/AutenticadorBiometrico.dart';
import 'package:arjipagos/src/domain/models/EstadoBiometria.dart';
import 'package:arjipagos/src/presentation/pages/biometria/bloc/BiometriaBloc.dart';
import 'package:arjipagos/src/presentation/pages/biometria/bloc/BiometriaEvent.dart';
import 'package:arjipagos/src/presentation/pages/biometria/bloc/BiometriaState.dart';
import 'package:arjipagos/src/presentation/widgets/IconoDeMenu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Interruptor del bloqueo biométrico, en la pantalla de Configuraciones.
///
/// Se dibuja con el mismo aspecto que las opciones del Menú Principal
/// —[IconoDeMenu] y título en `titleMedium` seminegrita—, porque
/// Configuraciones es una pantalla tipo menú y no un drawer.
///
/// Se dibuja **siempre**, incluso cuando el aparato no admite biometría: en ese
/// caso sale apagado, deshabilitado y con la razón escrita debajo. Esconderlo
/// dejaría al usuario preguntándose si la app tiene o no la función.
class InterruptorBiometria extends StatelessWidget {
  const InterruptorBiometria({super.key});

  /// Texto de apoyo bajo el título.
  String _subtitulo(EstadoBiometria estado) {
    if (!estado.sePuedeOfrecer) {
      return AppStrings.biometriaNoDisponibleEnAparato;
    }
    if (!estado.activado) {
      return AppStrings.biometriaSubtituloDesactivado;
    }
    // Con el bloqueo puesto se nombra el método real del aparato, que es lo que
    // el usuario va a ver cuando el cerrojo salte.
    return '${AppStrings.biometriaSubtituloActivado} '
        '(${AutenticadorBiometrico.nombreDe(estado.disponible)})';
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return BlocBuilder<BiometriaBloc, BiometriaState>(
      buildWhen: (BiometriaState anterior, BiometriaState actual) =>
          anterior.estado != actual.estado ||
          anterior.autenticando != actual.autenticando,
      builder: (BuildContext context, BiometriaState state) {
        final EstadoBiometria estado = state.estado;

        // Mientras el diálogo nativo está abierto no se acepta otro toque: dos
        // llamadas simultáneas a `authenticate` fallan en Android.
        final bool habilitado = estado.sePuedeOfrecer && !state.autenticando;

        return SwitchListTile(
          value: estado.activado,
          onChanged: habilitado
              ? (bool activar) => context
                  .read<BiometriaBloc>()
                  .add(BiometriaBloqueoCambiado(activar: activar))
              : null,
          secondary: IconoDeMenu(
            icono: estado.activado
                ? Icons.lock_outline
                : Icons.lock_open_outlined,
            habilitado: habilitado,
          ),
          title: Text(
            AppStrings.biometriaTituloAjuste,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            _subtitulo(estado),
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
          // El mismo margen que `MenuItemTile`, para que los iconos de las
          // opciones queden alineados en columna.
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 8,
          ),
        );
      },
    );
  }
}
