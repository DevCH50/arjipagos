import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

/// Reglas de selección y de referencia de **un** emisor fiscal.
///
/// Cada emisor es un contrato distinto con Adquira, con su propia cuenta
/// bancaria y sus propias condiciones. Nada obliga a que dos contratos exijan
/// lo mismo: uno puede pedir que los pagos se liquiden en orden y otro dejar
/// elegir suelto, y el tope de la referencia lo fija cada pasarela.
///
/// Por eso estas reglas **no** son constantes globales de la app. Vivían en
/// `AppConstants` cuando solo había un contrato; ahora cada emisor trae las
/// suyas y ninguno sabe qué hace el otro.
class PoliticaEmisor {
  /// Si los pagos deben seleccionarse del más antiguo al más reciente.
  ///
  /// Cuando es `false`, el usuario marca los que quiera en el orden que quiera
  /// y desaparecen los candados de la lista.
  final bool exigeOrdenAscendente;

  /// Tope de caracteres de la referencia que admite la pasarela.
  ///
  /// Pasarse no da un error claro: Adquira rechaza la transacción. Por eso se
  /// valida antes de dejar seleccionar y otra vez antes de pagar.
  final int maxLongitudReferencia;

  /// Separador de los IDs en la referencia cuando la app corre en iOS.
  final String separadorIOS;

  /// Separador de los IDs en la referencia cuando la app corre en Android.
  final String separadorAndroid;

  const PoliticaEmisor({
    required this.exigeOrdenAscendente,
    required this.maxLongitudReferencia,
    required this.separadorIOS,
    required this.separadorAndroid,
  });

  /// Separador que toca según la plataforma en la que corre la app.
  String get separador => defaultTargetPlatform == TargetPlatform.iOS
      ? separadorIOS
      : separadorAndroid;

  /// Arma la referencia de pago de este emisor a partir de los IDs indicados.
  ///
  /// Un solo pago lleva un `0` detrás del separador —`"3399A0"`—; varios se
  /// unen con él: `"5358A5359A5360"`. Los IDs nunca se truncan: si no caben,
  /// se impide seleccionar más, que es lo que comprueba
  /// [referenciaDentroDelLimite].
  String generarReferencia(List<int> ids) {
    if (ids.isEmpty) {
      return '';
    }
    final String sep = separador;
    if (ids.length == 1) {
      return '${ids.first}${sep}0';
    }
    return ids.join(sep);
  }

  /// `true` si [referencia] cabe en lo que admite esta pasarela.
  bool referenciaDentroDelLimite(String referencia) =>
      referencia.isEmpty || referencia.length <= maxLongitudReferencia;

  /// Política del emisor fiscal 1.
  ///
  /// Reproduce exactamente lo que la app hacía cuando había un solo contrato:
  /// orden ascendente obligatorio, 30 caracteres de referencia y separador
  /// `I`/`A` según plataforma. No cambiarla sin motivo: es la que está cobrando
  /// en producción.
  static const PoliticaEmisor ef1 = PoliticaEmisor(
    exigeOrdenAscendente: true,
    maxLongitudReferencia: 30,
    separadorIOS: 'I',
    separadorAndroid: 'A',
  );

  /// Política del emisor fiscal 2.
  ///
  /// Hoy coincide con la de [ef1] porque es lo que la app venía haciendo con
  /// estos pagos, no porque el contrato 2 la exija: **nadie ha confirmado sus
  /// reglas reales todavía**. En cuanto se sepan, se cambian aquí y solo aquí;
  /// el emisor 1 no se entera.
  static const PoliticaEmisor ef2 = PoliticaEmisor(
    exigeOrdenAscendente: true,
    maxLongitudReferencia: 30,
    separadorIOS: 'I',
    separadorAndroid: 'A',
  );
}
