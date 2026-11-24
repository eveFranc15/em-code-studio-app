import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'database_helper.dart';

class ServiciosGestionScreen extends StatefulWidget {
  const ServiciosGestionScreen({super.key});

  @override
  State<ServiciosGestionScreen> createState() => _ServiciosGestionScreenState();
}

class _ServiciosGestionScreenState extends State<ServiciosGestionScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _nombreCtrl = TextEditingController();
  final TextEditingController _descripcionCtrl = TextEditingController();

  String _categoriaSeleccionada = 'Páginas Web';
  List<Map<String, dynamic>> _servicios = [];
  bool _cargando = true;
  bool _subiendo = false;

  final List<String> _categorias = [
    'Páginas Web',
    'Sistemas de Venta',
    'Apps Móviles',
    'Soporte y Mantenimiento',
  ];

  @override
  void initState() {
    super.initState();
    _cargarServicios();
  }

  Future<void> _cargarServicios() async {
    setState(() => _cargando = true);
    final lista = await _dbHelper.obtenerServicios();
    setState(() {
      _servicios = lista;
      _cargando = false;
    });
  }

  Future<void> _subirImagen() async {
    if (_nombreCtrl.text.trim().isEmpty) {
      _mostrarMensaje('Ingresa un nombre para el servicio');
      return;
    }

    setState(() => _subiendo = true);

    try {
      final XFile? imagen = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1280,
        imageQuality: 80,
      );
      if (imagen == null) {
        setState(() => _subiendo = false);
        return;
      }

      // Subir imagen a Supabase Storage
      final url = await _dbHelper.subirImagen(
        await imagen.readAsBytes(),
        'servicio_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      if (url == null) {
        _mostrarMensaje('Error al subir imagen');
        setState(() => _subiendo = false);
        return;
      }

      // Guardar en la base de datos
      await _dbHelper.insertarServicio({
        'nombre': _nombreCtrl.text.trim(),
        'descripcion': _descripcionCtrl.text.trim(),
        'categoria': _categoriaSeleccionada,
        'imagen_url': url,
      });

      _nombreCtrl.clear();
      _descripcionCtrl.clear();
      _cargarServicios();
      _mostrarMensaje('Servicio agregado exitosamente');
    } catch (e) {
      _mostrarMensaje('Error: $e');
    }

    setState(() => _subiendo = false);
  }

  Future<void> _eliminarServicio(int id) async {
    final confirmacion = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Servicio'),
        content: const Text('¿Estás seguro de eliminar este servicio?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmacion == true) {
      await _dbHelper.eliminarServicio(id);
      _cargarServicios();
      _mostrarMensaje('Servicio eliminado');
    }
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D12),
      appBar: AppBar(
        title: const Text('Gestión de Servicios'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Formulario para agregar servicio
                  const Text(
                    'AGREGAR NUEVO SERVICIO',
                    style: TextStyle(fontSize: 12, color: Color(0xFF8888A0), letterSpacing: 2),
                  ),
                  const SizedBox(height: 16),

                  // Selector de categoría
                  const Text('Categoría', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _categorias.map((cat) {
                      final seleccionado = _categoriaSeleccionada == cat;
                      return GestureDetector(
                        onTap: () => setState(() => _categoriaSeleccionada = cat),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: seleccionado
                                ? const Color(0xFF33FF99).withValues(alpha: 0.2)
                                : const Color(0xFF1A1A24),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: seleccionado
                                  ? const Color(0xFF33FF99)
                                  : const Color(0xFF8888A0).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            cat,
                            style: TextStyle(
                              color: seleccionado ? const Color(0xFF33FF99) : const Color(0xFF8888A0),
                              fontWeight: seleccionado ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _nombreCtrl,
                    style: const TextStyle(color: Color(0xFFF4F4F6)),
                    decoration: _inputDecoration('Nombre del servicio', Icons.label),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descripcionCtrl,
                    maxLines: 3,
                    style: const TextStyle(color: Color(0xFFF4F4F6)),
                    decoration: _inputDecoration('Descripción', Icons.description),
                  ),
                  const SizedBox(height: 16),

                  // Botón subir imagen
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _subiendo ? null : _subirImagen,
                      icon: _subiendo
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.cloud_upload),
                      label: Text(_subiendo ? 'Subiendo...' : 'Subir Imagen y Guardar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF33FF99),
                        foregroundColor: const Color(0xFF0D0D12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Lista de servicios existentes
                  const Text(
                    'SERVICIOS EXISTENTES',
                    style: TextStyle(fontSize: 12, color: Color(0xFF8888A0), letterSpacing: 2),
                  ),
                  const SizedBox(height: 16),
                  ..._servicios.map((servicio) => _buildServicioCard(servicio)),
                ],
              ),
            ),
    );
  }

  Widget _buildServicioCard(Map<String, dynamic> servicio) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A24),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF8888A0).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          // Imagen
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: servicio['imagen_url'] != null
                ? Image.network(
                    servicio['imagen_url'],
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 60,
                        height: 60,
                        color: const Color(0xFF16161D),
                        child: const Icon(Icons.broken_image, color: Color(0xFF8888A0)),
                      );
                    },
                  )
                : Container(
                    width: 60,
                    height: 60,
                    color: const Color(0xFF16161D),
                    child: const Icon(Icons.image, color: Color(0xFF8888A0)),
                  ),
          ),
          const SizedBox(width: 12),
          // Información
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  servicio['nombre'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  servicio['categoria'] ?? '',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF8888A0)),
                ),
                if (servicio['descripcion'] != null && servicio['descripcion'].isNotEmpty)
                  Text(
                    servicio['descripcion'],
                    style: const TextStyle(fontSize: 12, color: Color(0xFF8888A0)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          // Botón eliminar
          IconButton(
            icon: const Icon(Icons.delete, color: Color(0xFFE74C3C)),
            onPressed: () => _eliminarServicio(servicio['id']),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF8888A0)),
      prefixIcon: Icon(icon, color: const Color(0xFF33FF99)),
      filled: true,
      fillColor: const Color(0xFF1A1A24),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF33FF99), width: 2)),
    );
  }
}
