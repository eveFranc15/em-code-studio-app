import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'modelos.dart';
import 'proyecto_form_screen.dart';
import 'imagen_completa.dart';

/// Pantalla que muestra los trabajos realizados y servicios de una categoría.
/// - [vistaCliente] = true  → portafolio de solo lectura (sin controles de admin)
/// - [vistaCliente] = false → vista de administrador (agregar / editar trabajos)
class TrabajosCategoriaScreen extends StatefulWidget {
  final String categoria;
  final bool vistaCliente;

  const TrabajosCategoriaScreen({
    super.key,
    required this.categoria,
    this.vistaCliente = false,
  });

  @override
  State<TrabajosCategoriaScreen> createState() => _TrabajosCategoriaScreenState();
}

class _TrabajosCategoriaScreenState extends State<TrabajosCategoriaScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Proyecto> _proyectos = [];
  List<Map<String, dynamic>> _servicios = [];
  bool _cargando = true;

  bool get _esCliente => widget.vistaCliente;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);
    final todosProyectos = await _dbHelper.obtenerProyectos();
    final todosServicios = await _dbHelper.obtenerServicios();

    setState(() {
      _proyectos = _filtrarPorCategoria(todosProyectos);
      _servicios = todosServicios
          .where((s) => (s['categoria'] ?? '') == widget.categoria)
          .toList();
      _cargando = false;
    });
  }

  /// Filtra los proyectos que pertenecen a esta categoría
  List<Proyecto> _filtrarPorCategoria(List<Proyecto> todos) {
    final cat = widget.categoria.toLowerCase();
    final palabrasClave = _palabrasClaveDeCategoria(widget.categoria);

    return todos.where((p) {
      if (p.categoria != null && p.categoria!.toLowerCase() == cat) return true;
      final tipo = p.tipoServicio.toLowerCase();
      final nombre = p.nombreProyecto.toLowerCase();
      for (final palabra in palabrasClave) {
        if (tipo.contains(palabra) || nombre.contains(palabra)) return true;
      }
      return false;
    }).toList();
  }

  List<String> _palabrasClaveDeCategoria(String categoria) {
    switch (categoria) {
      case 'Páginas Web':
        return ['web', 'pagina', 'página', 'sitio', 'landing', 'e-commerce', 'tienda online'];
      case 'Sistemas de Venta':
        return ['venta', 'sistema', 'pos', 'inventario', 'factura', 'restaurant', 'crud'];
      case 'Apps Móviles':
        return ['app', 'movil', 'móvil', 'celular', 'android', 'ios'];
      case 'Soporte y Mantenimiento':
        return ['soporte', 'mantenimiento', 'actualizacion', 'actualización', 'reparacion'];
      default:
        return [];
    }
  }

  Color get _colorCategoria {
    switch (widget.categoria) {
      case 'Páginas Web':
        return const Color(0xFF33FF99);
      case 'Sistemas de Venta':
        return const Color(0xFFB388FF);
      case 'Apps Móviles':
        return const Color(0xFF3498DB);
      case 'Soporte y Mantenimiento':
        return const Color(0xFFF39C12);
      default:
        return const Color(0xFF8888A0);
    }
  }

  IconData get _iconoCategoria {
    switch (widget.categoria) {
      case 'Páginas Web':
        return Icons.web;
      case 'Sistemas de Venta':
        return Icons.shopping_cart;
      case 'Apps Móviles':
        return Icons.phone_android;
      case 'Soporte y Mantenimiento':
        return Icons.support_agent;
      default:
        return Icons.build;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorCategoria;
    final totalTrabajos = _proyectos.length;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D12),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.categoria),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF33FF99)))
          : RefreshIndicator(
              color: color,
              onRefresh: _cargarDatos,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(color, totalTrabajos),
                    const SizedBox(height: 24),

                    // ===== TRABAJOS REALIZADOS =====
                    Text(
                      _esCliente ? 'NUESTROS TRABAJOS' : 'TRABAJOS REALIZADOS',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF8888A0),
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_proyectos.isEmpty)
                      _buildEstadoVacio(
                        Icons.image_search,
                        _esCliente
                            ? 'Pronto publicaremos trabajos de esta categoría'
                            : 'Aún no hay trabajos en esta categoría',
                        _esCliente
                            ? 'Estamos preparando nuevos proyectos para mostrarte.'
                            : 'Toca el botón "AGREGAR TRABAJO" para registrar uno con su imagen.',
                      )
                    else if (_esCliente)
                      _buildPortafolioCliente(color)
                    else
                      ..._proyectos.map((p) => _buildTrabajoCardAdmin(p, color)),

                    const SizedBox(height: 24),

                    // ===== SERVICIOS DE ESTA CATEGORÍA =====
                    if (_servicios.isNotEmpty) ...[
                      const Text(
                        'SERVICIOS DE ESTA CATEGORÍA',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF8888A0),
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._servicios.map((s) => _buildServicioCard(s, color)),
                    ],
                  ],
                ),
              ),
            ),
      // Solo el administrador ve el botón de agregar trabajo
      floatingActionButton: _esCliente
          ? null
          : FloatingActionButton.extended(
              onPressed: _agregarTrabajo,
              backgroundColor: const Color(0xFF33FF99),
              foregroundColor: const Color(0xFF0D0D12),
              icon: const Icon(Icons.add_a_photo),
              label: const Text(
                'AGREGAR TRABAJO',
                style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
            ),
    );
  }

  Widget _buildHeader(Color color, int totalTrabajos) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.04)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(_iconoCategoria, color: color, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.categoria,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFF4F4F6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  totalTrabajos == 0
                      ? 'Trabajos disponibles'
                      : '$totalTrabajos ${totalTrabajos == 1 ? 'trabajo realizado' : 'trabajos realizados'}',
                  style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============ VISTA CLIENTE: PORTAFOLIO CON IMÁGENES ============

  Widget _buildPortafolioCliente(Color color) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.78,
      ),
      itemCount: _proyectos.length,
      itemBuilder: (context, index) {
        final p = _proyectos[index];
        return GestureDetector(
          onTap: () => _mostrarDetalleTrabajo(p, color),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A24),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.25)),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Imagen del trabajo
                Expanded(
                  child: SizedBox(
                    width: double.infinity,
                    child: p.imagenUrl != null
                        ? Image.network(
                            p.imagenUrl!,
                            // contain: se ve la imagen COMPLETA, sin recortes
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                _placeholderImagen(color),
                          )
                        : _placeholderImagen(color),
                  ),
                ),
                // Info del trabajo
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.nombreProyecto,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFF4F4F6),
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _colorEstado(p.estado).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _colorEstado(p.estado).withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          _textoEstado(p.estado),
                          style: TextStyle(
                            color: _colorEstado(p.estado),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _placeholderImagen(Color color) {
    return Container(
      color: const Color(0xFF16161D),
      alignment: Alignment.center,
      child: Icon(_iconoCategoria, size: 42, color: color.withValues(alpha: 0.6)),
    );
  }

  /// Detalle del trabajo para el cliente (imagen grande + información)
  void _mostrarDetalleTrabajo(Proyecto p, Color color) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A24),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFF8888A0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Imagen grande: se muestra COMPLETA, sin recortes
                if (p.imagenUrl != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: ImagenCompleta(
                        url: p.imagenUrl!,
                        altoMin: 200,
                        altoMax: 420,
                        error: SizedBox(
                          height: 200,
                          width: double.infinity,
                          child: _placeholderImagen(color),
                        ),
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(height: 200, width: double.infinity, child: _placeholderImagen(color)),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.nombreProyecto,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFF4F4F6),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _colorEstado(p.estado).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: _colorEstado(p.estado)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.flag, size: 14, color: _colorEstado(p.estado)),
                                const SizedBox(width: 6),
                                Text(
                                  _textoEstado(p.estado),
                                  style: TextStyle(
                                    color: _colorEstado(p.estado),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: color.withValues(alpha: 0.5)),
                            ),
                            child: Text(
                              widget.categoria,
                              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (p.tipoServicio.isNotEmpty) _filaInfo(Icons.build, 'Tipo de servicio', p.tipoServicio),
                      _filaInfo(
                        Icons.calendar_today,
                        'Fecha de entrega',
                        '${p.fechaEntrega.day}/${p.fechaEntrega.month}/${p.fechaEntrega.year}',
                      ),
                      if (p.notas.isNotEmpty) _filaInfo(Icons.description, 'Detalles', p.notas),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back, size: 18),
                          label: const Text('VOLVER A SERVICIOS'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: color,
                            side: BorderSide(color: color),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
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

  Widget _filaInfo(IconData icono, String etiqueta, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 16, color: const Color(0xFF8888A0)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  etiqueta,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF8888A0)),
                ),
                Text(
                  valor,
                  style: const TextStyle(fontSize: 14, color: Color(0xFFF4F4F6), height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============ VISTA ADMIN ============

  /// Abre el formulario para crear un trabajo en esta categoría
  Future<void> _agregarTrabajo() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProyectoFormScreen(categoriaInicial: widget.categoria),
      ),
    );
    if (mounted) _cargarDatos();
  }

  /// Abre el formulario para editar un trabajo (imagen, montos, estado)
  Future<void> _editarTrabajo(Proyecto proyecto) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProyectoFormScreen(
          proyecto: proyecto,
          categoriaInicial: widget.categoria,
        ),
      ),
    );
    if (mounted) _cargarDatos();
  }

  Widget _buildEstadoVacio(IconData icono, String titulo, String subtitulo) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF8888A0).withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icono, size: 50, color: const Color(0xFF8888A0)),
          const SizedBox(height: 12),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFFF4F4F6)),
          ),
          const SizedBox(height: 6),
          Text(
            subtitulo,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Color(0xFF8888A0)),
          ),
        ],
      ),
    );
  }

  Widget _buildTrabajoCardAdmin(Proyecto p, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (p.imagenUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              // Imagen COMPLETA: el alto se adapta a la proporción real
              child: ImagenCompleta(
                url: p.imagenUrl!,
                altoMin: 160,
                altoMax: 380,
                error: Container(
                  height: 160,
                  width: double.infinity,
                  color: const Color(0xFF16161D),
                  child: Icon(_iconoCategoria, size: 45, color: color),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        p.nombreProyecto,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFF4F4F6),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _colorEstado(p.estado).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _colorEstado(p.estado).withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        _textoEstado(p.estado),
                        style: TextStyle(
                          color: _colorEstado(p.estado),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.person, size: 15, color: Color(0xFF8888A0)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        p.cliente.nombre,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF8888A0)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      formatearSoles(p.montoTotal),
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
                    ),
                    const SizedBox(width: 8),
                    // Botón editar trabajo (cambiar imagen, montos, estado)
                    GestureDetector(
                      onTap: () => _editarTrabajo(p),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: color.withValues(alpha: 0.4)),
                        ),
                        child: Icon(Icons.edit, size: 16, color: color),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicioCard(Map<String, dynamic> servicio, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A24),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: servicio['imagen_url'] != null
                ? Image.network(
                    servicio['imagen_url'],
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 56,
                      height: 56,
                      color: const Color(0xFF16161D),
                      child: Icon(_iconoCategoria, color: color),
                    ),
                  )
                : Container(
                    width: 56,
                    height: 56,
                    color: const Color(0xFF16161D),
                    child: Icon(_iconoCategoria, color: color),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  servicio['nombre'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF4F4F6)),
                ),
                if (servicio['descripcion'] != null && servicio['descripcion'].isNotEmpty)
                  Text(
                    servicio['descripcion'],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF8888A0)),
                  ),
              ],
            ),
          ),
        ],
      ),
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

  String _textoEstado(EstadoProyecto estado) {
    switch (estado) {
      case EstadoProyecto.pendiente:
        return 'Pendiente';
      case EstadoProyecto.enProceso:
        return 'En proceso';
      case EstadoProyecto.terminado:
        return 'Terminado';
    }
  }
}
