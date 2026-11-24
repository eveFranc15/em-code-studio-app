import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'animaciones_web.dart';

class FondoAnimado extends StatefulWidget {
  final Widget child;
  const FondoAnimado({super.key, required this.child});

  @override
  State<FondoAnimado> createState() => _FondoAnimadoState();
}

class _FondoAnimadoState extends State<FondoAnimado> with TickerProviderStateMixin {
  late AnimationController _controller1;
  late AnimationController _controller2;
  late AnimationController _controller3;

  @override
  void initState() {
    super.initState();
    _controller1 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    _controller2 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
    _controller3 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    )..repeat();
  }

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    _controller3.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Fondo gradiente
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0D0D12),
                Color(0xFF16161D),
              ],
            ),
          ),
        ),
        // Partículas SVG animadas
        AnimatedBuilder(
          animation: _controller1,
          builder: (context, child) {
            return CustomPaint(
              painter: ParticulasPainter(
                progress: _controller1.value,
                color: const Color(0xFF33FF99),
                cantidad: 8,
              ),
              size: Size.infinite,
            );
          },
        ),
        AnimatedBuilder(
          animation: _controller2,
          builder: (context, child) {
            return CustomPaint(
              painter: ParticulasPainter(
                progress: _controller2.value,
                color: const Color(0xFFB388FF),
                cantidad: 6,
              ),
              size: Size.infinite,
            );
          },
        ),
        // Orbes flotantes
        AnimatedBuilder(
          animation: _controller3,
          builder: (context, child) {
            return Stack(
              children: [
                Positioned(
                  top: 100 + math.sin(_controller3.value * 2 * math.pi) * 30,
                  right: 50 + math.cos(_controller3.value * 2 * math.pi) * 20,
                  child: _Orbe(
                    size: 150,
                    color: const Color(0xFF33FF99).withValues(alpha: 0.05),
                  ),
                ),
                Positioned(
                  bottom: 150 + math.cos(_controller3.value * 2 * math.pi) * 25,
                  left: 30 + math.sin(_controller3.value * 2 * math.pi) * 15,
                  child: _Orbe(
                    size: 100,
                    color: const Color(0xFFB388FF).withValues(alpha: 0.04),
                  ),
                ),
              ],
            );
          },
        ),
        // Estrellas titilando (estilo intro de la web)
        const EstrellasAnimadas(cantidad: 45),
        // Partículas de luz subiendo (estilo slow-light del hero)
        const ParticulasAscendentes(cantidad: 12),
        // Nubes SVG derivando en la parte inferior (crearNubes de la web)
        const Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 200,
          child: NubesSVG(cantidad: 3),
        ),
        // Contenido principal
        widget.child,
      ],
    );
  }
}

class ParticulasPainter extends CustomPainter {
  final double progress;
  final Color color;
  final int cantidad;

  ParticulasPainter({
    required this.progress,
    required this.color,
    required this.cantidad,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < cantidad; i++) {
      final x = (size.width / cantidad) * i + math.sin(progress * 2 * math.pi + i) * 30 + size.width / cantidad / 2;
      final y = (size.height / cantidad) * (i % 3) + math.cos(progress * 2 * math.pi + i * 0.5) * 40 + size.height / 3;
      final radius = 2.0 + math.sin(progress * 2 * math.pi + i) * 1.5;

      canvas.drawCircle(Offset(x, y), radius, paint);
    }

    // Líneas de red
    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..strokeWidth = 0.5;

    for (int i = 0; i < cantidad; i++) {
      for (int j = i + 1; j < cantidad; j++) {
        final x1 = (size.width / cantidad) * i + math.sin(progress * 2 * math.pi + i) * 30 + size.width / cantidad / 2;
        final y1 = (size.height / cantidad) * (i % 3) + math.cos(progress * 2 * math.pi + i * 0.5) * 40 + size.height / 3;
        final x2 = (size.width / cantidad) * j + math.sin(progress * 2 * math.pi + j) * 30 + size.width / cantidad / 2;
        final y2 = (size.height / cantidad) * (j % 3) + math.cos(progress * 2 * math.pi + j * 0.5) * 40 + size.height / 3;

        final dist = math.sqrt(math.pow(x2 - x1, 2) + math.pow(y2 - y1, 2));
        if (dist < 200) {
          canvas.drawLine(Offset(x1, y1), Offset(x2, y2), linePaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _Orbe extends StatelessWidget {
  final double size;
  final Color color;

  const _Orbe({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color,
            color.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}

class BotonAnimado extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;
  final Color color;

  const BotonAnimado({
    super.key,
    required this.onTap,
    required this.child,
    this.color = const Color(0xFF33FF99),
  });

  @override
  State<BotonAnimado> createState() => _BotonAnimadoState();
}

class _BotonAnimadoState extends State<BotonAnimado> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) {
          return Transform.scale(
            scale: _scale.value,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.3),
                    blurRadius: _controller.value * 10,
                    spreadRadius: _controller.value * 2,
                  ),
                ],
              ),
              child: widget.child,
            ),
          );
        },
      ),
    );
  }
}

class IconoAnimado extends StatefulWidget {
  final IconData icono;
  final Color color;
  final double size;

  const IconoAnimado({
    super.key,
    required this.icono,
    required this.color,
    this.size = 24,
  });

  @override
  State<IconoAnimado> createState() => _IconoAnimadoState();
}

class _IconoAnimadoState extends State<IconoAnimado> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Icon(
          widget.icono,
          color: widget.color,
          size: widget.size + _controller.value * 2,
        );
      },
    );
  }
}
