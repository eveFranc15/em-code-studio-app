// Smoke test de la app EM Code Studio.
//
// Verifica que la aplicación arranca en el SplashScreen, reproduce su
// animación de entrada y luego navega al Login después del temporizador.
//
// NOTA: la app usa `FondoAnimado`, que tiene animaciones infinitas (nubes,
// estrellas y partículas). Por eso NO se puede usar `pumpAndSettle()`,
// que esperaría a que todo se detenga y nunca lo haría; en su lugar se
// avanza el reloj de pruebas con duraciones fijas.

import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/login_screen.dart';
import 'package:flutter_application_1/main.dart';

void main() {
  testWidgets('La app muestra el splash y luego navega al login',
      (WidgetTester tester) async {
    // Construye la app y dispara el primer frame.
    await tester.pumpWidget(const CrmApp());

    // El splash debe estar visible de entrada.
    expect(find.byType(SplashScreen), findsOneWidget);

    // Deja correr la animación de entrada del splash (1.5 s).
    await tester.pump(const Duration(milliseconds: 1600));
    expect(find.byType(SplashScreen), findsOneWidget);

    // Pasa el temporizador de 3 s → debe navegar al Login.
    await tester.pump(const Duration(seconds: 3));
    // Deja terminar la transición de salida del splash.
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(SplashScreen), findsNothing);
  });
}
