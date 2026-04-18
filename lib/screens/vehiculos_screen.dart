import 'package:flutter/material.dart';
import '../api_service.dart';

class VehiculosScreen extends StatefulWidget {
  const VehiculosScreen({super.key});

  @override
  State<VehiculosScreen> createState() => _VehiculosScreenState();
}

class _VehiculosScreenState extends State<VehiculosScreen> {
  static const Color bgColor = Color(0xFF1A1A1A);
  static const Color cardColor = Color(0xFF2A2A2A);
  static const Color accentColor = Color(0xFFE67E22);

  List<dynamic> vehiculos = [];
  List<dynamic> clientes = [];
  bool cargando = true;
  String busqueda = '';

  final marcaController = TextEditingController();
  final modeloController = TextEditingController();
  final matriculaController = TextEditingController();
  final anioController = TextEditingController();
  String? clienteSeleccionado;

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  Future<void> cargarDatos() async {
    setState(() => cargando = true);
    try {
      final v = await ApiService.get('/vehiculos');
      final c = await ApiService.get('/clientes');
      setState(() {
        vehiculos = v is List ? v : [];
        clientes = c is List ? c : [];
        cargando = false;
      });
    } catch (e) {
      setState(() => cargando = false);
    }
  }

  Future<void> crearVehiculo() async {
    if (marcaController.text.isEmpty ||
        matriculaController.text.isEmpty ||
        clienteSeleccionado == null) return;
    try {
      await ApiService.post('/vehiculos', {
        'id_cliente': clienteSeleccionado,
        'marca': marcaController.text,
        'modelo': modeloController.text,
        'matricula': matriculaController.text,
        'anio': anioController.text,
      });
      marcaController.clear();
      modeloController.clear();
      matriculaController.clear();
      anioController.clear();
      clienteSeleccionado = null;
      await cargarDatos();
    } catch (e) {
      // error
    }
  }

  Future<void> eliminarVehiculo(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardColor,
        title: const Text('Eliminar vehículo',
            style: TextStyle(color: Colors.white)),
        content: const Text(
            '¿Estás seguro de que quieres eliminar este vehículo?',
            style: TextStyle(color: Colors.grey)),
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
      await ApiService.delete('/vehiculos/$id');
      await cargarDatos();
    }
  }

  String nombreCliente(dynamic idCliente) {
    final c = clientes.firstWhere(
      (c) => c['id_cliente'].toString() == idCliente.toString(),
      orElse: () => null,
    );
    return c != null ? c['nombre'] : 'Desconocido';
  }

  void mostrarFormulario() {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
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
              const Text('Nuevo vehículo',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              // Selector de cliente
              DropdownButtonFormField<String>(
                value: clienteSeleccionado,
                dropdownColor: const Color(0xFF333333),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Cliente *',
                  labelStyle: const TextStyle(color: Colors.grey),
                  prefixIcon:
                      const Icon(Icons.person_outline, color: Colors.grey),
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
                items: clientes.map<DropdownMenuItem<String>>((c) {
                  return DropdownMenuItem<String>(
                    value: c['id_cliente'].toString(),
                    child: Text(c['nombre'],
                        style: const TextStyle(color: Colors.white)),
                  );
                }).toList(),
                onChanged: (v) => setModalState(() => clienteSeleccionado = v),
              ),
              const SizedBox(height: 12),
              _buildInput(
                  marcaController, 'Marca *', Icons.directions_car_outlined),
              const SizedBox(height: 12),
              _buildInput(
                  modeloController, 'Modelo', Icons.car_repair_outlined),
              const SizedBox(height: 12),
              _buildInput(
                  matriculaController, 'Matrícula *', Icons.pin_outlined),
              const SizedBox(height: 12),
              _buildInput(anioController, 'Año', Icons.calendar_today_outlined,
                  tipo: TextInputType.number),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    crearVehiculo();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Crear vehículo',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
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

  List<dynamic> get vehiculosFiltrados {
    if (busqueda.isEmpty) return vehiculos;
    final texto = busqueda.toLowerCase();
    return vehiculos
        .where((v) =>
            v['marca']?.toString().toLowerCase().contains(texto) == true ||
            v['modelo']?.toString().toLowerCase().contains(texto) == true ||
            v['matricula']?.toString().toLowerCase().contains(texto) == true)
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
                const Text('Vehículos',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TextField(
                  style: const TextStyle(color: Colors.white),
                  onChanged: (v) => setState(() => busqueda = v),
                  decoration: InputDecoration(
                    hintText: 'Buscar por marca, modelo o matrícula...',
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
                : vehiculosFiltrados.isEmpty
                    ? const Center(
                        child: Text('No hay vehículos',
                            style: TextStyle(color: Colors.grey)))
                    : RefreshIndicator(
                        onRefresh: cargarDatos,
                        color: accentColor,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: vehiculosFiltrados.length,
                          itemBuilder: (context, index) {
                            final v = vehiculosFiltrados[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                leading: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: accentColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.directions_car,
                                      color: accentColor, size: 22),
                                ),
                                title: Text(
                                  '${v['marca']} ${v['modelo']}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(v['matricula'] ?? '',
                                        style: const TextStyle(
                                            color: accentColor,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold)),
                                    Text(
                                      '${nombreCliente(v['id_cliente'])}${v['anio'] != null && v['anio'].toString().isNotEmpty ? ' · ${v['anio']}' : ''}',
                                      style: const TextStyle(
                                          color: Colors.grey, fontSize: 12),
                                    ),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.red),
                                  onPressed: () => eliminarVehiculo(
                                      int.parse(v['id_vehiculo'].toString())),
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
