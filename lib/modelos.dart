enum EstadoProyecto { pendiente, enProceso, terminado }
enum TipoPago { efectivo, transferencia, yapePlin }
enum EstadoPago { pendiente, adelanto, pagado }
enum TipoCliente { persona, empresa }

/// Formatea un monto en soles con separador de miles.
/// Ejemplo: formatearSoles(32300) => 'S/ 32,300.00'
/// Usar decimales: 0 para montos enteros (ej. 'S/ 32,300').
String formatearSoles(num monto, {int decimales = 2}) {
  final fijo = monto.toDouble().toStringAsFixed(decimales);
  final partes = fijo.split('.');
  final entero = partes[0];
  final buf = StringBuffer();
  for (int i = 0; i < entero.length; i++) {
    if (i > 0 && (entero.length - i) % 3 == 0) buf.write(',');
    buf.write(entero[i]);
  }
  return decimales > 0 ? 'S/ $buf.${partes[1]}' : 'S/ $buf';
}

class Cliente {
  int? id;
  String nombre;
  String telefono;
  String? email;
  /// Contraseña que la dueña del estudio le otorga al cliente para que
  /// pueda entrar al panel de seguimiento con su correo.
  String? clave;
  TipoCliente tipoCliente;
  String? dni;
  String? ruc;
  String? contactoEmpresa;
  String? direccion;

  Cliente({
    this.id,
    required this.nombre,
    required this.telefono,
    this.email,
    this.clave,
    this.tipoCliente = TipoCliente.persona,
    this.dni,
    this.ruc,
    this.contactoEmpresa,
    this.direccion,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tipo': tipoCliente.name,
      'nombre': nombre,
      'dni': dni,
      'ruc': ruc,
      'telefono': telefono,
      'email': email,
      'clave': clave,
      // Persona de contacto cuando el cliente es una empresa.
      // Sin esta línea el campo nunca se guardaba en Supabase.
      'contacto_empresa': contactoEmpresa,
      'direccion': direccion,
    };
  }

  factory Cliente.fromMap(Map<String, dynamic> map) {
    return Cliente(
      id: map['id'],
      nombre: map['nombre'] ?? '',
      telefono: map['telefono'] ?? '',
      email: map['email'],
      clave: map['clave'],
      tipoCliente: map['tipo'] == 'empresa' ? TipoCliente.empresa : TipoCliente.persona,
      dni: map['dni'],
      ruc: map['ruc'],
      contactoEmpresa: map['contacto_empresa'],
      direccion: map['direccion'],
    );
  }
}

class Proyecto {
  int? id;
  String nombreProyecto;
  String tipoServicio;
  EstadoProyecto estado;
  DateTime fechaEntrega;
  double montoTotal;
  double montoPagado;
  TipoPago tipoPago;
  EstadoPago estadoPago;
  String notas;
  Cliente cliente;
  String? imagenUrl;
  String? categoria;
  String? descripcion;
  String? videoUrl;
  List<String>? imagenes;
  /// Porcentaje de avance del trabajo (0 a 100) que la dueña actualiza.
  int avance;
  /// Etapa en la que se encuentra el trabajo (ej. Diseño, Desarrollo...).
  String? etapa;
  /// Fecha en que se REGISTRÓ la venta en la app (columna `created_at`
  /// de Supabase). Es la que usan los reportes de ventas por período.
  /// Si un registro antiguo no la trae, los reportes usan la fecha
  /// de entrega como respaldo.
  DateTime? fechaRegistro;

  Proyecto({
    this.id,
    required this.nombreProyecto,
    required this.tipoServicio,
    required this.estado,
    required this.fechaEntrega,
    required this.montoTotal,
    required this.montoPagado,
    required this.tipoPago,
    required this.estadoPago,
    required this.notas,
    required this.cliente,
    this.imagenUrl,
    this.categoria,
    this.descripcion,
    this.videoUrl,
    this.imagenes,
    this.avance = 0,
    this.etapa,
    this.fechaRegistro,
  });

  double get saldoPendiente => montoTotal - montoPagado;

  /// Porcentaje que se muestra al cliente: si no se ha guardado un valor
  /// específico, se deduce del estado del proyecto.
  int get avanceCalculado {
    if (avance > 0) return avance > 100 ? 100 : avance;
    switch (estado) {
      case EstadoProyecto.pendiente:
        return 0;
      case EstadoProyecto.enProceso:
        return 50;
      case EstadoProyecto.terminado:
        return 100;
    }
  }

