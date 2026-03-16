// Test de widget: DefaultTextField
//
// Este archivo contiene los tests de widget para DefaultTextField,
// un componente de entrada de texto personalizado con soporte para:
// - Label e ícono prefix
// - Texto de error personalizable
// - Modo de contraseña con toggle de visibilidad
// - Callback onChanged
// - Validador opcional

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arjipagos/src/presentation/widgets/DefaultTextField.dart';

void main() {
  // Función auxiliar para envolver el widget en MaterialApp
  // Necesario para que el widget tenga acceso al contexto de Material
  Widget buildTestableWidget({
    required String label,
    required IconData icon,
    String? errorText,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    required Function(String) onChanged,
    String? Function(String?)? validator,
  }) {
    return MaterialApp(
      home: Scaffold(
        // Fondo oscuro para simular el contexto real del widget
        backgroundColor: Colors.black,
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: DefaultTextField(
            label: label,
            icon: icon,
            errorText: errorText,
            obscureText: obscureText,
            keyboardType: keyboardType,
            onChanged: onChanged,
            validator: validator,
          ),
        ),
      ),
    );
  }

  group('DefaultTextField - Tests de renderizado básico', () {
    testWidgets('Renderiza con el label correcto', (WidgetTester tester) async {
      // Arrange: Preparamos el widget con un label específico
      const testLabel = 'Correo electrónico';

      await tester.pumpWidget(
        buildTestableWidget(
          label: testLabel,
          icon: Icons.email,
          onChanged: (_) {},
        ),
      );

      // Assert: Verificamos que el label se muestra correctamente
      expect(find.text(testLabel), findsOneWidget);
    });

    testWidgets('Muestra el ícono prefix correctamente', (WidgetTester tester) async {
      // Arrange: Preparamos el widget con un ícono específico
      const testIcon = Icons.person;

      await tester.pumpWidget(
        buildTestableWidget(
          label: 'Usuario',
          icon: testIcon,
          onChanged: (_) {},
        ),
      );

      // Assert: Verificamos que el ícono se renderiza
      expect(find.byIcon(testIcon), findsOneWidget);
    });
  });

  group('DefaultTextField - Tests de interacción', () {
    testWidgets('Llama onChanged cuando el texto cambia', (WidgetTester tester) async {
      // Arrange: Variable para capturar el valor del callback
      String capturedText = '';

      await tester.pumpWidget(
        buildTestableWidget(
          label: 'Nombre',
          icon: Icons.person,
          onChanged: (text) {
            capturedText = text;
          },
        ),
      );

      // Act: Ingresamos texto en el campo
      const inputText = 'Juan Pérez';
      await tester.enterText(find.byType(TextFormField), inputText);
      await tester.pump();

      // Assert: Verificamos que el callback fue llamado con el texto correcto
      expect(capturedText, equals(inputText));
    });

    testWidgets('onChanged se llama con cada cambio de texto', (WidgetTester tester) async {
      // Arrange: Lista para capturar todas las llamadas al callback
      final List<String> capturedTexts = [];

      await tester.pumpWidget(
        buildTestableWidget(
          label: 'Búsqueda',
          icon: Icons.search,
          onChanged: (text) {
            capturedTexts.add(text);
          },
        ),
      );

      // Act: Ingresamos texto caracter por caracter
      await tester.enterText(find.byType(TextFormField), 'A');
      await tester.pump();
      await tester.enterText(find.byType(TextFormField), 'AB');
      await tester.pump();
      await tester.enterText(find.byType(TextFormField), 'ABC');
      await tester.pump();

      // Assert: Verificamos que se capturaron todas las llamadas
      expect(capturedTexts.length, equals(3));
      expect(capturedTexts.last, equals('ABC'));
    });
  });

  group('DefaultTextField - Tests de error', () {
    testWidgets('Muestra errorText cuando se proporciona', (WidgetTester tester) async {
      // Arrange: Preparamos el widget con un mensaje de error
      const errorMessage = 'El correo electrónico no es válido';

      await tester.pumpWidget(
        buildTestableWidget(
          label: 'Email',
          icon: Icons.email,
          errorText: errorMessage,
          onChanged: (_) {},
        ),
      );

      // Assert: Verificamos que el mensaje de error se muestra
      expect(find.text(errorMessage), findsOneWidget);
    });

    testWidgets('No muestra error cuando errorText es null', (WidgetTester tester) async {
      // Arrange: Widget sin mensaje de error
      await tester.pumpWidget(
        buildTestableWidget(
          label: 'Nombre completo',
          icon: Icons.text_fields,
          errorText: null,
          onChanged: (_) {},
        ),
      );

      // Assert: Verificamos que no hay texto de error visible
      // El InputDecoration no muestra ningún texto de error cuando errorText es null
      // Verificamos que un mensaje de error específico no aparece
      expect(find.textContaining('no es válido'), findsNothing);
      expect(find.textContaining('requerido'), findsNothing);
    });
  });

  group('DefaultTextField - Tests de contraseña', () {
    testWidgets('Oculta texto cuando obscureText=true', (WidgetTester tester) async {
      // Arrange: Widget configurado para contraseña
      await tester.pumpWidget(
        buildTestableWidget(
          label: 'Contraseña',
          icon: Icons.lock,
          obscureText: true,
          onChanged: (_) {},
        ),
      );

      // Act: Ingresamos una contraseña
      await tester.enterText(find.byType(TextFormField), 'miContraseña123');
      await tester.pump();

      // Assert: Verificamos que el EditableText tiene obscureText activo
      // TextFormField internamente usa EditableText que expone obscureText
      final editableText = tester.widget<EditableText>(find.byType(EditableText));
      expect(editableText.obscureText, isTrue);
    });

    testWidgets('Muestra ícono de visibilidad cuando obscureText=true', (WidgetTester tester) async {
      // Arrange: Widget configurado para contraseña
      await tester.pumpWidget(
        buildTestableWidget(
          label: 'Contraseña',
          icon: Icons.lock,
          obscureText: true,
          onChanged: (_) {},
        ),
      );

      // Assert: Verificamos que el ícono de visibilidad está presente
      // Inicialmente debe mostrar el ícono de "mostrar" (visibility_outlined)
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    });

    testWidgets('Toggle de visibilidad de contraseña funciona', (WidgetTester tester) async {
      // Arrange: Widget configurado para contraseña
      await tester.pumpWidget(
        buildTestableWidget(
          label: 'Contraseña',
          icon: Icons.lock,
          obscureText: true,
          onChanged: (_) {},
        ),
      );

      // Estado inicial: texto oculto, ícono de "mostrar"
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off_outlined), findsNothing);

      // Act: Hacemos tap en el botón de toggle
      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pump();

      // Assert: Ahora el ícono debe cambiar a "ocultar"
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
      expect(find.byIcon(Icons.visibility_outlined), findsNothing);

      // Act: Hacemos tap nuevamente para volver al estado original
      await tester.tap(find.byIcon(Icons.visibility_off_outlined));
      await tester.pump();

      // Assert: El ícono vuelve a "mostrar"
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off_outlined), findsNothing);
    });

    testWidgets('No muestra ícono de visibilidad cuando obscureText=false', (WidgetTester tester) async {
      // Arrange: Widget normal (no contraseña)
      await tester.pumpWidget(
        buildTestableWidget(
          label: 'Nombre',
          icon: Icons.person,
          obscureText: false,
          onChanged: (_) {},
        ),
      );

      // Assert: No debe haber ícono de visibilidad
      expect(find.byIcon(Icons.visibility_outlined), findsNothing);
      expect(find.byIcon(Icons.visibility_off_outlined), findsNothing);
    });

    testWidgets('Tooltip del botón de visibilidad cambia correctamente', (WidgetTester tester) async {
      // Arrange: Widget configurado para contraseña
      await tester.pumpWidget(
        buildTestableWidget(
          label: 'Contraseña',
          icon: Icons.lock,
          obscureText: true,
          onChanged: (_) {},
        ),
      );

      // Estado inicial: tooltip debe ser "Mostrar contraseña"
      final iconButtonInitial = tester.widget<IconButton>(find.byType(IconButton));
      expect(iconButtonInitial.tooltip, equals('Mostrar contraseña'));

      // Act: Toggle de visibilidad
      await tester.tap(find.byType(IconButton));
      await tester.pump();

      // Assert: tooltip debe ser "Ocultar contraseña"
      final iconButtonAfter = tester.widget<IconButton>(find.byType(IconButton));
      expect(iconButtonAfter.tooltip, equals('Ocultar contraseña'));
    });
  });

  group('DefaultTextField - Tests de keyboardType', () {
    testWidgets('Aplica keyboardType de email correctamente', (WidgetTester tester) async {
      // Arrange: Widget con teclado de email
      await tester.pumpWidget(
        buildTestableWidget(
          label: 'Email',
          icon: Icons.email,
          keyboardType: TextInputType.emailAddress,
          onChanged: (_) {},
        ),
      );

      // Assert: Verificamos que el keyboardType se aplica
      // Accedemos al EditableText que expone keyboardType
      final editableText = tester.widget<EditableText>(find.byType(EditableText));
      expect(editableText.keyboardType, equals(TextInputType.emailAddress));
    });

    testWidgets('Aplica keyboardType numérico correctamente', (WidgetTester tester) async {
      // Arrange: Widget con teclado numérico
      await tester.pumpWidget(
        buildTestableWidget(
          label: 'Teléfono',
          icon: Icons.phone,
          keyboardType: TextInputType.phone,
          onChanged: (_) {},
        ),
      );

      // Assert: Verificamos que el keyboardType se aplica
      final editableText = tester.widget<EditableText>(find.byType(EditableText));
      expect(editableText.keyboardType, equals(TextInputType.phone));
    });

    testWidgets('Usa keyboardType de texto por defecto', (WidgetTester tester) async {
      // Arrange: Widget sin especificar keyboardType
      await tester.pumpWidget(
        buildTestableWidget(
          label: 'Nombre',
          icon: Icons.person,
          onChanged: (_) {},
        ),
      );

      // Assert: Debe usar TextInputType.text por defecto
      final editableText = tester.widget<EditableText>(find.byType(EditableText));
      expect(editableText.keyboardType, equals(TextInputType.text));
    });
  });

  group('DefaultTextField - Tests de estilos de error', () {
    testWidgets('Aplica estilos de error personalizados', (WidgetTester tester) async {
      // Arrange: Widget con estilos de error personalizados
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DefaultTextField(
              label: 'Campo con error',
              icon: Icons.error,
              errorText: 'Error personalizado',
              errorColor: Colors.red,
              errorFontSize: 16.0,
              errorFontWeight: FontWeight.bold,
              errorWithShadow: false,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      // Assert: Verificamos que el error se muestra
      expect(find.text('Error personalizado'), findsOneWidget);
    });
  });

  group('DefaultTextField - Tests de validador', () {
    testWidgets('Ejecuta el validador cuando se proporciona', (WidgetTester tester) async {
      // Arrange: Variable para verificar si el validador fue llamado
      bool validatorCalled = false;
      String? validatorValue;

      final formKey = GlobalKey<FormState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: formKey,
              child: DefaultTextField(
                label: 'Campo validado',
                icon: Icons.check,
                onChanged: (_) {},
                validator: (value) {
                  validatorCalled = true;
                  validatorValue = value;
                  if (value == null || value.isEmpty) {
                    return 'Este campo es requerido';
                  }
                  return null;
                },
              ),
            ),
          ),
        ),
      );

      // Act: Validamos el formulario
      formKey.currentState!.validate();
      await tester.pump();

      // Assert: El validador fue llamado
      expect(validatorCalled, isTrue);
      expect(validatorValue, equals(''));

      // Verificamos que se muestra el mensaje de error del validador
      expect(find.text('Este campo es requerido'), findsOneWidget);
    });

    testWidgets('Validador retorna null cuando el campo es válido', (WidgetTester tester) async {
      // Arrange
      final formKey = GlobalKey<FormState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: formKey,
              child: DefaultTextField(
                label: 'Campo validado',
                icon: Icons.check,
                onChanged: (_) {},
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Este campo es requerido';
                  }
                  return null;
                },
              ),
            ),
          ),
        ),
      );

      // Act: Ingresamos texto válido y validamos
      await tester.enterText(find.byType(TextFormField), 'Texto válido');
      await tester.pump();

      final isValid = formKey.currentState!.validate();
      await tester.pump();

      // Assert: El formulario es válido
      expect(isValid, isTrue);
      expect(find.text('Este campo es requerido'), findsNothing);
    });
  });
}
