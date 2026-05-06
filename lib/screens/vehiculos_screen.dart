import 'package:flutter/material.dart';
import '../api_service.dart';
import '../theme/app_theme.dart';
import 'historial_vehiculo_screen.dart';

class VehiculosScreen extends StatefulWidget {
  const VehiculosScreen({super.key});

  @override
  State<VehiculosScreen> createState() => _VehiculosScreenState();
}

class _VehiculosScreenState extends State<VehiculosScreen> {
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

  void _limpiar() {
    marcaController.clear();
    modeloController.clear();
    matriculaController.clear();
    anioController.clear();
    clienteSeleccionado = null;
  }

  void _mostrarFormulario({dynamic vehiculo}) {
    if (vehiculo != null) {
      marcaController.text = vehiculo['marca'] ?? '';
      modeloController.text = vehiculo['modelo'] ?? '';
      matriculaController.text = vehiculo['matricula'] ?? '';
      anioController.text = vehiculo['anio']?.toString() ?? '';
      clienteSeleccionado = vehiculo['id_cliente']?.toString();
    } else {
      _limpiar();
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(vehiculo != null ? 'Editar vehículo' : 'Nuevo vehículo',
                  style: AppTheme.subtitulo),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: clienteSeleccionado,
                dropdownColor: AppTheme.inputColor,
                style: AppTheme.cuerpo,
                decoration: AppTheme.input('Cliente *', Icons.person_outline),
                items: clientes
                    .map<DropdownMenuItem<String>>((c) => DropdownMenuItem(
                          value: c['id_cliente'].toString(),
                          child: Text(c['nombre'], style: AppTheme.cuerpo),
                        ))
                    .toList(),
                onChanged: (v) => setModalState(() => clienteSeleccionado = v),
              ),
              const SizedBox(height: 12),
              TextField(
                  controller: marcaController,
                  style: AppTheme.cuerpo,
                  decoration:
                      AppTheme.input('Marca *', Icons.directions_car_outlined)),
              const SizedBox(height: 12),
              TextField(
                  controller: modeloController,
                  style: AppTheme.cuerpo,
                  decoration:
                      AppTheme.input('Modelo', Icons.car_repair_outlined)),
              const SizedBox(height: 12),
              TextField(
                  controller: matriculaController,
                  style: AppTheme.cuerpo,
                  decoration:
                      AppTheme.input('Matrícula *', Icons.pin_outlined)),
              const SizedBox(height: 12),
              TextField(
                  controller: anioController,
                  style: AppTheme.cuerpo,
                  keyboardType: TextInputType.number,
                  decoration:
                      AppTheme.input('Año', Icons.calendar_today_outlined)),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final data = {
                      'id_cliente': clienteSeleccionado,
                      'marca': marcaController.text,
                      'modelo': modeloController.text,
                      'matricula': matriculaController.text,
                      'anio': anioController.text,
                    };
                    if (vehiculo != null) {
                      await ApiService.put(
                          '/vehiculos/${vehiculo['id_vehiculo']}', data);
                    } else {
                      await ApiService.post('/vehiculos', data);
                    }
                    _limpiar();
                    await cargarDatos();
                  },
                  style: AppTheme.botonPrincipal(),
                  child: Text(
                      vehiculo != null ? 'Guardar cambios' : 'Crear vehículo',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> eliminarVehiculo(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: Text('Eliminar vehículo', style: AppTheme.subtitulo),
        content: Text('¿Estás seguro?', style: AppTheme.muted),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancelar', style: AppTheme.muted)),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Eliminar',
                  style: TextStyle(color: AppTheme.dangerColor))),
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
        orElse: () => null);
    return c != null ? c['nombre'] : 'Desconocido';
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
                Text('Vehículos', style: AppTheme.titulo),
                const SizedBox(height: 12),
                TextField(
                  style: AppTheme.cuerpo,
                  onChanged: (v) => setState(() => busqueda = v),
                  decoration: InputDecoration(
                    hintText: 'Buscar por marca, modelo o matrícula...',
                    hintStyle: AppTheme.muted,
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: AppTheme.cardColor,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: cargando
                ? const Center(
                    child:
                        CircularProgressIndicator(color: AppTheme.accentColor))
                : vehiculosFiltrados.isEmpty
                    ? Center(
                        child: Text('No hay vehículos', style: AppTheme.muted))
                    : RefreshIndicator(
                        onRefresh: cargarDatos,
                        color: AppTheme.accentColor,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: vehiculosFiltrados.length,
                          itemBuilder: (context, index) {
                            final v = vehiculosFiltrados[index];
                            return GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => HistorialVehiculoScreen(
                                      vehiculo: Map<String, dynamic>.from(v)),
                                ),
                              ),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: AppTheme.card(),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  leading: Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: AppTheme.accentColor
                                          .withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.directions_car,
                                        color: AppTheme.accentColor, size: 22),
                                  ),
                                  title: Text('${v['marca']} ${v['modelo']}',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500)),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(v['matricula'] ?? '',
                                          style: const TextStyle(
                                              color: AppTheme.accentColor,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold)),
                                      Text(
                                        '${nombreCliente(v['id_cliente'])}${v['anio'] != null && v['anio'].toString().isNotEmpty ? ' · ${v['anio']}' : ''}',
                                        style: AppTheme.small,
                                      ),
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
                                            _mostrarFormulario(vehiculo: v),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete_outline,
                                            color: AppTheme.dangerColor,
                                            size: 20),
                                        onPressed: () => eliminarVehiculo(
                                            int.parse(
                                                v['id_vehiculo'].toString())),
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
