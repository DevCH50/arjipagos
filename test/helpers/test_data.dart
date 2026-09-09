/// Datos de prueba para los tests unitarios.
///
/// Contiene factories y datos mock para User, Alumno, AuthResponse
/// y Notificacion.
library;

import 'package:arjipagos/src/domain/models/Alumno.dart';
import 'package:arjipagos/src/domain/models/notificacion/notificacion.dart';
import 'package:arjipagos/src/domain/models/AuthResponse.dart';
import 'package:arjipagos/src/domain/models/EstadoDeCuenta.dart';
import 'package:arjipagos/src/domain/models/User.dart';

/// Datos de prueba para User.
class TestUser {
  static User get valid => User(
    id: 1,
    username: 'juanperez',
    email: 'juan@ejemplo.com',
    nombre: 'Juan',
    apPaterno: 'Pérez',
    apMaterno: 'García',
    curp: 'PEGJ900101HDFRRL09',
    emails: 'juan@ejemplo.com',
    celulares: '5551234567',
    telefonos: '5559876543',
    fechaNacimiento: '1990-01-01',
    genero: 1,
    uuid: 'abc123-def456',
    activo: 1,
    fullName: 'Juan Pérez García',
    fullNameWithUsername: 'Juan Pérez García (juanperez)',
    pathImageProfile: 'https://example.com/avatar.jpg',
  );

  static Map<String, dynamic> get validJson => {
    'id': 1,
    'username': 'juanperez',
    'email': 'juan@ejemplo.com',
    'nombre': 'Juan',
    'ap_paterno': 'Pérez',
    'ap_materno': 'García',
    'curp': 'PEGJ900101HDFRRL09',
    'emails': 'juan@ejemplo.com',
    'celulares': '5551234567',
    'telefonos': '5559876543',
    'fecha_nacimiento': '1990-01-01',
    'genero': 1,
    'uuid': 'abc123-def456',
    'activo': 1,
    'full_name': 'Juan Pérez García',
    'full_name_with_username': 'Juan Pérez García (juanperez)',
    'path_image_profile': 'https://example.com/avatar.jpg',
  };
}

/// Datos de prueba para EstadoDeCuenta.
class TestEstadoDeCuenta {
  /// Ciclo por defecto de los pagos de prueba.
  static const int cicloActual = 2024;

  /// Ciclo distinto, para ejercitar el ámbito de la selección.
  static const int cicloAnterior = 2023;

  static EstadoDeCuenta get pendiente => EstadoDeCuenta(
    id: 1,
    cicloId: cicloActual,
    emisorFiscalId: 1,
    descripcionCorta: 'Colegiatura Enero 2024',
    total: 5000.0,
    totalFormatted: '\$5,000.00',
    fechaVencimiento: '2024-01-31',
    estadoPago: EstadoPago.pendiente,
    numPago: 1,
    aceptaPagosDiversos: true,
    estaDisponibleEnInternet: true,
  );

  static EstadoDeCuenta get vencido => EstadoDeCuenta(
    id: 2,
    cicloId: cicloActual,
    emisorFiscalId: 1,
    descripcionCorta: 'Colegiatura Diciembre 2023',
    total: 4500.0,
    totalFormatted: '\$4,500.00',
    fechaVencimiento: '2023-12-31',
    estadoPago: EstadoPago.vencido,
    numPago: 2,
    aceptaPagosDiversos: true,
    estaDisponibleEnInternet: true,
  );

  static List<EstadoDeCuenta> get lista => [pendiente, vencido];

  /// Pago del ciclo anterior, para verificar que la selección de un ciclo no
  /// condiciona la del otro.
  static EstadoDeCuenta get otroCiclo => EstadoDeCuenta(
    id: 10,
    cicloId: cicloAnterior,
    emisorFiscalId: 1,
    descripcionCorta: 'Colegiatura Enero 2023',
    total: 4000.0,
    totalFormatted: '\$4,000.00',
    fechaVencimiento: '2023-01-31',
    estadoPago: EstadoPago.vencido,
    numPago: 1,
    aceptaPagosDiversos: true,
    estaDisponibleEnInternet: true,
  );

  /// Pagos de dos ciclos distintos mezclados, ordenados por ID.
  /// Ojo: el ID más bajo (1, 2) es del ciclo actual y el más alto (10) del
  /// anterior, justo para que un orden global daría un resultado distinto al
  /// orden por ciclo.
  static List<EstadoDeCuenta> get listaDosCiclos => [
    pendiente,
    vencido,
    otroCiclo,
  ];
}

