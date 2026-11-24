import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';
import 'modelos.dart';

class DatabaseHelper {
  static final DatabaseHelper _instancia = DatabaseHelper._interno();
  factory DatabaseHelper() => _instancia;
  DatabaseHelper._interno();

  static SupabaseClient get _client => SupabaseConfig.client;

  /// Sube una imagen a Supabase Storage.
  ///
  /// Recibe los BYTES de la imagen (y no un archivo de disco) porque así
  /// funciona en todas las plataformas: celular, PC y también en el
  /// navegador, donde no existe la ruta de un archivo.
  Future<String?> subirImagen(Uint8List bytes, String nombreArchivo) async {
    try {
      await _client.storage.from('proyectos').uploadBinary(
            nombreArchivo,
            bytes,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: false,
              contentType: 'image/jpeg',
            ),
          );
      final urlPublica = _client.storage.from('proyectos').getPublicUrl(nombreArchivo);
      return urlPublica;
    } catch (e) {
      debugPrint('ERROR AL SUBIR IMAGEN: $e');
      return null;
    }
  }

  Future<int> insertarProyecto(Proyecto proyecto) async {
    final response = await _client.from('proyectos').insert({
      'nombre_proyecto': proyecto.nombreProyecto,
      'tipo_servicio': proyecto.tipoServicio,
      'estado': proyecto.estado.name,
      'fecha_entrega': proyecto.fechaEntrega.toIso8601String(),
      'monto_total': proyecto.montoTotal,
      'monto_pagado': proyecto.montoPagado,
      'tipo_pago': proyecto.tipoPago.name,
      'estado_pago': proyecto.estadoPago.name,
      'notas': proyecto.notas,
      'cliente_nombre': proyecto.cliente.nombre,
      'cliente_telefono': proyecto.cliente.telefono,
      'cliente_email': proyecto.cliente.email,
      'tipo_cliente': proyecto.cliente.tipoCliente.name,
      'dni': proyecto.cliente.dni,
      'ruc': proyecto.cliente.ruc,
      'contacto_empresa': proyecto.cliente.contactoEmpresa,
      'direccion': proyecto.cliente.direccion,
      'imagen_url': proyecto.imagenUrl,
      'categoria': proyecto.categoria,
      'descripcion': proyecto.descripcion,
      'video_url': proyecto.videoUrl,
      'imagenes': proyecto.imagenes,
      'avance': proyecto.avance,
      'etapa': proyecto.etapa,
    }).select();
    return response.first['id'] as int;
  }

  Future<List<Proyecto>> obtenerProyectos() async {
    try {
      final response = await _client.from('proyectos').select().order('created_at', ascending: false);
      print('Respuesta proyectos: ${response.length}');
      final lista = <Proyecto>[];
      for (var item in response) {
        try {
          lista.add(Proyecto.fromMap(item));
        } catch (e) {
          print('Error mapeando: $e');
        }
      }
      print('Proyectos mapeados: ${lista.length}');
      return lista;
    } catch (e) {
      print('Error obteniendo proyectos: $e');
      return [];
    }
  }

  Future<int> actualizarProyecto(Proyecto proyecto) async {
    await _client.from('proyectos').update({
      'nombre_proyecto': proyecto.nombreProyecto,
      'tipo_servicio': proyecto.tipoServicio,
      'estado': proyecto.estado.name,
      'fecha_entrega': proyecto.fechaEntrega.toIso8601String(),
      'monto_total': proyecto.montoTotal,
      'monto_pagado': proyecto.montoPagado,
      'tipo_pago': proyecto.tipoPago.name,
      'estado_pago': proyecto.estadoPago.name,
      'notas': proyecto.notas,
      'cliente_nombre': proyecto.cliente.nombre,
      'cliente_telefono': proyecto.cliente.telefono,
      'cliente_email': proyecto.cliente.email,
      'tipo_cliente': proyecto.cliente.tipoCliente.name,
      'dni': proyecto.cliente.dni,
      'ruc': proyecto.cliente.ruc,
      'contacto_empresa': proyecto.cliente.contactoEmpresa,
      'direccion': proyecto.cliente.direccion,
      'imagen_url': proyecto.imagenUrl,
      'categoria': proyecto.categoria,
      'descripcion': proyecto.descripcion,
      'video_url': proyecto.videoUrl,
      'imagenes': proyecto.imagenes,
      'avance': proyecto.avance,
      'etapa': proyecto.etapa,
    }).eq('id', proyecto.id!);
    return proyecto.id!;
  }

  Future<int> eliminarProyecto(int id) async {
    await _client.from('proyectos').delete().eq('id', id);
    return id;
  }

  /// Recupera UN proyecto por su id (se usa para refrescar el detalle
  /// después de editar, evitando mostrar datos viejos en pantalla).
  Future<Proyecto?> obtenerProyecto(int id) async {
    try {
      final response =
          await _client.from('proyectos').select().eq('id', id).limit(1);
      if (response.isEmpty) return null;
      return Proyecto.fromMap(response.first);
    } catch (e) {
      print('Error obteniendo proyecto: $e');
      return null;
    }
  }

  // ==================== CAJA DE MENSAJES (notas) ====================
  /// Mensajes del proyecto ordenados del más antiguo al más reciente.
  /// Si la tabla aún no existe en Supabase, devuelve una lista vacía.
  Future<List<NotaProyecto>> obtenerNotas(int proyectoId) async {
    try {
      final response = await _client
          .from('notas_proyecto')
          .select()
          .eq('proyecto_id', proyectoId)
          .order('creado_en', ascending: true);
      return (response as List)
          .map((m) => NotaProyecto.fromMap(m))
          .toList();
    } catch (e) {
      print('Error obteniendo notas: $e');
      return [];
    }
  }

  /// Guarda un mensaje en la caja. `autor` es 'estudio' o 'cliente'.
  Future<bool> agregarNota(int proyectoId, String autor, String mensaje) async {
    try {
      await _client.from('notas_proyecto').insert({
        'proyecto_id': proyectoId,
        'autor': autor,
        'mensaje': mensaje,
      });
      return true;
    } catch (e) {
      print('Error guardando nota: $e');
      return false;
    }
  }

  // ==================== UBICACIÓN DEL ESTUDIO (empresa) ====================
  /// Devuelve la única fila de la tabla `empresa` (id = 1).
  /// Si la tabla aún no existe en Supabase, devuelve valores por defecto
  /// (sin dirección ni coordenadas) para que la app no se rompa.
  Future<Empresa> obtenerEmpresa() async {
    try {
      final response =
          await _client.from('empresa').select().eq('id', 1).limit(1);
      if (response.isEmpty) return Empresa();
      return Empresa.fromMap(response.first);
    } catch (e) {
      print('Error obteniendo empresa: $e');
      return Empresa();
    }
  }

  /// Guarda (o actualiza) la ubicación del estudio. Como siempre es la
  /// misma fila (id = 1) se usa upsert: si no existe la crea y si existe
  /// la reemplaza.
  Future<bool> guardarEmpresa(Empresa e) async {
    try {
      await _client.from('empresa').upsert({
        'id': 1,
        'nombre': e.nombre,
        'direccion': e.direccion,
        'latitud': e.latitud,
        'longitud': e.longitud,
        'foto_url': e.fotoUrl,
        'actualizado_en': DateTime.now().toUtc().toIso8601String(),
      });
      return true;
    } catch (err) {
      print('Error guardando empresa: $err');
      return false;
    }
  }

  // ==================== CLIENTES ====================

  /// Excepción de validación: se lanza cuando un cliente no cumple
  /// las reglas del negocio (DNI 8, RUC 11, teléfono 9, correo válido).
  /// Última barrera: aunque una pantalla olvide validar, la capa de
  /// datos nunca guarda un cliente con datos incompletos.
  void _validarCliente(Cliente c) {
    final errores = <String>[];
    if (c.nombre.trim().isEmpty) {
      errores.add('El nombre / razón social es obligatorio.');
    }
    if (c.telefono.trim().length != 9) {
      errores.add(
          'El teléfono debe tener exactamente 9 dígitos (lleva ${c.telefono.trim().length}).');
    } else if (!c.telefono.trim().startsWith('9')) {
      errores.add('El teléfono debe empezar con 9 (celular peruano).');
    }
    if (c.dni != null && c.dni!.isNotEmpty && c.dni!.length != 8) {
      errores.add('El DNI debe tener exactamente 8 dígitos.');
    }
    if (c.ruc != null && c.ruc!.isNotEmpty && c.ruc!.length != 11) {
      errores.add('El RUC debe tener exactamente 11 dígitos.');
    }
    final email = (c.email ?? '').trim().toLowerCase();
    if (email.isNotEmpty &&
        !RegExp(r'^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$').hasMatch(email)) {
      errores.add(
          'El correo no tiene un formato válido (ejemplo: cliente@correo.com).');
    }
    if (errores.isNotEmpty) {
      throw Exception(errores.join(' '));
    }
  }

  /// Verifica que el DNI, RUC y correo del cliente NO pertenezcan a otro
  /// cliente ya registrado. `idActual` es el id del propio cliente cuando
  /// se edita, para no compararse consigo mismo.
  Future<void> _validarClienteUnico(Cliente c, {int? idActual}) async {
    final existentes = await obtenerClientes();
    final dni = c.dni?.trim();
    final ruc = c.ruc?.trim();
    final email = (c.email ?? '').trim().toLowerCase();
    for (final otro in existentes) {
      if (idActual != null && otro.id == idActual) continue;
      if (dni != null && dni.isNotEmpty && otro.dni == dni) {
        throw Exception('Ya existe un cliente con el DNI $dni (${otro.nombre}).');
      }
      if (ruc != null && ruc.isNotEmpty && otro.ruc == ruc) {
        throw Exception('Ya existe un cliente con el RUC $ruc (${otro.nombre}).');
      }
      if (email.isNotEmpty && (otro.email ?? '').trim().toLowerCase() == email) {
        throw Exception('Ya existe un cliente con el correo $email (${otro.nombre}).');
      }
    }
  }

  Future<int> insertarCliente(Cliente cliente) async {
    _validarCliente(cliente); // rechaza datos inválidos antes de guardar
    await _validarClienteUnico(cliente); // DNI, RUC y correo son únicos
    final data = cliente.toMap();
    data.remove('id'); // No enviar id para que Supabase lo genere automáticamente
    final response = await _client.from('clientes').insert(data).select();
    return response.first['id'] as int;
  }

  Future<List<Cliente>> obtenerClientes() async {
    try {
      final response = await _client.from('clientes').select().order('created_at', ascending: false);
      return (response as List).map((m) => Cliente.fromMap(m)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<int> actualizarCliente(Cliente cliente) async {
    final data = cliente.toMap();
    data.remove('id');
    _validarCliente(cliente); // rechaza datos inválidos antes de guardar
    // En edición se excluye al propio cliente de la comparación.
    await _validarClienteUnico(cliente, idActual: cliente.id);
    await _client.from('clientes').update(data).eq('id', cliente.id!);
    return cliente.id!;
  }

  Future<int> eliminarCliente(int id) async {
    await _client.from('clientes').delete().eq('id', id);
    return id;
  }

  /// Devuelve la ficha del cliente cuyo CORREO coincide con el usuario
  /// autenticado (Supabase Auth). El servidor ya validó la contraseña;
  /// aquí solo se recupera el registro que le pertenece.
  Future<Cliente?> obtenerClientePorEmail(String email) async {
    try {
      final response = await _client
          .from('clientes')
          .select()
          .eq('email', email.trim().toLowerCase())
          .limit(1);
      if (response.isEmpty) return null;
      return Cliente.fromMap(response.first);
    } catch (e) {
      print('Error buscando cliente por email: $e');
      return null;
    }
  }

  // ==================== SERVICIOS ====================
  Future<int> insertarServicio(Map<String, dynamic> servicio) async {
    final data = Map<String, dynamic>.from(servicio);
    data.remove('id');
    final response = await _client.from('servicios').insert(data).select();
    return response.first['id'] as int;
  }

  Future<List<Map<String, dynamic>>> obtenerServicios() async {
    try {
      final response = await _client.from('servicios').select().order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<int> eliminarServicio(int id) async {
    await _client.from('servicios').delete().eq('id', id);
    return id;
  }
}
