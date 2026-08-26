/// Tests de concordancia de número en `TotalSeleccionadoBar`.
///
/// La barra construía la frase pluralizando solo el sustantivo y dejando el
/// participio fijo en plural, así que con un único pago seleccionado se leía
/// "1 pago seleccionados". Estos tests fijan la concordancia en singular y en
/// plural para que la fuga no vuelva.
library;

import 'package:arjipagos/src/core/theme/app_theme.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta/bloc/EdoCtaListBloc.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta/bloc/EdoCtaListEvent.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta/bloc/EdoCtaListState.dart';
import 'package:arjipagos/src/presentation/pages/edo_cta/widgets/total_seleccionado_bar.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_data.dart';

class MockEdoCtaListBloc extends MockBloc<EdoCtaListEvent, EdoCtaListState>
    implements EdoCtaListBloc {}

void main() {
  late MockEdoCtaListBloc bloc;

  setUp(() {
    bloc = MockEdoCtaListBloc();
  });

  /// Monta la barra con un estado que tenga [cantidad] pagos seleccionados.
  ///
  /// Los IDs son irrelevantes para la frase: `cantidadPagosSeleccionados` solo
  /// cuenta cuántos hay, así que basta con repartirlos en un ciclo y un alumno.
  Future<void> montar(
    WidgetTester tester, {
    required int cantidad,
    Brightness brillo = Brightness.light,
  }) async {
    // La barra cuenta los pagos del emisor que se está viendo, así que el
    // estado necesita los alumnos: con solo el mapa de selección no se puede
    // saber de qué emisor es cada pago.
    final ids = List<int>.generate(cantidad, (i) => i + 1);
    final estado = EdoCtaListState(
      alumnos: [alumnoConPagosPorCiclo(10, {1: ids})],
      pagosSeleccionados: {
        1: {10: ids},
      },
    );

    whenListen(
      bloc,
      const Stream<EdoCtaListState>.empty(),
      initialState: estado,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: brillo == Brightness.dark ? AppTheme.dark : AppTheme.light,
        home: Scaffold(
          body: BlocProvider<EdoCtaListBloc>.value(
            value: bloc,
            child: const TotalSeleccionadoBar(),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('TotalSeleccionadoBar — concordancia de número', () {
    testWidgets('con un pago va todo en singular', (tester) async {
      await montar(tester, cantidad: 1);

      expect(find.text('1 pago seleccionado'), findsOneWidget);
      // La forma incorrecta que motivó el arreglo.
      expect(find.text('1 pago seleccionados'), findsNothing);
    });

    testWidgets('con dos pagos va todo en plural', (tester) async {
      await montar(tester, cantidad: 2);

      expect(find.text('2 pagos seleccionados'), findsOneWidget);
    });

    testWidgets('sin pagos usa el plural', (tester) async {
      await montar(tester, cantidad: 0);

      expect(find.text('0 pagos seleccionados'), findsOneWidget);
    });

    testWidgets('la concordancia no depende del tema', (tester) async {
      await montar(tester, cantidad: 1, brillo: Brightness.dark);

      expect(find.text('1 pago seleccionado'), findsOneWidget);
    });
  });
}
