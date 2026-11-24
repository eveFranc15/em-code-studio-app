import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'modelos.dart';
import 'database_helper.dart';
import 'pdf_actions.dart';
import 'boleta_pdf.dart';
import 'animaciones_web.dart';
import 'animaciones_svg.dart';

/// Períodos de reporte disponibles
enum PeriodoReporte { dia, semana, mes, anio }

class EstadisticasScreen extends StatefulWidget {
  const EstadisticasScreen({super.key});

  @override
  State<EstadisticasScreen> createState() => _EstadisticasScreenState();
}

class _EstadisticasScreenState extends State<EstadisticasScreen> {
  // Colores usados en el PDF
  static const _pdfVerde = PdfColor.fromInt(0xFF33FF99);
  static const _pdfLila = PdfColor.fromInt(0xFFB388FF);
  static const _pdfAzul = PdfColor.fromInt(0xFF3498DB);
  static const _pdfNaranja = PdfColor.fromInt(0xFFF39C12);
  static const _pdfOscuro = PdfColor.fromInt(0xFF0D0D12);
  static const _pdfGris = PdfColor.fromInt(0xFF8888A0);

  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Proyecto> _todos = [];
  bool _cargando = true;
  bool _generandoPdf = false;

  PeriodoReporte _periodo = PeriodoReporte.semana;
  int _desplazamiento = 0; // 0 = período actual, -1 = anterior, etc.

  @override
  void initState() {
    super.initState();
    _cargarProyectos();
  }

  Future<void> _cargarProyectos() async {
    setState(() => _cargando = true);
    final lista = await _dbHelper.obtenerProyectos();
    setState(() {
      _todos = lista;
      _cargando = false;
    });
  }

  // ============ CÁLCULOS DE PERÍODO ============

  DateTime get _hoy => DateTime.now();

  /// Fecha en la que se contabiliza la venta en los reportes: la de
  /// REGISTRO (cuando se agregó el proyecto), que refleja el día en
  /// que se hizo la venta. Si no existe, respalda con la de entrega.
  DateTime _fechaVenta(Proyecto p) => p.fechaRegistro ?? p.fechaEntrega;

  /// Lunes de la semana actual
  DateTime _inicioSemana() {
    final hoy = DateTime(_hoy.year, _hoy.month, _hoy.day);
    return hoy.subtract(Duration(days: hoy.weekday - 1));
  }

  DateTime _inicioMes() => DateTime(_hoy.year, _hoy.month, 1);

  DateTime get _inicioPeriodo {
    switch (_periodo) {
      case PeriodoReporte.dia:
        final base = DateTime(_hoy.year, _hoy.month, _hoy.day);
        return base.add(Duration(days: _desplazamiento));
      case PeriodoReporte.semana:
        return _inicioSemana().add(Duration(days: 7 * _desplazamiento));
      case PeriodoReporte.mes:
        final base = _inicioMes();
        return DateTime(base.year, base.month + _desplazamiento, 1);
      case PeriodoReporte.anio:
        return DateTime(_hoy.year + _desplazamiento, 1, 1);
    }
  }

  DateTime get _finPeriodo {
    switch (_periodo) {
      case PeriodoReporte.dia:
        return _inicioPeriodo.add(const Duration(days: 1));
      case PeriodoReporte.semana:
        return _inicioPeriodo.add(const Duration(days: 7));
      case PeriodoReporte.mes:
        final inicio = _inicioPeriodo;
        return DateTime(inicio.year, inicio.month + 1, 1);
      case PeriodoReporte.anio:
        return DateTime(_inicioPeriodo.year + 1, 1, 1);
    }
  }

  String get _tituloPeriodo {
    final inicio = _inicioPeriodo;
    const meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    switch (_periodo) {
      case PeriodoReporte.dia:
        return 'Día ${inicio.day} de ${meses[inicio.month - 1]} ${inicio.year}';
      case PeriodoReporte.semana:
        final fin = _inicioPeriodo.add(const Duration(days: 6));
        return 'Semana del ${inicio.day} al ${fin.day} de ${meses[fin.month - 1]} ${fin.year}';
      case PeriodoReporte.mes:
        return '${meses[inicio.month - 1]} ${inicio.year}';
      case PeriodoReporte.anio:
        return 'Año ${inicio.year}';
    }
  }

