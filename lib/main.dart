import 'package:flutter/material.dart';
import 'dart:async';
import 'modelos.dart';
import 'database_helper.dart';
import 'supabase_config.dart';
import 'animaciones_svg.dart';
import 'animaciones_web.dart';
import 'login_screen.dart';
import 'estadisticas_screen.dart';
import 'clientes_screen.dart';
import 'configuracion_screen.dart';
import 'proyecto_form_screen.dart';
import 'servicios_gestion_screen.dart';
import 'trabajos_categoria_screen.dart';
import 'inicio_mejoras.dart';
import 'boleta_pdf.dart';
import 'pdf_actions.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();
  runApp(const CrmApp());
}

// Colores de la marca EM Code Studio
class AppColores {
  static const verde = Color(0xFF33FF99);
  static const lila = Color(0xFFB388FF);
  static const fondoOscuro = Color(0xFF0D0D12);
  static const fondoSuave = Color(0xFF16161D);
  static const tarjeta = Color(0xFF1A1A24);
  static const texto = Color(0xFFF4F4F6);
  static const textoTenue = Color(0xFF8888A0);
  static const rojo = Color(0xFFE74C3C);
  static const naranja = Color(0xFFF39C12);
  static const azul = Color(0xFF3498DB);
}

class CrmApp extends StatelessWidget {
  const CrmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EM Code Studio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: AppColores.verde,
        scaffoldBackgroundColor: AppColores.fondoOscuro,
        colorScheme: const ColorScheme.dark(
          primary: AppColores.verde,
          secondary: AppColores.lila,
          surface: AppColores.tarjeta,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColores.fondoOscuro,
          foregroundColor: AppColores.texto,
          elevation: 0,
          centerTitle: true,
        ),
        cardTheme: CardThemeData(
          color: AppColores.tarjeta,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColores.verde,
          foregroundColor: AppColores.fondoOscuro,
        ),
        // Transiciones tipo app nativa: cada pantalla nueva entra
        // deslizandose hacia adelante (estilo Android/iOS moderno).
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: FadeForwardsPageTransitionsBuilder(),
            TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
            TargetPlatform.macOS: FadeForwardsPageTransitionsBuilder(),
            TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
          },
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

