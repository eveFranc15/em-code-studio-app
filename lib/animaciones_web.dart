import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// ============================================================
/// ANIMACIONES WEB → FLUTTER
/// Réplica en la app de las animaciones de la página web
/// EM Code Studio (animaciones.js / animaciones.css):
///
///  - NubesSVG .............. nubes derivando (crearNubes / cloudDrift)
///  - EstrellasAnimadas ..... estrellas titilando (intro-star / starTwinkle)
///  - ParticulasAscendentes . luces lentas subiendo (slow-light / particleUp)
///  - ApareceAnimado ........ entradas al hacer scroll (AOS / fadeUp)
///  - ContadorAnimado ....... números que cuentan (hstat-num / RF04)
/// ============================================================

// ============ 1. NUBES SVG DERIVANTES ============
// Estilo hero de la web: capas de nubes que se mueven lentamente
// a distintas velocidades (efecto de profundidad).
class NubesSVG extends StatefulWidget {
  final int cantidad;
  /// Multiplicador general de opacidad (0.0 a 1.0)
  final double intensidad;

  const NubesSVG({super.key, this.cantidad = 3, this.intensidad = 1.0});

  @override
  State<NubesSVG> createState() => _NubesSVGState();
}

class _Nube {
  final double desfase;
  final double amplitud;
  final double opacidad;
  final double nivel; // 0 = más abajo
  final double velocidad;
  const _Nube({
    required this.desfase,
    required this.amplitud,
    required this.opacidad,
    required this.nivel,
    required this.velocidad,
  });
}

