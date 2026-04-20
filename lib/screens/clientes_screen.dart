import 'package:flutter/material.dart';
import '../api_service.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  static const Color bgColor = Color(0xFF1A1A1A);
  static const Color cardColor = Color(0xFF2A2A2A);
  static const Color accentColor = Color(0xFFE67E22);

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

  Future<void> crearCliente() async {
    if (nombreController.text.isEmpty) return;
    try {
      await ApiService.post('/clientes', {
        'nombre': nombreController.text,
        'telefono': telefonoController.text,
        'email': emailController.text,
        'direccion': direccionController.text,
      });
      nombreController.clear();
      telefonoController.clear();
      emailController.clear();
      direccionController.clear();
      await cargarClientes();
    } catch (e) {}
  }

  void mostrarFormularioEdicion(dynamic cliente) {
    nombreController.text = cliente['nombre'] ?? '';
    telefonoController.text = cliente['telefono'] ?? '';
    emailController.text = cliente['email'] ?? '';
    direccionController.text = cliente['direccion'] ?? '';

    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Editar cliente',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildInput(nombreController, 'Nombre *', Icons.person_outline),
            const SizedBox(height: 12),
            _buildInput(telefonoController, 'Teléfono', Icons.phone_outlined),
            const SizedBox(height: 12),
            _buildInput(emailController, 'Email', Icons.email_outlined,
                tipo: TextInputType.emailAddress),
            const SizedBox(height: 12),
            _buildInput(
                direccionController, 'Dirección', Icons.location_on_outlined),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await ApiService.put('/clientes/${cliente['id_cliente']}', {
                    'nombre': nombreController.text,
                    'telefono': telefonoController.text,
                    'email': emailController.text,
                    'direccion': direccionController.text,
                  });
                  nombreController.clear();
                  telefonoController.clear();
                  emailController.clear();
                  direccionController.clear();
                  await cargarClientes();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Guardar cambios',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> eliminarCliente(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardColor,
        title: const Text('Eliminar cliente',
            style: TextStyle(color: Colors.white)),
        content:
            const Text('¿Estás seguro?', style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child:
                  const Text('Cancelar', style: TextStyle(color: Colors.grey))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child:
                  const Text('Eliminar', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      await ApiService.delete('/clientes/$id');
      await cargarClientes();
    }
  }

  void mostrarFormulario() {
    nombreController.clear();
    telefonoController.clear();
    emailController.clear();
    direccionController.clear();

    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Nuevo cliente',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildInput(nombreController, 'Nombre *', Icons.person_outline),
            const SizedBox(height: 12),
            _buildInput(telefonoController, 'Teléfono', Icons.phone_outlined),
            const SizedBox(height: 12),
            _buildInput(emailController, 'Email', Icons.email_outlined,
                tipo: TextInputType.emailAddress),
            const SizedBox(height: 12),
            _buildInput(
                direccionController, 'Dirección', Icons.location_on_outlined),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  crearCliente();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Crear cliente',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(
      TextEditingController controller, String label, IconData icon,
      {TextInputType tipo = TextInputType.text}) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      keyboardType: tipo,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: Colors.grey),
        filled: true,
        fillColor: const Color(0xFF333333),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.transparent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: accentColor),
        ),
      ),
    );
  }

  List<dynamic> get clientesFiltrados {
    if (busqueda.isEmpty) return clientes;
    final texto = busqueda.toLowerCase();
    return clientes
        .where((c) =>
            c['nombre']?.toString().toLowerCase().contains(texto) == true ||
            c['email']?.toString().toLowerCase().contains(texto) == true ||
            c['telefono']?.toString().contains(texto) == true)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      floatingActionButton: FloatingActionButton(
        onPressed: mostrarFormulario,
        backgroundColor: accentColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Clientes',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TextField(
                  style: const TextStyle(color: Colors.white),
                  onChanged: (v) => setState(() => busqueda = v),
                  decoration: InputDecoration(
                    hintText: 'Buscar cliente...',
                    hintStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: cargando
                ? const Center(
                    child: CircularProgressIndicator(color: accentColor))
                : clientesFiltrados.isEmpty
                    ? const Center(
                        child: Text('No hay clientes',
                            style: TextStyle(color: Colors.grey)))
                    : RefreshIndicator(
                        onRefresh: cargarClientes,
                        color: accentColor,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: clientesFiltrados.length,
                          itemBuilder: (context, index) {
                            final c = clientesFiltrados[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                leading: CircleAvatar(
                                  backgroundColor: accentColor.withOpacity(0.2),
                                  child: Text(
                                    c['nombre']
                                            ?.toString()
                                            .substring(0, 1)
                                            .toUpperCase() ??
                                        '?',
                                    style: const TextStyle(
                                        color: accentColor,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                title: Text(c['nombre'] ?? '',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (c['telefono'] != null &&
                                        c['telefono'].toString().isNotEmpty)
                                      Text(c['telefono'],
                                          style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12)),
                                    if (c['email'] != null &&
                                        c['email'].toString().isNotEmpty)
                                      Text(c['email'],
                                          style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12)),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined,
                                          color: accentColor, size: 20),
                                      onPressed: () =>
                                          mostrarFormularioEdicion(c),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                          color: Colors.red, size: 20),
                                      onPressed: () => eliminarCliente(
                                          int.parse(
                                              c['id_cliente'].toString())),
                                    ),
                                  ],
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
