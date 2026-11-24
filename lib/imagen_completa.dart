import 'dart:async';

import 'package:flutter/material.dart';

/// Muestra una imagen de internet **completa, sin recortarla**.
///
/// A diferencia de `BoxFit.cover` (que recorta la imagen para llenar el
/// espacio), este widget consulta las dimensiones originales de la imagen y
/// adapta su alto a la proporción real, respetando siempre un mínimo
/// ([altoMin]) y un máximo ([altoMax]) para que el diseño no se desborde.
///
/// Si la imagen es muy alta (vertical) y supera [altoMax], se muestra
/// completa dentro de ese alto, centrada sobre fondo oscuro (tipo cartel).
class ImagenCompleta extends StatefulWidget {
  final String url;

  /// Alto mínimo mientras se carga la imagen o si esta es muy panorámica.
  final double altoMin;

  /// Alto máximo permitido (evita tarjetas interminables con imágenes
  /// verticales muy grandes).
  final double altoMax;

  /// Widget que se muestra mientras se resuelve la imagen (opcional).
  final Widget? mientrasCarga;

  /// Widget de respaldo si la imagen no se puede cargar (opcional).
  final Widget? error;

  const ImagenCompleta({
    super.key,
    required this.url,
    this.altoMin = 160,
    this.altoMax = 360,
    this.mientrasCarga,
    this.error,
  });

  @override
  State<ImagenCompleta> createState() => _ImagenCompletaState();
}

class _ImagenCompletaState extends State<ImagenCompleta> {
  Size? _dimensiones;
  bool _fallo = false;
  ImageStream? _stream;
  ImageStreamListener? _listener;

  @override
  void initState() {
    super.initState();
    _resolverImagen();
  }

  @override
  void didUpdateWidget(covariant ImagenCompleta oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _liberar();
      _dimensiones = null;
      _fallo = false;
      _resolverImagen();
    }
  }

  @override
  void dispose() {
    _liberar();
    super.dispose();
  }

  /// Deja de escuchar la imagen anterior (si cambió la URL o se destruyó
  /// el widget) para no dejar escuchas huérfanas.
  void _liberar() {
    final stream = _stream;
    final listener = _listener;
    if (stream != null && listener != null) {
      stream.removeListener(listener);
    }
    _stream = null;
    _listener = null;
  }

  /// Obtiene el ancho y alto reales de la imagen sin descargarla dos veces
  /// (usa la caché de imágenes de Flutter).
  Future<void> _resolverImagen() async {
    try {
      final stream = NetworkImage(widget.url)
          .resolve(const ImageConfiguration());
      final completer = Completer<Size>();

      late final ImageStreamListener listener;
      listener = ImageStreamListener(
        (info, _) {
          if (!completer.isCompleted) {
            completer.complete(
              Size(
                info.image.width.toDouble(),
                info.image.height.toDouble(),
              ),
            );
          }
        },
        onError: (error, stackTrace) {
          if (!completer.isCompleted) {
            completer.completeError(error, stackTrace);
          }
        },
      );

      _stream = stream;
      _listener = listener;
      stream.addListener(listener);

      final size = await completer.future;
      stream.removeListener(listener);
      if (_stream == stream) {
        _stream = null;
        _listener = null;
      }

      if (mounted && size.width > 0 && size.height > 0) {
        setState(() => _dimensiones = size);
      }
    } catch (_) {
      if (mounted) setState(() => _fallo = true);
    }
  }

  Widget _placeholder() {
    return widget.mientrasCarga ??
        Container(
          color: const Color(0xFF16161D),
          alignment: Alignment.center,
          child: const SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF33FF99),
            ),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    if (_fallo) {
      return widget.error ??
          Container(
            height: widget.altoMin,
            color: const Color(0xFF16161D),
            alignment: Alignment.center,
            child: const Icon(
              Icons.broken_image,
              size: 40,
              color: Color(0xFF8888A0),
            ),
          );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final ancho = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : widget.altoMax;

        // Alto según la proporción real de la imagen, dentro del rango.
        double alto = widget.altoMin;
        final dim = _dimensiones;
        if (dim != null && dim.width > 0 && ancho > 0) {
          alto = (ancho * dim.height / dim.width)
              .clamp(widget.altoMin, widget.altoMax);
        }

        return SizedBox(
          width: ancho,
          height: alto,
          child: dim == null
              ? _placeholder()
              : Image.network(
                  widget.url,
                  width: ancho,
                  height: alto,
                  // contain = se ve SIEMPRE la imagen completa, sin recortes.
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      widget.error ??
                      Container(
                        color: const Color(0xFF16161D),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.broken_image,
                          size: 40,
                          color: Color(0xFF8888A0),
                        ),
                      ),
                ),
        );
      },
    );
  }
}