class _NubesSVGState extends State<NubesSVG> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  final _rand = math.Random(2026);
  late final List<_Nube> _nubes;

  // Opacidades del sitio web: 0.10, 0.07, 0.05
  static const _opacidades = [0.10, 0.07, 0.05];

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 30))
      ..repeat();
    _nubes = List.generate(widget.cantidad, (i) {
      return _Nube(
        desfase: _rand.nextDouble() * math.pi * 2,
        amplitud: 22 + _rand.nextDouble() * 28,
        opacidad: _opacidades[i % _opacidades.length] * widget.intensidad,
        nivel: i.toDouble(),
        velocidad: 1.0 + i * 0.35, // capas más altas se mueven más rápido
      );
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  // SVG de nube (mismo trazado que la página web)
  static const String _svgNube = '''
<svg viewBox="0 0 400 120" xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="none">
  <defs>
    <linearGradient id="nubeGrad" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="#FFFFFF" stop-opacity="0.85"/>
      <stop offset="100%" stop-color="#FFFFFF" stop-opacity="0"/>
    </linearGradient>
  </defs>
  <ellipse cx="200" cy="90" rx="180" ry="60" fill="url(#nubeGrad)"/>
  <ellipse cx="120" cy="70" rx="100" ry="50" fill="url(#nubeGrad)"/>
  <ellipse cx="290" cy="75" rx="110" ry="45" fill="url(#nubeGrad)"/>
  <ellipse cx="60"  cy="85" rx="70"  ry="40" fill="url(#nubeGrad)"/>
  <ellipse cx="340" cy="88" rx="65"  ry="38" fill="url(#nubeGrad)"/>
</svg>''';

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final ancho = constraints.maxWidth;
          return AnimatedBuilder(
            animation: _c,
            builder: (context, child) {
              return Stack(
                children: _nubes.map((n) {
                  final t = _c.value * 2 * math.pi * n.velocidad + n.desfase;
                  final dx = math.sin(t) * n.amplitud;
                  final altoNube = 130.0 + n.nivel * 35;
                  return Positioned(
                    bottom: -18.0 + n.nivel * 14,
                    left: -ancho * 0.08,
                    child: Transform.translate(
                      offset: Offset(dx, 0),
                      child: Opacity(
                        opacity: n.opacidad,
                        child: SvgPicture.string(
                          _svgNube,
                          width: ancho * 1.2,
                          height: altoNube,
                          fit: BoxFit.fill,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          );
        },
      ),
    );
  }
}

// ============ 2. ESTRELLAS TITILANDO ============
class EstrellasAnimadas extends StatefulWidget {
  final int cantidad;
  const EstrellasAnimadas({super.key, this.cantidad = 45});

  @override
  State<EstrellasAnimadas> createState() => _EstrellasAnimadasState();
}

class _EstrellasAnimadasState extends State<EstrellasAnimadas>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  final _rand = math.Random(7);
  late final List<List<double>> _estrellas; // [x, y, radio, fase]

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 6))
      ..repeat();
    _estrellas = List.generate(widget.cantidad, (i) {
      return [
        _rand.nextDouble(),
        _rand.nextDouble(),
        0.6 + _rand.nextDouble() * 1.4, // 0.5..2.5 px
        _rand.nextDouble() * math.pi * 2,
      ];
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) {
          return CustomPaint(
            painter: _EstrellasPainter(progress: _c.value, estrellas: _estrellas),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _EstrellasPainter extends CustomPainter {
  final double progress;
  final List<List<double>> estrellas;
  _EstrellasPainter({required this.progress, required this.estrellas});

  @override
  void paint(Canvas canvas, Size size) {
    for (final e in estrellas) {
      final x = e[0] * size.width;
      final y = e[1] * size.height;
      final r = e[2];
      final fase = e[3];
      // Titileo: 0.15 .. 0.7
      final alpha = 0.15 +
          (0.55 * (0.5 + 0.5 * math.sin((progress + fase) * 2 * math.pi)));
      final paint = Paint()
        ..color = const Color(0xFF33FF99).withValues(alpha: alpha * 0.6)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), r, paint);
      // Punto blanco central
      canvas.drawCircle(
        Offset(x, y),
        r * 0.5,
        Paint()..color = Colors.white.withValues(alpha: alpha),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ============ 3. PARTÍCULAS ASCENDENTES (luces lentas) ============
class ParticulasAscendentes extends StatefulWidget {
  final int cantidad;
  const ParticulasAscendentes({super.key, this.cantidad = 14});

  @override
  State<ParticulasAscendentes> createState() => _ParticulasAscendentesState();
}

class _ParticulasAscendentesState extends State<ParticulasAscendentes>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  final _rand = math.Random(42);
  late final List<List<dynamic>> _p; // [x, duracionCiclo, delay, tam, esVerde]

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..repeat();
    _p = List.generate(widget.cantidad, (i) {
      return [
        _rand.nextDouble(),
        10.0 + _rand.nextDouble() * 8, // 10..18 s por ciclo
        _rand.nextDouble(),
        1.5 + _rand.nextDouble() * 3.5,
        _rand.nextBool(),
      ];
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) {
          return CustomPaint(
            painter: _AscendentesPainter(tick: _c.value, particulas: _p),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _AscendentesPainter extends CustomPainter {
  final double tick;
  final List<List<dynamic>> particulas;
  _AscendentesPainter({required this.tick, required this.particulas});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particulas) {
      final x = (p[0] as double) * size.width;
      final dur = p[1] as double;
      final delay = p[2] as double;
      final tam = p[3] as double;
      final esVerde = p[4] as bool;

      // Progreso del ciclo (0 abajo → 1 arriba) — duración por partícula
      final progreso = ((tick * (14.0 / dur)) + delay) % 1.0;
      final y = size.height + 20 - progreso * (size.height + 60);

      // Aparece suave y se desvanece al llegar arriba
      final alpha = 0.55 * math.sin(math.pi * progreso.clamp(0.0, 1.0));

      final color = esVerde ? const Color(0xFF33FF99) : const Color(0xFFB388FF);
      final paint = Paint()
        ..color = color.withValues(alpha: alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2);

      canvas.drawCircle(Offset(x, y), tam, paint);
      // Núcleo brillante
      canvas.drawCircle(
        Offset(x, y),
        tam * 0.4,
        Paint()..color = Colors.white.withValues(alpha: alpha * 0.8),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ============ 4. APARECE ANIMADO (estilo AOS fadeUp) ============
class ApareceAnimado extends StatefulWidget {
  final Widget child;
  /// Retardo antes de aparecer (para efecto escalonado)
  final Duration retardo;
  /// Distancia vertical de entrada en píxeles
  final double desplazamiento;

  const ApareceAnimado({
    super.key,
    required this.child,
    this.retardo = Duration.zero,
    this.desplazamiento = 24,
  });

  @override
  State<ApareceAnimado> createState() => _ApareceAnimadoState();
}

class _ApareceAnimadoState extends State<ApareceAnimado>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _opacidad;
  late Animation<Offset> _desplazamiento;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _opacidad = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    _desplazamiento = Tween<Offset>(
      begin: Offset(0, widget.desplazamiento / 100),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));

    if (widget.retardo == Duration.zero) {
      _c.forward();
    } else {
      Future.delayed(widget.retardo, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacidad,
      child: SlideTransition(position: _desplazamiento, child: widget.child),
    );
  }
}

// ============ 5. CONTADOR ANIMADO (RF04 de la web) ============
class ContadorAnimado extends StatefulWidget {
  final double valor;
  final String prefijo;
  final String sufijo;
  final int decimales;
  final TextStyle? estilo;
  final TextOverflow overflow;
  final int? maxLines;

  const ContadorAnimado({
    super.key,
    required this.valor,
    this.prefijo = '',
    this.sufijo = '',
    this.decimales = 0,
    this.estilo,
    this.overflow = TextOverflow.ellipsis,
    this.maxLines,
  });

  @override
  State<ContadorAnimado> createState() => _ContadorAnimadoState();
}

class _ContadorAnimadoState extends State<ContadorAnimado>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _c.forward();
  }

  @override
  void didUpdateWidget(covariant ContadorAnimado oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si el valor cambia (ej: período semana/mes/año) se vuelve a animar
    if (oldWidget.valor != widget.valor) {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final v = Curves.easeOutCubic.transform(_c.value) * widget.valor;
        // Agrupa los miles con comas (ej. 32300.00 -> 32,300.00)
        final fijo = v.toStringAsFixed(widget.decimales);
        final partes = fijo.split('.');
        final entero = partes[0];
        final buf = StringBuffer();
        for (int i = 0; i < entero.length; i++) {
          if (i > 0 && (entero.length - i) % 3 == 0) buf.write(',');
          buf.write(entero[i]);
        }
        final texto =
            '${widget.prefijo}$buf${widget.decimales > 0 ? '.${partes[1]}' : ''}${widget.sufijo}';
        return Text(
          texto,
          style: widget.estilo,
          overflow: widget.overflow,
          maxLines: widget.maxLines,
        );
      },
    );
  }
}

// ============ 6. BANNER TECNOLÓGICO ANIMADO ============
/// Motivos visuales (tecnología) — cada pantalla usa el suyo para que no se
/// vean todas iguales.
enum MotivoTecnologico {
  /// Circuitos impresos con pulsos recorriendo los rieles.
  circuito,
  /// Red de nodos con paquetes de datos viajando por las aristas.
  red,
  /// Radar con barrido rotando y contactos que se van apagando.
  radar,
  /// Microprocesador con pines y anillos expansivos.
  chip,
  /// Ondas de señal emanando de un emisor.
  ondas,
  /// Órbitas de átomo girando (ideal para "quiénes somos").
  orbita,
  /// Panel de datos con barras que laten y un escáner.
  data,
}

/// Cabecera animada con fondo tecnológico dibujado por código (SVG-like)
/// y el título de la sección encima.
class BannerTecnologico extends StatefulWidget {
  final MotivoTecnologico motivo;
  final String titulo;
  final String? subtitulo;
  final double alto;
  final Color acento;
  final bool animarEntrada;

  const BannerTecnologico({
    super.key,
    required this.motivo,
    required this.titulo,
    this.subtitulo,
    this.alto = 128,
    this.acento = const Color(0xFF33FF99),
    this.animarEntrada = true,
  });

  @override
  State<BannerTecnologico> createState() => _BannerTecnologicoState();
}

class _BannerTecnologicoState extends State<BannerTecnologico>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 4))
      ..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final acento = widget.acento;
    final banner = Container(
      width: double.infinity,
      height: widget.alto,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [acento.withValues(alpha: 0.16), const Color(0xFF12121A)],
        ),
        border: Border.all(color: acento.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: acento.withValues(alpha: 0.14),
            blurRadius: 20,
            spreadRadius: 1,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Dibujo tecnológico animado
            AnimatedBuilder(
              animation: _c,
              builder: (context, child) {
                return CustomPaint(
                  painter: _TecnoPainter(
                    motivo: widget.motivo,
                    progreso: _c.value,
                    acento: acento,
                  ),
                );
              },
            ),
            // Texto encima
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.titulo,
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: const Color(0xFFF4F4F6),
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.7),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  if (widget.subtitulo != null) ...[
                    const SizedBox(height: 5),
                    Text(
                      widget.subtitulo!,
                      style: TextStyle(
                        fontSize: 12,
                        color: acento,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (!widget.animarEntrada) return banner;
    return ApareceAnimado(child: banner);
  }
}

/// Pinta el motivo tecnológico elegido. Un solo painter para los 7 casos,
/// animado en bucle con un único controller.
class _TecnoPainter extends CustomPainter {
  final MotivoTecnologico motivo;
  final double progreso;
  final Color acento;

  _TecnoPainter({
    required this.motivo,
    required this.progreso,
    required this.acento,
  });

  @override
  void paint(Canvas canvas, Size size) {
    switch (motivo) {
      case MotivoTecnologico.circuito:
        _circuito(canvas, size, progreso);
      case MotivoTecnologico.red:
        _red(canvas, size, progreso);
      case MotivoTecnologico.radar:
        _radar(canvas, size, progreso);
      case MotivoTecnologico.chip:
        _chip(canvas, size, progreso);
      case MotivoTecnologico.ondas:
        _ondas(canvas, size, progreso);
      case MotivoTecnologico.orbita:
        _orbita(canvas, size, progreso);
      case MotivoTecnologico.data:
        _data(canvas, size, progreso);
    }
  }

  // ---- Circuitos impresos con pulsos ----
  void _circuito(Canvas canvas, Size size, double t) {
    final w = size.width;
    final h = size.height;
    final linea = Paint()
      ..color = acento.withValues(alpha: 0.28)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    final rielesH = [h * 0.24, h * 0.52, h * 0.78];
    final rielesV = [w * 0.20, w * 0.44, w * 0.68, w * 0.90];

    for (final y in rielesH) {
      canvas.drawLine(Offset(0, y), Offset(w, y), linea);
    }
    for (final x in rielesV) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), linea);
    }

    final nodo = Paint()..color = acento.withValues(alpha: 0.55);
    for (final y in rielesH) {
      for (final x in rielesV) {
        canvas.drawCircle(Offset(x, y), 2.6, nodo);
      }
    }

    final pulsoVerde = Paint()
      ..color = acento
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    for (var i = 0; i < rielesH.length; i++) {
      final p = (t + i * 0.33) % 1.0;
      canvas.drawCircle(Offset(w * p, rielesH[i]), 3.6, pulsoVerde);
    }

    final pulsoBlanco = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
    for (var i = 0; i < rielesV.length; i++) {
      final p = (t * 0.85 + i * 0.25) % 1.0;
      canvas.drawCircle(Offset(rielesV[i], h * p), 3.2, pulsoBlanco);
    }
  }

  // ---- Red de datos ----
  void _red(Canvas canvas, Size size, double t) {
    final w = size.width;
    final h = size.height;
    final nodos = <Offset>[
      Offset(w * 0.10, h * 0.30),
      Offset(w * 0.30, h * 0.72),
      Offset(w * 0.48, h * 0.26),
      Offset(w * 0.68, h * 0.68),
      Offset(w * 0.86, h * 0.34),
      Offset(w * 0.22, h * 0.48),
      Offset(w * 0.58, h * 0.50),
    ];
    const aristas = [
      [0, 5],
      [5, 1],
      [5, 2],
      [2, 6],
      [6, 3],
      [3, 4],
      [2, 3],
      [6, 4],
      [0, 2],
      [1, 3],
    ];

    final linea = Paint()
      ..color = acento.withValues(alpha: 0.26)
      ..strokeWidth = 1.3;
    for (final e in aristas) {
      canvas.drawLine(nodos[e[0]], nodos[e[1]], linea);
    }

    for (var i = 0; i < nodos.length; i++) {
      final brillo = 0.5 + 0.5 * math.sin(t * 2 * math.pi + i);
      canvas.drawCircle(
        nodos[i],
        5.5,
        Paint()..color = acento.withValues(alpha: 0.30 + 0.35 * brillo),
      );
      canvas.drawCircle(
        nodos[i],
        2.4,
        Paint()..color = Colors.white.withValues(alpha: 0.55 + 0.4 * brillo),
      );
    }

    for (var k = 0; k < aristas.length; k++) {
      final e = aristas[k];
      final p = ((t * 1.5) + k * 0.17) % 1.0;
      final pos = Offset.lerp(nodos[e[0]], nodos[e[1]], p)!;
      canvas.drawCircle(
        pos,
        3.2,
        Paint()
          ..color = Colors.white
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
    }
  }

  // ---- Radar con barrido ----
  void _radar(Canvas canvas, Size size, double t) {
    final c = Offset(size.width * 0.80, size.height * 0.5);
    final rMax = size.height * 0.46;
    final circulo = Paint()
      ..color = acento.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (var i = 1; i <= 3; i++) {
      canvas.drawCircle(c, rMax * i / 3, circulo);
    }

    final ang = t * 2 * math.pi;
    final wedge = Path()
      ..moveTo(c.dx, c.dy)
      ..arcTo(Rect.fromCircle(center: c, radius: rMax), ang, math.pi / 3, false)
      ..close();
    canvas.drawPath(
      wedge,
      Paint()
        ..color = acento.withValues(alpha: 0.20)
        ..style = PaintingStyle.fill,
    );
    canvas.drawLine(
      c,
      Offset(c.dx + rMax * math.cos(ang), c.dy + rMax * math.sin(ang)),
      Paint()
        ..color = acento
        ..strokeWidth = 2,
    );

    const blips = [Offset(0.30, -0.35), Offset(-0.45, 0.25), Offset(0.15, 0.55)];
    for (var i = 0; i < blips.length; i++) {
      final bp = Offset(c.dx + blips[i].dx * rMax, c.dy + blips[i].dy * rMax);
      final fase = ((ang / (2 * math.pi)) - i * 0.33) % 1.0;
      final alpha = (1.0 - fase).clamp(0.0, 1.0);
      canvas.drawCircle(
        bp,
        4,
        Paint()..color = const Color(0xFFFFD166).withValues(alpha: alpha),
      );
    }
  }

  // ---- Microprocesador ----
  void _chip(Canvas canvas, Size size, double t) {
    final c = Offset(size.width * 0.80, size.height * 0.5);
    final lado = size.height * 0.36;
    final rect = Rect.fromCenter(center: c, width: lado, height: lado);

    for (var i = 0; i < 3; i++) {
      final p = ((t + i / 3) % 1.0);
      canvas.drawCircle(
        c,
        lado * (0.7 + p * 1.6),
        Paint()
          ..color = acento.withValues(alpha: (1 - p) * 0.30)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    final cuerpo = RRect.fromRectAndRadius(rect, const Radius.circular(8));
    canvas.drawRRect(
      cuerpo,
      Paint()
        ..color = const Color(0xFF0E0E16)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      cuerpo,
      Paint()
        ..color = acento.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final pin = Paint()
      ..color = acento
      ..strokeWidth = 2;
    const n = 4;
    for (var i = 0; i < n; i++) {
      final f = (i + 0.5) / n;
      final dx = rect.left + lado * f;
      final dy = rect.top + lado * f;
      canvas.drawLine(Offset(dx, rect.top - 9), Offset(dx, rect.top), pin);
      canvas.drawLine(Offset(dx, rect.bottom), Offset(dx, rect.bottom + 9), pin);
      canvas.drawLine(Offset(rect.left - 9, dy), Offset(rect.left, dy), pin);
      canvas.drawLine(Offset(rect.right, dy), Offset(rect.right + 9, dy), pin);
    }

    final brillo = 0.5 + 0.5 * math.sin(t * 2 * math.pi * 2);
    canvas.drawRect(
      Rect.fromCenter(center: c, width: lado * 0.42, height: lado * 0.42),
      Paint()..color = acento.withValues(alpha: 0.30 + 0.5 * brillo),
    );
  }

  // ---- Ondas de señal ----
  void _ondas(Canvas canvas, Size size, double t) {
    final c = Offset(size.width * 0.84, size.height * 0.5);
    for (var i = 0; i < 4; i++) {
      final p = ((t + i / 4) % 1.0);
      canvas.drawCircle(
        c,
        size.height * (0.14 + p * 0.8),
        Paint()
          ..color = acento.withValues(alpha: (1 - p) * 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4,
      );
    }
    canvas.drawCircle(
      c,
      6,
      Paint()
        ..color = Colors.white
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    canvas.drawCircle(c, 3.5, Paint()..color = acento);
  }

  // ---- Órbitas de átomo ----
  void _orbita(Canvas canvas, Size size, double t) {
    final c = Offset(size.width * 0.80, size.height * 0.5);
    final rx = size.height * 0.52;
    final ry = size.height * 0.19;

    for (var i = 0; i < 3; i++) {
      final rot = t * 2 * math.pi + i * math.pi / 3;
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(rot);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2),
        Paint()
          ..color = acento.withValues(alpha: 0.42)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
      canvas.restore();
    }

    for (var i = 0; i < 3; i++) {
      final eAng = t * 2 * math.pi * (1 + i * 0.2) + i * 2 * math.pi / 3;
      final rot = t * 2 * math.pi + i * math.pi / 3;
      final local = Offset(rx * math.cos(eAng), ry * math.sin(eAng));
      final pos = Offset(
        c.dx + local.dx * math.cos(rot) - local.dy * math.sin(rot),
        c.dy + local.dx * math.sin(rot) + local.dy * math.cos(rot),
      );
      canvas.drawCircle(
        pos,
        4.2,
        Paint()
          ..color = Colors.white
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
      );
    }

    canvas.drawCircle(
      c,
      7,
      Paint()
        ..color = acento
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawCircle(c, 3.5, Paint()..color = Colors.white);
  }

  // ---- Panel de datos ----
  void _data(Canvas canvas, Size size, double t) {
    final w = size.width;
    final h = size.height;
    canvas.drawLine(
      Offset(0, h * 0.86),
      Offset(w, h * 0.86),
      Paint()
        ..color = acento.withValues(alpha: 0.25)
        ..strokeWidth = 1,
    );

    const n = 14;
    final anchoBarra = w / (n * 1.7);
    for (var i = 0; i < n; i++) {
      final fase = ((t * 1.2) + i * 0.08) % 1.0;
      final alt = (0.25 +
              0.6 *
                  (0.5 + 0.5 * math.sin(fase * 2 * math.pi + i))) *
          h *
          0.7;
      final x = (w / n) * i + anchoBarra * 0.4;
      final r = Rect.fromLTWH(x, h * 0.86 - alt, anchoBarra, alt);
      canvas.drawRRect(
        RRect.fromRectAndRadius(r, const Radius.circular(3)),
        Paint()
          ..color = acento.withValues(alpha: 0.30 + 0.45 * (alt / (h * 0.7))),
      );
    }

    final sx = w * t;
    canvas.drawLine(
      Offset(sx, 0),
      Offset(sx, h),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.4)
        ..strokeWidth = 1.6
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
  }

  @override
  bool shouldRepaint(covariant _TecnoPainter oldDelegate) => true;
}