/// Datos de prueba para Alumno.
class TestAlumno {
  static Alumno get activo => Alumno(
    alumnoId: 1,
    familia: 'Familia López García',
    alumno: 'LOPEZ GARCIA MARIA',
    nombre: 'María',
    esBaja: false,
    grupo: '3ro A',
    urlPhoto: 'https://example.com/maria.jpg',
    estadoDeCuenta: TestEstadoDeCuenta.lista,
  );

  static Alumno get baja => Alumno(
    alumnoId: 2,
    familia: 'Familia López García',
    alumno: 'SANCHEZ MARTINEZ PEDRO',
    nombre: 'Pedro',
    esBaja: true,
    grupo: '2do B',
    urlPhoto: '',
    estadoDeCuenta: [],
  );

  static Map<String, dynamic> get activoJson => {
    'alumno_id': 1,
    'familia': 'Familia López García',
    'alumno': 'LOPEZ GARCIA MARIA',
    'nombre': 'María',
    'es_baja': false,
    'grupo': '3ro A',
    'url_photo': 'https://example.com/maria.jpg',
    'estado_de_cuenta': [
      {
        'id': 1,
        'ciclo_id': TestEstadoDeCuenta.cicloActual,
        'emisorfiscal_id': 1,
        // Las dos parcialidades son del mismo cargo, así que comparten
        // `pago_id`: es la clave del concepto en el ámbito de selección.
        'pago_id': 900,
        'descripcion_corta': 'Colegiatura Enero 2024',
        'total': 5000.0,
        'total_formatted': '\$5,000.00',
        'fecha_vencimiento': '2024-01-31',
        'estadoPago': 'Pendiente',
        'num_pago': 1,
        'acepta_pagos_diversos': true,
        'esta_disponible_en_internet': true,
        'deuda_anterior': false,
      },
      {
        'id': 2,
        'ciclo_id': TestEstadoDeCuenta.cicloActual,
        'emisorfiscal_id': 1,
        'pago_id': 900,
        'descripcion_corta': 'Colegiatura Diciembre 2023',
        'total': 4500.0,
        'total_formatted': '\$4,500.00',
        'fecha_vencimiento': '2023-12-31',
        'estadoPago': 'Vencido',
        'num_pago': 2,
        'acepta_pagos_diversos': true,
        'esta_disponible_en_internet': true,
        'deuda_anterior': false,
      },
    ],
  };

  static Map<String, dynamic> get bajaJson => {
    'alumno_id': 2,
    'familia': 'Familia López García',
    'alumno': 'SANCHEZ MARTINEZ PEDRO',
    'nombre': 'Pedro',
    'es_baja': true,
    'grupo': '2do B',
    'url_photo': '',
    'estado_de_cuenta': [],
  };

  static List<Alumno> get lista => [activo, baja];

  static List<Map<String, dynamic>> get listaJson => [activoJson, bajaJson];
}

/// Datos de prueba para los pagos ya realizados.
///
/// Reproducen la respuesta real de `estado-de-cuenta-pagados`, que difiere de la
/// de pagos pendientes en cuatro cosas: `estadoPago` llega como `"Pagado"`, se
/// añaden los datos del ticket, NO vienen `factura_pdf` / `factura_xml`, y
/// `fecha_vencimiento` puede llegar en `null`.
class TestPagoRealizado {
  /// Pago liquidado con ticket disponible.
  static Map<String, dynamic> get conTicketJson => {
    'id': 3403,
    'ciclo_id': 12,
    'emisorfiscal_id': 1,
    'descripcion_corta': 'COLEGIATURA PRIMARIA Mar 26',
    'total': 9770,
    'total_formatted': '9,770.00',
    'fecha_vencimiento': '10-03-2026',
    'acepta_pagos_diversos': true,
    'esta_disponible_en_internet': true,
    'estadoPago': 'Pagado',
    'num_pago': 7,
    'fecha_de_pago': '17-08-2026 10:01:01',
    'ticket_uuid': 'a7064b3b-a517-4636-95da-c5b2cdcd19ff',
    'ticket_folio': 'T7672',
    'ticket_url':
        'https://arjipagos.moriah.mx/api/v1/tickets/a7064b3b-a517-4636-95da-c5b2cdcd19ff/print',
    'deuda_anterior': true,
  };

