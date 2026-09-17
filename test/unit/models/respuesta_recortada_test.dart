/// Test guardián del recorte del JSON que se le pidió al backend en
/// `CAMPOS_JSON_QUE_LA_APP_NO_USA.md` (repo ArjiApp).
///
/// Cada caso parte de una respuesta **completa** —con los campos que la app no
/// usa— y la parsea dos veces: tal cual y quitándole esos campos. Las dos deben
/// dar lo mismo en todo lo que la app pinta o manda.
///
/// Por qué importa: la versión publicada en las tiendas (1.0.30+39) se compiló
/// con estos mismos modelos. Si este test pasa, el recorte no le rompe nada a
/// quien ya la tiene instalada. Si algún día falla, el backend NO debe quitar
/// ese campo hasta que la versión que lo tolera sea la mínima obligatoria.
///
/// Hay un límite que el test deja escrito: el `id` de cada factura NO se puede
/// quitar, porque `Factura.id` es un `int` no nulable.
library;

import 'package:arjipagos/src/domain/models/AuthResponse.dart';
import 'package:arjipagos/src/domain/models/EstadosDeCuentaResponse.dart';
import 'package:arjipagos/src/domain/models/FacturaResponse.dart';
import 'package:arjipagos/src/domain/models/notificacion/NotificacionResponse.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_data.dart';

/// Copia profunda de [json] sin las claves de [campos], a cualquier nivel.
///
/// Es recursiva porque los campos a quitar se repiten dentro de cada alumno y
/// de cada renglón de pago, no solo en la raíz.
dynamic _sin(dynamic json, Set<String> campos) {
  if (json is Map) {
    return <String, dynamic>{
      for (final entrada in json.entries)
        if (!campos.contains(entrada.key))
          entrada.key as String: _sin(entrada.value, campos),
    };
  }
  if (json is List) {
    return json.map((e) => _sin(e, campos)).toList();
  }
  return json;
}

/// Campos por alumno que se pueden dejar de mandar.
const _camposAlumno = {
  'familia_id',
  'ap_paterno',
  'ap_materno',
  'beca_sep',
  'beca_arji',
  'beca_bach',
  'beca_sp',
  'grupo_id',
};

/// Campos por renglón de pago que se pueden dejar de mandar.
const _camposPago = {
  'nivel_id',
  'num_pago_activo',
  'esta_disponible_en_la_app_movil',
  'factura_pdf',
  'factura_xml',
};

/// Campos de la raíz de los estados de cuenta y de las facturas.
const _camposRaiz = {'ciclo_predeterminado_id', 'familia_id'};

/// Datos de perfil del login que la app no lee (decisión de producto).
const _camposPerfil = {
  'curp',
  'emails',
  'celulares',
  'telefonos',
  'fecha_nacimiento',
  'genero',
  'uuid',
  'activo',
  'full_name_with_username',
  'path_image_profile',
  'ap_paterno',
  'ap_materno',
};

/// Añade a un renglón de pago los campos que el backend manda hoy y sobran.
Map<String, dynamic> _pagoCompleto(Map<String, dynamic> pago) => {
  ...pago,
  'nivel_id': 3,
  'num_pago_activo': 1,
  'esta_disponible_en_la_app_movil': true,
  'factura_pdf': 'https://example.com/f.pdf',
  'factura_xml': 'https://example.com/f.xml',
};

/// Añade a un alumno los campos que sobran, también en cada uno de sus pagos.
Map<String, dynamic> _alumnoCompleto(Map<String, dynamic> alumno) => {
  ...alumno,
  'familia_id': 55,
  'ap_paterno': 'LOPEZ',
  'ap_materno': 'GARCIA',
  'beca_sep': '0',
  'beca_arji': '10',
  'beca_bach': '0',
  'beca_sp': '0',
  'grupo_id': 7,
  'estado_de_cuenta': [
    for (final pago in alumno['estado_de_cuenta'] as List)
      _pagoCompleto(pago as Map<String, dynamic>),
  ],
};

/// Lo que la app pinta o decide de una respuesta de estados de cuenta.
List<Object?> _visible(EstadosDeCuentaResponse r) => [
  r.familia,
  r.success,
  for (final a in r.alumnos) ...[
    a.alumnoId,
    a.nombre,
    a.grupo,
    a.esBaja,
    a.urlPhoto,
    for (final p in a.estadoDeCuenta) ...[
      p.id,
      p.cicloId,
      p.emisorFiscalId,
      p.pagoId,
      p.descripcionCompleta,
      p.total,
      p.totalFormatted,
      p.estadoPago,
      p.numPago,
      p.estaDisponibleEnInternet,
      p.deudaAnterior,
      p.ticketUrl,
    ],
  ],
];

