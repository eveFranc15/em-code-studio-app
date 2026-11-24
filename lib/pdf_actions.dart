import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'pdf_web_stub.dart'
    if (dart.library.html) 'pdf_web_html.dart';

/// Acciones comunes para todos los documentos PDF de la app:
/// vista previa, descarga local y compartir.
class PdfActions {
  /// Muestra una hoja de opciones elegante con las 3 acciones disponibles.
  ///
  /// [generar] construye los bytes del PDF bajo demanda (se ejecuta
  /// recién cuando el usuario elige una opción, con diálogo de carga).
  static Future<void> mostrarOpciones(
    BuildContext context, {
    required Future<Uint8List> Function() generar,
    required String nombreArchivo,
    required String titulo,
    String? subtitulo,
    Color acento = const Color(0xFF33FF99),
  }) async {
    final accion = await showModalBottomSheet<_AccionPdf>(
      context: context,
      backgroundColor: const Color(0xFF1A1A24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Encabezado de la hoja
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: acento.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.picture_as_pdf, color: acento, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titulo,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFF4F4F6),
                          ),
                        ),
                        if (subtitulo != null)
                          Text(
                            subtitulo,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF8888A0),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Color(0xFF8888A0), height: 24),
            _opcion(
              ctx,
              _AccionPdf.vistaPrevia,
              Icons.visibility_outlined,
              'Vista previa',
              'Revisar el documento antes de exportarlo',
              acento,
            ),
            _opcion(
              ctx,
              _AccionPdf.descargar,
              Icons.download_rounded,
              'Descargar',
              'Guarda el archivo PDF en tu equipo',
              acento,
            ),
            _opcion(
              ctx,
              _AccionPdf.compartir,
              Icons.share_rounded,
              'Compartir',
              'Enviar por WhatsApp, correo o nube',
              acento,
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );

    if (accion == null || !context.mounted) return;

    // Diálogo de carga mientras se genera el PDF
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF33FF99)),
      ),
    );

    Uint8List? bytes;
    String? error;
    try {
      bytes = await generar();
    } catch (e) {
      error = '$e';
    }

    if (context.mounted) Navigator.pop(context); // cierra la carga

    if (bytes == null) {
      if (context.mounted) {
        _snackBar(
          context,
          'No se pudo generar el PDF: ${error ?? 'error desconocido'}',
          color: const Color(0xFFE74C3C),
        );
      }
      return;
    }

    final nombre = _sanearNombre(nombreArchivo);

    switch (accion) {
      case _AccionPdf.vistaPrevia:
        await Printing.layoutPdf(
          onLayout: (_) async => bytes!,
          name: nombre,
        );
        break;

      case _AccionPdf.descargar:
        try {
          final ruta = await _descargar(bytes, nombre);
          if (context.mounted) {
            _snackBar(
              context,
              'PDF guardado en: $ruta',
              color: const Color(0xFF33FF99),
              ruta: ruta,
            );
          }
        } catch (e) {
          if (context.mounted) {
            _snackBar(
              context,
              'No se pudo descargar el PDF: $e',
              color: const Color(0xFFE74C3C),
            );
          }
        }
        break;

      case _AccionPdf.compartir:
        if (!context.mounted) return;
        await _compartir(context, bytes, nombre);
        break;
    }
  }

  static Widget _opcion(
    BuildContext ctx,
    _AccionPdf accion,
    IconData icono,
    String titulo,
    String detalle,
    Color acento,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: acento.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icono, color: acento, size: 22),
      ),
      title: Text(
        titulo,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFFF4F4F6),
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        detalle,
        style: const TextStyle(color: Color(0xFF8888A0), fontSize: 12),
      ),
      trailing: const Icon(Icons.chevron_right, color: Color(0xFF8888A0)),
      onTap: () => Navigator.pop(ctx, accion),
    );
  }

  /// Guarda el PDF y devuelve la ruta/donde quedo.
  static Future<String> _descargar(Uint8List bytes, String nombre) async {
    // WEB: el navegador guarda el archivo en su carpeta de Descargas.
    if (kIsWeb) {
      descargarArchivoWeb(bytes, '$nombre.pdf');
      return 'Tu carpeta de Descargas (navegador)';
    }
    try {
      final carpeta = await _carpetaDestino();
      await carpeta.create(recursive: true);
      final archivo = File(
        '${carpeta.path}${Platform.pathSeparator}$nombre.pdf',
      );
      await archivo.writeAsBytes(bytes, flush: true);
      return archivo.path;
    } catch (e) {
      // Si el equipo no permite guardar directo, el PDF se ofrece por
      // el compartidor nativo del sistema (ahi el usuario puede
      // guardarlo en su carpeta deseada o enviarlo por WhatsApp, etc.).
      await Printing.sharePdf(bytes: bytes, filename: '$nombre.pdf');
      return 'PDF compartido por el sistema (usalo para guardarlo)';
    }
  }

  /// Carpeta donde se guardan los PDF segun el dispositivo.
  static Future<Directory> _carpetaDestino() async {
    // Android / iOS: carpeta de documentos de la app (siempre
    // accesible sin permisos especiales).
    if (Platform.isAndroid || Platform.isIOS) {
      final docs = await getApplicationDocumentsDirectory();
      return Directory('${docs.path}${Platform.pathSeparator}EM Code Studio');
    }
    // Windows / macOS / Linux: carpeta Documentos del usuario.
    final home =
        Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'];
    if (home != null) {
      return Directory(
        '$home${Platform.pathSeparator}Documents${Platform.pathSeparator}EM Code Studio',
      );
    }
    return Directory.current;
  }

  static Future<void> _compartir(
    BuildContext context,
    Uint8List bytes,
    String nombre,
  ) async {
    // WEB: muestra el selector de apps (WhatsApp, Gmail, correo y
    // copia del PDF para adjuntar). En Windows y Android mantiene el
    // compartido nativo del sistema operativo.
    if (kIsWeb) {
      if (context.mounted) {
        await _elegirAppWeb(context, bytes, nombre);
      }
      return;
    }
    try {
      await Printing.sharePdf(bytes: bytes, filename: '$nombre.pdf');
    } catch (_) {
      // Si el equipo no permite compartir directo, guardamos el archivo
      final ruta = await _descargar(bytes, nombre);
      if (context.mounted) {
        _snackBar(
          context,
          'Este equipo no permite compartir directo. PDF guardado en: $ruta',
          color: const Color(0xFFF39C12),
          ruta: ruta,
        );
      }
    }
  }

  /// WEB: selector de app por si el navegador no comparte archivos.
  static Future<void> _elegirAppWeb(
    BuildContext context,
    Uint8List bytes,
    String nombre,
  ) async {
    final acento = const Color(0xFF33FF99);
    final elegida = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF1A1A24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 18, 20, 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'COMPARTIR POR',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 2,
                    color: Color(0xFF8888A0),
                  ),
                ),
              ),
            ),
            const Divider(color: Color(0xFF8888A0), height: 12),
            _opcWebIcono(ctx, 'copia', Icons.download, 'Copia del PDF',
                'La descarga a tu equipo para adjuntarla', acento),
            _opcWebIcono(ctx, 'whatsapp', Icons.chat, 'WhatsApp',
                'Abre WhatsApp Web para enviar el mensaje', acento),
            _opcWebIcono(ctx, 'gmail', Icons.mail, 'Gmail',
                'Abre Gmail para redactar el correo', acento),
            _opcWebIcono(ctx, 'correo', Icons.alternate_email, 'Otro correo',
                'Abre tu app de correo del equipo', acento),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
    if (elegida == null) return;

    final sujeto = Uri.encodeComponent(nombre);
    switch (elegida) {
      case 'copia':
        descargarArchivoWeb(bytes, '$nombre.pdf');
        if (context.mounted) {
          _snackBar(
            context,
            'PDF descargado: adjúntalo a tu mensaje de WhatsApp o correo.',
            color: const Color(0xFF33FF99),
          );
        }
        break;
      case 'whatsapp':
        abrirUrlWeb('https://api.whatsapp.com/send?text=Te envio $nombre');
        if (context.mounted) {
          _snackBar(context,
              'WhatsApp abierto. Usa "Copia del PDF" y adjúntalo en el chat.',
              color: const Color(0xFFF39C12));
        }
        break;
      case 'gmail':
        abrirUrlWeb(
            'https://mail.google.com/mail/?view=cm&fs=1&su=$sujeto');
        if (context.mounted) {
          _snackBar(context,
              'Gmail abierto. Usa "Copia del PDF" y adjúntalo al correo.',
              color: const Color(0xFFF39C12));
        }
        break;
      default:
        abrirUrlWeb('mailto:?subject=$sujeto');
        if (context.mounted) {
          _snackBar(context,
              'Correo abierto. Usa "Copia del PDF" y adjúntalo al mensaje.',
              color: const Color(0xFFF39C12));
        }
    }
  }

  static Widget _opcWebIcono(
    BuildContext ctx,
    String clave,
    IconData icono,
    String titulo,
    String detalle,
    Color acento,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: acento.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icono, color: acento, size: 22),
      ),
      title: Text(
        titulo,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFFF4F4F6),
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        detalle,
        style: const TextStyle(color: Color(0xFF8888A0), fontSize: 12),
      ),
      trailing: const Icon(Icons.chevron_right, color: Color(0xFF8888A0)),
      onTap: () => Navigator.pop(ctx, clave),
    );
  }

  /// Resalta el archivo en el explorador de Windows / Finder.
  static void abrirCarpeta(String ruta) {
    try {
      if (Platform.isWindows) {
        Process.run('explorer.exe', ['/select,', ruta]);
      } else if (Platform.isMacOS) {
        Process.run('open', ['-R', ruta]);
      } else {
        Process.run('xdg-open', [ruta]);
      }
    } catch (_) {
      // silencioso: no es crítico
    }
  }

  static String _sanearNombre(String nombre) {
    return nombre.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim();
  }

  static void _snackBar(
    BuildContext context,
    String mensaje, {
    Color color = const Color(0xFF33FF99),
    String? ruta,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje, style: const TextStyle(fontSize: 13)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 5),
        action: ruta != null
            ? SnackBarAction(
                label: 'ABRIR',
                textColor: const Color(0xFF0D0D12),
                onPressed: () => abrirCarpeta(ruta),
              )
            : null,
      ),
    );
  }
}

enum _AccionPdf { vistaPrevia, descargar, compartir }
