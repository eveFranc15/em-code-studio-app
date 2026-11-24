import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'modelos.dart';

/// Generación de la boleta de venta PDF (documento interno de cobranza)
/// con diseño corporativo de EM Code Studio.
///
/// NOTA: los datos de la empresa son editables abajo. Si más adelante
/// cuentas con RUC y dirección oficiales, actualízalos ahí.
class BoletaPdf {
  // ====== DATOS DE LA EMPRESA (editables) ======
  static const String empresaNombre = 'EM CODE STUDIO';
  static const String empresaRubro = 'Diseño y desarrollo de soluciones digitales';
  static const String empresaContacto = 'Web · Apps · Sistemas';
  static const String empresaSede = 'Perú';

  // Paleta corporativa
  static const _verde = PdfColor.fromInt(0xFF33FF99);
  static const _lila = PdfColor.fromInt(0xFFB388FF);
  static const _naranja = PdfColor.fromInt(0xFFF39C12);
  static const _oscuro = PdfColor.fromInt(0xFF0D0D12);
  static const _gris = PdfColor.fromInt(0xFF8888A0);
  static const _fondo = PdfColor.fromInt(0xFF1A1A24);

  static String _fechaCorta(DateTime f) =>
      '${f.day.toString().padLeft(2, '0')}/${f.month.toString().padLeft(2, '0')}/${f.year}';

  static String _etiquetaEstadoPago(EstadoPago e) {
    switch (e) {
      case EstadoPago.pendiente:
        return 'PENDIENTE';
      case EstadoPago.adelanto:
        return 'ADELANTO';
      case EstadoPago.pagado:
        return 'PAGADO';
    }
  }

  static PdfColor _colorEstadoPago(EstadoPago e) {
    switch (e) {
      case EstadoPago.pendiente:
        return _naranja;
      case EstadoPago.adelanto:
        return _lila;
      case EstadoPago.pagado:
        return _verde;
    }
  }

  static String _etiquetaTipoPago(TipoPago t) {
    switch (t) {
      case TipoPago.efectivo:
        return 'Efectivo';
      case TipoPago.transferencia:
        return 'Transferencia';
      case TipoPago.yapePlin:
        return 'Yape / Plin';
    }
  }

  static String _etiquetaEstadoProyecto(EstadoProyecto e) {
    switch (e) {
      case EstadoProyecto.pendiente:
        return 'Pendiente';
      case EstadoProyecto.enProceso:
        return 'En proceso';
      case EstadoProyecto.terminado:
        return 'Terminado';
    }
  }

