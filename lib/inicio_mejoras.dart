import 'package:flutter/material.dart';

// ============================================================
//  MEJORAS DE LA PANTALLA DE INICIO (aditivas)
//  - BannerLogoEmpresa: cuadro elegante con el logo y
//    chispitas que suben (particulas suaves).
//  - CintaServicios: carrusel que se desliza solo con las
//    4 categorias de servicio (imagenes reales de trabajos).
//
//  IMPORTANTE: para cambiar el nombre del administrador,
//  edita SOLO la constante nombreAdministrador de abajo.
// ============================================================

/// Nombre que aparece en el saludo de la pantalla de inicio.
/// Si el administrador cambia, se edita esta linea unicamente.
const String nombreAdministrador = 'Evelin';

/// Devuelve el saludo segun la hora del dia (D + A).
String saludoSegunHora() {
  final hora = DateTime.now().hour;
  if (hora < 12) return 'Buenos dias';
  if (hora < 19) return 'Buenas tardes';
  return 'Buenas noches';
}

// ============ BANNER CON EL LOGO + CHISPAS ============
class BannerLogoEmpresa extends StatefulWidget {
  const BannerLogoEmpresa({super.key});

  @override
  State<BannerLogoEmpresa> createState() => _BannerLogoEmpresaState();
}

