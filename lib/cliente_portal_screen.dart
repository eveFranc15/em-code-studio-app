import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'animaciones_svg.dart';
import 'animaciones_web.dart';
import 'modelos.dart';
import 'database_helper.dart';
import 'login_screen.dart';

/// Panel del cliente.
///
/// Es la ÚNICA pantalla a la que llega el cliente: aquí ve el estado de su
/// servicio, en qué etapa está, el porcentaje de avance (gráfico) y las
/// imágenes de progreso que sube el estudio. No tiene secciones de marketing
/// (quienes somos, servicios, contacto): si el cliente está aquí ya conoce
/// el estudio.
class ClientePortalScreen extends StatefulWidget {
  final Cliente cliente;

  const ClientePortalScreen({super.key, required this.cliente});

  @override
  State<ClientePortalScreen> createState() => _ClientePortalScreenState();
}

class _ClientePortalScreenState extends State<ClientePortalScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Proyecto> proyectos = [];
  Empresa _empresa = Empresa();
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarProyectos();
    _cargarEmpresa();
  }

  Future<void> _cargarProyectos() async {
    setState(() => _cargando = true);
    final lista = await _dbHelper.obtenerProyectos();
    if (!mounted) return;
    setState(() {
      proyectos = lista
          .where((p) => p.cliente.nombre.trim().toLowerCase() ==
              widget.cliente.nombre.trim().toLowerCase())
          .toList();
      _cargando = false;
    });
  }

  /// Ubicación del estudio (la edita el admin desde Configuración).
  Future<void> _cargarEmpresa() async {
    final e = await _dbHelper.obtenerEmpresa();
    if (!mounted) return;
    setState(() => _empresa = e);
  }

  /// Abre la ubicación del estudio en Google Maps.
  Future<void> _abrirUbicacionEnMaps() async {
    if (!_empresa.tieneCoordenadas && (_empresa.direccion ?? '').trim().isEmpty) {
      return;
    }
    final destino = _empresa.tieneCoordenadas
        ? '${_empresa.latitud},${_empresa.longitud}'
        : Uri.encodeQueryComponent(_empresa.direccion!.trim());
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$destino');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo abrir Google Maps'),
          backgroundColor: Color(0xFFE74C3C),
        ),
      );
    }
  }

  void _cerrarSesion() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  Color _colorEstado(EstadoProyecto estado) {
    switch (estado) {
      case EstadoProyecto.pendiente:
        return const Color(0xFFF39C12);
      case EstadoProyecto.enProceso:
        return const Color(0xFFB388FF);
      case EstadoProyecto.terminado:
        return const Color(0xFF33FF99);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FondoAnimado(
        child: RefreshIndicator(
          color: const Color(0xFF33FF99),
          backgroundColor: const Color(0xFF1A1A24),
          onRefresh: _cargarProyectos,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                // ===== CABECERA =====
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 50, 20, 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF33FF99).withValues(alpha: 0.15),
                        const Color(0xFFB388FF).withValues(alpha: 0.1),
                        const Color(0xFF0D0D12),
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF33FF99).withValues(alpha: 0.4),
                              ),
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/logo.png',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => const Icon(
                                  Icons.code,
                                  color: Color(0xFF33FF99),
                                  size: 22,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'MI PANEL',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2,
                                    color: Color(0xFFF4F4F6),
                                  ),
                                ),
                                Text(
                                  'Seguimiento de tu servicio',
                                  style: TextStyle(fontSize: 12, color: Color(0xFF8888A0)),
                                ),
                              ],
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _cerrarSesion,
                            icon: const Icon(Icons.logout, size: 18, color: Color(0xFFE74C3C)),
                            label: const Text(
                              'SALIR',
                              style: TextStyle(
                                color: Color(0xFFE74C3C),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A24),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF8888A0).withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          widget.cliente.nombre,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFF4F4F6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: BannerTecnologico(
                    motivo: MotivoTecnologico.radar,
                    titulo: 'ESTADO DE TU SERVICIO',
                    subtitulo: 'Avance en tiempo real',
                    acento: Color(0xFF33FF99),
                  ),
                ),
                // ===== UBICACIÓN DEL ESTUDIO =====
                if (_empresa.tieneCoordenadas || (_empresa.fotoUrl ?? '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: _TarjetaUbicacion(
                      empresa: _empresa,
                      onAbrirMaps: _abrirUbicacionEnMaps,
                    ),
                  ),
                // ===== CONTENIDO =====
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: _cargando
                      ? const Padding(
                          padding: EdgeInsets.all(40),
                          child: Center(
                            child: CircularProgressIndicator(color: Color(0xFF33FF99)),
                          ),
                        )
                      : proyectos.isEmpty
                          ? const _SinServicios()
                          : Column(
                              children: [
                                ...proyectos.map((p) => _TarjetaProyecto(
                                      proyecto: p,
                                      color: _colorEstado(p.estado),
                                    )),
                                const SizedBox(height: 8),
                                const Text(
                                  'Desliza hacia abajo para actualizar',
                                  style: TextStyle(fontSize: 11, color: Color(0xFF8888A0)),
                                ),
                              ],
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SinServicios extends StatelessWidget {
  const _SinServicios();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(Icons.work_off, size: 60, color: Color(0xFF8888A0)),
          SizedBox(height: 16),
          Text(
            'Aún no tienes servicios contratados',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Color(0xFF8888A0)),
          ),
          SizedBox(height: 8),
          Text(
            'Cuando iniciemos tu proyecto, verás aquí su avance.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xFF8888A0)),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta de ubicación del estudio: foto del lugar + dirección y,
/// al seleccionar la foto, aparecen las coordenadas con la opción de
/// abrir Google Maps. (Recomendación del profesor)
class _TarjetaUbicacion extends StatelessWidget {
  final Empresa empresa;
  final VoidCallback onAbrirMaps;

  const _TarjetaUbicacion({required this.empresa, required this.onAbrirMaps});

  void _verFotoYCoordenadas(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: const Color(0xFF16161D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'UBICACIÓN DEL ESTUDIO',
                style: TextStyle(fontSize: 12, color: Color(0xFF8888A0), letterSpacing: 2),
              ),
              const SizedBox(height: 12),
              if ((empresa.fotoUrl ?? '').isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    empresa.fotoUrl!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox(
                      height: 120,
                      child: Icon(Icons.location_on, size: 60, color: Color(0xFF33FF99)),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              if ((empresa.direccion ?? '').isNotEmpty)
                Text(
                  empresa.direccion!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15, color: Color(0xFFF4F4F6), fontWeight: FontWeight.bold),
                ),
              const SizedBox(height: 8),
              if (empresa.tieneCoordenadas)
                Text(
                  'Lat: ${empresa.latitud!.toStringAsFixed(6)}  ·  Lng: ${empresa.longitud!.toStringAsFixed(6)}',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF33FF99)),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    onAbrirMaps();
                  },
                  icon: const Icon(Icons.map, size: 18),
                  label: const Text('ABRIR EN GOOGLE MAPS'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF33FF99),
                    foregroundColor: const Color(0xFF0D0D12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('CERRAR', style: TextStyle(fontSize: 12, color: Color(0xFF8888A0))),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16161D),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF33FF99).withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF33FF99).withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.location_on, size: 18, color: Color(0xFF33FF99)),
              SizedBox(width: 6),
              Text(
                'UBICACIÓN DEL ESTUDIO',
                style: TextStyle(fontSize: 12, color: Color(0xFF8888A0), letterSpacing: 2, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Foto: al seleccionarla aparecen las coordenadas
              if ((empresa.fotoUrl ?? '').isNotEmpty)
                GestureDetector(
                  onTap: () => _verFotoYCoordenadas(context),
                  child: Hero(
                    tag: 'foto-empresa',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        empresa.fotoUrl!,
                        width: 84,
                        height: 84,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 84,
                          height: 84,
                          color: const Color(0xFF1A1A24),
                          child: const Icon(Icons.location_on, color: Color(0xFF33FF99)),
                        ),
                      ),
                    ),
                  ),
                ),
              if ((empresa.fotoUrl ?? '').isNotEmpty) const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (empresa.direccion ?? '').isEmpty
                          ? 'Dirección no registrada'
                          : empresa.direccion!,
                      style: const TextStyle(fontSize: 14, color: Color(0xFFF4F4F6), fontWeight: FontWeight.w600),
                    ),
                    if (empresa.tieneCoordenadas) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Lat: ${empresa.latitud!.toStringAsFixed(6)}\nLng: ${empresa.longitud!.toStringAsFixed(6)}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF8888A0)),
                      ),
                    ],
                    const SizedBox(height: 6),
                    const Text(
                      'Toca la foto para ver los detalles',
                      style: TextStyle(fontSize: 11, color: Color(0xFF8888A0)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: onAbrirMaps,
              icon: const Icon(Icons.map, size: 18),
              label: const Text('ABRIR EN GOOGLE MAPS'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF33FF99),
                foregroundColor: const Color(0xFF0D0D12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta de un proyecto: estado, gráfico de avance, etapa y fotos.
class _TarjetaProyecto extends StatelessWidget {
  final Proyecto proyecto;
  final Color color;

  const _TarjetaProyecto({required this.proyecto, required this.color});

  @override
  Widget build(BuildContext context) {
    final avance = proyecto.avanceCalculado;
    final ahora = DateTime.now();
    final diasRestantes = proyecto.fechaEntrega.difference(ahora).inDays;
    final fotos = proyecto.imagenes ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16161D),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---- Título y estado ----
          Row(
            children: [
              Icon(Icons.work, color: color, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  proyecto.nombreProyecto,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFF4F4F6),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withValues(alpha: 0.5)),
                ),
                child: Text(
                  _textoEstado(proyecto.estado),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: color,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            proyecto.tipoServicio,
            style: const TextStyle(fontSize: 12, color: Color(0xFF8888A0)),
          ),
          const SizedBox(height: 16),

          // ---- Gráfico de avance + etapa ----
          Row(
            children: [
              SizedBox(
                width: 110,
                height: 110,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: avance / 100),
                      duration: const Duration(milliseconds: 1200),
                      curve: Curves.easeOutCubic,
                      builder: (context, valor, _) {
                        return CustomPaint(
                          size: const Size(110, 110),
                          painter: _GaugeAvancePainter(
                            progreso: valor,
                            color: color,
                          ),
                        );
                      },
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$avance%',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        const Text(
                          'avance',
                          style: TextStyle(fontSize: 11, color: Color(0xFF8888A0)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ETAPA ACTUAL',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF8888A0),
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      proyecto.etapaActual,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Barra de avance (segundo gráfico)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: avance / 100,
                        minHeight: 8,
                        backgroundColor: const Color(0xFF1A1A24),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ---- Línea de etapas ----
          Row(
            children: [
              _Paso(texto: 'Recibido', activo: proyecto.estado.index >= 0, color: const Color(0xFFF39C12)),
              _Linea(activa: proyecto.estado.index >= 1),
              _Paso(texto: 'En proceso', activo: proyecto.estado.index >= 1, color: const Color(0xFFB388FF)),
              _Linea(activa: proyecto.estado.index >= 2),
              _Paso(texto: 'Entregado', activo: proyecto.estado.index >= 2, color: const Color(0xFF33FF99)),
            ],
          ),
          const SizedBox(height: 14),

          // ---- Fecha de entrega ----
          Row(
            children: [
              const Icon(Icons.event, size: 16, color: Color(0xFF8888A0)),
              const SizedBox(width: 6),
              Text(
                'Entrega: ${proyecto.fechaEntrega.day}/${proyecto.fechaEntrega.month}/${proyecto.fechaEntrega.year}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF8888A0)),
              ),
              const Spacer(),
              if (diasRestantes > 0 && proyecto.estado != EstadoProyecto.terminado)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3498DB).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '~$diasRestantes días',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3498DB),
                    ),
                  ),
                ),
            ],
          ),

          // ---- Ultimo mensaje del estudio: se ve sin abrir la caja ----
          if (proyecto.id != null)
            FutureBuilder<List<NotaProyecto>>(
              future: DatabaseHelper().obtenerNotas(proyecto.id!),
              builder: (context, snap) {
                final lista = snap.data ?? const <NotaProyecto>[];
                final notasEstudio = lista.where((n) => n.esEstudio).toList();
                // Si aun no hay mensajes del chat, se muestra la nota
                // general que el estudio escribio en "Editar Proyecto"
                // (campo "Notas adicionales") para que el cliente
                // siempre la vea sin abrir la caja.
                final texto = notasEstudio.isNotEmpty
                    ? notasEstudio.last.mensaje
                    : proyecto.notas.trim();
                if (texto.isEmpty) return const SizedBox.shrink();
                return Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF33FF99).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: const Color(0xFF33FF99).withValues(alpha: 0.35)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.chat_bubble,
                              color: Color(0xFF33FF99), size: 13),
                          SizedBox(width: 6),
                          Text(
                            'MENSAJE DEL ESTUDIO',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF33FF99),
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        texto,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFC7C7D6),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

          // ---- Caja de mensajes con el estudio ----
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _abrirMensajes(context),
              icon: const Icon(Icons.chat_bubble_outline, size: 18),
              label: const Text(
                'MENSAJES CON EL ESTUDIO',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                side: BorderSide(color: color.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // ---- Imágenes de avance ----
          if (fotos.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'IMÁGENES DE AVANCE',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF8888A0),
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 90,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: fotos.length,
                itemBuilder: (context, i) => GestureDetector(
                  onTap: () => _verFotoCompleta(context, fotos, i),
                  child: Container(
                    width: 120,
                    margin: const EdgeInsets.only(right: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        fotos[i],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: const Color(0xFF16161D),
                          child: const Icon(
                            Icons.broken_image,
                            color: Color(0xFF8888A0),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Toca una imagen para verla completa',
              style: TextStyle(fontSize: 10, color: Color(0xFF8888A0)),
            ),
          ],
        ],
      ),
    );
  }

  void _verFotoCompleta(BuildContext context, List<String> fotos, int indice) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF0D0D12),
        insetPadding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Avance de tu proyecto',
                      style: TextStyle(
                        color: Color(0xFFF4F4F6),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF8888A0)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Ajuste: la imagen nunca puede ser mas alta que la
            // ventana o se desparrama (error de OVERFLOW de Flutter).
            InteractiveViewer(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.70,
                  ),
                  child: Image.network(
                    fotos[indice],
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        const Padding(
                      padding: EdgeInsets.all(40),
                      child: Icon(
                        Icons.broken_image,
                        size: 60,
                        color: Color(0xFF8888A0),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  /// Abre la caja de mensajes con el estudio: el cliente ve las notas
  /// que le dejaron y puede responder o dejar sus sugerencias.
  void _abrirMensajes(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CajaMensajes(proyecto: proyecto),
    );
  }

  String _textoEstado(EstadoProyecto estado) {
    switch (estado) {
      case EstadoProyecto.pendiente:
        return 'PENDIENTE';
      case EstadoProyecto.enProceso:
        return 'EN PROCESO';
      case EstadoProyecto.terminado:
        return 'TERMINADO';
    }
  }
}

/// Caja de mensajes entre el estudio y el cliente.
///
/// Muestra la nota general que el estudio dejó en "Editar Proyecto",
/// el historial de mensajes y un campo para responder.
class _CajaMensajes extends StatefulWidget {
  final Proyecto proyecto;
  const _CajaMensajes({required this.proyecto});

  @override
  State<_CajaMensajes> createState() => _CajaMensajesState();
}

class _CajaMensajesState extends State<_CajaMensajes> {
  final DatabaseHelper _db = DatabaseHelper();
  final TextEditingController _ctrl = TextEditingController();
  List<NotaProyecto> _notas = [];
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    final id = widget.proyecto.id;
    if (id == null) return;
    final lista = await _db.obtenerNotas(id);
    if (mounted) setState(() => _notas = lista);
  }

  Future<void> _enviar() async {
    final texto = _ctrl.text.trim();
    if (texto.isEmpty || widget.proyecto.id == null || _enviando) return;
    setState(() => _enviando = true);
    final ok = await _db.agregarNota(widget.proyecto.id!, 'cliente', texto);
    if (ok) {
      _ctrl.clear();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo enviar: falta crear la tabla en Supabase'),
          backgroundColor: Color(0xFFE74C3C),
        ),
      );
    }
    if (mounted) setState(() => _enviando = false);
    await _cargar();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: const BoxDecoration(
          color: Color(0xFF12121A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título de la caja
            Row(
              children: [
                const Icon(
                  Icons.chat_bubble_outline,
                  color: Color(0xFF33FF99),
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'MENSAJES CON EL ESTUDIO',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: Color(0xFFF4F4F6),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF8888A0)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Nota general que el estudio deja en "Editar Proyecto"
            if (widget.proyecto.notas.isNotEmpty) ...[
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF33FF99).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF33FF99).withValues(alpha: 0.35),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'NOTA DEL ESTUDIO',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: Color(0xFF33FF99),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.proyecto.notas,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFFF4F4F6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // Historial de mensajes
            Flexible(
              child: _notas.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'Aún no hay mensajes. Escribe abajo tu primera '
                        'pregunta o sugerencia.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF8888A0),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _notas.length,
                      itemBuilder: (context, i) => _burbuja(_notas[i]),
                    ),
            ),
            const SizedBox(height: 8),
            // Campo para responder
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    minLines: 1,
                    maxLines: 3,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFFF4F4F6),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Escribe tu respuesta o sugerencia...',
                      hintStyle: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF8888A0),
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF8888A0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF33FF99)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _enviando ? null : _enviar,
                  icon: const Icon(Icons.send, color: Color(0xFF33FF99)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Burbuja de un mensaje (verde = estudio, azul = yo como cliente).
  Widget _burbuja(NotaProyecto n) {
    final esEstudio = n.esEstudio;
    final color = esEstudio ? const Color(0xFF33FF99) : const Color(0xFF3498DB);
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
                esEstudio ? 'ESTUDIO' : 'YO',
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
                  color: Color(0xFF8888A0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            n.mensaje,
            style: const TextStyle(fontSize: 14, color: Color(0xFFF4F4F6)),
          ),
        ],
      ),
    );
  }
}

