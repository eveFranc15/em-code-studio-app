import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'modelos.dart';
import 'database_helper.dart';
import 'imagen_completa.dart';

class ProyectoFormScreen extends StatefulWidget {
  final Proyecto? proyecto;
  /// Permite precargar una categoría al abrir desde Servicios
  final String? categoriaInicial;

  const ProyectoFormScreen({super.key, this.proyecto, this.categoriaInicial});

  @override
  State<ProyectoFormScreen> createState() => _ProyectoFormScreenState();
}

class _ProyectoFormScreenState extends State<ProyectoFormScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final ImagePicker _picker = ImagePicker();
  final _nombreCtrl = TextEditingController();
  final _tipoServicioCtrl = TextEditingController();
  final _montoTotalCtrl = TextEditingController();
  final _montoPagadoCtrl = TextEditingController();
  final _notasCtrl = TextEditingController();
  final _nombreClienteCtrl = TextEditingController();
  final _telefonoClienteCtrl = TextEditingController();
  final _dniCtrl = TextEditingController();
  final _rucCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();

  EstadoProyecto _estado = EstadoProyecto.pendiente;
  TipoPago _tipoPago = TipoPago.efectivo;
  EstadoPago _estadoPago = EstadoPago.pendiente;
  TipoCliente _tipoCliente = TipoCliente.persona;
  DateTime _fechaEntrega = DateTime.now().add(const Duration(days: 30));
  String? _categoria;
  String? _imagenPath;
  List<String> _imagenesUrls = [];
  bool _subiendoImagenes = false;
  bool _cargando = false;

  /// Porcentaje de avance visible para el cliente (0 a 100).
  double _avance = 0;
  /// Etapa del trabajo (ej. Diseño, Desarrollo, Pruebas...).
  final _etapaCtrl = TextEditingController();

  /// Etapas sugeridas para el avance del trabajo.
  static const List<String> _etapasSugeridas = [
    'Levantamiento de datos',
    'Diseño',
    'Maquetación',
    'Desarrollo',
    'Pruebas',
    'Capacitación',
    'Entrega final',
  ];

  static const List<String> _categoriasProyecto = [
    'Páginas Web',
    'Sistemas de Venta',
    'Apps Móviles',
    'Soporte y Mantenimiento',
  ];

  bool get _esEdicion => widget.proyecto != null;

  @override
  void initState() {
    super.initState();
    if (_esEdicion) {
      final p = widget.proyecto!;
      _nombreCtrl.text = p.nombreProyecto;
      _tipoServicioCtrl.text = p.tipoServicio;
      _montoTotalCtrl.text = p.montoTotal.toString();
      _montoPagadoCtrl.text = p.montoPagado.toString();
      _notasCtrl.text = p.notas;
      _nombreClienteCtrl.text = p.cliente.nombre;
      _telefonoClienteCtrl.text = p.cliente.telefono;
      _dniCtrl.text = p.cliente.dni ?? '';
      _rucCtrl.text = p.cliente.ruc ?? '';
      _emailCtrl.text = p.cliente.email ?? '';
      _direccionCtrl.text = p.cliente.direccion ?? '';
      _estado = p.estado;
      _tipoPago = p.tipoPago;
      _estadoPago = p.estadoPago;
      _tipoCliente = p.cliente.tipoCliente;
      _fechaEntrega = p.fechaEntrega;
      _categoria = p.categoria;
      _imagenPath = p.imagenUrl;
      _imagenesUrls = p.imagenes ?? [];
      _avance = p.avanceCalculado.toDouble();
      _etapaCtrl.text = p.etapa ?? '';
    } else if (widget.categoriaInicial != null) {
      _categoria = widget.categoriaInicial;
      _tipoServicioCtrl.text = widget.categoriaInicial!;
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _tipoServicioCtrl.dispose();
    _montoTotalCtrl.dispose();
    _montoPagadoCtrl.dispose();
    _notasCtrl.dispose();
    _nombreClienteCtrl.dispose();
    _telefonoClienteCtrl.dispose();
    _dniCtrl.dispose();
    _rucCtrl.dispose();
    _emailCtrl.dispose();
    _direccionCtrl.dispose();
    _etapaCtrl.dispose();
    super.dispose();
  }

  // ============ IMÁGENES ============

  Future<void> _seleccionarImagen(ImageSource source) async {
    final XFile? imagen = await _picker.pickImage(
      source: source,
      maxWidth: 1280,
      imageQuality: 80,
    );
    if (imagen == null) return;

    setState(() => _subiendoImagenes = true);
    // Se leen los BYTES de la imagen (funciona también en el navegador,
    // donde no existe la ruta de un archivo en el disco).
    final bytes = await imagen.readAsBytes();
    final url = await _dbHelper.subirImagen(
      bytes,
      'proyecto_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );

    if (url != null) {
      setState(() {
        _imagenPath = url;
        _imagenesUrls.add(url);
        _subiendoImagenes = false;
      });
    } else {
      setState(() => _subiendoImagenes = false);
      _mostrarError('No se pudo subir la imagen. Verifica tu conexión.');
    }
  }

  Future<void> _seleccionarMultiplesImagenes() async {
    final List<XFile> imagenes = await _picker.pickMultiImage(
      maxWidth: 1280,
      imageQuality: 80,
    );
    if (imagenes.isEmpty) return;

    setState(() => _subiendoImagenes = true);
    for (int i = 0; i < imagenes.length; i++) {
      final url = await _dbHelper.subirImagen(
        await imagenes[i].readAsBytes(),
        'proyecto_${DateTime.now().millisecondsSinceEpoch}_$i.jpg',
      );
      if (url != null) {
        setState(() {
          _imagenesUrls.add(url);
          _imagenPath ??= url;
        });
      }
    }
    setState(() => _subiendoImagenes = false);
  }

  /// Quita una imagen de la lista de imágenes del proyecto.
  /// Si era la principal, pasa a ser principal la primera que quede.
  void _eliminarImagen(String url) {
    setState(() {
      _imagenesUrls.remove(url);
      if (_imagenPath == url) {
        _imagenPath = _imagenesUrls.isNotEmpty ? _imagenesUrls.first : null;
      }
    });
  }

  void _mostrarOpcionesImagen() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'IMAGEN DEL TRABAJO',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF8888A0),
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF33FF99)),
              title: const Text('Tomar foto'),
              onTap: () {
                Navigator.pop(context);
                _seleccionarImagen(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF33FF99)),
              title: const Text('Elegir de la galería'),
              onTap: () {
                Navigator.pop(context);
                _seleccionarImagen(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: Color(0xFFB388FF)),
              title: const Text('Agregar varias imágenes'),
              onTap: () {
                Navigator.pop(context);
                _seleccionarMultiplesImagenes();
              },
            ),
            if (_imagenPath != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Color(0xFFE74C3C)),
                title: const Text('Quitar imagen principal'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _imagenPath = null);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ============ GUARDAR ============

  void _mostrarError(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: const Color(0xFFE74C3C),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _guardar() async {
    if (_nombreCtrl.text.trim().isEmpty) {
      _mostrarError('Ingresa el nombre del proyecto');
      return;
    }
    if (_tipoServicioCtrl.text.trim().isEmpty) {
      _mostrarError('Ingresa el tipo de servicio');
      return;
    }
    if (_montoTotalCtrl.text.trim().isEmpty) {
      _mostrarError('Ingresa el monto total');
      return;
    }
    if (_nombreClienteCtrl.text.trim().isEmpty) {
      _mostrarError('Ingresa el nombre del cliente');
      return;
    }
    if (_telefonoClienteCtrl.text.trim().isEmpty) {
      _mostrarError('Ingresa el teléfono del cliente');
      return;
    }
    if (_tipoCliente == TipoCliente.persona &&
        _dniCtrl.text.isNotEmpty &&
        _dniCtrl.text.trim().length != 8) {
      _mostrarError('El DNI debe tener 8 dígitos');
      return;
    }
    if (_tipoCliente == TipoCliente.empresa &&
        _rucCtrl.text.isNotEmpty &&
        _rucCtrl.text.trim().length != 11) {
      _mostrarError('El RUC debe tener 11 dígitos');
      return;
    }
    // Teléfono peruano: exactamente 9 dígitos y empieza con 9 (misma
    // regla que la pestaña Clientes, donde es obligatorio).
    final telefonoCliente = _telefonoClienteCtrl.text.trim();
    if (telefonoCliente.length != 9) {
      _mostrarError('El teléfono debe tener 9 dígitos');
      return;
    }
    if (!telefonoCliente.startsWith('9')) {
      _mostrarError('El teléfono debe empezar con 9 (celular peruano)');
      return;
    }
    // Correo: si se escribe, debe tener formato válido
    // (@ y dominio con punto, ej. cliente@correo.com).
    final emailTexto = _emailCtrl.text.trim();
    if (emailTexto.isNotEmpty &&
        !RegExp(r'^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$')
            .hasMatch(emailTexto.toLowerCase())) {
      _mostrarError('El correo no es válido (ejemplo: cliente@correo.com)');
      return;
    }

    setState(() => _cargando = true);

    try {
      // ---- EVITAR PROYECTOS DUPLICADOS ----
      // No permite guardar dos proyectos con el mismo nombre para el mismo
      // cliente (evita dobles guardados accidentales).
      try {
        final existentes = await _dbHelper.obtenerProyectos();
        final nombreNuevo = _nombreCtrl.text.trim().toLowerCase();
        final clienteNuevo = _nombreClienteCtrl.text.trim().toLowerCase();
        final duplicado = existentes.any((e) =>
            (widget.proyecto == null || e.id != widget.proyecto!.id) &&
            e.nombreProyecto.trim().toLowerCase() == nombreNuevo &&
            e.cliente.nombre.trim().toLowerCase() == clienteNuevo);
        if (duplicado) {
          setState(() => _cargando = false);
          _mostrarError(
            'Ya existe el proyecto "${_nombreCtrl.text.trim()}" para el cliente ${_nombreClienteCtrl.text.trim()}. '
            'Edita el proyecto existente o usa otro nombre.',
          );
          return;
        }
      } catch (e) {
        debugPrint('No se pudo verificar proyectos duplicados: $e');
      }

      final cliente = Cliente(
        id: widget.proyecto?.cliente.id,
        nombre: _nombreClienteCtrl.text.trim(),
        telefono: _telefonoClienteCtrl.text.trim(),
        email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        tipoCliente: _tipoCliente,
        dni: _dniCtrl.text.trim().isEmpty ? null : _dniCtrl.text.trim(),
        ruc: _rucCtrl.text.trim().isEmpty ? null : _rucCtrl.text.trim(),
        direccion: _direccionCtrl.text.trim().isEmpty ? null : _direccionCtrl.text.trim(),
      );

      // Guardar cliente automáticamente si es nuevo (sin duplicados).
      // Se busca por DNI/RUC, correo o nombre, para que también se
      // registre un cliente al que aún no se conocen sus documentos
      // (antes solo se creaba si traía DNI o RUC).
      if (!_esEdicion && cliente.id == null) {
        try {
          final existentes = await _dbHelper.obtenerClientes();
          final nombreNuevo = cliente.nombre.trim().toLowerCase();
          final emailNuevo = cliente.email?.trim().toLowerCase();
          final yaExiste = existentes.any((c) =>
              (cliente.dni != null && c.dni == cliente.dni) ||
              (cliente.ruc != null && c.ruc == cliente.ruc) ||
              (emailNuevo != null &&
                  emailNuevo.isNotEmpty &&
                  (c.email ?? '').trim().toLowerCase() == emailNuevo) ||
              c.nombre.trim().toLowerCase() == nombreNuevo);
          if (!yaExiste) {
            final idCliente = await _dbHelper.insertarCliente(cliente);
            cliente.id = idCliente;
          }
        } catch (e) {
          debugPrint('No se pudo auto-guardar cliente: $e');
        }
      }

      final proyecto = Proyecto(
        id: widget.proyecto?.id,
        nombreProyecto: _nombreCtrl.text.trim(),
        tipoServicio: _tipoServicioCtrl.text.trim(),
        estado: _estado,
        fechaEntrega: _fechaEntrega,
        montoTotal: double.tryParse(_montoTotalCtrl.text) ?? 0,
        montoPagado: double.tryParse(_montoPagadoCtrl.text) ?? 0,
        tipoPago: _tipoPago,
        estadoPago: _estadoPago,
        notas: _notasCtrl.text.trim(),
        cliente: cliente,
        categoria: _categoria,
        imagenUrl: _imagenPath,
        imagenes: _imagenesUrls.isNotEmpty ? _imagenesUrls : null,
        avance: _estado == EstadoProyecto.terminado ? 100 : _avance.round(),
        etapa: _etapaCtrl.text.trim().isEmpty ? null : _etapaCtrl.text.trim(),
      );

      if (_esEdicion) {
        await _dbHelper.actualizarProyecto(proyecto);
      } else {
        await _dbHelper.insertarProyecto(proyecto);
      }

      setState(() => _cargando = false);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_esEdicion ? 'Proyecto actualizado' : 'Proyecto creado'),
            backgroundColor: const Color(0xFF33FF99),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      setState(() => _cargando = false);
      _mostrarError('Error al guardar: $e');
    }
  }

  // ============ UI ============

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D12),
      appBar: AppBar(
        title: Text(_esEdicion ? 'Editar Proyecto' : 'Nuevo Proyecto'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== IMAGEN DEL TRABAJO =====
            const Text(
              'IMAGEN DEL TRABAJO',
              style: TextStyle(fontSize: 12, color: Color(0xFF8888A0), letterSpacing: 2),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _subiendoImagenes ? null : _mostrarOpcionesImagen,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A24),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF8888A0).withValues(alpha: 0.3)),
                ),
                clipBehavior: Clip.antiAlias,
                child: _subiendoImagenes
                    ? const SizedBox(
                        height: 160,
                        child: Center(
                          child: CircularProgressIndicator(color: Color(0xFF33FF99)),
                        ),
                      )
                    : _imagenPath != null
                        ? Stack(
                            children: [
                              // Imagen COMPLETA: el alto se adapta a la
                              // proporción real de la foto (sin recortes).
                              ImagenCompleta(
                                url: _imagenPath!,
                                altoMin: 160,
                                altoMax: 380,
                                error: Container(
                                  color: const Color(0xFF16161D),
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.broken_image,
                                    size: 40,
                                    color: Color(0xFF8888A0),
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 8,
                                top: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Toca para cambiar',
                                    style: TextStyle(fontSize: 11, color: Colors.white),
                                  ),
                                ),
                              ),
                              // Botón para eliminar la imagen principal
                              Positioned(
                                right: 8,
                                bottom: 8,
                                child: GestureDetector(
                                  onTap: () => _eliminarImagen(_imagenPath!),
                                  child: Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE74C3C),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.close, size: 16, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : const SizedBox(
                            height: 160,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate, size: 44, color: Color(0xFF33FF99)),
                                SizedBox(height: 8),
                                Text(
                                  'Toca para agregar imagen del trabajo',
                                  style: TextStyle(color: Color(0xFF8888A0)),
                                ),
                              ],
                            ),
                          ),
              ),
            ),
            if (_imagenesUrls.isNotEmpty) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 64,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    ..._imagenesUrls.map((url) => Container(
                          margin: const EdgeInsets.only(right: 8),
                          width: 64,
                          height: 64,
                          child: Stack(
                            children: [
                              // Tocar la miniatura la vuelve la imagen principal
                              Positioned.fill(
                                child: GestureDetector(
                                  onTap: () => setState(() => _imagenPath = url),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      url,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        color: const Color(0xFF16161D),
                                        child: const Icon(Icons.broken_image, size: 20, color: Color(0xFF8888A0)),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              if (_imagenPath == url)
                                Positioned(
                                  left: 3,
                                  top: 3,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF33FF99),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              // Botón ✕ para eliminar la imagen
                              Positioned(
                                right: 0,
                                top: 0,
                                child: GestureDetector(
                                  onTap: () => _eliminarImagen(url),
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE74C3C),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(Icons.close, size: 13, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                    GestureDetector(
                      onTap: _subiendoImagenes ? null : _seleccionarMultiplesImagenes,
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: const Color(0xFF16161D),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF33FF99).withValues(alpha: 0.5)),
                        ),
                        child: const Icon(Icons.add, color: Color(0xFF33FF99)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),

            // ===== INFORMACIÓN DEL PROYECTO =====
            const Text(
              'INFORMACIÓN DEL PROYECTO',
              style: TextStyle(fontSize: 12, color: Color(0xFF8888A0), letterSpacing: 2),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nombreCtrl,
              style: const TextStyle(color: Color(0xFFF4F4F6)),
              decoration: _inputDecoration('Nombre del proyecto', Icons.work),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _tipoServicioCtrl,
              style: const TextStyle(color: Color(0xFFF4F4F6)),
              decoration: _inputDecoration('Tipo de servicio', Icons.build),
            ),
            const SizedBox(height: 12),
            // Categoría (vincula con la sección Servicios)
            DropdownButtonFormField<String>(
              initialValue: _categoria,
              decoration: _inputDecoration('Categoría (aparece en Servicios)', Icons.category),
              dropdownColor: const Color(0xFF1A1A24),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('Sin categoría', style: TextStyle(color: Color(0xFF8888A0))),
                ),
                ..._categoriasProyecto.map((c) => DropdownMenuItem<String>(
                      value: c,
                      child: Text(c, style: const TextStyle(color: Color(0xFFF4F4F6))),
                    )),
              ],
              onChanged: (v) => setState(() => _categoria = v),
            ),
            const SizedBox(height: 16),

            // ===== ESTADO DEL PROYECTO =====
            const Text(
              'ESTADO DEL PROYECTO',
              style: TextStyle(fontSize: 12, color: Color(0xFF8888A0), letterSpacing: 2),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildEstadoChip('Pendiente', EstadoProyecto.pendiente, const Color(0xFFF39C12))),
                const SizedBox(width: 8),
                Expanded(child: _buildEstadoChip('En Proceso', EstadoProyecto.enProceso, const Color(0xFFB388FF))),
                const SizedBox(width: 8),
                Expanded(child: _buildEstadoChip('Terminado', EstadoProyecto.terminado, const Color(0xFF33FF99))),
              ],
            ),
            const SizedBox(height: 16),

            // ===== AVANCE DEL TRABAJO (lo que ve el cliente) =====
            const Text(
              'AVANCE DEL TRABAJO',
              style: TextStyle(fontSize: 12, color: Color(0xFF8888A0), letterSpacing: 2),
            ),
            const SizedBox(height: 4),
            const Text(
              'Este porcentaje y la etapa se muestran en el panel del cliente.',
              style: TextStyle(fontSize: 11, color: Color(0xFF8888A0)),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A24),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF8888A0).withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Porcentaje de avance',
                        style: TextStyle(color: Color(0xFF8888A0), fontSize: 13),
                      ),
                      Text(
                        '${_avance.round()}%',
                        style: const TextStyle(
                          color: Color(0xFF33FF99),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _avance,
                    min: 0,
                    max: 100,
                    divisions: 100,
                    activeColor: const Color(0xFF33FF99),
                    inactiveColor: const Color(0xFF8888A0).withValues(alpha: 0.3),
                    label: '${_avance.round()}%',
                    onChanged: (v) => setState(() => _avance = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _etapaCtrl,
              style: const TextStyle(color: Color(0xFFF4F4F6)),
              decoration: _inputDecoration('Etapa actual (ej. Desarrollo)', Icons.flag),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _etapasSugeridas
                  .map(
                    (e) => ActionChip(
                      onPressed: () => setState(() => _etapaCtrl.text = e),
                      backgroundColor: const Color(0xFF1A1A24),
                      side: BorderSide(
                        color: const Color(0xFFB388FF).withValues(alpha: 0.5),
                      ),
                      label: Text(
                        e,
                        style: const TextStyle(fontSize: 12, color: Color(0xFFB388FF)),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),

            // ===== TIPO DE PAGO =====
            const Text(
              'TIPO DE PAGO',
              style: TextStyle(fontSize: 12, color: Color(0xFF8888A0), letterSpacing: 2),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildPagoChip('Efectivo', TipoPago.efectivo)),
                const SizedBox(width: 8),
                Expanded(child: _buildPagoChip('Transferencia', TipoPago.transferencia)),
                const SizedBox(width: 8),
                Expanded(child: _buildPagoChip('Yape/Plin', TipoPago.yapePlin)),
              ],
            ),
            const SizedBox(height: 16),

            // ===== ESTADO DE PAGO =====
            const Text(
              'ESTADO DE PAGO',
              style: TextStyle(fontSize: 12, color: Color(0xFF8888A0), letterSpacing: 2),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildEstadoPagoChip('Pendiente', EstadoPago.pendiente, const Color(0xFFF39C12))),
                const SizedBox(width: 8),
                Expanded(child: _buildEstadoPagoChip('Adelanto', EstadoPago.adelanto, const Color(0xFFB388FF))),
                const SizedBox(width: 8),
                Expanded(child: _buildEstadoPagoChip('Pagado', EstadoPago.pagado, const Color(0xFF33FF99))),
              ],
            ),
            const SizedBox(height: 16),

            // ===== FECHA DE ENTREGA =====
            const Text(
              'FECHA DE ENTREGA',
              style: TextStyle(fontSize: 12, color: Color(0xFF8888A0), letterSpacing: 2),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                final fecha = await showDatePicker(
                  context: context,
                  initialDate: _fechaEntrega,
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (fecha != null) setState(() => _fechaEntrega = fecha);
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A24),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF8888A0).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Color(0xFF33FF99)),
                    const SizedBox(width: 12),
                    Text(
                      '${_fechaEntrega.day}/${_fechaEntrega.month}/${_fechaEntrega.year}',
                      style: const TextStyle(fontSize: 16, color: Color(0xFFF4F4F6)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ===== INFORMACIÓN FINANCIERA =====
            const Text(
              'INFORMACIÓN FINANCIERA',
              style: TextStyle(fontSize: 12, color: Color(0xFF8888A0), letterSpacing: 2),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _montoTotalCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Color(0xFFF4F4F6)),
              decoration: _inputDecoration('Monto total (S/)', Icons.attach_money),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _montoPagadoCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Color(0xFFF4F4F6)),
              decoration: _inputDecoration('Monto pagado (S/)', Icons.money),
            ),
            const SizedBox(height: 24),

            // ===== INFORMACIÓN DEL CLIENTE =====
            const Text(
              'INFORMACIÓN DEL CLIENTE',
              style: TextStyle(fontSize: 12, color: Color(0xFF8888A0), letterSpacing: 2),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _tipoCliente = TipoCliente.persona),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _tipoCliente == TipoCliente.persona
                            ? const Color(0xFF33FF99).withValues(alpha: 0.2)
                            : const Color(0xFF1A1A24),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _tipoCliente == TipoCliente.persona
                              ? const Color(0xFF33FF99)
                              : const Color(0xFF8888A0).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.person,
                              color: _tipoCliente == TipoCliente.persona
                                  ? const Color(0xFF33FF99)
                                  : const Color(0xFF8888A0)),
                          const SizedBox(height: 4),
                          Text('Persona',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _tipoCliente == TipoCliente.persona
                                      ? const Color(0xFF33FF99)
                                      : const Color(0xFF8888A0))),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _tipoCliente = TipoCliente.empresa),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _tipoCliente == TipoCliente.empresa
                            ? const Color(0xFFB388FF).withValues(alpha: 0.2)
                            : const Color(0xFF1A1A24),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _tipoCliente == TipoCliente.empresa
                              ? const Color(0xFFB388FF)
                              : const Color(0xFF8888A0).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.business,
                              color: _tipoCliente == TipoCliente.empresa
                                  ? const Color(0xFFB388FF)
                                  : const Color(0xFF8888A0)),
                          const SizedBox(height: 4),
                          Text('Empresa',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _tipoCliente == TipoCliente.empresa
                                      ? const Color(0xFFB388FF)
                                      : const Color(0xFF8888A0))),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nombreClienteCtrl,
              style: const TextStyle(color: Color(0xFFF4F4F6)),
              decoration: _inputDecoration('Nombre completo / Razón social', Icons.person),
            ),
            const SizedBox(height: 12),
            if (_tipoCliente == TipoCliente.persona)
              TextField(
                controller: _dniCtrl,
                keyboardType: TextInputType.number,
                maxLength: 8,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(color: Color(0xFFF4F4F6)),
                decoration: _inputDecoration('DNI (8 dígitos)', Icons.badge),
              ),
            if (_tipoCliente == TipoCliente.empresa)
              TextField(
                controller: _rucCtrl,
                keyboardType: TextInputType.number,
                maxLength: 11,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(color: Color(0xFFF4F4F6)),
                decoration: _inputDecoration('RUC (11 dígitos)', Icons.receipt),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _telefonoClienteCtrl,
              keyboardType: TextInputType.phone,
              maxLength: 9,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(color: Color(0xFFF4F4F6)),
              decoration: _inputDecoration('Teléfono (9 dígitos, empieza con 9)', Icons.phone),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Color(0xFFF4F4F6)),
              decoration: _inputDecoration('Correo electrónico (opcional)', Icons.email),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _direccionCtrl,
              style: const TextStyle(color: Color(0xFFF4F4F6)),
              decoration: _inputDecoration('Dirección (opcional)', Icons.location_on),
            ),
            const SizedBox(height: 24),

            // ===== NOTAS =====
            const Text(
              'NOTAS',
              style: TextStyle(fontSize: 12, color: Color(0xFF8888A0), letterSpacing: 2),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notasCtrl,
              maxLines: 3,
              style: const TextStyle(color: Color(0xFFF4F4F6)),
              decoration: _inputDecoration('Notas adicionales (opcional)', Icons.note),
            ),
            const SizedBox(height: 32),

            // ===== BOTÓN GUARDAR =====
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _cargando ? null : _guardar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF33FF99),
                  foregroundColor: const Color(0xFF0D0D12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _cargando
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0D0D12)),
                      )
                    : Text(
                        _esEdicion ? 'ACTUALIZAR' : 'GUARDAR',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
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
      counterText: '',
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF33FF99), width: 2),
      ),
    );
  }

  Widget _buildEstadoChip(String label, EstadoProyecto estado, Color color) {
    final seleccionado = _estado == estado;
    return GestureDetector(
      onTap: () => setState(() {
        _estado = estado;
        // Sincroniza el porcentaje con el estado elegido: el cliente lo
        // verá reflejado en su gráfico de avance.
        if (estado == EstadoProyecto.pendiente) {
          _avance = 0;
        } else if (estado == EstadoProyecto.terminado) {
          _avance = 100;
        } else if (_avance == 0 || _avance >= 100) {
          _avance = 50;
        }
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: seleccionado ? color.withValues(alpha: 0.2) : const Color(0xFF1A1A24),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: seleccionado ? color : const Color(0xFF8888A0).withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: seleccionado ? color : const Color(0xFF8888A0),
            fontWeight: seleccionado ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildPagoChip(String label, TipoPago tipo) {
    final seleccionado = _tipoPago == tipo;
    return GestureDetector(
      onTap: () => setState(() => _tipoPago = tipo),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: seleccionado ? const Color(0xFF33FF99).withValues(alpha: 0.2) : const Color(0xFF1A1A24),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: seleccionado ? const Color(0xFF33FF99) : const Color(0xFF8888A0).withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: seleccionado ? const Color(0xFF33FF99) : const Color(0xFF8888A0),
            fontWeight: seleccionado ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildEstadoPagoChip(String label, EstadoPago estado, Color color) {
    final seleccionado = _estadoPago == estado;
    return GestureDetector(
      onTap: () => setState(() => _estadoPago = estado),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: seleccionado ? color.withValues(alpha: 0.2) : const Color(0xFF1A1A24),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: seleccionado ? color : const Color(0xFF8888A0).withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: seleccionado ? color : const Color(0xFF8888A0),
            fontWeight: seleccionado ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