  String get _nombrePeriodo {
    switch (_periodo) {
      case PeriodoReporte.dia:
        return 'Día';
      case PeriodoReporte.semana:
        return 'Semana';
      case PeriodoReporte.mes:
        return 'Mes';
      case PeriodoReporte.anio:
        return 'Año';
    }
  }

  List<Proyecto> get _proyectosDelPeriodo {
    final inicio = _inicioPeriodo;
    final fin = _finPeriodo;
    return _todos.where((p) {
      final f = DateTime(_fechaVenta(p).year, _fechaVenta(p).month, _fechaVenta(p).day);
      return !f.isBefore(inicio) && f.isBefore(fin);
    }).toList();
  }

  double _suma(List<Proyecto> lista, double Function(Proyecto) fn) =>
      lista.fold(0.0, (s, p) => s + fn(p));

  // ============ SERIE DE DATOS PARA GRÁFICOS ============

  /// Devuelve etiquetas y montos para el gráfico de barras del período
  List<MapEntry<String, double>> _serieBarras() {
    final proyectos = _proyectosDelPeriodo;
    final inicio = _inicioPeriodo;

    switch (_periodo) {
      case PeriodoReporte.dia:
        // Un solo día: una sola barra con el total del día
        final totalDia = _suma(proyectos, (p) => p.montoTotal);
        return [MapEntry('Ventas', totalDia)];

      case PeriodoReporte.semana:
        // 7 días: Lun..Dom
        const dias = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
        final montos = List<double>.filled(7, 0);
        for (final p in proyectos) {
          final venta = _fechaVenta(p);
          final diff = DateTime(venta.year, venta.month, venta.day)
              .difference(inicio)
              .inDays;
          if (diff >= 0 && diff < 7) montos[diff] += p.montoTotal;
        }
        return List.generate(7, (i) => MapEntry(dias[i], montos[i]));

      case PeriodoReporte.mes:
        // Semanas del mes: S1..S5
        final diasEnMes = DateTime(inicio.year, inicio.month + 1, 0).day;
        final numSemanas = ((diasEnMes + inicio.weekday - 1) / 7).ceil();
        final montos = List<double>.filled(numSemanas, 0);
        for (final p in proyectos) {
          final venta = _fechaVenta(p);
          final diaMes = venta.day;
          final idxSemana = ((diaMes + inicio.weekday - 1) ~/ 7).clamp(0, numSemanas - 1);
          montos[idxSemana] += p.montoTotal;
        }
        return List.generate(numSemanas, (i) => MapEntry('S${i + 1}', montos[i]));

      case PeriodoReporte.anio:
        const meses = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
        final montos = List<double>.filled(12, 0);
        for (final p in proyectos) {
          final venta = _fechaVenta(p);
          if (venta.year == inicio.year) {
            montos[venta.month - 1] += p.montoTotal;
          }
        }
        return List.generate(12, (i) => MapEntry(meses[i], montos[i]));
    }
  }

  /// Servicios más vendidos del período: nombre -> monto
  Map<String, double> _ventasPorServicio() {
    final mapa = <String, double>{};
    for (final p in _proyectosDelPeriodo) {
      final clave = p.tipoServicio.trim().isEmpty ? 'Sin especificar' : p.tipoServicio;
      mapa[clave] = (mapa[clave] ?? 0) + p.montoTotal;
    }
    return mapa;
  }

