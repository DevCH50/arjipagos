/// Tests unitarios para BannerInfo y BannersResponse.
///
/// Blindan el parseo de la respuesta de `/api/v1/banners` ante cambios del
/// contrato. Lo más delicado es `cuerpo_formato`: si llegara un valor nuevo y
/// el enum lo tratara como desconocido dejando el cuerpo vacío, la nota se
/// abriría en blanco sin lanzar ningún error.
library;

import 'package:arjipagos/src/domain/models/banner/BannerInfo.dart';
import 'package:arjipagos/src/domain/models/banner/BannersResponse.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_data.dart';

void main() {
  group('BannerInfo.fromJson', () {
    test('parsea todos los campos de la respuesta real', () {
      final banner = BannerInfo.fromJson(TestBanner.anualidadJson);

      expect(banner.id, 1);
      expect(banner.titulo,
          'Se acaba el tiempo para el descuento especial por anualidad');
      expect(banner.imagenUrl, contains('arjipagos.moriah.mx'));
      expect(banner.fecha, '20-08-2026');
      expect(banner.cuerpo, contains('**25 de septiembre**'));
      expect(banner.formato, BannerFormato.markdown);
    });

    test('tieneImagen distingue el banner con portada del que no la trae', () {
      final conImagen = BannerInfo.fromJson(TestBanner.anualidadJson);
      final sinImagen = BannerInfo.fromJson(
        Map<String, dynamic>.from(TestBanner.anualidadJson)..['imagen_url'] = '',
      );

      expect(conImagen.tieneImagen, isTrue);
      expect(sinImagen.tieneImagen, isFalse);
    });

    test('reconoce cuerpo_formato html', () {
      final json = Map<String, dynamic>.from(TestBanner.anualidadJson)
        ..['cuerpo_formato'] = 'html';

      expect(BannerInfo.fromJson(json).formato, BannerFormato.html);
    });

    test('tolera cuerpo_formato en mayúsculas', () {
      final json = Map<String, dynamic>.from(TestBanner.anualidadJson)
        ..['cuerpo_formato'] = 'HTML';

      expect(BannerInfo.fromJson(json).formato, BannerFormato.html);
    });

    test('un cuerpo_formato desconocido cae a markdown, no deja la nota muda',
        () {
      final json = Map<String, dynamic>.from(TestBanner.anualidadJson)
        ..['cuerpo_formato'] = 'formato_del_futuro';

      expect(BannerInfo.fromJson(json).formato, BannerFormato.markdown);
    });

    test('un JSON sin claves no rompe el parseo', () {
      final banner = BannerInfo.fromJson(<String, dynamic>{});

      expect(banner.id, 0);
      expect(banner.titulo, '');
      expect(banner.imagenUrl, '');
      expect(banner.cuerpo, '');
      expect(banner.tieneImagen, isFalse);
    });

    test('acepta un id mandado como texto', () {
      final json = Map<String, dynamic>.from(TestBanner.anualidadJson)
        ..['id'] = '7';

      expect(BannerInfo.fromJson(json).id, 7);
    });

    test('fromJson y toJson son inversas', () {
      final banner = BannerInfo.fromJson(TestBanner.anualidadJson);
      final ida = banner.toJson();

      expect(BannerInfo.fromJson(ida).toJson(), equals(ida));
    });
  });

  group('BannersResponse.fromJson', () {
    test('parsea la lista completa de banners', () {
      final respuesta = BannersResponse.fromJson(TestBanner.respuestaJson);

      expect(respuesta.success, isTrue);
      expect(respuesta.message, 'OK');
      expect(respuesta.banners, hasLength(2));
      expect(respuesta.banners.first.id, 1);
      expect(respuesta.banners.last.id, 2);
    });

    test('una respuesta sin banners devuelve lista vacía', () {
      final respuesta = BannersResponse.fromJson(TestBanner.respuestaVaciaJson);

      expect(respuesta.banners, isEmpty);
    });

    test('una respuesta sin la clave banners no revienta', () {
      final respuesta = BannersResponse.fromJson({'success': true});

      expect(respuesta.banners, isEmpty);
      expect(respuesta.message, '');
    });

    test('ignora elementos que no son objetos dentro de banners', () {
      final respuesta = BannersResponse.fromJson({
        'success': true,
        'message': 'OK',
        'banners': [TestBanner.anualidadJson, 'basura', 42],
      });

      expect(respuesta.banners, hasLength(1));
    });
  });

  group('BannerInfo — fecha y novedad', () {
    /// Banner con la fecha que se le indique; lo demás no interviene aquí.
    BannerInfo conFecha(String fecha) => BannerInfo(
          id: 1,
          titulo: 'Aviso',
          imagenUrl: 'https://ejemplo.mx/a.jpg',
          fecha: fecha,
          cuerpo: 'cuerpo',
          formato: BannerFormato.markdown,
        );

    String formatear(DateTime dia) =>
        '${dia.day.toString().padLeft(2, '0')}-'
        '${dia.month.toString().padLeft(2, '0')}-${dia.year}';

    test('parsea el formato dd-MM-yyyy que manda el backend', () {
      // `DateTime.parse` reventaría con esto: espera yyyy-MM-dd.
      expect(conFecha('20-08-2026').fechaPublicacion, DateTime(2026, 8, 20));
    });

    test('una fecha con formato inesperado no revienta, devuelve null', () {
      expect(conFecha('2026/08/20').fechaPublicacion, isNull);
      expect(conFecha('ayer').fechaPublicacion, isNull);
      expect(conFecha('').fechaPublicacion, isNull);
    });

    test('un aviso de hoy es reciente', () {
      expect(conFecha(formatear(DateTime.now())).esReciente, isTrue);
    });

    test('un aviso dentro de la ventana de días es reciente', () {
      final dentro = DateTime.now()
          .subtract(const Duration(days: BannerInfo.diasReciente - 1));

      expect(conFecha(formatear(dentro)).esReciente, isTrue);
    });

    test('un aviso más viejo que la ventana ya no es reciente', () {
      final viejo = DateTime.now()
          .subtract(const Duration(days: BannerInfo.diasReciente + 1));

      expect(conFecha(formatear(viejo)).esReciente, isFalse);
    });

    test('una fecha futura no se marca como reciente', () {
      // Mejor no señalar nada que señalar de más si el backend se adelanta.
      final futuro = DateTime.now().add(const Duration(days: 3));

      expect(conFecha(formatear(futuro)).esReciente, isFalse);
    });

    test('una fecha ilegible no se marca como reciente', () {
      expect(conFecha('basura').esReciente, isFalse);
    });
  });
}
