/// Configuración de los contratos con Adquira México.
///
/// Cada **emisor fiscal** es un contrato distinto con el proveedor y cobra
/// contra una **cuenta bancaria distinta**. Por eso no basta con cambiar el
/// importe: el endpoint y los parámetros del comercio cambian por completo.
///
/// La tabla está indexada por `emisorfiscal_id`, el mismo valor que el backend
/// manda en cada renglón del estado de cuenta
/// (`EstadoDeCuenta.emisorFiscalId`). Añadir un contrato nuevo es añadir una
/// entrada al mapa: no hay que tocar el service, el bloc ni la pantalla.
library;

import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/data/api/pasarela_pago.dart';
import 'package:arjipagos/src/domain/models/EstadoDeCuenta.dart'
    show kEmisorFiscalPredeterminado;
import 'package:arjipagos/src/domain/models/PoliticaEmisor.dart';

/// Datos de un contrato con Adquira: a dónde se envía el pago y con qué
/// parámetros de comercio.
class ConfiguracionAdquira {
  /// Proveedor con el que cobra este emisor.
  ///
  /// Decide **de dónde sale la URL que abre el WebView**, y con ello si los
  /// campos de comercio de abajo ([endpoint], [idExpress], [financiamiento],
  /// [tipo], [tipoPago], [plazos], [mediosPago]) se usan o se ignoran: son de
  /// Adquira y solo tienen sentido con [PasarelaPago.adquira].
  ///
  /// Se declara con valor por omisión [PasarelaPago.adquira] a propósito: es
  /// como cobraba la app cuando solo había un proveedor, así que un contrato
  /// nuevo que no diga nada sigue comportándose como siempre.
  final PasarelaPago pasarela;

  /// URL de Adquira a la que el WebView hace el POST del pago.
  ///
  /// Solo se usa con [PasarelaPago.adquira]. Con OpenPay la URL la da el
  /// backend en cada cobro, porque lleva el identificador del checkout.
  final String endpoint;

  /// Identificador del comercio en Adquira. Es el que decide a qué cuenta
  /// bancaria entra el dinero, así que un valor equivocado cobra en la cuenta
  /// de otro emisor sin dar ningún error.
  final String idExpress;

  final String financiamiento;
  final String moneda;
  final String tipo;
  final String tipoPago;
  final String plazos;

  /// Máscara de medios de pago admitidos por el contrato.
  final String mediosPago;

  /// Nombre legible del emisor, para los registros de `AppLogger`.
  final String descripcion;

  /// Reglas de selección y de referencia de este emisor.
  ///
  /// Van aquí, y no en `AppConstants`, porque son suyas: otro contrato puede
  /// no exigir orden ascendente o admitir una referencia más larga.
  final PoliticaEmisor politica;

  /// Nombre de la ruta de su pantalla de estados de cuenta.
  ///
  /// Lo necesita el WebView de pago para volver a la pantalla correcta al
  /// terminar: con la ruta escrita a mano, pagar en un emisor devolvía al
  /// usuario a la pantalla del otro.
  final String ruta;

  /// Título de su pantalla. Para el usuario son dos sitios distintos.
  final String titulo;

  /// Clave propia en el almacenamiento local para la selección de pagos.
  ///
  /// **Una por emisor, y ese es justo el punto.** Con una clave compartida,
  /// vaciar un carrito, recargar una lista o completar un pago borraba también
  /// la selección del otro emisor. Separando la clave, cada uno vive en su
  /// sitio y ninguna operación de uno alcanza al otro.
  final String claveSeleccion;

  /// `true` mientras los datos sean prestados de otro contrato y NO los
  /// reales de este.
  ///
  /// Un pago hecho con una configuración provisional entra en la cuenta
  /// bancaria equivocada, y Adquira no devuelve ningún error porque para él la
  /// operación es válida. Ver `test/unit/configuracion_adquira_test.dart`.
  final bool esProvisional;

  const ConfiguracionAdquira({
    required this.endpoint,
    required this.idExpress,
    required this.financiamiento,
    required this.moneda,
    required this.tipo,
    required this.tipoPago,
    required this.plazos,
    required this.mediosPago,
    required this.descripcion,
    required this.politica,
    required this.ruta,
    required this.titulo,
    required this.claveSeleccion,
    this.pasarela = PasarelaPago.adquira,
    this.esProvisional = false,
  });