// ==================== SPLASH SCREEN ====================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacidad;
  late Animation<double> _escala;
  /// Temporizador del splash; se guarda para poder cancelarlo si el
  /// usuario cierra la pantalla antes de los 3 segundos.
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _opacidad = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _escala = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();

    _timer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColores.fondoOscuro,
      body: FondoAnimado(
        child: Center(
          child: FadeTransition(
            opacity: _opacidad,
            child: ScaleTransition(
              scale: _escala,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo con efecto glow
                  Container(
                    width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColores.verde.withValues(alpha: 0.3), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColores.verde.withValues(alpha: 0.2),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppColores.fondoSuave,
                          child: const Icon(Icons.code, size: 60, color: AppColores.verde),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  'EM CODE STUDIO',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                    color: AppColores.texto,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Soluciones Digitales',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColores.textoTenue,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: 200,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      backgroundColor: AppColores.texto.withValues(alpha: 0.1),
                      color: AppColores.verde,
                      minHeight: 4,
                    ),
                  ),
                ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== PANTALLA PRINCIPAL CON NAVEGACIÓN ====================
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _indiceActual = 0;

  List<Widget> _getPantallas() {
    return [
      InicioScreen(onChangeTab: (index) => setState(() => _indiceActual = index)),
      const ProyectosScreen(),
      const ServiciosScreen(),
      const ClientesScreen(),
      const PerfilScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FondoAnimado(
        // Transicion suave al cambiar de pestana (tipo app nativa).
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animacion) =>
              FadeTransition(opacity: animacion, child: child),
          child: KeyedSubtree(
            key: ValueKey<int>(_indiceActual),
            child: _getPantallas()[_indiceActual],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColores.fondoSuave,
          border: Border(top: BorderSide(color: AppColores.texto.withValues(alpha: 0.1))),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Row(
              children: [
                Expanded(child: _buildNavItem(0, Icons.home, 'Inicio')),
                Expanded(child: _buildNavItem(1, Icons.work, 'Proyectos')),
                Expanded(child: _buildNavItem(2, Icons.build, 'Servicios')),
                Expanded(child: _buildNavItem(3, Icons.people, 'Clientes')),
                Expanded(child: _buildNavItem(4, Icons.person, 'Perfil')),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int indice, IconData icono, String etiqueta) {
    final seleccionado = _indiceActual == indice;
    return GestureDetector(
      onTap: () => setState(() => _indiceActual = indice),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        decoration: BoxDecoration(
          color: seleccionado ? AppColores.verde.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icono,
              color: seleccionado ? AppColores.verde : AppColores.textoTenue,
              size: 24,
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                etiqueta,
                maxLines: 1,
                style: TextStyle(
                  color: seleccionado ? AppColores.verde : AppColores.textoTenue,
                  fontSize: 11,
                  fontWeight: seleccionado ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== PANTALLA DE INICIO ====================
class InicioScreen extends StatefulWidget {
  final Function(int)? onChangeTab;

  const InicioScreen({super.key, this.onChangeTab});

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

/// Servicios que ofrece el estudio. Se usa en la pestaña "Servicios"
/// y también para contar el indicador del tablero, así ambos siempre
/// muestran el mismo número.
final List<Map<String, dynamic>> serviciosCatalogo = [
  {'nombre': 'Páginas Web', 'descripcion': 'Sitios modernos, rápidos y responsive', 'precio': 'S/ 500', 'icono': Icons.web, 'color': AppColores.verde},
  {'nombre': 'Sistemas de Venta', 'descripcion': 'Controla ventas, inventario y clientes', 'precio': 'S/ 800', 'icono': Icons.shopping_cart, 'color': AppColores.lila},
  {'nombre': 'Apps Móviles', 'descripcion': 'Aplicaciones iOS y Android a tu medida', 'precio': 'S/ 1500', 'icono': Icons.phone_android, 'color': AppColores.naranja},
  {'nombre': 'Soporte y Mantenimiento', 'descripcion': 'Mantenimiento y actualizaciones', 'precio': 'S/ 300', 'icono': Icons.support_agent, 'color': AppColores.azul},
];

class _InicioScreenState extends State<InicioScreen> {
  // Estadísticas reales cargadas desde Supabase
  int _totalProyectos = 0;
  int _totalClientes = 0;
  int _totalServicios = 0;
  double _montoCobrado = 0;
  bool _cargandoEstadisticas = true;

  String _formatoSoles(double valor) {
    final entero = valor.round().toString();
    final texto = StringBuffer();
    for (int i = 0; i < entero.length; i++) {
      if (i > 0 && (entero.length - i) % 3 == 0) texto.write(',');
      texto.write(entero[i]);
    }
    return 'S/ $texto';
  }

  @override
  void initState() {
    super.initState();
    _cargarEstadisticas();
  }

  /// Cuenta los servicios ofreciendo los del catálogo más los que se
  /// registren desde la app, sin repetir ninguno (se comparan por nombre).
  int _contarServicios(List<Map<String, dynamic>> guardados) {
    final nombres = <String>{};
    for (final s in serviciosCatalogo) {
      nombres.add(s['nombre'].toString().trim().toLowerCase());
    }
    for (final s in guardados) {
      final nombre = s['nombre']?.toString().trim().toLowerCase() ?? '';
      if (nombre.isNotEmpty) nombres.add(nombre);
    }
    return nombres.length;
  }

  Future<void> _cargarEstadisticas() async {
    final db = DatabaseHelper();
    final proyectos = await db.obtenerProyectos();
    final clientes = await db.obtenerClientes();
    final servicios = await db.obtenerServicios();
    if (!mounted) return;
    setState(() {
      _totalProyectos = proyectos.length;
      _totalClientes = clientes.length;
      _totalServicios = _contarServicios(servicios);
      _montoCobrado = proyectos.fold<double>(0, (suma, p) => suma + p.montoPagado);
      _cargandoEstadisticas = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${saludoSegunHora()}, $nombreAdministrador 👋',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColores.texto,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Tu mundo tecnológico en un solo lugar',
                        style: TextStyle(fontSize: 13, color: AppColores.textoTenue),
                      ),
                    ],
                  ),
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColores.verde.withValues(alpha: 0.3)),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.code, color: AppColores.verde);
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Banner con el logo de la empresa + chispitas (nuevo)
              const BannerLogoEmpresa(),
              const SizedBox(height: 16),
              // Titulo de la cinta de servicios (nuevo)
              const Text(
                'NUESTROS SERVICIOS ⟶',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  color: AppColores.textoTenue,
                ),
              ),
              const SizedBox(height: 10),
              // Cinta de servicios con imagenes reales, se desliza sola (nuevo)
              const CintaServicios(),
              const SizedBox(height: 20),
              // Cabecera tecnológica animada (red de datos)
              const BannerTecnologico(
                motivo: MotivoTecnologico.red,
                titulo: 'CENTRO DE CONTROL',
                subtitulo: 'Todo tu negocio en un solo lugar',
              ),
              const SizedBox(height: 20),
              // Hero card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColores.verde.withValues(alpha: 0.1), AppColores.lila.withValues(alpha: 0.05)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColores.verde.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColores.verde.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '⚡ Desarrollo Profesional',
                        style: TextStyle(color: AppColores.verde, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Creamos tu presencia digital desde cero',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColores.texto,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Páginas web modernas, sistemas de venta y soluciones tecnológicas para tu negocio.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColores.textoTenue,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              // Estadísticas
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      _cargandoEstadisticas ? '…' : '$_totalProyectos',
                      'Proyectos',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      _cargandoEstadisticas ? '…' : '$_totalClientes',
                      'Clientes',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      _cargandoEstadisticas ? '…' : '$_totalServicios',
                      'Servicios',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Resumen económico real (Supabase)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A24),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColores.verde.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Monto cobrado', style: TextStyle(fontSize: 13, color: AppColores.textoTenue)),
                    Text(
                      _cargandoEstadisticas ? '…' : _formatoSoles(_montoCobrado),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColores.verde,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              // Acciones rápidas
              const Text(
                'ACCIONES RÁPIDAS',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColores.textoTenue,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      context,
                      Icons.add_circle_outline,
                      'Nuevo Proyecto',
                      AppColores.verde,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ProyectoFormScreen()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionCard(
                      context,
                      Icons.people,
                      'Clientes',
                      AppColores.lila,
                      () {
                        widget.onChangeTab?.call(3);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      context,
                      Icons.analytics,
                      'Reportes',
                      AppColores.azul,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const EstadisticasScreen()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionCard(
                      context,
                      Icons.settings,
                      'Configuración',
                      AppColores.naranja,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ConfiguracionScreen()),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String numero, String etiqueta) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColores.tarjeta,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColores.texto.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Text(
            numero,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColores.verde,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            etiqueta,
            style: TextStyle(fontSize: 12, color: AppColores.textoTenue),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, IconData icono, String titulo, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColores.tarjeta,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icono, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              titulo,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== PANTALLA DE PROYECTOS ====================
class ProyectosScreen extends StatefulWidget {
  const ProyectosScreen({super.key});

  @override
  State<ProyectosScreen> createState() => _ProyectosScreenState();
}

class _ProyectosScreenState extends State<ProyectosScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final TextEditingController _busquedaCtrl = TextEditingController();
  List<Proyecto> proyectos = [];
  List<Proyecto> proyectosFiltrados = [];
  bool _cargando = true;
  EstadoProyecto? _filtroEstado;
  String _ordenarPor = 'fecha'; // fecha, monto, nombre

  @override
  void initState() {
    super.initState();
    _cargarProyectos();
    _busquedaCtrl.addListener(_filtrarProyectos);
  }

  @override
  void dispose() {
    _busquedaCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarProyectos() async {
    setState(() => _cargando = true);
    final lista = await _dbHelper.obtenerProyectos();
    print('Proyectos cargados: ${lista.length}');
    if (lista.isNotEmpty) {
      print('Primer proyecto: ${lista.first.nombreProyecto}');
    }
    setState(() {
      proyectos = lista;
      proyectosFiltrados = lista;
      _cargando = false;
    });
  }

  void _filtrarProyectos() {
    final query = _busquedaCtrl.text.toLowerCase();
    setState(() {
      proyectosFiltrados = proyectos.where((p) {
        final coincideBusqueda = query.isEmpty ||
            p.nombreProyecto.toLowerCase().contains(query) ||
            p.cliente.nombre.toLowerCase().contains(query) ||
            p.tipoServicio.toLowerCase().contains(query);
        final coincideEstado = _filtroEstado == null || p.estado == _filtroEstado;
        return coincideBusqueda && coincideEstado;
      }).toList();
      _ordenarProyectos();
    });
  }

  void _ordenarProyectos() {
    switch (_ordenarPor) {
      case 'fecha':
        proyectosFiltrados.sort((a, b) => b.fechaEntrega.compareTo(a.fechaEntrega));
        break;
      case 'monto':
        proyectosFiltrados.sort((a, b) => b.montoTotal.compareTo(a.montoTotal));
        break;
      case 'nombre':
        proyectosFiltrados.sort((a, b) => a.nombreProyecto.compareTo(b.nombreProyecto));
        break;
    }
  }

  Future<void> _eliminarProyecto(int id) async {
    await _dbHelper.eliminarProyecto(id);
    _cargarProyectos();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Proyecto eliminado')),
      );
    }
  }

  /// Ventana de confirmación previa a eliminar un proyecto.
  ///
  /// Se muestra al deslizar la tarjeta: devuelve `true` solo cuando el
  /// usuario pulsa "ELIMINAR". Si elige "CANCELAR" (o cierra la ventana),
  /// la tarjeta regresa a su lugar y NO se borra nada.
  Future<bool> _confirmarEliminacionProyecto(Proyecto proyecto) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(
          Icons.warning_amber_rounded,
          color: Color(0xFFF39C12),
          size: 40,
        ),
        title: const Text(
          '¿Eliminar proyecto?',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFFF4F4F6),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Vas a eliminar el proyecto "${proyecto.nombreProyecto}" y su '
          'información. Esta acción no se puede deshacer.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF8888A0), fontSize: 14, height: 1.4),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'CANCELAR',
              style: TextStyle(
                color: Color(0xFF8888A0),
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE74C3C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text(
              'ELIMINAR',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
          ),
        ],
      ),
    );
    return confirmado ?? false;
  }

  Color _colorEstado(EstadoProyecto estado) {
    switch (estado) {
      case EstadoProyecto.pendiente:
        return AppColores.naranja;
      case EstadoProyecto.enProceso:
        return AppColores.lila;
      case EstadoProyecto.terminado:
        return AppColores.verde;
    }
  }

  Widget _buildFilterChip(String label, bool seleccionado, VoidCallback onTap, {Color? color}) {
    final chipColor = color ?? AppColores.textoTenue;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: seleccionado ? chipColor.withValues(alpha: 0.2) : AppColores.tarjeta,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: seleccionado ? chipColor : AppColores.textoTenue.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: seleccionado ? chipColor : AppColores.textoTenue,
            fontSize: 12,
            fontWeight: seleccionado ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Proyectos'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort, color: AppColores.verde),
            onSelected: (valor) {
              setState(() => _ordenarPor = valor);
              _filtrarProyectos();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'fecha', child: Text('Ordenar por fecha')),
              const PopupMenuItem(value: 'monto', child: Text('Ordenar por monto')),
              const PopupMenuItem(value: 'nombre', child: Text('Ordenar por nombre')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarProyectos,
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: AppColores.verde))
          : Column(
              children: [
                // Barra de búsqueda
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    controller: _busquedaCtrl,
                    decoration: InputDecoration(
                      hintText: 'Buscar por proyecto, cliente o servicio...',
                      prefixIcon: const Icon(Icons.search, color: AppColores.verde),
                      suffixIcon: _busquedaCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: AppColores.textoTenue),
                              onPressed: () {
                                _busquedaCtrl.clear();
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: AppColores.tarjeta,
                    ),
                  ),
                ),
                // Filtros por estado
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      _buildFilterChip('Todos', _filtroEstado == null, () {
                        setState(() => _filtroEstado = null);
                        _filtrarProyectos();
                      }),
                      const SizedBox(width: 8),
                      _buildFilterChip('Pendiente', _filtroEstado == EstadoProyecto.pendiente, () {
                        setState(() => _filtroEstado = EstadoProyecto.pendiente);
                        _filtrarProyectos();
                      }, color: AppColores.naranja),
                      const SizedBox(width: 8),
                      _buildFilterChip('En Proceso', _filtroEstado == EstadoProyecto.enProceso, () {
                        setState(() => _filtroEstado = EstadoProyecto.enProceso);
                        _filtrarProyectos();
                      }, color: AppColores.lila),
                      const SizedBox(width: 8),
                      _buildFilterChip('Terminado', _filtroEstado == EstadoProyecto.terminado, () {
                        setState(() => _filtroEstado = EstadoProyecto.terminado);
                        _filtrarProyectos();
                      }, color: AppColores.verde),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Lista de proyectos
                Expanded(
                  child: proyectos.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.folder_open, size: 80, color: AppColores.textoTenue),
                              const SizedBox(height: 16),
                              Text(
                                'No hay proyectos aún',
                                style: TextStyle(fontSize: 18, color: AppColores.textoTenue),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Toca + para agregar uno',
                                style: TextStyle(fontSize: 14, color: AppColores.textoTenue),
                              ),
                            ],
                          ),
                        )
                      : proyectosFiltrados.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.search_off, size: 80, color: AppColores.textoTenue),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No se encontraron resultados',
                                    style: TextStyle(fontSize: 18, color: AppColores.textoTenue),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Intenta con otra búsqueda',
                                    style: TextStyle(fontSize: 14, color: AppColores.textoTenue),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _cargarProyectos,
                              color: AppColores.verde,
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                itemCount: proyectosFiltrados.length,
                                itemBuilder: (context, index) {
                                  final proyecto = proyectosFiltrados[index];
                                  return Dismissible(
                                    key: Key(proyecto.id.toString()),
                                    direction: DismissDirection.endToStart,
                                    // Pide confirmación antes de borrar: un
                                    // desliz accidental NO elimina el proyecto.
                                    confirmDismiss: (_) =>
                                        _confirmarEliminacionProyecto(proyecto),
                                    background: Container(
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.only(right: 20),
                                      margin: const EdgeInsets.only(bottom: 12),
                                      decoration: BoxDecoration(
                                        color: AppColores.rojo.withValues(alpha: 0.8),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Icon(Icons.delete, color: Colors.white, size: 30),
                                    ),
                                    onDismissed: (_) => _eliminarProyecto(proyecto.id!),
                                    child: Card(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(16),
                                        onTap: () async {
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => DetalleProyectoScreen(proyecto: proyecto),
                                            ),
                                          );
                                          _cargarProyectos();
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              if (proyecto.imagenUrl != null)
                                                ClipRRect(
                                                  borderRadius: BorderRadius.circular(12),
                                                  child: Image.network(
                                                    proyecto.imagenUrl!,
                                                    height: 120,
                                                    width: double.infinity,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return Container(
                                                        height: 120,
                                                        width: double.infinity,
                                                        color: AppColores.fondoSuave,
                                                        child: const Icon(Icons.broken_image, size: 40, color: AppColores.textoTenue),
                                                      );
                                                    },
                                                  ),
                                                ),
                                              if (proyecto.imagenUrl != null) const SizedBox(height: 12),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      proyecto.nombreProyecto,
                                                      style: const TextStyle(
                                                        fontSize: 18,
                                                        fontWeight: FontWeight.bold,
                                                        color: AppColores.texto,
                                                      ),
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: _colorEstado(proyecto.estado).withValues(alpha: 0.15),
                                                      borderRadius: BorderRadius.circular(20),
                                                      border: Border.all(
                                                        color: _colorEstado(proyecto.estado).withValues(alpha: 0.5),
                                                      ),
                                                    ),
                                                    child: Text(
                                                      proyecto.estado.name,
                                                      style: TextStyle(
                                                        color: _colorEstado(proyecto.estado),
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  const Icon(Icons.person, size: 16, color: AppColores.textoTenue),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    proyecto.cliente.nombre,
                                                    style: const TextStyle(color: AppColores.textoTenue),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  const Icon(Icons.phone, size: 16, color: AppColores.textoTenue),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    proyecto.cliente.telefono,
                                                    style: const TextStyle(color: AppColores.textoTenue),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 12),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      const Text('Monto total', style: TextStyle(fontSize: 11, color: AppColores.textoTenue)),
                                                      Text(
                                                        formatearSoles(proyecto.montoTotal),
                                                        style: const TextStyle(
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.bold,
                                                          color: AppColores.verde,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  Column(
                                                    crossAxisAlignment: CrossAxisAlignment.end,
                                                    children: [
                                                      const Text('Saldo pendiente', style: TextStyle(fontSize: 11, color: AppColores.textoTenue)),
                                                      Text(
                                                        formatearSoles(proyecto.saldoPendiente),
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.bold,
                                                          color: proyecto.saldoPendiente > 0 ? AppColores.naranja : AppColores.verde,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProyectoFormScreen()),
          );
          _cargarProyectos();
        },
        icon: const Icon(Icons.add),
        label: const Text('Nuevo'),
      ),
    );
  }
}

// ==================== PANTALLA DE SERVICIOS ====================
class ServiciosScreen extends StatelessWidget {
  const ServiciosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final servicios = serviciosCatalogo;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Servicios')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: servicios.length,
        itemBuilder: (context, index) {
          final servicio = servicios[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TrabajosCategoriaScreen(categoria: servicio['nombre'] as String),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: (servicio['color'] as Color).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: (servicio['color'] as Color).withValues(alpha: 0.3)),
                      ),
                      child: Icon(servicio['icono'] as IconData, color: servicio['color'] as Color, size: 30),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            servicio['nombre'] as String,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            servicio['descripcion'] as String,
                            style: TextStyle(color: AppColores.textoTenue, fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                servicio['precio'] as String,
                                style: TextStyle(
                                  color: servicio['color'] as Color,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 14,
                                color: (servicio['color'] as Color),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ServiciosGestionScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Gestionar'),
        backgroundColor: AppColores.verde,
        foregroundColor: AppColores.fondoOscuro,
      ),
    );
  }
}

// ==================== PANTALLA DE PERFIL ====================
class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  Empresa _empresa = Empresa();

  @override
  void initState() {
    super.initState();
    _cargarEmpresa();
  }

  /// Los datos del estudio se leen de la tabla `empresa`, que se
  /// edita desde Configuración (dirección, foto y coordenadas GPS).
  Future<void> _cargarEmpresa() async {
    final e = await _db.obtenerEmpresa();
    if (mounted) {
      setState(() => _empresa = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String direccion =
        (_empresa.direccion != null && _empresa.direccion!.trim().isNotEmpty)
            ? _empresa.direccion!
            : 'Lima, Perú';
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Perfil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColores.verde.withValues(alpha: 0.3), width: 3),
                boxShadow: [
                  BoxShadow(
                    color: AppColores.verde.withValues(alpha: 0.2),
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
                      color: AppColores.fondoSuave,
                      child: const Icon(Icons.code, size: 50, color: AppColores.verde),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'EM CODE STUDIO',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2),
            ),
            const SizedBox(height: 8),
            Text(
              'Soluciones Digitales',
              style: TextStyle(color: AppColores.textoTenue, fontSize: 14),
            ),
            const SizedBox(height: 30),
            // Información
            _buildInfoCard(Icons.email, 'Email', 'info@emcodestudio.com'),
            _buildInfoCard(Icons.phone, 'Teléfono', '+51 947 872 446'),
            _buildInfoCard(Icons.location_on, 'Ubicación', direccion),
            _buildInfoCard(Icons.language, 'Web', 'www.emcodestudio.com'),
            const SizedBox(height: 30),
            // Redes sociales
            const Text(
              'SÍGUENOS',
              style: TextStyle(fontSize: 12, color: AppColores.textoTenue, letterSpacing: 2),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSocialButton(Icons.facebook, AppColores.azul),
                const SizedBox(width: 16),
                _buildSocialButton(Icons.camera_alt, AppColores.rojo),
                const SizedBox(width: 16),
                _buildSocialButton(Icons.chat, AppColores.verde),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(IconData icono, String etiqueta, String valor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icono, color: AppColores.verde),
        title: Text(etiqueta, style: const TextStyle(fontSize: 12, color: AppColores.textoTenue)),
        subtitle: Text(valor, style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  Widget _buildSocialButton(IconData icono, Color color) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Icon(icono, color: color),
    );
  }
}

// ==================== DETALLE DEL PROYECTO ====================
class DetalleProyectoScreen extends StatefulWidget {
  final Proyecto proyecto;

  const DetalleProyectoScreen({super.key, required this.proyecto});

  @override
  State<DetalleProyectoScreen> createState() => _DetalleProyectoScreenState();
}

class _DetalleProyectoScreenState extends State<DetalleProyectoScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  final TextEditingController _mensajeCtrl = TextEditingController();
  late Proyecto _proyecto;
  List<NotaProyecto> _notas = [];
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    _proyecto = widget.proyecto;
    _cargarNotas();
  }

  @override
  void dispose() {
    _mensajeCtrl.dispose();
    super.dispose();
  }

  /// Carga la caja de mensajes del proyecto desde Supabase.
  Future<void> _cargarNotas() async {
    final id = _proyecto.id;
    if (id == null) return;
    final lista = await _db.obtenerNotas(id);
    if (mounted) setState(() => _notas = lista);
  }

  /// Al volver de "Editar" vuelve a consultar Supabase para que la
  /// pantalla muestre los cambios recién guardados (antes quedaban
  /// los datos viejos en memoria aunque se hubieran guardado bien).
  Future<void> _editarProyecto() async {
    final guardado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ProyectoFormScreen(proyecto: _proyecto),
      ),
    );
    if (guardado == true && _proyecto.id != null) {
      final actualizado = await _db.obtenerProyecto(_proyecto.id!);
      if (actualizado != null && mounted) {
        setState(() => _proyecto = actualizado);
      }
      await _cargarNotas();
    }
  }

  /// Envía una nota del estudio; el cliente la verá en su panel.
  Future<void> _enviarNota() async {
    final texto = _mensajeCtrl.text.trim();
    if (texto.isEmpty || _proyecto.id == null || _enviando) return;
    setState(() => _enviando = true);
    final ok = await _db.agregarNota(_proyecto.id!, 'estudio', texto);
    if (ok) {
      _mensajeCtrl.clear();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo enviar: falta crear la tabla en Supabase'),
          backgroundColor: Color(0xFFE74C3C),
        ),
      );
    }
    if (mounted) setState(() => _enviando = false);
    await _cargarNotas();
  }

  @override
  Widget build(BuildContext context) {
    // Versión más reciente del proyecto (recargada de la base de datos).
    final proyecto = _proyecto;
    return Scaffold(
      appBar: AppBar(
        title: Text(proyecto.nombreProyecto),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editarProyecto,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen del proyecto
            if (proyecto.imagenUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  proyecto.imagenUrl!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColores.fondoSuave,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.broken_image, size: 60, color: AppColores.textoTenue),
                    );
                  },
                ),
              ),
            if (proyecto.imagenUrl != null) const SizedBox(height: 16),
            // Tarjeta de información del cliente
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('CLIENTE', style: TextStyle(fontSize: 12, color: AppColores.textoTenue, letterSpacing: 2)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.person, color: AppColores.verde),
                        const SizedBox(width: 8),
                        Text(proyecto.cliente.nombre, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.phone, color: AppColores.verde),
                        const SizedBox(width: 8),
                        Text(proyecto.cliente.telefono, style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Tarjeta de detalles del proyecto
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('DETALLES DEL PROYECTO', style: TextStyle(fontSize: 12, color: AppColores.textoTenue, letterSpacing: 2)),
                    const SizedBox(height: 12),
                    _buildRow('Servicio', proyecto.tipoServicio),
                    _buildRow('Estado', proyecto.estado.name),
                    _buildRow('Fecha de entrega', '${proyecto.fechaEntrega.day}/${proyecto.fechaEntrega.month}/${proyecto.fechaEntrega.year}'),
                    _buildRow('Tipo de pago', proyecto.tipoPago.name),
                    _buildRow('Estado de pago', proyecto.estadoPago.name),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // ===== Ultimo mensaje del cliente: visible sin abrir la caja =====
            if (proyecto.id != null)
              FutureBuilder<List<NotaProyecto>>(
                future: _db.obtenerNotas(proyecto.id!),
                builder: (context, snap) {
                  final lista = snap.data ?? const <NotaProyecto>[];
                  final delCliente = lista.where((n) => !n.esEstudio).toList();
                  if (delCliente.isEmpty) return const SizedBox.shrink();
                  final ultima = delCliente.last;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF9B7BFF).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: const Color(0xFF9B7BFF).withValues(alpha: 0.5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.phone_in_talk,
                                color: Color(0xFF9B7BFF), size: 14),
                            SizedBox(width: 6),
                            Text(
                              'MENSAJE DEL CLIENTE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF9B7BFF),
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          ultima.mensaje,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFFE4E4F0),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            // Tarjeta financiera
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('INFORMACIÓN FINANCIERA', style: TextStyle(fontSize: 12, color: AppColores.textoTenue, letterSpacing: 2)),
                    const SizedBox(height: 12),
                    _buildRow('Monto total', formatearSoles(proyecto.montoTotal)),
                    _buildRow('Monto pagado', formatearSoles(proyecto.montoPagado)),
                    _buildRow('Saldo pendiente', formatearSoles(proyecto.saldoPendiente)),
                  ],
                ),
              ),
            ),
            if (proyecto.notas.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('NOTAS', style: TextStyle(fontSize: 12, color: AppColores.textoTenue, letterSpacing: 2)),
                      const SizedBox(height: 12),
                      Text(proyecto.notas, style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ],
            // ===== CAJA DE MENSAJES CON EL CLIENTE =====
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'MENSAJES CON EL CLIENTE',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColores.textoTenue,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_notas.isEmpty)
                      const Text(
                        'Aún no hay mensajes. Escribe una nota y el cliente '
                        'la verá en su panel.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColores.textoTenue,
                        ),
                      ),
                    ..._notas.map(_burbujaNota),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _mensajeCtrl,
                            minLines: 1,
                            maxLines: 3,
                            style: const TextStyle(fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Escribe una nota para el cliente...',
                              hintStyle: const TextStyle(
                                fontSize: 13,
                                color: AppColores.textoTenue,
                              ),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _enviando ? null : _enviarNota,
                          icon: const Icon(Icons.send, color: AppColores.verde),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // ===== GENERAR BOLETA =====
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => PdfActions.mostrarOpciones(
                  context,
                  titulo: 'BOLETA DE VENTA',
                  subtitulo:
                      '${proyecto.nombreProyecto} · ${formatearSoles(proyecto.montoTotal)}',
                  nombreArchivo:
                      'Boleta_EMCodeStudio_${proyecto.id ?? proyecto.nombreProyecto}',
                  generar: () => BoletaPdf.generar(proyecto),
                ),
                icon: const Icon(Icons.receipt_long),
                label: const Text(
                  'GENERAR BOLETA (PDF)',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF33FF99),
                  foregroundColor: const Color(0xFF0D0D12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// Burbuja de un mensaje de la caja (verde = estudio, azul = cliente).
  Widget _burbujaNota(NotaProyecto n) {
    final esEstudio = n.esEstudio;
    final color = esEstudio ? AppColores.verde : AppColores.azul;
    final fecha = n.creadoEn.toLocal();
    final hora =
        '${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                esEstudio ? 'ESTUDIO (tú)' : 'CLIENTE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: color,
                ),
              ),
              Text(
                '${fecha.day}/${fecha.month}/${fecha.year} · $hora',
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColores.textoTenue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(n.mensaje, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColores.textoTenue)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