  /// Caso real observado en producción: reinscripción sin fecha de vencimiento.
  static Map<String, dynamic> get sinVencimientoJson => {
    'id': 15173,
    'ciclo_id': 14,
    'emisorfiscal_id': 1,
    'descripcion_corta': 'REINSCRIPCION SECUNDARIA  26 / 27  ',
    'total': 14250,
    'total_formatted': '14,250.00',
    'fecha_vencimiento': null,
    'acepta_pagos_diversos': false,
    'esta_disponible_en_internet': true,
    'estadoPago': 'Pagado',
    'num_pago': 1,
    'fecha_de_pago': '20-08-2026 14:24:32',
    'ticket_uuid': '261f8b68-78d5-4185-b065-38a898487c44',
    'ticket_folio': 'T7719',
    'ticket_url':
        'https://arjipagos.moriah.mx/api/v1/tickets/261f8b68-78d5-4185-b065-38a898487c44/print',
    'deuda_anterior': false,
  };

  /// Alumno tal como llega en esta respuesta: con familia y con `grupo` vacío.
  static Map<String, dynamic> get alumnoJson => {
    'alumno_id': 97,
    'alumno': 'DAMASCO CANELLA NOAH',
    'nombre': 'NOAH',
    'es_baja': false,
    'familia': 'DAMASCO CANELLA',
    'grupo': '',
    'url_photo': '/storage/profile/97.jpg',
    'estado_de_cuenta': [conTicketJson, sinVencimientoJson],
  };

  /// Respuesta completa del endpoint de pagos realizados.
  static Map<String, dynamic> get respuestaJson => {
    'success': true,
    'message': 'OK',
    'pagados_desde': '01-07-2026',
    'pagados_hasta': '30-06-2027',
    'familia': 'DAMASCO CANELLA',
    'alumnos': [alumnoJson],
  };
}

/// Datos de prueba para AuthResponse.
class TestAuthResponse {
  static AuthResponse get valid => AuthResponse(
    status: 200,
    msg: 'Login exitoso',
    accessToken: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.test',
    user: TestUser.valid,
    apiVersion: '1.0.0',
    appVersion: '1.0.0',
  );

  static Map<String, dynamic> get validJson => {
    'status': 200,
    'msg': 'Login exitoso',
    'access_token': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.test',
    'user': TestUser.validJson,
    'api_version': '1.0.0',
    'app_version': '1.0.0',
  };
}


/// Datos de prueba para Notificacion.
class TestNotificacion {
  /// Notificación no leída con texto plano.
  static Notificacion get noLeida => Notificacion(
    id: 1,
    titulo: 'Estado de Cuenta Vencido',
    mensaje: 'Tu pago de enero ha vencido.',
    campania: 'estado_cuenta',
    fecha: DateTime(2024, 1, 15, 10, 0),
    isRead: false,
  );

  /// Notificación ya leída.
  static Notificacion get leida => Notificacion(
    id: 2,
    titulo: 'Pago Confirmado',
    mensaje: 'Tu pago fue procesado correctamente.',
    campania: 'pago',
    fecha: DateTime(2024, 1, 14, 9, 0),
    isRead: true,
  );

  /// Lista de la primera página: una no leída y una leída.
  static List<Notificacion> get listaPagina1 => [noLeida, leida];

  /// Lista de la segunda página (para tests de paginación).
  static List<Notificacion> get listaPagina2 => [
    Notificacion(
      id: 3,
      titulo: 'Recordatorio de Pago',
      mensaje: 'Tu próximo pago vence en 5 días.',
      campania: 'recordatorio',
      fecha: DateTime(2024, 1, 13, 8, 0),
      isRead: false,
    ),
  ];

  /// Notificación simulada recibida por FCM en foreground.
  static Notificacion get foreground => Notificacion(
    id: 0,
    titulo: 'Nueva Notificación',
    mensaje: 'Tienes un nuevo aviso.',
    campania: 'general',
    fecha: DateTime(2024, 1, 16, 11, 0),
    isRead: false,
  );
}

/// Fixtures de los banners informativos.
///
/// El JSON es el que devuelve `/api/v1/banners` en producción, con el cuerpo
/// en Markdown y los saltos de línea `\r\n` tal cual los manda el backend.
class TestBanner {
  /// Banner con cuerpo Markdown: negritas, subtítulo y lista.
  static Map<String, dynamic> get anualidadJson => {
    'id': 1,
    'titulo': 'Se acaba el tiempo para el descuento especial por anualidad',
    'imagen_url':
        'https://arjipagos.moriah.mx/storage/banners/anualidad-l4xwyp.jpg',
    'fecha': '20-08-2026',
    'cuerpo':
        'El **25 de septiembre** es la fecha límite para pagar la '
        'anualidad completa y\r\naprovechar el descuento especial del ciclo.'
        '\r\n\r\n### Qué necesita saber\r\n\r\n- El descuento se aplica '
        '**solo** sobre el pago de la anualidad.\r\n- Después de esa fecha, '
        'la colegiatura vuelve a cobrarse mes por mes.',
    'cuerpo_formato': 'markdown',
  };