  /// Emisor fiscal 1 — "Pagos Pendientes". Datos reales, en producción desde
  /// siempre: son los que la app venía enviando cuando había un solo endpoint.
  static const ConfiguracionAdquira ef1 = ConfiguracionAdquira(
    pasarela: PasarelaPago.adquira,
    endpoint: 'https://www.adquiramexico.com.mx:443/mExpress/pago/avanzado',
    idExpress: '928',
    financiamiento: '0',
    moneda: 'MXN',
    tipo: '1',
    tipoPago: '1',
    plazos: '',
    mediosPago: '111000',
    descripcion: 'Emisor fiscal 1 (Pagos Pendientes)',
    politica: PoliticaEmisor.ef1,
    ruta: 'edo_cta',
    titulo: AppStrings.edoCtaTitle,
    claveSeleccion: 'seleccion_pagos_ef1',
  );

  /// Emisor fiscal 2 — "Otros pagos". **Cobra por OpenPay, no por Adquira.**
  ///
  /// El contrato 2 nunca llegó a tener datos propios de Adquira, y en vez de
  /// esperarlos se le cambió de proveedor: desde el 2026-09-24 cobra con el
  /// «Botón de pago» de OpenPay. La URL del formulario la pide la app al
  /// backend en cada cobro (ver [PasarelaPago.openpay]).
  ///
  /// ⚠️ **Los campos de Adquira de aquí abajo están INERTES.** Siguen siendo
  /// copia de los de [ef1] y siguen sin ser los del contrato 2, pero con
  /// [PasarelaPago.openpay] no los lee nadie: `CarritoBloc` ni construye el
  /// `PagoRequest` en ese camino. Se conservan —y con ellos `esProvisional`—
  /// porque son la red de seguridad del día que alguien devuelva este emisor a
  /// Adquira: si eso pasa **sin cambiar el `idexpress`, el dinero vuelve a
  /// entrar en la cuenta bancaria del emisor 1**, y Adquira no se queja porque
  /// para él la operación es válida.
  ///
  /// O sea: quitar `esProvisional` solo cuando existan de verdad los datos del
  /// contrato 2 en Adquira, no por el hecho de haber pasado a OpenPay.
  static const ConfiguracionAdquira ef2 = ConfiguracionAdquira(
    pasarela: PasarelaPago.openpay,
    endpoint: 'https://www.adquiramexico.com.mx:443/mExpress/pago/avanzado',
    idExpress: '928',
    financiamiento: '0',
    moneda: 'MXN',
    tipo: '1',
    tipoPago: '1',
    plazos: '',
    mediosPago: '111000',
    descripcion: 'Emisor fiscal 2 (Otros pagos)',
    politica: PoliticaEmisor.ef2,
    ruta: 'edo_cta_otros',
    titulo: AppStrings.menuOtrosPagos,
    claveSeleccion: 'seleccion_pagos_ef2',
    esProvisional: true,
  );

  /// Emisor que se asume cuando el backend no manda `emisorfiscal_id`.
  ///
  /// Reexporta la constante del dominio para no tener el mismo número escrito
  /// en dos sitios: quien cambie uno cambiaría solo la mitad del comportamiento.
  static const int emisorFiscalPredeterminado = kEmisorFiscalPredeterminado;

  static const Map<int, ConfiguracionAdquira> _porEmisorFiscal = {
    1: ef1,
    2: ef2,
  };

  /// Emisores fiscales que la app sabe cobrar, de menor a mayor.
  static List<int> get emisoresConocidos =>
      _porEmisorFiscal.keys.toList()..sort();

  /// Devuelve la configuración de [emisorFiscalId].
  ///
  /// Si el backend manda un emisor que esta versión de la app no conoce, cae
  /// en [ef1] en lugar de reventar: es preferible cobrar en la cuenta
  /// principal —donde el dinero se puede reasignar— que dejar al usuario sin
  /// poder pagar. El aviso queda en `AppLogger`.
  static ConfiguracionAdquira para(int emisorFiscalId) =>
      _porEmisorFiscal[emisorFiscalId] ?? ef1;

  /// `true` si [emisorFiscalId] tiene configuración propia en esta versión.
  static bool conoce(int emisorFiscalId) =>
      _porEmisorFiscal.containsKey(emisorFiscalId);
}
