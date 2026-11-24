// SOLO WEB: acciones de PDF desde el navegador.
//
// En el navegador los archivos no se manipulan con dart:io, sino que
// se descargan con "blobs" del navegador. El compartir por apps se
// resuelve en pdf_actions.dart con WhatsApp Web / Gmail / mailto.
import 'dart:html' as html;
import 'dart:typed_data';

// Descarga el PDF con el navegador (queda en su carpeta de Descargas).
void descargarArchivoWeb(Uint8List bytes, String nombre) {
  final blob = html.Blob([bytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..download = nombre
    ..click();
  html.Url.revokeObjectUrl(url);
}

// Abre un enlace en otra pestana (WhatsApp Web, Gmail, correo).
void abrirUrlWeb(String url) => html.window.open(url, '_blank');
