/// Tests unitarios para TicketBloc.
///
/// Verifican la secuencia de estados de la descarga del ticket y que un error
/// del caso de uso llegue a la pantalla como mensaje legible, nunca como
/// excepción cruda.
library;

import 'package:arjipagos/src/core/constants/app_strings.dart';
import 'package:arjipagos/src/domain/utils/Resource.dart' as utils;
import 'package:arjipagos/src/presentation/pages/ticket/bloc/TicketBloc.dart';
import 'package:arjipagos/src/presentation/pages/ticket/bloc/TicketEvent.dart';
import 'package:arjipagos/src/presentation/pages/ticket/bloc/TicketState.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';

const String _url =
    'https://arjipagos.moriah.mx/api/v1/tickets/a7064b3b-a517-4636-95da-c5b2cdcd19ff/print';
const String _folio = 'T7672';
const String _ruta = '/tmp/ticket_T7672.pdf';

void main() {
  late MockDescargarTicketUseCase mockDescargarTicket;
  late TicketBloc bloc;

  setUp(() {
    mockDescargarTicket = MockDescargarTicketUseCase();
    bloc = TicketBloc(
      createMockTicketUseCases(descargarTicket: mockDescargarTicket),
    );
  });

  tearDown(() async {
    await bloc.close();
  });

  group('TicketBloc — estado inicial', () {
    test('arranca sin archivo, sin carga y sin error', () {
      expect(bloc.state.rutaArchivo, '');
      expect(bloc.state.tieneArchivo, isFalse);
      expect(bloc.state.isLoading, isFalse);
      expect(bloc.state.errorMessage, isNull);
    });
  });

  group('TicketBloc — TicketDescargarEvent', () {
    blocTest<TicketBloc, TicketState>(
      'emite carga y luego la ruta del PDF descargado',
      build: () {
        when(() => mockDescargarTicket.run(_url, _folio))
            .thenAnswer((_) async => utils.Success(_ruta));
        return bloc;
      },
      act: (b) => b.add(const TicketDescargarEvent(url: _url, folio: _folio)),
      expect: () => [
        const TicketState(folio: _folio, url: _url, isLoading: true),
        const TicketState(
          rutaArchivo: _ruta,
          folio: _folio,
          url: _url,
          isLoading: false,
        ),
      ],
    );

    blocTest<TicketBloc, TicketState>(
      'conserva la URL en el estado para poder reintentar',
      build: () {
        when(() => mockDescargarTicket.run(_url, _folio))
            .thenAnswer((_) async => utils.Error<String>(AppStrings.errorTimeout));
        return bloc;
      },
      act: (b) => b.add(const TicketDescargarEvent(url: _url, folio: _folio)),
      verify: (b) {
        expect(b.state.url, _url);
        expect(b.state.folio, _folio);
      },
    );

    blocTest<TicketBloc, TicketState>(
      'emite el mensaje de error del caso de uso sin archivo',
      build: () {
        when(() => mockDescargarTicket.run(_url, _folio)).thenAnswer(
            (_) async => utils.Error<String>(AppStrings.ticketSesionExpirada));
        return bloc;
      },
      act: (b) => b.add(const TicketDescargarEvent(url: _url, folio: _folio)),
      verify: (b) {
        expect(b.state.errorMessage, AppStrings.ticketSesionExpirada);
        expect(b.state.tieneArchivo, isFalse);
        expect(b.state.isLoading, isFalse);
      },
    );

    blocTest<TicketBloc, TicketState>(
      'una excepción inesperada nunca llega cruda al estado',
      build: () {
        when(() => mockDescargarTicket.run(_url, _folio))
            .thenThrow(Exception('fallo interno del repositorio'));
        return bloc;
      },
      act: (b) => b.add(const TicketDescargarEvent(url: _url, folio: _folio)),
      verify: (b) {
        expect(b.state.isLoading, isFalse);
        expect(b.state.errorMessage, isNotNull);
        expect(b.state.errorMessage, isNot(contains('Exception')));
      },
    );

    blocTest<TicketBloc, TicketState>(
      'un segundo intento limpia el archivo y el error del intento anterior',
      build: () {
        when(() => mockDescargarTicket.run(_url, _folio))
            .thenAnswer((_) async => utils.Success(_ruta));
        return bloc;
      },
      seed: () => const TicketState(
        rutaArchivo: '/tmp/viejo.pdf',
        folio: _folio,
        url: _url,
        errorMessage: 'error anterior',
      ),
      act: (b) => b.add(const TicketDescargarEvent(url: _url, folio: _folio)),
      verify: (b) {
        expect(b.state.rutaArchivo, _ruta);
        expect(b.state.errorMessage, isNull);
      },
    );
  });
}