  /// Segundo banner, para ejercitar listas de más de un elemento.
  static Map<String, dynamic> get reinscripcionesJson => {
    'id': 2,
    'titulo': 'Reinscripciones del próximo ciclo: ya están disponibles',
    'imagen_url':
        'https://arjipagos.moriah.mx/storage/banners/reinscripciones-4cmpno.jpg',
    'fecha': '17-08-2026',
    'cuerpo': 'Ya puede realizar la **reinscripción** de sus hijos.',
    'cuerpo_formato': 'markdown',
  };

  /// Respuesta completa del endpoint.
  static Map<String, dynamic> get respuestaJson => {
    'success': true,
    'message': 'OK',
    'banners': [anualidadJson, reinscripcionesJson],
  };

  /// Respuesta sin banners: la tirilla no debe pintarse.
  static Map<String, dynamic> get respuestaVaciaJson => {
    'success': true,
    'message': 'OK',
    'banners': <Map<String, dynamic>>[],
  };
}

/// Una parcialidad suelta, con todo lo que interviene en el ámbito de
/// selección abierto: ciclo, emisor, concepto (`pagoId`) y tipo de deuda.
///
/// Es lo que hace falta para montar el caso de IVANA —dos conceptos en el mismo
/// ciclo— sin repetir los quince campos del modelo en cada test.
EstadoDeCuenta pagoDePrueba({
  required int id,
  int cicloId = TestEstadoDeCuenta.cicloActual,
  int emisorFiscalId = 1,
  int pagoId = 0,
  bool deudaAnterior = false,
  bool aceptaPagosDiversos = true,
  bool estaDisponibleEnInternet = true,
  int numPago = 1,
  bool numPagoActivo = true,
  double total = 1000.0,
  String? descripcionCorta,
}) {
  return EstadoDeCuenta(
    id: id,
    cicloId: cicloId,
    emisorFiscalId: emisorFiscalId,
    pagoId: pagoId,
    deudaAnterior: deudaAnterior,
    descripcionCorta: descripcionCorta ?? 'Pago $id',
    total: total,
    totalFormatted: '\$1,000.00',
    fechaVencimiento: '2026-12-31',
    estadoPago: EstadoPago.pendiente,
    numPago: numPago,
    aceptaPagosDiversos: aceptaPagosDiversos,
    estaDisponibleEnInternet: estaDisponibleEnInternet,
  );
}

/// Un [Alumno] con la lista de pagos que se le pase, tal cual.
Alumno alumnoConPagos(int alumnoId, List<EstadoDeCuenta> pagos) =>
    TestAlumno.activo.conEstadoDeCuenta(pagos)..alumnoId = alumnoId;

/// Construye un [Alumno] con pagos repartidos por ciclo, para los tests que
/// necesitan que la selección case con datos reales de pago.
///
/// Desde que los pagos se reparten por emisor fiscal, ni la barra del total ni
/// el carrito pueden calcularse solo con el mapa `{ciclo: {alumno: [pagoId]}}`:
/// ese mapa guarda junta la selección de los dos emisores, así que hay que
/// mirar cada pago para saber cuál pertenece a la pantalla que se está viendo.
Alumno alumnoConPagosPorCiclo(
  int alumnoId,
  Map<int, List<int>> pagosPorCiclo, {
  int emisorFiscalId = 1,
  double total = 1000.0,
}) {
  final pagos = <EstadoDeCuenta>[];
  pagosPorCiclo.forEach((cicloId, ids) {
    for (final id in ids) {
      pagos.add(
        EstadoDeCuenta(
          id: id,
          cicloId: cicloId,
          emisorFiscalId: emisorFiscalId,
          descripcionCorta: 'Pago $id',
          total: total,
          totalFormatted: '\$1,000.00',
          fechaVencimiento: '2026-12-31',
          estadoPago: EstadoPago.pendiente,
          numPago: 1,
          aceptaPagosDiversos: false,
          estaDisponibleEnInternet: true,
        ),
      );
    }
  });

  return alumnoConPagos(alumnoId, pagos);
}