void main() {
  group('Estados de cuenta sin pagar sin los campos que sobran', () {
    final completo = {
      'success': true,
      'message': 'OK',
      'familia': 'Familia López García',
      'ciclo_predeterminado_id': 14,
      'familia_id': 55,
      'alumnos': [
        _alumnoCompleto(TestAlumno.activoJson),
        _alumnoCompleto(TestAlumno.bajaJson),
      ],
    };
    final recortado =
        _sin(completo, {..._camposRaiz, ..._camposAlumno, ..._camposPago})
            as Map<String, dynamic>;

    test('el recortado de verdad ya no lleva ninguno de esos campos', () {
      final texto = recortado.toString();
      for (final campo in {..._camposAlumno, ..._camposPago, ..._camposRaiz}) {
        expect(texto.contains('$campo:'), isFalse, reason: campo);
      }
    });

    test('se parsea sin lanzar y da lo mismo que la respuesta completa', () {
      final antes = EstadosDeCuentaResponse.fromJson(completo);
      final despues = EstadosDeCuentaResponse.fromJson(recortado);

      expect(despues.alumnos, hasLength(2));
      expect(despues.alumnos.first.estadoDeCuenta, hasLength(2));
      expect(_visible(despues), equals(_visible(antes)));
    });
  });

  group('Pagos realizados sin los campos que sobran', () {
    test('se parsea sin lanzar y conserva el ticket', () {
      final completo = {
        ...TestPagoRealizado.respuestaJson,
        'ciclo_predeterminado_id': 14,
        'familia_id': 55,
        'alumnos': [_alumnoCompleto(TestPagoRealizado.alumnoJson)],
      };
      final recortado =
          _sin(completo, {..._camposRaiz, ..._camposAlumno, ..._camposPago})
              as Map<String, dynamic>;

      final antes = EstadosDeCuentaResponse.fromJson(completo);
      final despues = EstadosDeCuentaResponse.fromJson(recortado);

      expect(despues.alumnos.single.estadoDeCuenta, hasLength(2));
      expect(_visible(despues), equals(_visible(antes)));
    });
  });

  group('Facturas sin los campos que sobran', () {
    Map<String, dynamic> factura() => {
      'id': 812,
      'folio': 'A-1045',
      'fecha': '12-08-2026',
      'fecha_timbrado': '12-08-2026 10:15:00',
      'referencia': 'REF123',
      'total': '9,770.00',
      'zip_url': 'https://arjipagos.moriah.mx/api/v1/facturas/812/zip',
      'zip_nombre': 'A-1045.zip',
      'directorio': '/facturas/2026/08',
      'pdf': 'A-1045.pdf',
      'xml': 'A-1045.xml',
    };
    Map<String, dynamic> respuesta(Map<String, dynamic> f) => {
      'success': true,
      'message': 'OK',
      'familia': 'DAMASCO CANELLA',
      'ciclo_predeterminado_id': 14,
      'familia_id': 55,
      'facturas': [f],
    };

    test('sin directorio, pdf ni xml se parsea y conserva el ZIP', () {
      final recortado =
          _sin(respuesta(factura()), {
                ..._camposRaiz,
                'directorio',
                'pdf',
                'xml',
              })
              as Map<String, dynamic>;

      final f = FacturaResponse.fromJson(recortado).facturas.single;

      expect(f.id, 812);
      expect(f.folio, 'A-1045');
      expect(f.zipUrl, endsWith('/812/zip'));
      expect(f.zipNombre, 'A-1045.zip');
    });

    test('el id de la factura NO se puede quitar: sin él revienta', () {
      final sinId = _sin(respuesta(factura()), {'id'}) as Map<String, dynamic>;

      expect(() => FacturaResponse.fromJson(sinId), throwsA(isA<TypeError>()));
    });
  });

  group('Notificaciones sin tags ni user_id', () {
    test('se parsean sin lanzar y conservan la campaña', () {
      final completo = {
        'no_leidas': 1,
        'data': [
          {
            'id': 31,
            'title': 'Pago confirmado',
            'message': 'Tu pago fue procesado.',
            'campania': 'pago',
            'fecha': '2026-09-10T17:47:39Z',
            'is_read': false,
            'tags': 'pago,colegiatura',
            'user_id': 820,
          },
        ],
      };
      final recortado =
          _sin(completo, {'tags', 'user_id'}) as Map<String, dynamic>;

      final n = NotificacionResponse.fromJson(recortado).data.single;

      expect(n.id, 31);
      expect(n.campania, 'pago');
      expect(n.isRead, isFalse);
    });
  });

  group('Login sin token_type ni datos de perfil', () {
    final completo = {
      ...TestAuthResponse.validJson,
      'token_type': 'Bearer',
    };

    test('sin token_type se entra igual', () {
      final r = AuthResponse.fromJson(
        _sin(completo, {'token_type'}) as Map<String, dynamic>,
      );

      expect(r.accessToken, TestAuthResponse.validJson['access_token']);
      expect(r.user.id, 1);
    });

    test('sin los datos de perfil se conserva lo que la app pinta', () {
      final r = AuthResponse.fromJson(
        _sin(completo, {'token_type', ..._camposPerfil})
            as Map<String, dynamic>,
      );

      expect(r.user.nombre, 'Juan');
      expect(r.user.fullName, 'Juan Pérez García');
      expect(r.user.username, 'juanperez');
      expect(r.user.email, 'juan@ejemplo.com');
      expect(r.apiVersion, '1.0.0');
      expect(r.appVersion, '1.0.0');
    });

    test('la sesión guardada sin perfil se vuelve a leer al arrancar', () {
      final r = AuthResponse.fromJson(
        _sin(completo, _camposPerfil) as Map<String, dynamic>,
      );

      // La sesión se persiste con toJson y se relee con fromJson en el splash.
      final releida = AuthResponse.fromJson(r.toJson());

      expect(releida.user.nombre, 'Juan');
      expect(releida.accessToken, r.accessToken);
    });
  });
}
