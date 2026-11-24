import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'animaciones_svg.dart';
import 'animaciones_web.dart';
import 'modelos.dart';
import 'database_helper.dart';
import 'supabase_config.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final TextEditingController _busquedaCtrl = TextEditingController();
  List<Cliente> clientes = [];
  List<Cliente> clientesFiltrados = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarClientes();
    _busquedaCtrl.addListener(_filtrarClientes);
  }

  @override
  void dispose() {
    _busquedaCtrl.dispose();
    super.dispose();
  }

  void _filtrarClientes() {
    final query = _busquedaCtrl.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        clientesFiltrados = clientes;
      } else {
        clientesFiltrados = clientes.where((c) {
          return c.nombre.toLowerCase().contains(query) ||
              (c.dni?.toLowerCase().contains(query) ?? false) ||
              (c.ruc?.toLowerCase().contains(query) ?? false) ||
              (c.email?.toLowerCase().contains(query) ?? false);
        }).toList();
      }
    });
  }

  Future<void> _cargarClientes() async {
    setState(() => _cargando = true);
    final lista = await _dbHelper.obtenerClientes();
    setState(() {
      clientes = lista;
      clientesFiltrados = lista;
      _cargando = false;
    });
  }

  Future<void> _eliminarCliente(Cliente cliente) async {
    await _dbHelper.eliminarCliente(cliente.id!);
    _cargarClientes();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cliente eliminado')),
      );
    }
  }

  /// Ventana de confirmación previa a eliminar un cliente.
  ///
  /// Se muestra al deslizar la tarjeta: devuelve `true` solo cuando el
  /// usuario pulsa "ELIMINAR". Si elige "CANCELAR" (o cierra la ventana),
  /// la tarjeta regresa a su lugar y NO se borra nada.
  Future<bool> _confirmarEliminacionCliente(Cliente cliente) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(
          Icons.warning_amber_rounded,
          color: Color(0xFFF39C12),
          size: 40,
        ),
        title: const Text(
          '¿Eliminar cliente?',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFFF4F4F6),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Vas a eliminar a "${cliente.nombre}" y todos sus datos. '
          'Esta acción no se puede deshacer.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF8888A0), fontSize: 14, height: 1.4),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'CANCELAR',
              style: TextStyle(
                color: Color(0xFF8888A0),
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE74C3C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text(
              'ELIMINAR',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
          ),
        ],
      ),
    );
    return confirmado ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Clientes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarClientes,
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Barra de búsqueda
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    controller: _busquedaCtrl,
                    decoration: InputDecoration(
                      hintText: 'Buscar por nombre, DNI, RUC o email...',
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF33FF99)),
                      suffixIcon: _busquedaCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Color(0xFF8888A0)),
                              onPressed: () {
                                _busquedaCtrl.clear();
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: const Color(0xFF1A1A24),
                    ),
                  ),
                ),
                // Lista de clientes
                Expanded(
                  child: clientes.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people, size: 80, color: const Color(0xFF8888A0)),
                              const SizedBox(height: 16),
                              Text(
                                'No hay clientes aún',
                                style: TextStyle(fontSize: 16, color: const Color(0xFF8888A0)),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Toca + para agregar uno',
                                style: TextStyle(fontSize: 14, color: const Color(0xFF8888A0)),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: clientesFiltrados.length,
                          itemBuilder: (context, index) {
                            final cliente = clientesFiltrados[index];
                            return Dismissible(
                              key: Key(cliente.id.toString()),
                              direction: DismissDirection.endToStart,
                              // Pide confirmación antes de borrar: un
                              // desliz accidental NO elimina al cliente.
                              confirmDismiss: (_) =>
                                  _confirmarEliminacionCliente(cliente),
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE74C3C).withValues(alpha: 0.8),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(Icons.delete, color: Colors.white, size: 30),
                              ),
                              onDismissed: (_) => _eliminarCliente(cliente),
                              child: Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: cliente.tipoCliente == TipoCliente.empresa
                                        ? const Color(0xFFB388FF).withValues(alpha: 0.2)
                                        : const Color(0xFF33FF99).withValues(alpha: 0.2),
                                    child: Icon(
                                      cliente.tipoCliente == TipoCliente.empresa
                                          ? Icons.business
                                          : Icons.person,
                                      color: cliente.tipoCliente == TipoCliente.empresa
                                          ? const Color(0xFFB388FF)
                                          : const Color(0xFF33FF99),
                                    ),
                                  ),
                                  title: Text(
                                    cliente.nombre,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (cliente.dni != null && cliente.dni!.isNotEmpty)
                                        Text('DNI: ${cliente.dni}'),
                                      if (cliente.ruc != null && cliente.ruc!.isNotEmpty)
                                        Text('RUC: ${cliente.ruc}'),
                                      if (cliente.telefono.isNotEmpty)
                                        Text('Tel: ${cliente.telefono}'),
                                      if (cliente.email != null && cliente.email!.isNotEmpty)
                                        Text('Email: ${cliente.email}'),
                                      if (cliente.clave != null && cliente.clave!.isNotEmpty)
                                        Text('Clave de acceso: ${cliente.clave}'),
                                    ],
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.edit, color: Color(0xFF33FF99)),
                                    onPressed: () => _mostrarFormularioCliente(cliente: cliente),
                                  ),
                                  onTap: () => _mostrarDetalleCliente(cliente),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarFormularioCliente(),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Cliente'),
      ),
    );
  }

  void _mostrarFormularioCliente({Cliente? cliente}) {
    final esEdicion = cliente != null;
    final nombreCtrl = TextEditingController(text: cliente?.nombre ?? '');
    final dniCtrl = TextEditingController(text: cliente?.dni ?? '');
    final rucCtrl = TextEditingController(text: cliente?.ruc ?? '');
    final telefonoCtrl = TextEditingController(text: cliente?.telefono ?? '');
    final emailCtrl = TextEditingController(text: cliente?.email ?? '');
    final claveCtrl = TextEditingController(text: cliente?.clave ?? '');
    final direccionCtrl = TextEditingController(text: cliente?.direccion ?? '');
    TipoCliente tipoCliente = cliente?.tipoCliente ?? TipoCliente.persona;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.88,
            child: FondoAnimado(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                  left: 16,
                  right: 16,
                  top: 16,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
              ApareceAnimado(
                child: Text(
                  esEdicion ? 'Editar Cliente' : 'Nuevo Cliente',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
              // Tipo de cliente
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setModalState(() => tipoCliente = TipoCliente.persona),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: tipoCliente == TipoCliente.persona
                              ? const Color(0xFF33FF99).withValues(alpha: 0.2)
                              : const Color(0xFF1A1A24),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: tipoCliente == TipoCliente.persona
                                ? const Color(0xFF33FF99)
                                : const Color(0xFF8888A0).withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.person, color: Color(0xFF33FF99)),
                            Text('Persona'),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setModalState(() => tipoCliente = TipoCliente.empresa),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: tipoCliente == TipoCliente.empresa
                              ? const Color(0xFFB388FF).withValues(alpha: 0.2)
                              : const Color(0xFF1A1A24),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: tipoCliente == TipoCliente.empresa
                                ? const Color(0xFFB388FF)
                                : const Color(0xFF8888A0).withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.business, color: Color(0xFFB388FF)),
                            Text('Empresa'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nombreCtrl,
                maxLength: 60,
                decoration: const InputDecoration(
                  labelText: 'Nombre completo / Razón social',
                  counterText: '',
                  prefixIcon: Icon(Icons.person, color: Color(0xFF33FF99)),
                ),
              ),
              const SizedBox(height: 12),
              // El DNI solo aplica a personas naturales (las empresas no tienen DNI)
              if (tipoCliente == TipoCliente.persona) ...[
                TextField(
                  controller: dniCtrl,
                  maxLength: 8,
                  decoration: const InputDecoration(
                    labelText: 'DNI (8 dígitos, obligatorio)',
                    helperText: 'El campo no deja escribir más de 8 dígitos',
                    counterText: '',
                    prefixIcon: Icon(Icons.badge, color: Color(0xFF33FF99)),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: rucCtrl,
                maxLength: 11,
                decoration: InputDecoration(
                  labelText: tipoCliente == TipoCliente.empresa
                      ? 'RUC (11 dígitos, obligatorio)'
                      : 'RUC (opcional, 11 dígitos)',
                  helperText: 'El campo no deja escribir más de 11 dígitos',
                  counterText: '',
                  prefixIcon: const Icon(Icons.receipt, color: Color(0xFFB388FF)),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: telefonoCtrl,
                maxLength: 9,
                decoration: const InputDecoration(
                  labelText: 'Teléfono (9 dígitos, empieza con 9)',
                  counterText: '',
                  prefixIcon: Icon(Icons.phone, color: Color(0xFF33FF99)),
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailCtrl,
                maxLength: 80,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico (obligatorio)',
                  helperText: 'Con este correo el cliente entra a su panel',
                  counterText: '',
                  prefixIcon: Icon(Icons.email, color: Color(0xFF33FF99)),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: claveCtrl,
                maxLength: 40,
                decoration: const InputDecoration(
                  labelText: 'Contraseña que le otorgas al cliente',
                  helperText: 'Ella la usa junto con el correo para iniciar sesión',
                  counterText: '',
                  prefixIcon: Icon(Icons.key, color: Color(0xFFB388FF)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: direccionCtrl,
                maxLength: 120,
                decoration: const InputDecoration(
                  labelText: 'Dirección (opcional)',
                  counterText: '',
                  prefixIcon: Icon(Icons.location_on, color: Color(0xFF33FF99)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    // ===== VALIDACIÓN =====
                    final errores = <String>[];
                    final dni = dniCtrl.text.trim();
                    final ruc = rucCtrl.text.trim();
                    final email = emailCtrl.text.trim().toLowerCase();

                    if (nombreCtrl.text.trim().isEmpty) {
                      errores.add('El nombre / razón social es obligatorio.');
                    }

                    // Acceso del cliente: correo + contraseña otorgada
                    if (email.isEmpty) {
                      errores.add(
                          'El correo es obligatorio: es con lo que el cliente entrará a su panel.');
                    } else if (!RegExp(r'^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$')
                        .hasMatch(email)) {
                      errores.add('El correo no tiene un formato válido (ejemplo: cliente@correo.com).');
                    }
                    if (claveCtrl.text.trim().isEmpty) {
                      errores.add(
                          'La contraseña es obligatoria: es la que le otorgas al cliente.');
                    } else if (claveCtrl.text.trim().length < 4) {
                      errores.add('La contraseña debe tener al menos 4 caracteres.');
                    }

                    // Teléfono peruano: obligatorio y exactamente 9 dígitos
                    final telefono = telefonoCtrl.text.trim();
                    if (telefono.isEmpty) {
                      errores.add('El teléfono es obligatorio (9 dígitos).');
                    } else if (telefono.length != 9) {
                      errores.add(
                          'El teléfono lleva 9 dígitos; faltan ${9 - telefono.length}.');
                    } else if (!telefono.startsWith('9')) {
                      errores.add('El teléfono debe empezar con 9 (celular peruano).');
                    }

                    if (tipoCliente == TipoCliente.persona) {
                      // Persona: DNI obligatorio de 8 dígitos
                      if (dni.isEmpty) {
                        errores.add('El DNI es obligatorio (8 dígitos).');
                      } else if (dni.length != 8) {
                        errores.add('El DNI lleva 8 dígitos; faltan ${8 - dni.length}.');
                      }
                      // RUC opcional, pero si se escribe debe ser válido
                      if (ruc.isNotEmpty && ruc.length != 11) {
                        errores.add('El RUC lleva 11 dígitos; faltan ${11 - ruc.length}.');
                      }
                    } else {
                      // Empresa: RUC obligatorio de 11 dígitos y sin DNI
                      if (ruc.isEmpty) {
                        errores.add('El RUC es obligatorio (11 dígitos).');
                      } else if (ruc.length != 11) {
                        errores.add('El RUC lleva 11 dígitos; faltan ${11 - ruc.length}.');
                      }
                    }

                    // SIN DUPLICADOS: DNI, RUC y correo son únicos entre
                    // clientes. Al editar se excluye al propio cliente
                    // (mismo id) para no marcarse como duplicado a sí mismo.
                    for (final c in clientes) {
                      if (esEdicion && c.id == cliente.id) continue;
                      if (dni.isNotEmpty && c.dni == dni) {
                        errores.add('Ya existe un cliente con el DNI $dni (${c.nombre}).');
                      }
                      if (ruc.isNotEmpty && c.ruc == ruc) {
                        errores.add('Ya existe un cliente con el RUC $ruc (${c.nombre}).');
                      }
                      if (email.isNotEmpty &&
                          c.email != null &&
                          c.email!.toLowerCase() == email) {
                        errores.add('Ya existe un cliente con el correo $email (${c.nombre}).');
                      }
                    }

                    if (errores.isNotEmpty) {
                      await showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: const Color(0xFF1A1A24),
                          title: const Text('Revisa estos datos'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: errores
                                .map((e) => Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Text('• $e'),
                                    ))
                                .toList(),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text(
                                'ENTENDIDO',
                                style: TextStyle(color: Color(0xFF33FF99)),
                              ),
                            ),
                          ],
                        ),
                      );
                      return;
                    }

                    final nuevoCliente = Cliente(
                      id: cliente?.id,
                      nombre: nombreCtrl.text.trim(),
                      telefono: telefono,
                      email: emailCtrl.text.isEmpty ? null : emailCtrl.text.trim(),
                      clave: claveCtrl.text.trim().isEmpty ? null : claveCtrl.text.trim(),
                      tipoCliente: tipoCliente,
                      // Las empresas no tienen DNI
                      dni: tipoCliente == TipoCliente.persona && dni.isNotEmpty ? dni : null,
                      ruc: ruc.isEmpty ? null : ruc,
                      direccion: direccionCtrl.text.isEmpty ? null : direccionCtrl.text,
                    );
                    try {
                      // Correo del administrador: si Supabase deja la
                      // sesion con otro correo es porque el usuario
                      // recien creado la reemplazo, y hay que cerrarla.
                      const correoAdmin = 'admin@emcodestudio.com';

                      /// Aviso verde cuando todo el guardado sale bien.
                      void avisarOk(String texto) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(texto),
                              backgroundColor: const Color(0xFF33FF99),
                              behavior: SnackBarBehavior.floating,
                              margin: const EdgeInsets.all(16),
                            ),
                          );
                        }
                      }

                      /// Aviso rojo cuando el cliente se guardo pero Hubo
                      /// problema creando su usuario de acceso.
                      void avisarAuth(String texto) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(texto),
                              backgroundColor: const Color(0xFFE74C3C),
                              behavior: SnackBarBehavior.floating,
                              margin: const EdgeInsets.all(16),
                            ),
                          );
                        }
                      }

                      /// Crea el usuario de Supabase Auth (correo + clave)
                      /// para que el cliente pueda entrar a su panel.
                      /// Si el usuario ya existia no es un problema (por
                      /// ejemplo los 43 migrados con el script SQL).
                      Future<void> crearUsuarioAuth(Cliente c) async {
                        if (c.email == null || c.clave == null) return;
                        try {
                          final auth = SupabaseConfig.client.auth;
                          await auth.signUp(
                            email: c.email!.trim().toLowerCase(),
                            password: c.clave!,
                          );
                          // Si hubo exito y Supabase cambio la sesion
                          // (la dejo con el cliente nuevo en vez del
                          // admin), se cierra para poder reingresar.
                          final correoSesion =
                              (auth.currentUser?.email ?? '').toLowerCase();
                          if (correoSesion.isNotEmpty &&
                              correoSesion != correoAdmin) {
                            await auth.signOut();
                            avisarOk(
                                'Cliente guardado: su usuario ya puede entrar con su correo y clave. Cierra sesión y vuelve a entrar como administradora.');
                          } else {
                            avisarOk(
                                'Cliente guardado: su usuario ya puede entrar con su correo y clave.');
                          }
                        } on AuthException catch (e) {
                          if (!e.message.toLowerCase()
                              .contains('already registered')) {
                            debugPrint(
                                'No se creó el usuario de auth: ${e.message}');
                            avisarAuth(
                                'El cliente se guardó, PERO su usuario de acceso no se creó: ${e.message}');
                          }
                        } catch (e) {
                          debugPrint('Error creando usuario de auth: $e');
                          avisarAuth(
                              'El cliente se guardó, PERO su usuario de acceso no se creó: $e');
                        }
                      }

                      if (esEdicion) {
                        await _dbHelper.actualizarCliente(nuevoCliente);
                        // Si al editar se completo el correo y la clave,
                        // TAMBIEN se crea su usuario de acceso. Antes solo
                        // se creaba al registrar un cliente nuevo, y por
                        // eso los clientes a los que se les agrego el
                        // correo editando no podian entrar.
                        await crearUsuarioAuth(nuevoCliente);
                      } else {
                        await _dbHelper.insertarCliente(nuevoCliente);

                        // Al crear el cliente también se crea su USUARIO
                        // de Supabase Auth (correo + clave que le diste),
                        // para que pueda entrar a su panel con esos datos.
                        await crearUsuarioAuth(nuevoCliente);
                      }
                      // Solo se cierra el formulario si se guardó bien
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      _cargarClientes();
                    } catch (e) {
                      // Muestra el motivo del rechazo (p. ej. teléfono
                      // de 8 dígitos) sin cerrar el formulario.
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('$e'.replaceFirst('Exception: ', '')),
                          backgroundColor: const Color(0xFFE74C3C),
                          behavior: SnackBarBehavior.floating,
                          margin: const EdgeInsets.all(16),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF33FF99),
                    foregroundColor: const Color(0xFF0D0D12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(esEdicion ? 'ACTUALIZAR' : 'GUARDAR'),
                ),
              ),
              const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _mostrarDetalleCliente(Cliente cliente) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.3,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF8888A0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Contenido scrollable
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: cliente.tipoCliente == TipoCliente.empresa
                              ? const Color(0xFFB388FF).withValues(alpha: 0.2)
                              : const Color(0xFF33FF99).withValues(alpha: 0.2),
                          child: Icon(
                            cliente.tipoCliente == TipoCliente.empresa ? Icons.business : Icons.person,
                            color: cliente.tipoCliente == TipoCliente.empresa
                                ? const Color(0xFFB388FF)
                                : const Color(0xFF33FF99),
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cliente.nombre,
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                cliente.tipoCliente == TipoCliente.empresa ? 'Empresa' : 'Persona',
                                style: const TextStyle(color: Color(0xFF8888A0)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (cliente.dni != null && cliente.dni!.isNotEmpty)
                      _buildInfoRow(Icons.badge, 'DNI', cliente.dni!),
                    if (cliente.ruc != null && cliente.ruc!.isNotEmpty)
                      _buildInfoRow(Icons.receipt, 'RUC', cliente.ruc!),
                    if (cliente.telefono.isNotEmpty)
                      _buildInfoRow(Icons.phone, 'Teléfono', cliente.telefono),
                    if (cliente.email != null && cliente.email!.isNotEmpty)
                      _buildInfoRow(Icons.email, 'Email', cliente.email!),
                    if (cliente.direccion != null && cliente.direccion!.isNotEmpty)
                      _buildInfoRow(Icons.location_on, 'Dirección', cliente.direccion!),
                    const SizedBox(height: 20),
                    // Historial de servicios del cliente
                    _buildHistorialServicios(cliente),
                  ],
                ),
              ),
            ),
            // Botones fijos abajo
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF1A1A24),
                border: Border(top: BorderSide(color: Color(0xFF8888A0), width: 0.5)),
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _mostrarFormularioCliente(cliente: cliente);
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('EDITAR CLIENTE'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF33FF99),
                        foregroundColor: const Color(0xFF0D0D12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Eliminar Cliente'),
                            content: Text('¿Seguro que deseas eliminar a ${cliente.nombre}?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Cancelar'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  Navigator.pop(ctx);
                                  Navigator.pop(context);
                                  await _dbHelper.eliminarCliente(cliente.id!);
                                  _cargarClientes();
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Cliente eliminado')),
                                    );
                                  }
                                },
                                child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.delete),
                      label: const Text('ELIMINAR CLIENTE'),
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
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icono, String etiqueta, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icono, color: const Color(0xFF33FF99), size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(etiqueta, style: const TextStyle(fontSize: 12, color: Color(0xFF8888A0))),
              Text(valor, style: const TextStyle(fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistorialServicios(Cliente cliente) {
    return FutureBuilder<List<Proyecto>>(
      future: _dbHelper.obtenerProyectos(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF33FF99)));
        }
        final servicios = snapshot.data!.where((p) {
          return p.cliente.nombre == cliente.nombre;
        }).toList();
        if (servicios.isEmpty) {
          return const Text(
            'No hay servicios registrados',
            style: TextStyle(color: Color(0xFF8888A0)),
          );
        }
        double total = servicios.fold(0.0, (sum, s) => sum + s.montoTotal);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SUS SERVICIOS',
              style: TextStyle(fontSize: 12, color: Color(0xFF8888A0), letterSpacing: 2),
            ),
            const SizedBox(height: 10),
            ...servicios.map((s) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16161D),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF8888A0).withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.tipoServicio, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            Text('${s.fechaEntrega.day}/${s.fechaEntrega.month}/${s.fechaEntrega.year}',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF8888A0))),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(formatearSoles(s.montoTotal, decimales: 0),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF33FF99))),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _colorEstado(s.estado).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              s.estado.name,
                              style: TextStyle(fontSize: 10, color: _colorEstado(s.estado)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )),
            const Divider(color: Color(0xFF8888A0)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total en servicios:', style: TextStyle(fontSize: 14)),
                Text(formatearSoles(total),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF33FF99))),
              ],
            ),
          ],
        );
      },
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
}
