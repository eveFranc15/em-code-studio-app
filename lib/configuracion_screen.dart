import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import 'database_helper.dart';
import 'login_screen.dart';
import 'modelos.dart';

class ConfiguracionScreen extends StatefulWidget {
  const ConfiguracionScreen({super.key});

  @override
  State<ConfiguracionScreen> createState() => _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends State<ConfiguracionScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _direccionCtrl = TextEditingController();

  Empresa _empresa = Empresa();
  Uint8List? _fotoNueva; // foto elegida que aún no se sube
  bool _cargando = true;
  bool _guardando = false;
  bool _obteniendoGps = false;

  @override
  void initState() {
    super.initState();
    _cargarEmpresa();
  }

  @override
  void dispose() {
    _direccionCtrl.dispose();
    super.dispose();
  }

  void _mostrar(String mensaje, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: error ? const Color(0xFFE74C3C) : const Color(0xFF33FF99),
      ),
    );
  }

  Future<void> _cargarEmpresa() async {
    final e = await _dbHelper.obtenerEmpresa();
    if (!mounted) return;
    setState(() {
      _empresa = e;
      _direccionCtrl.text = e.direccion ?? '';
      _cargando = false;
    });
  }

  // ============ UBICACIÓN DEL ESTUDIO ============

  /// Opciones de la foto: tomar con la cámara, elegir de la galería
  /// o quitar la actual. (Mismo patrón que el formulario de proyectos)
  /// La quitar solo se visualiza aquí: el cambio se aprieta al
  /// pulsar GUARDAR UBICACIÓN.
  void _mostrarOpcionesFoto() {
    final hayFoto = _empresa.fotoUrl != null || _fotoNueva != null;
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
                'FOTO DE LA UBICACIÓN',
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
                _seleccionarFoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF33FF99)),
              title: const Text('Elegir de la galería'),
              onTap: () {
                Navigator.pop(context);
                _seleccionarFoto(ImageSource.gallery);
              },
            ),
            if (hayFoto)
              ListTile(
                leading: const Icon(Icons.delete, color: Color(0xFFE74C3C)),
                title: const Text('Quitar foto'),
                subtitle: const Text(
                  'Se quita al pulsar GUARDAR UBICACIÓN',
                  style: TextStyle(fontSize: 11, color: Color(0xFF8888A0)),
                ),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _fotoNueva = null;
                    _empresa.fotoUrl = null;
                  });
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _seleccionarFoto(ImageSource source) async {
    final XFile? imagen = await _picker.pickImage(
      source: source,
      maxWidth: 1280,
      imageQuality: 80,
    );
    if (imagen == null) return;
    final bytes = await imagen.readAsBytes();
    setState(() => _fotoNueva = bytes);
  }

  // Obtiene la ubicación actual del teléfono (mismo flujo que GeoCam)
  Future<void> _usarUbicacionActual() async {
    setState(() => _obteniendoGps = true);
    try {
      final servicioActivo = await Geolocator.isLocationServiceEnabled();
      if (!servicioActivo) {
        _mostrar('Activa el GPS del teléfono para usar tu ubicación', error: true);
        return;
      }

      var permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }
      if (permiso == LocationPermission.denied ||
          permiso == LocationPermission.deniedForever) {
        _mostrar('Permiso de ubicación denegado. Puedes escribir la dirección a mano.', error: true);
        return;
      }

      final posicion = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 25),
        ),
      );

      if (!mounted) return;
      setState(() {
        _empresa.latitud = posicion.latitude;
        _empresa.longitud = posicion.longitude;
      });
      _mostrar('Ubicación capturada');
    } catch (e) {
      _mostrar('No se pudo obtener la ubicación. Escribe la dirección a mano.', error: true);
    } finally {
      if (mounted) setState(() => _obteniendoGps = false);
    }
  }

  Future<void> _guardarUbicacion() async {
    if (_direccionCtrl.text.trim().isEmpty && !_empresa.tieneCoordenadas) {
      _mostrar('Escribe la dirección o usa tu ubicación actual', error: true);
      return;
    }

    setState(() => _guardando = true);
    try {
      // Si eligió una foto nueva, se sube primero a Supabase Storage
      String? url = _empresa.fotoUrl;
      if (_fotoNueva != null) {
        url = await _dbHelper.subirImagen(
          _fotoNueva!,
          'empresa_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        if (url == null) {
          _mostrar('No se pudo subir la foto', error: true);
          return;
        }
      }

      final exito = await _dbHelper.guardarEmpresa(Empresa(
        nombre: _empresa.nombre,
        direccion: _direccionCtrl.text.trim().isEmpty ? null : _direccionCtrl.text.trim(),
        latitud: _empresa.latitud,
        longitud: _empresa.longitud,
        fotoUrl: url,
      ));

      if (!mounted) return;
      if (exito) {
        setState(() {
          _empresa.fotoUrl = url;
          _empresa.direccion = _direccionCtrl.text.trim().isEmpty ? null : _direccionCtrl.text.trim();
          _fotoNueva = null;
        });
        _mostrar('Ubicación del estudio guardada');
      } else {
        _mostrar('No se pudo guardar: falta crear la tabla "empresa" en Supabase', error: true);
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _abrirEnMaps() async {
    if (!_empresa.tieneCoordenadas && _direccionCtrl.text.trim().isEmpty) return;
    final destino = _empresa.tieneCoordenadas
        ? '${_empresa.latitud},${_empresa.longitud}'
        : Uri.encodeQueryComponent(_direccionCtrl.text.trim());
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$destino');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      _mostrar('No se pudo abrir Google Maps', error: true);
    }
  }

  Widget _fotoDeEmpresa() {
    final String? url = _fotoNueva == null ? _empresa.fotoUrl : null;
    if (url != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          url,
          width: 96,
          height: 96,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const _FotoVacia(),
        ),
      );
    }
    if (_fotoNueva != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(
          _fotoNueva!,
          width: 96,
          height: 96,
          fit: BoxFit.cover,
        ),
      );
    }
    return const _FotoVacia();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _cargando
            ? const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator(color: Color(0xFF33FF99))),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cuenta
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'CUENTA',
                            style: TextStyle(fontSize: 12, color: Color(0xFF8888A0), letterSpacing: 2),
                          ),
                          const SizedBox(height: 16),
                          ListTile(
                            leading: const Icon(Icons.person, color: Color(0xFF33FF99)),
                            title: const Text('Administrador'),
                            subtitle: const Text('admin evelin marreros'),
                          ),
                          ListTile(
                            leading: const Icon(Icons.email, color: Color(0xFF33FF99)),
                            title: const Text('Email'),
                            subtitle: const Text('admin@emcodestudio.com'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ===== UBICACIÓN DEL ESTUDIO =====
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'UBICACIÓN DEL ESTUDIO',
                            style: TextStyle(fontSize: 12, color: Color(0xFF8888A0), letterSpacing: 2),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'El cliente la verá en su panel y podrá abrirla en Google Maps. '
                            'Edítala aquí cada vez que cambies de dirección.',
                            style: TextStyle(fontSize: 12, color: Color(0xFF8888A0)),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _fotoDeEmpresa(),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton.icon(
                                        onPressed: _mostrarOpcionesFoto,
                                        icon: const Icon(Icons.photo_camera, size: 16),
                                        label: Text(
                                          _empresa.fotoUrl != null || _fotoNueva != null
                                              ? 'CAMBIAR FOTO'
                                              : 'AGREGAR FOTO',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: const Color(0xFF33FF99),
                                          side: const BorderSide(color: Color(0xFF33FF99)),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _empresa.tieneCoordenadas
                                          ? 'Lat: ${_empresa.latitud!.toStringAsFixed(6)}\nLng: ${_empresa.longitud!.toStringAsFixed(6)}'
                                          : 'Sin coordenadas',
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF8888A0)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _direccionCtrl,
                            decoration: InputDecoration(
                              labelText: 'Dirección del estudio',
                              hintText: 'Ej.: Av. Principal, Cúcuta',
                              labelStyle: const TextStyle(color: Color(0xFF8888A0)),
                              prefixIcon: const Icon(Icons.place, color: Color(0xFF33FF99)),
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
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _obteniendoGps ? null : _usarUbicacionActual,
                              icon: _obteniendoGps
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF33FF99)),
                                    )
                                  : const Icon(Icons.my_location, size: 16),
                              label: Text(
                                _obteniendoGps ? 'OBTENIENDO...' : 'USAR MI UBICACIÓN ACTUAL (GPS)',
                                style: const TextStyle(fontSize: 12),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFB388FF),
                                side: const BorderSide(color: Color(0xFFB388FF)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: ElevatedButton.icon(
                              onPressed: _guardando ? null : _guardarUbicacion,
                              icon: _guardando
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0D0D12)),
                                    )
                                  : const Icon(Icons.save, size: 18),
                              label: Text(_guardando ? 'GUARDANDO...' : 'GUARDAR UBICACIÓN'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF33FF99),
                                foregroundColor: const Color(0xFF0D0D12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          if (_empresa.tieneCoordenadas) ...[
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: TextButton.icon(
                                onPressed: _abrirEnMaps,
                                icon: const Icon(Icons.map, size: 18, color: Color(0xFF33FF99)),
                                label: const Text(
                                  'VER COMO LO VE EL CLIENTE (GOOGLE MAPS)',
                                  style: TextStyle(fontSize: 11, color: Color(0xFF33FF99)),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Acerca de
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ACERCA DE',
                            style: TextStyle(fontSize: 12, color: Color(0xFF8888A0), letterSpacing: 2),
                          ),
                          const SizedBox(height: 16),
                          ListTile(
                            leading: const Icon(Icons.info, color: Color(0xFF33FF99)),
                            title: const Text('Versión'),
                            subtitle: const Text('1.0.0'),
                          ),
                          ListTile(
                            leading: const Icon(Icons.code, color: Color(0xFF33FF99)),
                            title: const Text('Desarrollado por'),
                            subtitle: const Text('Evelin Marreros - EM Code Studio'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Cerrar sesión
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                        );
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('CERRAR SESIÓN'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE74C3C),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _FotoVacia extends StatelessWidget {
  const _FotoVacia();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A24),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF8888A0).withValues(alpha: 0.3)),
      ),
      child: const Icon(Icons.add_a_photo, color: Color(0xFF8888A0), size: 32),
    );
  }
}
