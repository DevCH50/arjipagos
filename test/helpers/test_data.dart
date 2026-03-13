/// Datos de prueba para los tests unitarios.
///
/// Contiene factories y datos mock para User, Alumno, AuthResponse y AlumnoResponse.
library;

import 'package:arjipagos/src/domain/models/Alumno.dart';
import 'package:arjipagos/src/domain/models/AlumnoResponse.dart';
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
  static EstadoDeCuenta get pendiente => EstadoDeCuenta(
        id: 1,
        descripcionCorta: 'Colegiatura Enero 2024',
        total: 5000.0,
        totalFormatted: '\$5,000.00',
        fechaVencimiento: '2024-01-31',
        estadoPago: EstadoPago.pendiente,
        numPago: 1,
        numPagoActivo: true,
        aceptaPagosDiversos: true,
        estaDisponibleEnInternet: true,
        facturaPdf: '',
        facturaXml: '',
      );

  static EstadoDeCuenta get vencido => EstadoDeCuenta(
        id: 2,
        descripcionCorta: 'Colegiatura Diciembre 2023',
        total: 4500.0,
        totalFormatted: '\$4,500.00',
        fechaVencimiento: '2023-12-31',
        estadoPago: EstadoPago.vencido,
        numPago: 2,
        numPagoActivo: false,
        aceptaPagosDiversos: true,
        estaDisponibleEnInternet: true,
        facturaPdf: '',
        facturaXml: '',
      );

  static List<EstadoDeCuenta> get lista => [pendiente, vencido];
}

/// Datos de prueba para Alumno.
class TestAlumno {
  static Alumno get activo => Alumno(
        alumnoId: 1,
        alumno: 'María López',
        becaSep: 'Sí',
        becaArji: 'No',
        becaBach: 'No',
        becaSp: 'No',
        esBaja: false,
        grupoId: 101,
        grupo: '3ro A',
        urlPhoto: 'https://example.com/maria.jpg',
        estadoDeCuenta: TestEstadoDeCuenta.lista,
      );

  static Alumno get baja => Alumno(
        alumnoId: 2,
        alumno: 'Pedro Sánchez',
        becaSep: 'No',
        becaArji: 'Sí',
        becaBach: 'No',
        becaSp: 'No',
        esBaja: true,
        grupoId: 102,
        grupo: '2do B',
        urlPhoto: '',
        estadoDeCuenta: [],
      );

  static Map<String, dynamic> get activoJson => {
        'alumno_id': 1,
        'alumno': 'María López',
        'beca_sep': 'Sí',
        'beca_arji': 'No',
        'beca_bach': 'No',
        'beca_sp': 'No',
        'es_baja': false,
        'grupo_id': 101,
        'grupo': '3ro A',
        'url_photo': 'https://example.com/maria.jpg',
        'estado_de_cuenta': [
          {
            'id': 1,
            'descripcion_corta': 'Colegiatura Enero 2024',
            'total': 5000.0,
            'total_formatted': '\$5,000.00',
            'fecha_vencimiento': '2024-01-31',
            'estadoPago': 'Pendiente',
            'num_pago': 1,
            'num_pago_activo': true,
            'acepta_pagos_diversos': true,
            'esta_disponible_en_internet': true,
            'factura_pdf': '',
            'factura_xml': '',
          },
          {
            'id': 2,
            'descripcion_corta': 'Colegiatura Diciembre 2023',
            'total': 4500.0,
            'total_formatted': '\$4,500.00',
            'fecha_vencimiento': '2023-12-31',
            'estadoPago': 'Vencido',
            'num_pago': 2,
            'num_pago_activo': false,
            'acepta_pagos_diversos': true,
            'esta_disponible_en_internet': true,
            'factura_pdf': '',
            'factura_xml': '',
          },
        ],
      };

  static Map<String, dynamic> get bajaJson => {
        'alumno_id': 2,
        'alumno': 'Pedro Sánchez',
        'beca_sep': 'No',
        'beca_arji': 'Sí',
        'beca_bach': 'No',
        'beca_sp': 'No',
        'es_baja': true,
        'grupo_id': 102,
        'grupo': '2do B',
        'url_photo': '',
        'estado_de_cuenta': [],
      };

  static List<Alumno> get lista => [activo, baja];

  static List<Map<String, dynamic>> get listaJson => [activoJson, bajaJson];
}

/// Datos de prueba para AuthResponse.
class TestAuthResponse {
  static AuthResponse get valid => AuthResponse(
        status: 200,
        msg: 'Login exitoso',
        accessToken: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.test',
        tokenType: 'Bearer',
        user: TestUser.valid,
        apiVersion: '1.0.0',
        appVersion: '1.0.0',
      );

  static Map<String, dynamic> get validJson => {
        'status': 200,
        'msg': 'Login exitoso',
        'access_token': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.test',
        'token_type': 'Bearer',
        'user': TestUser.validJson,
        'api_version': '1.0.0',
        'app_version': '1.0.0',
      };
}

/// Datos de prueba para AlumnoResponse.
class TestAlumnoResponse {
  static AlumnoResponse get valid => AlumnoResponse(
        familiaId: 1,
        familia: 'Familia López García',
        roleId: 2,
        cicloPredeterminadoId: 2024,
        cicloPredeterminado: '2024-2025',
        alumnos: TestAlumno.lista,
      );

  static AlumnoResponse get empty => AlumnoResponse(
        familiaId: 1,
        familia: 'Familia López García',
        roleId: 2,
        cicloPredeterminadoId: 2024,
        cicloPredeterminado: '2024-2025',
        alumnos: [],
      );

  static Map<String, dynamic> get validJson => {
        'familia_id': 1,
        'familia': 'Familia López García',
        'role_id': 2,
        'ciclo_predeterminado_id': 2024,
        'ciclo_predeterminado': '2024-2025',
        'alumnos': TestAlumno.listaJson,
      };

  static Map<String, dynamic> get emptyJson => {
        'familia_id': 1,
        'familia': 'Familia López García',
        'role_id': 2,
        'ciclo_predeterminado_id': 2024,
        'ciclo_predeterminado': '2024-2025',
        'alumnos': [],
      };
}
