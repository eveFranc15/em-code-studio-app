import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/login_screen.dart';

/// Pruebas del ACCESO UNIFICADO del login principal.
///
/// El docente recomendó que no exista un botón separado para el cliente:
/// administrador y cliente ingresan por el mismo formulario y la aplicación
/// decide el destino según las credenciales (primero valida al administrador
/// y luego busca al cliente en la base de datos).
///
/// NOTA: las pantallas usan `FondoAnimado` (nubes, estrellas y partículas),
/// que tiene animaciones **infinitas**. Por eso NO se puede usar
/// `pumpAndSettle()` (esperaría a que todo se detenga y nunca lo haría);
/// en su lugar avanzamos el reloj con duraciones fijas con [asentar].
void main() {
  void prepararPantalla(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  Future<void> asentar(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 500));
  }

  Future<void> abrirAcceso(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    await asentar(tester);
  }

  testWidgets('Con campos vacíos, INGRESAR muestra el error sin navegar',
      (tester) async {
    prepararPantalla(tester);
    await abrirAcceso(tester);

    await tester.tap(find.text('INGRESAR'));
    await asentar(tester);

    // Credenciales vacías → mensaje genérico y sigue en el acceso.
    expect(find.text('Usuario o contraseña incorrectos'), findsOneWidget);
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('Con credenciales incorrectas aparece el mensaje genérico',
      (tester) async {
    prepararPantalla(tester);
    await abrirAcceso(tester);

    await tester.enterText(find.byType(TextField).at(0), 'usuario inventado');
    await tester.enterText(find.byType(TextField).at(1), 'clave mala');
    await tester.tap(find.text('INGRESAR'));
    await asentar(tester);

    // El mensaje no revela si la cuenta existe ni cuál campo falló.
    expect(find.text('Usuario o contraseña incorrectos'), findsOneWidget);
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('El ojo de la contraseña oculta y muestra la clave',
      (tester) async {
    prepararPantalla(tester);
    await abrirAcceso(tester);

    // La contraseña inicia oculta.
    var campo = tester.widget<TextField>(find.byType(TextField).at(1));
    expect(campo.obscureText, isTrue);

    await tester.tap(find.byIcon(Icons.visibility));
    await tester.pump();

    campo = tester.widget<TextField>(find.byType(TextField).at(1));
    expect(campo.obscureText, isFalse);
  });

  testWidgets('El login es unificado: no existe botón separado de CLIENTE',
      (tester) async {
    prepararPantalla(tester);
    await abrirAcceso(tester);

    expect(find.text('INGRESAR'), findsOneWidget);
    expect(find.text('CLIENTE'), findsNothing);
    expect(find.byType(OutlinedButton), findsNothing);
  });

  testWidgets(
      'El texto de ayuda invita a administradores y clientes al mismo formulario',
      (tester) async {
    prepararPantalla(tester);
    await abrirAcceso(tester);

    expect(find.textContaining('Administradores y clientes'), findsOneWidget);
    expect(find.textContaining('usuario o correo'), findsOneWidget);
  });

  testWidgets('El login principal ya no muestra Volver ni NUEVO CLIENTE',
      (tester) async {
    prepararPantalla(tester);
    await abrirAcceso(tester);

    expect(find.text('← Volver'), findsNothing);
    expect(find.text('NUEVO CLIENTE'), findsNothing);
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