  // ============ UI ============

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Reportes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarProyectos,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: FondoAnimado(
        child: _cargando
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF33FF99)))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cabecera tecnológica animada (panel de datos)
                    const BannerTecnologico(
                      motivo: MotivoTecnologico.data,
                      titulo: 'REPORTES',
                      subtitulo: 'Analítica de ventas en tiempo real',
                      acento: Color(0xFF3498DB),
                    ),
                    const SizedBox(height: 16),
                    _buildSelectorPeriodo(),
                    const SizedBox(height: 16),
                    _buildBotonBoleta(),
                    const SizedBox(height: 16),
                    _buildKpis(),
                    const SizedBox(height: 20),
                    _buildGraficoBarras(),
                    const SizedBox(height: 20),
                    _buildTopServicios(),
                    const SizedBox(height: 20),
                    _buildResumenProductos(),
                    const SizedBox(height: 90),
                  ],
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _generandoPdf ? null : _abrirOpcionesPdf,
        backgroundColor: const Color(0xFF33FF99),
        foregroundColor: const Color(0xFF0D0D12),
        icon: _generandoPdf
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0D0D12)),
              )
            : const Icon(Icons.picture_as_pdf),
        label: Text(_generandoPdf ? 'Generando...' : 'Exportar PDF'),
      ),
    );
  }

  Widget _buildSelectorPeriodo() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A24),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF8888A0).withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildBotonPeriodo(PeriodoReporte.dia, 'DÍA'),
              const SizedBox(width: 6),
              _buildBotonPeriodo(PeriodoReporte.semana, 'SEMANA'),
              const SizedBox(width: 6),
              _buildBotonPeriodo(PeriodoReporte.mes, 'MES'),
              const SizedBox(width: 6),
              _buildBotonPeriodo(PeriodoReporte.anio, 'AÑO'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                onPressed: () => setState(() => _desplazamiento--),
                icon: const Icon(Icons.chevron_left, color: Color(0xFF33FF99)),
                tooltip: 'Período anterior',
              ),
              Expanded(
                child: Text(
                  _tituloPeriodo,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFF4F4F6),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              IconButton(
                onPressed: _desplazamiento < 0
                    ? () => setState(() => _desplazamiento++)
                    : null,
                icon: Icon(
                  Icons.chevron_right,
                  color: _desplazamiento < 0 ? const Color(0xFF33FF99) : const Color(0xFF8888A0),
                ),
                tooltip: 'Período siguiente',
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Botón para generar la BOLETA DE VENTA de un proyecto.
  /// (También disponible dentro del detalle de cada proyecto.)
  Widget _buildBotonBoleta() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _todos.isEmpty ? null : _elegirProyectoParaBoleta,
        icon: const Icon(Icons.receipt_long, color: Color(0xFF33FF99)),
        label: const Text(
          'GENERAR BOLETA DE VENTA',
          style: TextStyle(
            color: Color(0xFF33FF99),
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: const BorderSide(color: Color(0xFF33FF99)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  /// Selector de proyecto → genera la boleta con vista previa / descarga /
  /// compartir.
  Future<void> _elegirProyectoParaBoleta() async {
    final elegido = await showModalBottomSheet<Proyecto>(
      context: context,
      backgroundColor: const Color(0xFF16161F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: _todos.length,
          separatorBuilder: (_, __) => const Divider(color: Color(0xFF8888A0)),
          itemBuilder: (ctx, i) {
            final p = _todos[i];
            return ListTile(
              leading: const Icon(Icons.receipt_long, color: Color(0xFF33FF99)),
              title: Text(
                p.nombreProyecto,
                style: const TextStyle(color: Color(0xFFF4F4F6)),
              ),
              subtitle: Text(
                formatearSoles(p.montoTotal),
                style: const TextStyle(color: Color(0xFF33FF99)),
              ),
              onTap: () => Navigator.pop(ctx, p),
            );
          },
        ),
      ),
    );

    if (elegido == null || !mounted) return;
    await PdfActions.mostrarOpciones(
      context,
      titulo: 'BOLETA DE VENTA',
      subtitulo:
          '${elegido.nombreProyecto} · ${formatearSoles(elegido.montoTotal)}',
      nombreArchivo:
          'Boleta_EMCodeStudio_${elegido.id ?? elegido.nombreProyecto}',
      generar: () => BoletaPdf.generar(elegido),
    );
  }

  Widget _buildBotonPeriodo(PeriodoReporte p, String texto) {
    final activo = _periodo == p;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _periodo = p;
          _desplazamiento = 0;
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: activo ? const Color(0xFF33FF99).withValues(alpha: 0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: activo ? const Color(0xFF33FF99) : Colors.transparent,
            ),
          ),
          child: Text(
            texto,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: activo ? const Color(0xFF33FF99) : const Color(0xFF8888A0),
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKpis() {
    final proyectos = _proyectosDelPeriodo;
    final vendido = _suma(proyectos, (p) => p.montoTotal);
    final cobrado = _suma(proyectos, (p) => p.montoPagado);
    final pendiente = vendido - cobrado;

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _kpiCard('Vendido', const Color(0xFF33FF99), Icons.attach_money, valor: vendido, prefijo: 'S/ ')),
            const SizedBox(width: 10),
            Expanded(child: _kpiCard('Proyectos', const Color(0xFFB388FF), Icons.work, valor: proyectos.length.toDouble())),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _kpiCard('Cobrado', const Color(0xFF3498DB), Icons.check_circle_outline, valor: cobrado, prefijo: 'S/ ')),
            const SizedBox(width: 10),
            Expanded(child: _kpiCard('Pendiente', const Color(0xFFF39C12), Icons.schedule, valor: pendiente, prefijo: 'S/ ')),
          ],
        ),
      ],
    );
  }

  Widget _kpiCard(String label, Color color, IconData icono, {required double valor, String prefijo = ''}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icono, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ContadorAnimado(
                  valor: valor,
                  prefijo: prefijo,
                  estilo: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: color),
                ),
                Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF8888A0))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGraficoBarras() {
    final serie = _serieBarras();
    final maxValor = serie.fold<double>(0, (m, e) => e.value > m ? e.value : m);
    final hayDatos = serie.any((e) => e.value > 0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF8888A0).withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'VENTAS DEL PERÍODO',
                style: TextStyle(fontSize: 12, color: Color(0xFF8888A0), letterSpacing: 2),
              ),
              Text(
                formatearSoles(_suma(_proyectosDelPeriodo, (p) => p.montoTotal), decimales: 0),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF33FF99)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!hayDatos)
            const SizedBox(
              height: 180,
              child: Center(
                child: Text(
                  'Sin ventas registradas en este período',
                  style: TextStyle(color: Color(0xFF8888A0), fontSize: 14),
                ),
              ),
            )
          else
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxValor * 1.25,
                  barGroups: serie.asMap().entries.map((e) {
                    return BarChartGroupData(
                      x: e.key,
                      barRods: [
                        BarChartRodData(
                          toY: e.value.value,
                          width: _periodo == PeriodoReporte.anio ? 16 : 26,
                          color: e.value.value > 0 ? const Color(0xFF33FF99) : const Color(0xFF2A2A38),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }).toList(),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (v) => FlLine(
                      color: Colors.white.withValues(alpha: 0.05),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (i >= 0 && i < serie.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                serie[i].key,
                                style: TextStyle(
                                  fontSize: _periodo == PeriodoReporte.anio ? 9 : 11,
                                  color: const Color(0xFF8888A0),
                                ),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 44,
                        getTitlesWidget: (value, meta) {
                          if (value <= 0) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Text(
                              value >= 1000
                                  ? '${(value / 1000).toStringAsFixed(1)}k'
                                  : value.toStringAsFixed(0),
                              style: const TextStyle(fontSize: 9, color: Color(0xFF8888A0)),
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTopServicios() {
    final ventas = _ventasPorServicio();
    if (ventas.isEmpty) return const SizedBox.shrink();

    final ordenado = ventas.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final total = ventas.values.fold<double>(0, (s, v) => s + v);
    const colores = [
      Color(0xFF33FF99),
      Color(0xFFB388FF),
      Color(0xFF3498DB),
      Color(0xFFF39C12),
      Color(0xFFE74C3C),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF8888A0).withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SERVICIOS MÁS VENDIDOS',
            style: TextStyle(fontSize: 12, color: Color(0xFF8888A0), letterSpacing: 2),
          ),
          const SizedBox(height: 16),
          if (ordenado.length > 1)
            SizedBox(
              height: 180,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 3,
                  centerSpaceRadius: 36,
                  sections: ordenado.asMap().entries.map((e) {
                    final color = colores[e.key % colores.length];
                    final porcentaje = total > 0 ? (e.value.value / total * 100) : 0.0;
                    return PieChartSectionData(
                      value: e.value.value,
                      color: color,
                      radius: 56,
                      title: '${porcentaje.toStringAsFixed(0)}%',
                      titleStyle: const TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          const SizedBox(height: 12),
          ...ordenado.asMap().entries.map((e) {
            final color = colores[e.key % colores.length];
            final porcentaje = total > 0 ? (e.value.value / total * 100) : 0.0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Center(
                      child: Text(
                        '${e.key + 1}',
                        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      e.value.key,
                      style: const TextStyle(fontSize: 14, color: Color(0xFFF4F4F6)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${porcentaje.toStringAsFixed(0)}%',
                    style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    formatearSoles(e.value.value, decimales: 0),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildResumenProductos() {
    final proyectos = _proyectosDelPeriodo;
    if (proyectos.isEmpty) return const SizedBox.shrink();

    final ordenados = [...proyectos]..sort((a, b) => b.fechaEntrega.compareTo(a.fechaEntrega));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF8888A0).withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DETALLE DE PROYECTOS (${ordenados.length})',
            style: const TextStyle(fontSize: 12, color: Color(0xFF8888A0), letterSpacing: 2),
          ),
          const SizedBox(height: 12),
          ...ordenados.map((p) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _colorEstado(p.estado),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.nombreProyecto,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFFF4F4F6),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${p.cliente.nombre} · ${p.fechaEntrega.day}/${p.fechaEntrega.month}/${p.fechaEntrega.year}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF8888A0)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatearSoles(p.montoTotal),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        _textoEstado(p.estado),
                        style: TextStyle(fontSize: 11, color: _colorEstado(p.estado)),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Color _colorEstado(EstadoProyecto e) {
    switch (e) {
      case EstadoProyecto.pendiente:
        return const Color(0xFFF39C12);
      case EstadoProyecto.enProceso:
        return const Color(0xFFB388FF);
      case EstadoProyecto.terminado:
        return const Color(0xFF33FF99);
    }
  }

  String _textoEstado(EstadoProyecto e) {
    switch (e) {
      case EstadoProyecto.pendiente:
        return 'Pendiente';
      case EstadoProyecto.enProceso:
        return 'En proceso';
      case EstadoProyecto.terminado:
        return 'Terminado';
    }
  }

  // ============ EXPORTAR PDF ============

  Future<void> _abrirOpcionesPdf() async {
    await PdfActions.mostrarOpciones(
      context,
      titulo: 'REPORTE DE VENTAS',
      subtitulo: '$_nombrePeriodo · $_tituloPeriodo',
      nombreArchivo: 'Reporte_EMCodeStudio_${_nombrePeriodo}_$_desplazamiento',
      generar: () async {
        setState(() => _generandoPdf = true);
        try {
          return await _generarPdf();
        } finally {
          if (mounted) setState(() => _generandoPdf = false);
        }
      },
    );
  }

  Future<Uint8List> _generarPdf() async {
    final pdf = pw.Document();
    final proyectos = _proyectosDelPeriodo;
    final serie = _serieBarras();
    final ventasServicio = _ventasPorServicio();
    final ordenadoServicios = ventasServicio.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final vendido = _suma(proyectos, (p) => p.montoTotal);
    final cobrado = _suma(proyectos, (p) => p.montoPagado);
    final pendiente = vendido - cobrado;

    const verde = _pdfVerde;
    const lila = _pdfLila;
    const oscuro = _pdfOscuro;
    const gris = _pdfGris;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 16),
          child: pw.Text(
            'EM Code Studio · Página ${context.pageNumber} de ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: gris),
          ),
        ),
        build: (context) => [
          // Encabezado
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: oscuro,
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'EM CODE STUDIO',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: verde,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Reporte de ventas - $_nombrePeriodo',
                      style: const pw.TextStyle(fontSize: 11, color: PdfColors.white),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      _tituloPeriodo,
                      style: const pw.TextStyle(fontSize: 10, color: gris),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Emitido: ${_hoy.day}/${_hoy.month}/${_hoy.year}',
                      style: const pw.TextStyle(fontSize: 9, color: gris),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // Resumen
          pw.Text(
            'RESUMEN DEL PERÍODO',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
              letterSpacing: 1,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
              _pdfKpi('Total vendido', formatearSoles(vendido), verde),
              pw.SizedBox(width: 8),
              _pdfKpi('Cobrado', formatearSoles(cobrado), _pdfAzul),
              pw.SizedBox(width: 8),
              _pdfKpi('Pendiente', formatearSoles(pendiente), _pdfNaranja),
              pw.SizedBox(width: 8),
              _pdfKpi('Proyectos', '${proyectos.length}', lila),
            ],
          ),
          pw.SizedBox(height: 20),

          // Gráfico de barras dibujado manualmente
          pw.Text(
            'VENTAS POR ${_periodo == PeriodoReporte.anio ? 'MES' : _periodo == PeriodoReporte.mes ? 'SEMANA' : 'DÍA'}',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
              letterSpacing: 1,
            ),
          ),
          pw.SizedBox(height: 10),
          _pdfGraficoBarras(serie),
          pw.SizedBox(height: 20),

          // Servicios más vendidos
          if (ordenadoServicios.isNotEmpty) ...[
            pw.Text(
              'SERVICIOS MÁS VENDIDOS',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey800,
                letterSpacing: 1,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(1),
                1: const pw.FlexColumnWidth(3),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FlexColumnWidth(2),
              },
              children: [
                _pdfFilaTabla(['#', 'Servicio', 'Monto', '% del total'], esCabecera: true),
                ...ordenadoServicios.asMap().entries.map((e) {
                  final total = ventasServicio.values.fold<double>(0, (s, v) => s + v);
                  final pct = total > 0 ? (e.value.value / total * 100) : 0.0;
                  return _pdfFilaTabla([
                    '${e.key + 1}',
                    e.value.key,
                    formatearSoles(e.value.value),
                    '${pct.toStringAsFixed(1)}%',
                  ]);
                }),
              ],
            ),
            pw.SizedBox(height: 20),
          ],

          // Detalle de proyectos
          if (proyectos.isNotEmpty) ...[
            pw.Text(
              'DETALLE DE PROYECTOS',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey800,
                letterSpacing: 1,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FlexColumnWidth(1.5),
                4: const pw.FlexColumnWidth(2),
                5: const pw.FlexColumnWidth(1.5),
              },
              children: [
                _pdfFilaTabla(
                  ['Proyecto', 'Cliente', 'Fecha', 'Estado', 'Monto', 'Pagado'],
                  esCabecera: true,
                ),
                ...proyectos.map((p) => _pdfFilaTabla([
                      p.nombreProyecto,
                      p.cliente.nombre,
                      '${p.fechaEntrega.day}/${p.fechaEntrega.month}/${p.fechaEntrega.year}',
                      _textoEstado(p.estado),
                      formatearSoles(p.montoTotal),
                      formatearSoles(p.montoPagado),
                    ])),
              ],
            ),
          ] else
            pw.Container(
              padding: const pw.EdgeInsets.all(24),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Center(
                child: pw.Text(
                  'No hay proyectos registrados en este período',
                  style: const pw.TextStyle(color: gris),
                ),
              ),
            ),
        ],
      ),
    );

    return pdf.save();
  }

  pw.Widget _pdfKpi(String label, String valor, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: color, width: 0.8),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              valor,
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: color),
            ),
            pw.SizedBox(height: 3),
            pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: _pdfGris)),
          ],
        ),
      ),
    );
  }

  pw.Widget _pdfGraficoBarras(List<MapEntry<String, double>> serie) {
    final maxValor = serie.fold<double>(0, (m, e) => e.value > m ? e.value : m);
    if (maxValor <= 0) {
      return pw.Container(
        height: 80,
        alignment: pw.Alignment.center,
        child: pw.Text('Sin datos en este período', style: const pw.TextStyle(color: _pdfGris)),
      );
    }

    return pw.Container(
      height: 140,
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: serie.map((e) {
          final altura = (e.value / maxValor) * 100;
          return pw.Expanded(
            child: pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 2),
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  if (e.value > 0)
                    pw.Text(
                      e.value >= 1000
                          ? '${(e.value / 1000).toStringAsFixed(1)}k'
                          : e.value.toStringAsFixed(0),
                      style: const pw.TextStyle(fontSize: 6, color: _pdfGris),
                    ),
                  pw.SizedBox(height: 2),
                  pw.Container(
                    height: altura < 3 ? 3 : altura,
                    decoration: pw.BoxDecoration(
                      color: e.value > 0 ? _pdfVerde : PdfColors.grey400,
                      borderRadius: pw.BorderRadius.circular(2),
                    ),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(e.key, style: const pw.TextStyle(fontSize: 7, color: _pdfGris)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  pw.TableRow _pdfFilaTabla(List<String> celdas, {bool esCabecera = false}) {
    return pw.TableRow(
      decoration: esCabecera
          ? const pw.BoxDecoration(color: PdfColor.fromInt(0xFF0D0D12))
          : null,
      children: celdas.map((c) {
        return pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(
            c,
            style: pw.TextStyle(
              fontSize: 8.5,
              fontWeight: esCabecera ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: esCabecera ? PdfColors.white : PdfColors.black,
            ),
            maxLines: 2,
          ),
        );
      }).toList(),
    );
  }
}