  /// Construye la boleta en PDF para el proyecto indicado.
  static Future<Uint8List> generar(Proyecto p) async {
    final pdf = pw.Document();

    final hoy = DateTime.now();
    final correlativo =
        'B001-${(p.id ?? 0).toString().padLeft(6, '0')}';
    final total = p.montoTotal;
    final gravada = total / 1.18;
    final igv = total - gravada;
    final colorPago = _colorEstadoPago(p.estadoPago);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // ============ ENCABEZADO ============
            pw.Container(
              padding: const pw.EdgeInsets.all(18),
              decoration: pw.BoxDecoration(
                color: _oscuro,
                borderRadius: pw.BorderRadius.circular(14),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        empresaNombre,
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: _verde,
                          letterSpacing: 1.5,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        empresaRubro,
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        empresaContacto,
                        style: const pw.TextStyle(fontSize: 8.5, color: _gris),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'BOLETA DE VENTA',
                        style: pw.TextStyle(
                          fontSize: 13,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                          letterSpacing: 2,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: pw.BoxDecoration(
                          color: _verde,
                          borderRadius: pw.BorderRadius.circular(6),
                        ),
                        child: pw.Text(
                          'N° $correlativo',
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: _oscuro,
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Emitido: ${_fechaCorta(hoy)}',
                        style: const pw.TextStyle(fontSize: 8.5, color: _gris),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 18),

            // ============ EMISOR + CLIENTE ============
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: _cajaInfo('EMISOR', [
                    empresaNombre,
                    empresaRubro,
                    empresaSede,
                  ]),
                ),
                pw.SizedBox(width: 12),
                pw.Expanded(
                  child: _cajaInfo('CLIENTE', [
                    p.cliente.nombre,
                    if (p.cliente.ruc != null && p.cliente.ruc!.isNotEmpty)
                      'RUC: ${p.cliente.ruc}'
                    else if (p.cliente.dni != null &&
                        p.cliente.dni!.isNotEmpty)
                      'DNI: ${p.cliente.dni}',
                    if (p.cliente.telefono.isNotEmpty)
                      'Tel: ${p.cliente.telefono}',
                    if (p.cliente.direccion != null &&
                        p.cliente.direccion!.isNotEmpty)
                      p.cliente.direccion!,
                  ]),
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            // ============ CONCEPTO ============
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(5),
                1: const pw.FlexColumnWidth(1.2),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FlexColumnWidth(2),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: _oscuro),
                  children: _celdas([
                    'CONCEPTO',
                    'CANT.',
                    'PRECIO UNIT.',
                    'IMPORTE',
                  ], esCabecera: true),
                ),
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            p.tipoServicio.isEmpty
                                ? p.nombreProyecto
                                : p.tipoServicio,
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            '${p.nombreProyecto} · Entrega: ${_fechaCorta(p.fechaEntrega)}',
                            style: const pw.TextStyle(
                              fontSize: 8,
                              color: _gris,
                            ),
                          ),
                          if (p.notas.isNotEmpty) ...[
                            pw.SizedBox(height: 2),
                            pw.Text(
                              p.notas,
                              style: const pw.TextStyle(
                                fontSize: 7.5,
                                color: _gris,
                              ),
                              maxLines: 2,
                            ),
                          ],
                        ],
                      ),
                    ),
                    _celdaCentro('1'),
                    _celdaDerecha(formatearSoles(total)),
                    _celdaDerecha(formatearSoles(total)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 14),

            // ============ TOTALES + ESTADO DE PAGO ============
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Estado de pago
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: colorPago, width: 1),
                      borderRadius: pw.BorderRadius.circular(10),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'ESTADO DE PAGO: ${_etiquetaEstadoPago(p.estadoPago)}',
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: colorPago,
                          ),
                        ),
                        pw.SizedBox(height: 6),
                        pw.Text(
                          'Forma de pago: ${_etiquetaTipoPago(p.tipoPago)}',
                          style: const pw.TextStyle(
                            fontSize: 9,
                            color: PdfColors.black,
                          ),
                        ),
                        pw.Text(
                          'Pagado: ${formatearSoles(p.montoPagado)}   ·   Saldo: ${formatearSoles(p.saldoPendiente)}',
                          style: const pw.TextStyle(
                            fontSize: 9,
                            color: PdfColors.black,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Estado del proyecto: ${_etiquetaEstadoProyecto(p.estado)}',
                          style: const pw.TextStyle(
                            fontSize: 8.5,
                            color: _gris,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 12),
                // Totales
                pw.Container(
                  width: 210,
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: _fondo,
                    borderRadius: pw.BorderRadius.circular(10),
                  ),
                  child: pw.Column(
                    children: [
                      _filaTotal(
                        'Op. Gravada',
                        formatearSoles(gravada),
                        colorTexto: PdfColors.white,
                      ),
                      _filaTotal(
                        'IGV (18%)',
                        formatearSoles(igv),
                        colorTexto: PdfColors.white,
                      ),
                      pw.Container(
                        margin: const pw.EdgeInsets.symmetric(vertical: 6),
                        height: 1,
                        color: _gris,
                      ),
                      pw.Row(
                        mainAxisAlignment:
                            pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'TOTAL',
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                              color: _verde,
                            ),
                          ),
                          pw.Text(
                            formatearSoles(total),
                            style: pw.TextStyle(
                              fontSize: 15,
                              fontWeight: pw.FontWeight.bold,
                              color: _verde,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 28),

            // ============ FIRMAS ============
            pw.Row(
              children: [
                pw.Expanded(child: _firma('Cliente', p.cliente.nombre)),
                pw.SizedBox(width: 24),
                pw.Expanded(child: _firma('EM Code Studio', empresaNombre)),
              ],
            ),

            pw.Spacer(),

            // ============ PIE ============
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: _oscuro,
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Gracias por confiar en $empresaNombre',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: _verde,
                    ),
                  ),
                  pw.Text(
                    'Documento interno de cobranza · sin valor tributario',
                    style: const pw.TextStyle(fontSize: 7.5, color: _gris),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  // ============ AUXILIARES DE DISEÑO ============

  static pw.Widget _cajaInfo(String titulo, List<String> lineas) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            titulo,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: _gris,
              letterSpacing: 1.5,
            ),
          ),
          pw.SizedBox(height: 6),
          for (var i = 0; i < lineas.length; i++)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 2),
              child: pw.Text(
                lineas[i],
                style: pw.TextStyle(
                  fontSize: i == 0 ? 11 : 9.5,
                  fontWeight: i == 0 ? pw.FontWeight.bold : pw.FontWeight.normal,
                  color: i == 0 ? PdfColors.black : PdfColors.grey700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  static List<pw.Widget> _celdas(
    List<String> textos, {
    bool esCabecera = false,
  }) {
    return textos.map((t) {
      return pw.Padding(
        padding: const pw.EdgeInsets.all(7),
        child: pw.Text(
          t,
          style: pw.TextStyle(
            fontSize: 8.5,
            fontWeight: esCabecera ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: esCabecera ? PdfColors.white : PdfColors.black,
            letterSpacing: esCabecera ? 0.8 : 0,
          ),
        ),
      );
    }).toList();
  }

  static pw.Widget _celdaCentro(String texto) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        texto,
        textAlign: pw.TextAlign.center,
        style: const pw.TextStyle(fontSize: 10),
      ),
    );
  }

  static pw.Widget _celdaDerecha(String texto) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        texto,
        textAlign: pw.TextAlign.right,
        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  static pw.Widget _filaTotal(
    String label,
    String valor, {
    PdfColor colorTexto = PdfColors.black,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(fontSize: 9.5, color: colorTexto),
        ),
        pw.Text(
          valor,
          style: pw.TextStyle(fontSize: 9.5, color: colorTexto),
        ),
      ],
    );
  }

  static pw.Widget _firma(String titulo, String nombre) {
    return pw.Column(
      children: [
        pw.Container(height: 1, color: PdfColors.grey500),
        pw.SizedBox(height: 5),
        pw.Text(
          titulo,
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.black,
          ),
        ),
        pw.Text(
          nombre,
          style: const pw.TextStyle(fontSize: 8, color: _gris),
        ),
      ],
    );
  }
}
