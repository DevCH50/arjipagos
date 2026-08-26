import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/data/dataSource/local/AutenticadorBiometrico.dart';
import 'package:arjipagos/src/domain/models/BiometriaDisponible.dart';
import 'package:arjipagos/src/presentation/widgets/LogoRedondeUno.dart';
import 'package:flutter/material.dart';

/// Pantalla que tapa la aplicación mientras el cerrojo está echado.
///
/// Repite el fondo degradado del splash a propósito: es la imagen que el
/// usuario ya asocia con "la app todavía no está lista", y así el bloqueo no
/// parece un error. Se adapta a tema claro y oscuro porque toma los colores del
/// `colorScheme`, no constantes fijas.
///
/// No sabe nada del BLoC: recibe qué mostrar y dos callbacks. Así se puede
/// pintar en cualquier estado sin montar la app entera.
class CerrojoPantalla extends StatelessWidget {
  /// Qué método admite el aparato, para nombrarlo bien y elegir el icono.
  final BiometriaDisponible disponible;

  /// Si el diálogo nativo está abierto ahora mismo.
  final bool autenticando;

  /// Reintentar el desbloqueo.
  final VoidCallback onDesbloquear;

  /// Salir al login y entrar con contraseña.
  final VoidCallback onUsarContrasena;

  const CerrojoPantalla({
    super.key,
    required this.disponible,
    required this.autenticando,
    required this.onDesbloquear,
    required this.onUsarContrasena,
  });

  /// Icono acorde al sensor. Un rostro para el reconocimiento facial, una
  /// huella para el lector, y un candado cuando solo hay PIN o patrón.
  IconData get _icono {
    switch (disponible) {
      case BiometriaDisponible.rostro:
        return Icons.face_retouching_natural;
      case BiometriaDisponible.huella:
      case BiometriaDisponible.generica:
        return Icons.fingerprint;
      case BiometriaDisponible.soloCredencial:
      case BiometriaDisponible.ninguna:
        return Icons.lock_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    // ## Sobre el botón atrás de Android
    //
    // Estando el cerrojo echado, el atrás llega al `Navigator` de debajo y va
    // cerrando rutas que no se ven, hasta salir de la app. **Se decidió dejarlo
    // así**, y conviene explicar por qué, para que nadie lo "arregle" con algo
    // que no funciona:
    //
    //  - `PopScope` NO sirve aquí. Se registra contra `ModalRoute.of(context)`,
    //    y este widget es un overlay del `builder` del MaterialApp: por encima
    //    del `Navigator`, sin ninguna ruta antepasada. `ModalRoute.of` devuelve
    //    null y el `PopScope` queda inerte — parece que protege y no protege.
    //  - Sobrescribir `didPopRoute` en el observador tampoco. `_WidgetsAppState`
    //    se registra como observador en SU initState, es decir antes que
    //    cualquier descendiente, y `handlePopRoute` se detiene en el primero que
    //    responde: nunca nos llegaría el turno.
    //  - Convertir el cerrojo en una ruta sí permitiría interceptarlo, pero es
    //    exactamente lo que se evita a propósito (ver `CerrojoBiometrico`).
    //
    // Y sobre todo: **no expone nada**. Lo que se cierra queda tapado por el
    // cerrojo mientras tanto, y al volver a abrir la app el cerrojo se echa otra
    // vez, porque la preferencia vive en `SecureStorage` y no en memoria. El
    // atrás cierra la app; no la abre.
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[colorScheme.primary, colorScheme.secondary],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: _Contenido(
                icono: _icono,
                disponible: disponible,
                autenticando: autenticando,
                onDesbloquear: onDesbloquear,
                onUsarContrasena: onUsarContrasena,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Columna central del cerrojo.
///
/// Está separada para no pasar de tres niveles de anidación en el `build` de
/// arriba, como pide la guía del proyecto.
class _Contenido extends StatelessWidget {
  final IconData icono;
  final BiometriaDisponible disponible;
  final bool autenticando;
  final VoidCallback onDesbloquear;
  final VoidCallback onUsarContrasena;

  const _Contenido({
    required this.icono,
    required this.disponible,
    required this.autenticando,
    required this.onDesbloquear,
    required this.onUsarContrasena,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color sobreFondo = colorScheme.onPrimary;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const LogoRedondoUno(
          blurRadius: 10,
          spreadRadius: 2,
          paddingEdgeInsets: 8,
          marginBottom: 24,
          size: 112,
        ),
        Text(
          AppStrings.biometriaAppBloqueada,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: sobreFondo,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          // Se nombra el método real del aparato: "Face ID" en iPhone,
          // "huella digital" en un Android con lector, y nunca al revés.
          'Usa tu ${AutenticadorBiometrico.nombreDe(disponible)} para continuar',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: sobreFondo.withValues(alpha: 0.75),
          ),
        ),
        const SizedBox(height: 40),
        _BotonDesbloqueo(
          icono: icono,
          autenticando: autenticando,
          onDesbloquear: onDesbloquear,
        ),
        const SizedBox(height: 16),
        TextButton(
          // La salida de emergencia: si el sensor no coopera, siempre se puede
          // entrar con la contraseña. Sin esto el usuario quedaría atrapado.
          onPressed: autenticando ? null : onUsarContrasena,
          style: TextButton.styleFrom(
            foregroundColor: sobreFondo.withValues(alpha: 0.9),
          ),
          child: const Text(AppStrings.biometriaUsarContrasena),
        ),
      ],
    );
  }
}

/// Botón circular grande que relanza el diálogo del sistema.
class _BotonDesbloqueo extends StatelessWidget {
  final IconData icono;
  final bool autenticando;
  final VoidCallback onDesbloquear;

  const _BotonDesbloqueo({
    required this.icono,
    required this.autenticando,
    required this.onDesbloquear,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color sobreFondo = colorScheme.onPrimary;

    return Semantics(
      button: true,
      label: AppStrings.biometriaDesbloquear,
      child: InkWell(
        // Mientras el diálogo nativo está abierto no se acepta otro toque: dos
        // llamadas simultáneas a `authenticate` fallan en Android.
        onTap: autenticando ? null : onDesbloquear,
        borderRadius: BorderRadius.circular(72),
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: sobreFondo.withValues(alpha: 0.15),
            border: Border.all(color: sobreFondo.withValues(alpha: 0.4)),
          ),
          child: autenticando
              ? Center(child: CircularProgressIndicator(color: sobreFondo))
              : Icon(icono, size: 56, color: sobreFondo),
        ),
      ),
    );
  }
}
