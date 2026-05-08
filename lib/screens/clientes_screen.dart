import 'package:flutter/material.dart';
import '../api_service.dart';
import '../theme/app_theme.dart';
import 'historial_cliente_screen.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  List<dynamic> clientes = [];
  bool cargando = true;
  String busqueda = '';

  final nombreController = TextEditingController();
  final telefonoController = TextEditingController();
  final emailController = TextEditingController();
  final direccionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    cargarClientes();
  }

  Future<void> cargarClientes() async {
    setState(() => cargando = true);
    try {
      final res = await ApiService.get('/clientes');
      setState(() {
        clientes = res is List ? res : [];
        cargando = false;
      });
    } catch (e) {
      setState(() => cargando = false);
    }
  }

  void _limpiar() {
    nombreController.clear();
    telefonoController.clear();
    emailController.clear();
    direccionController.clear();
  }

  void _mostrarFormulario({dynamic cliente}) {
    if (cliente != null) {
      nombreController.text = cliente['nombre'] ?? '';
      telefonoController.text = cliente['telefono'] ?? '';
      emailController.text = cliente['email'] ?? '';
      direccionController.text = cliente['direccion'] ?? '';
    } else {
      _limpiar();
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(cliente != null ? 'Editar cliente' : 'Nuevo cliente',
                style: AppTheme.subtitulo),
            const SizedBox(height: 16),
            TextField(
                controller: nombreController,
                style: AppTheme.cuerpo,
                decoration: AppTheme.input('Nombre *', Icons.person_outline)),
            const SizedBox(height: 12),
            TextField(
                controller: telefonoController,
                style: AppTheme.cuerpo,
                decoration: AppTheme.input('Teléfono', Icons.phone_outlined)),
            const SizedBox(height: 12),
            TextField(
                controller: emailController,
                style: AppTheme.cuerpo,
                keyboardType: TextInputType.emailAddress,
                decoration: AppTheme.input('Email', Icons.email_outlined)),
            const SizedBox(height: 12),
            TextField(
                controller: direccionController,
                style: AppTheme.cuerpo,
                decoration:
                    AppTheme.input('Dirección', Icons.location_on_outlined)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  final data = {
                    'nombre': nombreController.text,
                    'telefono': telefonoController.text,
                    'email': emailController.text,
                    'direccion': direccionController.text,
                  };
                  if (cliente != null) {
                    await ApiService.put(
                        '/clientes/${cliente['id_cliente']}', data);
                  } else {
                    await ApiService.post('/clientes', data);
                  }
                  _limpiar();
                  await cargarClientes();
                },
                style: AppTheme.botonPrincipal(),
                child: Text(
                  cliente != null ? 'Guardar cambios' : 'Crear cliente',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> eliminarCliente(int id) async {
    final ok = await AppTheme.confirmarEliminar(context, 'cliente');
    if (ok) {
      await ApiService.delete('/clientes/$id');
      await cargarClientes();
    }
  }

  List<dynamic> get clientesFiltrados {
    if (busqueda.isEmpty) return clientes;
    final t = busqueda.toLowerCase();
    return clientes
        .where((c) =>
            c['nombre']?.toString().toLowerCase().contains(t) == true ||
            c['email']?.toString().toLowerCase().contains(t) == true ||
            c['telefono']?.toString().contains(t) == true)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarFormulario(),
        backgroundColor: AppTheme.accentColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Clientes', style: AppTheme.titulo),
                const SizedBox(height: 12),
                TextField(
                  style: AppTheme.cuerpo,
                  onChanged: (v) => setState(() => busqueda = v),
                  decoration: AppTheme.searchInput('Buscar cliente...'),
                ),
              ],
            ),
          ),
          Expanded(
            child: cargando
                ? const Center(
                    child:
                        CircularProgressIndicator(color: AppTheme.accentColor))
                : clientesFiltrados.isEmpty
                    ? Center(
                        child: Text('No hay clientes', style: AppTheme.muted))
                    : RefreshIndicator(
                        onRefresh: cargarClientes,
                        color: AppTheme.accentColor,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: clientesFiltrados.length,
                          itemBuilder: (context, index) {
                            final c = clientesFiltrados[index];
                            return GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => HistorialClienteScreen(
                                    cliente: Map<String, dynamic>.from(c),
                                  ),
                                ),
                              ),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: AppTheme.card(),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  leading: AppTheme.avatar(
                                      c['nombre']?.toString() ?? '?'),
                                  title: Text(c['nombre'] ?? '',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500)),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (c['telefono'] != null &&
                                          c['telefono'].toString().isNotEmpty)
                                        Text(c['telefono'],
                                            style: AppTheme.small),
                                      if (c['email'] != null &&
                                          c['email'].toString().isNotEmpty)
                                        Text(c['email'], style: AppTheme.small),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.history,
                                          color: Colors.grey, size: 18),
                                      const SizedBox(width: 4),
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined,
                                            color: AppTheme.accentColor,
                                            size: 20),
                                        onPressed: () =>
                                            _mostrarFormulario(cliente: c),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete_outline,
                                            color: AppTheme.dangerColor,
                                            size: 20),
                                        onPressed: () => eliminarCliente(
                                            int.parse(
                                                c['id_cliente'].toString())),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
