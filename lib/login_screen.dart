import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';
import 'main.dart';
import 'animaciones_svg.dart';
import 'cliente_portal_screen.dart';
import 'database_helper.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usuarioCtrl = TextEditingController();
  final _contrasenaCtrl = TextEditingController();
  bool _ocultarContrasena = true;
  bool _cargando = false;

  @override
  void dispose() {
    _usuarioCtrl.dispose();
    _contrasenaCtrl.dispose();
    super.dispose();
  }

  void _iniciarSesion() {
    FocusScope.of(context).unfocus();
    setState(() => _cargando = true);
    _validarAcceso();
  }

  /// Autenticación con Supabase Auth para todos los usuarios:
  /// 1) valida el correo y la contraseña en el SERVIDOR de Supabase
  ///    (antes ya no se comparan claves guardadas en el dispositivo);
  /// 2) si el usuario tiene rol "admin", abre el menú de gestión;
  /// 3) si es un cliente, recupera su ficha de la tabla `clientes`
  ///    y abre su panel de seguimiento.
  Future<void> _validarAcceso() async {
    final usuario = _usuarioCtrl.text.trim().toLowerCase();
    final contrasena = _contrasenaCtrl.text;

    // 1) Validación centralizada en Supabase Auth
    try {
      final respuesta = await SupabaseConfig.client.auth
          .signInWithPassword(email: usuario, password: contrasena);
      final usuarioAutenticado = respuesta.user;
      if (usuarioAutenticado == null) {
        throw Exception('Usuario o contraseña incorrectos');
      }

      // 2) Administrador: abre el menú principal de gestión
      final esAdmin =
          usuarioAutenticado.userMetadata?['rol'] == 'admin';
      if (esAdmin) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
        return;
      }

      // 3) Cliente: se busca su ficha por el correo con el que entró,
      //    únicamente el que le pertenece a esa dirección de correo.
      final cliente = await DatabaseHelper().obtenerClientePorEmail(usuario);
      if (cliente != null) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ClientePortalScreen(cliente: cliente),
          ),
        );
        return;
      }

      // Autenticado pero sin ficha de cliente: se cierra la sesión
      // para no dejar abierta una sesión sin datos.
      await SupabaseConfig.client.auth.signOut();
      if (!mounted) return;
      setState(() => _cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'El usuario no tiene ficha de cliente en el estudio'),
          backgroundColor: Color(0xFFF39C12),
        ),
      );
      return;
    } on AuthException catch (e) {
      // Error real de Supabase Auth (contraseña incorrecta, usuario
      // inexistente, etc.). No se revela cuál de los dos falló.
      if (!mounted) return;
      setState(() => _cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message == 'Invalid login credentials'
              ? 'Usuario o contraseña incorrectos'
              : 'Error de acceso: ${e.message}'),
          backgroundColor: const Color(0xFFE74C3C),
        ),
      );
      return;
    } catch (e) {
      // Fallo de conexión u otro error inesperado.
      if (!mounted) return;
      setState(() => _cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo conectar: $e'),
          backgroundColor: const Color(0xFFE74C3C),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D12),
      body: FondoAnimado(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF0D0D12),
                const Color(0xFF16161D),
              ],
            ),
          ),
          child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF33FF99).withValues(alpha: 0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF33FF99).withValues(alpha: 0.2),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: const Color(0xFF16161D),
                            child: const Icon(
                              Icons.code,
                              size: 40,
                              color: Color(0xFF33FF99),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'EM CODE STUDIO',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                      color: Color(0xFFF4F4F6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Inicia sesión para continuar',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF8888A0),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Campo Usuario
                  TextField(
                    controller: _usuarioCtrl,
                    style: const TextStyle(color: Color(0xFFF4F4F6)),
                    decoration: InputDecoration(
                      hintText: 'Usuario / Correo',
                      hintStyle: const TextStyle(color: Color(0xFF8888A0)),
                      prefixIcon: const Icon(Icons.person, color: Color(0xFF33FF99)),
                      filled: true,
                      fillColor: const Color(0xFF1A1A24),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF33FF99), width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Campo Contraseña
                  TextField(
                    controller: _contrasenaCtrl,
                    obscureText: _ocultarContrasena,
                    style: const TextStyle(color: Color(0xFFF4F4F6)),
                    decoration: InputDecoration(
                      hintText: 'Contraseña',
                      hintStyle: const TextStyle(color: Color(0xFF8888A0)),
                      prefixIcon: const Icon(Icons.lock, color: Color(0xFF33FF99)),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _ocultarContrasena ? Icons.visibility : Icons.visibility_off,
                          color: const Color(0xFF8888A0),
                        ),
                        onPressed: () => setState(() => _ocultarContrasena = !_ocultarContrasena),
                      ),
                      filled: true,
                      fillColor: const Color(0xFF1A1A24),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF33FF99), width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Botón Ingresar
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _cargando ? null : _iniciarSesion,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF33FF99),
                        foregroundColor: const Color(0xFF0D0D12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _cargando
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF0D0D12),
                              ),
                            )
                          : const Text(
                              'INGRESAR',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Administradores y clientes ingresan con su CORREO y contraseña',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Color(0xFF8888A0)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
    );
  }
}