class _BannerLogoEmpresaState extends State<BannerLogoEmpresa>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;

  // Cada chispa: posicion horizontal (fraccion del ancho), tamano,
  // retardo y color.
  static const List<Map<String, Object>> _chispas = [
    {'x': 0.12, 'tamano': 5.0, 'retardo': 0.0, 'lila': false},
    {'x': 0.30, 'tamano': 4.0, 'retardo': 0.3, 'lila': true},
    {'x': 0.50, 'tamano': 6.0, 'retardo': 0.55, 'lila': false},
    {'x': 0.70, 'tamano': 4.0, 'retardo': 0.15, 'lila': true},
    {'x': 0.88, 'tamano': 5.0, 'retardo': 0.42, 'lila': false},
  ];

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4500),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      width: double.infinity, // Ocupa todo el ancho disponible
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF221A3D), Color(0xFF120F1E)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFB388FF).withValues(alpha: 0.3)),
      ),
      child: LayoutBuilder(
        builder: (context, limites) {
          // Ancho real del banner para posicionar las chispas.
          final anchoBanner = limites.maxWidth;
          return ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Logo de la empresa
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.workspace_premium,
                          color: Color(0xFFB388FF), size: 60);
                    },
                  ),
                ),
                // Chispitas que suben (particulas suaves)
                ..._chispas.map((chispa) {
                  final inicio = (chispa['retardo'] as double);
                  final lila = chispa['lila'] as bool;
                  final x = anchoBanner * (chispa['x'] as double);
                  return Positioned(
                    left: x,
                    bottom: 0,
                    child: AnimatedBuilder(
                      animation: _c,
                      builder: (context, child) {
                        // Avance de la chispa desfasado por su retardo.
                        var t = (_c.value - inicio) % 1.0;
                        if (t < 0) t += 1.0;
                        final opacidad = t < 0.15
                            ? t / 0.15
                            : (t > 0.85 ? (1.0 - t) / 0.15 : 1.0);
                        return Opacity(
                          opacity: (opacidad * 0.45).clamp(0.0, 1.0),
                          child: Transform.translate(
                            offset: Offset(0, -t * 200),
                            child: child,
                          ),
                        );
                      },
                      child: Container(
                        width: chispa['tamano'] as double,
                        height: chispa['tamano'] as double,
                        decoration: BoxDecoration(
                          color: lila
                              ? const Color(0xFFB388FF)
                              : const Color(0xFF33FF99),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ============ CINTA DE SERVICIOS EN MOVIMIENTO ============
class CintaServicios extends StatefulWidget {
  const CintaServicios({super.key});

  @override
  State<CintaServicios> createState() => _CintaServiciosState();
}

class _CintaServiciosState extends State<CintaServicios>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;

  static const double _anchoTarjeta = 165;
  static const double _separacion = 12;
  // La mitad de la cinta (las 4 tarjetas + sus separaciones).
  static const double _recorrido =
      4 * _anchoTarjeta + 4 * _separacion;

  static const List<Map<String, String>> _servicios = [
    {
      'imagen': 'assets/images/servicios/servicio_web.jpg',
      'nombre': 'Paginas Web',
      'precio': 'Desde S/ 500',
      'color': '0xFF33FF99',
    },
    {
      'imagen': 'assets/images/servicios/servicio_ventas.jpg',
      'nombre': 'Sistemas de Venta',
      'precio': 'Desde S/ 800',
      'color': '0xFFB388FF',
    },
    {
      'imagen': 'assets/images/servicios/servicio_apps.jpg',
      'nombre': 'Apps Moviles',
      'precio': 'Desde S/ 1,500',
      'color': '0xFFF39C12',
    },
    {
      'imagen': 'assets/images/servicios/servicio_soporte.jpg',
      'nombre': 'Soporte y Mantenimiento',
      'precio': 'Desde S/ 300',
      'color': '0xFF5DADE2',
    },
  ];

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 22),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _tarjeta(Map<String, String> s, {required bool particulasLila}) {
    final color = Color(int.parse(s['color']!));
    return Container(
      width: _anchoTarjeta,
      height: 200,
      margin: const EdgeInsets.only(right: _separacion),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        color: const Color(0xFF15151D),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Imagen real del trabajo
          Image.asset(
            s['imagen']!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: const Color(0xFF1A1A24),
                child: Icon(Icons.image, color: color, size: 40),
              );
            },
          ),
          // Velo oscuro para que el nombre se lea siempre
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.35, 0.62, 1.0],
                colors: [
                  Colors.transparent,
                  Color(0x730A0A10),
                  Color(0xEC0A0A10),
                ],
              ),
            ),
          ),
          // Particulas que suben dentro de la tarjeta
          ...List.generate(3, (i) {
            final x = 0.2 + i * 0.3;
            return Positioned(
              left: _anchoTarjeta * x,
              bottom: 0,
              child: AnimatedBuilder(
                animation: _c,
                builder: (context, child) {
                  var t = (_c.value - i * 0.22) % 1.0;
                  if (t < 0) t += 1.0;
                  final opacidad =
                      t < 0.15 ? t / 0.15 : (t > 0.85 ? (1 - t) / 0.15 : 1.0);
                  return Opacity(
                    opacity: (opacidad * 0.5).clamp(0.0, 1.0),
                    child: Transform.translate(
                      offset: Offset(0, -t * 190),
                      child: Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: particulasLila
                              ? const Color(0xFFB388FF)
                              : const Color(0xFF33FF99),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          }),
          // Nombre del servicio + precio (siempre legibles)
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s['nombre']!,
                  maxLines: 2,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  s['precio']!,
                  style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 3,
                  width: 34,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, limites) {
        // Ventana visible: maximo 4 tarjetas (mas ancho en celulares
        // angostos, centrado en pantallas grandes como la laptop).
        final anchoCuatro =
            4 * _anchoTarjeta + 3 * _separacion;
        final anchoVisible =
            limites.maxWidth < anchoCuatro ? limites.maxWidth : anchoCuatro;
        return Center(
          child: SizedBox(
            width: anchoVisible,
            height: 200,
            child: ClipRect(
              child: AnimatedBuilder(
                animation: _c,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(-_c.value * _recorrido, 0),
                    child: child,
                  );
                },
                // OverflowBox: le dice a Flutter que la fila ES mas ancha
                // a proposito (es una cinta que se desliza), sin avisos.
                child: OverflowBox(
                  alignment: Alignment.centerLeft,
                  minWidth: 0,
                  maxWidth: double.infinity,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final s in _servicios)
                        _tarjeta(s, particulasLila: false),
                      // Duplicadas para que el bucle se vea continuo
                      for (final s in _servicios)
                        _tarjeta(s, particulasLila: true),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