  /// Etapa visible para el cliente.
  String get etapaActual {
    final e = etapa?.trim();
    if (e != null && e.isNotEmpty) return e;
    switch (estado) {
      case EstadoProyecto.pendiente:
        return 'Pendiente de iniciar';
      case EstadoProyecto.enProceso:
        return 'En desarrollo';
      case EstadoProyecto.terminado:
        return 'Entregado';
    }
  }

  factory Proyecto.fromMap(Map<String, dynamic> map) {
    return Proyecto(
      id: map['id'] ?? 0,
      nombreProyecto: map['nombre_proyecto'] ?? '',
      tipoServicio: map['tipo_servicio'] ?? '',
      estado: EstadoProyecto.values.firstWhere(
        (e) => e.name == map['estado'],
        orElse: () => EstadoProyecto.pendiente,
      ),
      fechaEntrega: map['fecha_entrega'] != null
          ? DateTime.parse(map['fecha_entrega'])
          : DateTime.now(),
      // Fecha de registro de la venta (created_at en Supabase).
      fechaRegistro: DateTime.tryParse(map['created_at']?.toString() ?? ''),
      montoTotal: (map['monto_total'] as num?)?.toDouble() ?? 0.0,
      montoPagado: (map['monto_pagado'] as num?)?.toDouble() ?? 0.0,
      tipoPago: TipoPago.values.firstWhere(
        (e) => e.name == map['tipo_pago'],
        orElse: () => TipoPago.efectivo,
      ),
      estadoPago: EstadoPago.values.firstWhere(
        (e) => e.name == map['estado_pago'],
        orElse: () => EstadoPago.pendiente,
      ),
      notas: map['notas'] ?? '',
      cliente: Cliente(
        nombre: map['cliente_nombre'] ?? '',
        telefono: map['cliente_telefono'] ?? '',
        tipoCliente: map['tipo_cliente'] == 'empresa' ? TipoCliente.empresa : TipoCliente.persona,
        dni: map['dni'],
        ruc: map['ruc'],
        contactoEmpresa: map['contacto_empresa'],
        direccion: map['direccion'],
        email: map['cliente_email'],
      ),
      imagenUrl: map['imagen_url'],
      categoria: map['categoria'],
      descripcion: map['descripcion'],
      videoUrl: map['video_url'],
      imagenes: map['imagenes'] != null
          ? List<String>.from(map['imagenes'])
          : null,
      avance: (map['avance'] as num?)?.toInt() ?? 0,
      etapa: map['etapa'],
    );
  }
}

/// Mensaje dentro de la caja de notas de un proyecto.
///
/// `autor` es 'estudio' (la dueña del proyecto) o 'cliente'.
/// El profesor pidió una caja donde el estudio deje notas y el
/// cliente pueda verlas y responder con sus sugerencias.
class NotaProyecto {
  final int? id;
  final int proyectoId;
  final String autor;
  final String mensaje;
  final DateTime creadoEn;

  NotaProyecto({
    this.id,
    required this.proyectoId,
    required this.autor,
    required this.mensaje,
    required this.creadoEn,
  });

  /// true si la nota la escribió el estudio; false si la escribió el cliente.
  bool get esEstudio => autor == 'estudio';

  factory NotaProyecto.fromMap(Map<String, dynamic> map) {
    return NotaProyecto(
      id: (map['id'] as num?)?.toInt(),
      proyectoId: (map['proyecto_id'] as num?)?.toInt() ?? 0,
      autor: map['autor'] ?? 'estudio',
      mensaje: map['mensaje'] ?? '',
      creadoEn: DateTime.tryParse(map['creado_en']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

/// Datos de la empresa (una sola fila, id = 1): la ubicación del
/// estudio que el cliente ve en su panel y abre en Google Maps.
/// El admin la edita desde Configuración si cambia de dirección.
class Empresa {
  int id;
  String nombre;
  String? direccion;
  double? latitud;
  double? longitud;
  String? fotoUrl;

  Empresa({
    this.id = 1,
    this.nombre = 'EM Code Studio',
    this.direccion,
    this.latitud,
    this.longitud,
    this.fotoUrl,
  });

  /// true si ya se registraron las coordenadas.
  bool get tieneCoordenadas => latitud != null && longitud != null;

  factory Empresa.fromMap(Map<String, dynamic> map) {
    return Empresa(
      id: (map['id'] as num?)?.toInt() ?? 1,
      nombre: map['nombre'] ?? 'EM Code Studio',
      direccion: map['direccion'],
      latitud: (map['latitud'] as num?)?.toDouble(),
      longitud: (map['longitud'] as num?)?.toDouble(),
      fotoUrl: map['foto_url'],
    );
  }
}