class _Paso extends StatelessWidget {
  final String texto;
  final bool activo;
  final Color color;

  const _Paso({required this.texto, required this.activo, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: activo ? color : const Color(0xFF1A1A24),
            border: Border.all(color: activo ? color : const Color(0xFF8888A0)),
          ),
          child: Center(
            child: activo
                ? const Icon(Icons.check, size: 14, color: Color(0xFF0D0D12))
                : const Icon(Icons.circle_outlined, size: 10, color: Color(0xFF8888A0)),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          texto,
          style: TextStyle(
            fontSize: 10,
            color: activo ? color : const Color(0xFF8888A0),
          ),
        ),
      ],
    );
  }
}

class _Linea extends StatelessWidget {
  final bool activa;

  const _Linea({required this.activa});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 16),
        color: activa
            ? const Color(0xFF33FF99)
            : const Color(0xFF8888A0).withValues(alpha: 0.3),
      ),
    );
  }
}

/// Anillo de porcentaje (gráfico circular de avance).
class _GaugeAvancePainter extends CustomPainter {
  final double progreso;
  final Color color;

  _GaugeAvancePainter({required this.progreso, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const grosor = 10.0;
    final centro = Offset(size.width / 2, size.height / 2);
    final radio = (math.min(size.width, size.height) - grosor) / 2;

    final fondo = Paint()
      ..color = const Color(0xFF1A1A24)
      ..style = PaintingStyle.stroke
      ..strokeWidth = grosor
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(centro, radio, fondo);

    final barra = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = grosor
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: centro, radius: radio),
      -math.pi / 2,
      2 * math.pi * progreso.clamp(0.0, 1.0),
      false,
      barra,
    );
  }

  @override
  bool shouldRepaint(_GaugeAvancePainter viejo) =>
      viejo.progreso != progreso || viejo.color != color;
}
