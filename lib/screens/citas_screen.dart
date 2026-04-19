import 'package:flutter/material.dart';
import '../api_service.dart';

class CitasScreen extends StatefulWidget {
  const CitasScreen({super.key});

  @override
  State<CitasScreen> createState() => _CitasScreenState();
}

class _CitasScreenState extends State<CitasScreen> {
  static const Color bgColor = Color(0xFF1A1A1A);
  static const Color cardColor = Color(0xFF2A2A2A);
  static const Color accentColor = Color(0xFFE67E22);

  List<dynamic> citas = [];
  List<dynamic> vehiculos = [];
  bool cargando = true;
  String busqueda = '';

  final descripcionController = TextEditingController();
  final manoObraController = TextEditingController();
  final piezasController = TextEditingController();
  final otrosController = TextEditingController();

  String? vehiculoSeleccionado;
  String? clienteSeleccionado;
  DateTime? fechaSeleccionada;
  TimeOfDay? horaSeleccionada;

  final Map<String, Color> estadoColores = {
    'pendiente': const Color(0xFFF39C12),
    'en_proceso': const Color(0xFF2980B9),
    'finalizada': const Color(0xFF27AE60),
  };

  final Map<String, String> estadoTextos = {
    'pendiente': 'Pendiente',
    'en_proceso': 'En proceso',
    'finalizada': 'Finalizada',
  };

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  Future<void> cargarDatos() async {
    setState(() => cargando = true);
    try {
      final c = await ApiService.get('/citas');
      final v = await ApiService.get('/vehiculos');
      setState(() {
        citas = c is List ? c : [];
        vehiculos = v is List ? v : [];
        cargando = false;
      });
    } catch (e) {
      setState(() => cargando = false);
    }
  }

  double get totalConIVA {
    final mo = double.tryParse(manoObraController.text) ?? 0;
    final pi = double.tryParse(piezasController.text) ?? 0;
    final ot = double.tryParse(otrosController.text) ?? 0;
    return (mo + pi + ot) * 1.21;
  }

  Future<void> crearCita() async {
    if (vehiculoSeleccionado == null ||
        fechaSeleccionada == null ||
        horaSeleccionada == null) return;

    final fecha =
        '${fechaSeleccionada!.year}-${fechaSeleccionada!.month.toString().padLeft(2, '0')}-${fechaSeleccionada!.day.toString().padLeft(2, '0')}';
    final hora =
        '${horaSeleccionada!.hour.toString().padLeft(2, '0')}:${horaSeleccionada!.minute.toString().padLeft(2, '0')}:00';

    try {
      await ApiService.post('/citas', {
        'id_vehiculo': vehiculoSeleccionado,
        'id_cliente': clienteSeleccionado,
        'fecha': fecha,
        'hora': hora,
        'estado': 'pendiente',
        'descripcion': descripcionController.text,
        'mano_obra': double.tryParse(manoObraController.text) ?? 0,
        'piezas': double.tryParse(piezasController.text) ?? 0,
        'otros': double.tryParse(otrosController.text) ?? 0,
      });
      descripcionController.clear();
      manoObraController.clear();
      piezasController.clear();
      otrosController.clear();
      vehiculoSeleccionado = null;
      clienteSeleccionado = null;
      fechaSeleccionada = null;
      horaSeleccionada = null;
      await cargarDatos();
    } catch (e) {
      // error
    }
  }

  Future<void> eliminarCita(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardColor,
        title:
            const Text('Eliminar cita', style: TextStyle(color: Colors.white)),
        content: const Text('¿Estás seguro de que quieres eliminar esta cita?',
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
      await ApiService.delete('/citas/$id');
      await cargarDatos();
    }
  }

  Future<void> actualizarEstado(int id, String nuevoEstado) async {
    await ApiService.post('/citas/update/$id', {'estado': nuevoEstado});
    await cargarDatos();
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
        builder: (ctx, setModalState) => SingleChildScrollView(
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
              const Text('Nueva cita',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              // Selector de vehículo
              DropdownButtonFormField<String>(
                value: vehiculoSeleccionado,
                dropdownColor: const Color(0xFF333333),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Vehículo *',
                  labelStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(Icons.directions_car_outlined,
                      color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF333333),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.transparent)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: accentColor)),
                ),
                items: vehiculos.map<DropdownMenuItem<String>>((v) {
                  return DropdownMenuItem<String>(
                    value: v['id_vehiculo'].toString(),
                    child: Text(
                        '${v['marca']} ${v['modelo']} - ${v['matricula']}',
                        style: const TextStyle(color: Colors.white)),
                  );
                }).toList(),
                onChanged: (v) {
                  setModalState(() {
                    vehiculoSeleccionado = v;
                    final veh = vehiculos.firstWhere(
                        (veh) => veh['id_vehiculo'].toString() == v,
                        orElse: () => null);
                    if (veh != null)
                      clienteSeleccionado = veh['id_cliente'].toString();
                  });
                },
              ),
              const SizedBox(height: 12),

              // Fecha
              GestureDetector(
                onTap: () async {
                  final fecha = await showDatePicker(
                    context: ctx,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    builder: (ctx, child) => Theme(
                      data: ThemeData.dark().copyWith(
                          colorScheme:
                              const ColorScheme.dark(primary: accentColor)),
                      child: child!,
                    ),
                  );
                  if (fecha != null)
                    setModalState(() => fechaSeleccionada = fecha);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF333333),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          color: Colors.grey, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        fechaSeleccionada != null
                            ? '${fechaSeleccionada!.day}/${fechaSeleccionada!.month}/${fechaSeleccionada!.year}'
                            : 'Seleccionar fecha *',
                        style: TextStyle(
                            color: fechaSeleccionada != null
                                ? Colors.white
                                : Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Hora
              GestureDetector(
                onTap: () async {
                  final hora = await showTimePicker(
                    context: ctx,
                    initialTime: TimeOfDay.now(),
                    builder: (ctx, child) => Theme(
                      data: ThemeData.dark().copyWith(
                          colorScheme:
                              const ColorScheme.dark(primary: accentColor)),
                      child: child!,
                    ),
                  );
                  if (hora != null)
                    setModalState(() => horaSeleccionada = hora);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF333333),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time_outlined,
                          color: Colors.grey, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        horaSeleccionada != null
                            ? '${horaSeleccionada!.hour.toString().padLeft(2, '0')}:${horaSeleccionada!.minute.toString().padLeft(2, '0')}'
                            : 'Seleccionar hora *',
                        style: TextStyle(
                            color: horaSeleccionada != null
                                ? Colors.white
                                : Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              _buildInput(descripcionController, 'Descripción',
                  Icons.description_outlined),
              const SizedBox(height: 12),

              // Desglose de costes
              const Text('Desglose de costes',
                  style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 8),
              _buildInput(
                  manoObraController, 'Mano de obra (€)', Icons.build_outlined,
                  tipo: TextInputType.number,
                  onChanged: () => setModalState(() {})),
              const SizedBox(height: 8),
              _buildInput(piezasController, 'Piezas / Recambios (€)',
                  Icons.inventory_2_outlined,
                  tipo: TextInputType.number,
                  onChanged: () => setModalState(() {})),
              const SizedBox(height: 8),
              _buildInput(otrosController, 'Otros conceptos (€)',
                  Icons.add_circle_outline,
                  tipo: TextInputType.number,
                  onChanged: () => setModalState(() {})),
              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF27AE60).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: const Color(0xFF27AE60).withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total con IVA (21%):',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    Text('${totalConIVA.toStringAsFixed(2)} €',
                        style: const TextStyle(
                            color: Color(0xFF27AE60),
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    crearCita();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Crear cita',
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
      {TextInputType tipo = TextInputType.text, VoidCallback? onChanged}) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      keyboardType: tipo,
      onChanged: onChanged != null ? (_) => onChanged() : null,
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

  List<dynamic> get citasFiltradas {
    if (busqueda.isEmpty) return citas;
    final texto = busqueda.toLowerCase();
    return citas
        .where((c) =>
            c['nombre']?.toString().toLowerCase().contains(texto) == true ||
            c['marca']?.toString().toLowerCase().contains(texto) == true ||
            c['modelo']?.toString().toLowerCase().contains(texto) == true ||
            c['matricula']?.toString().toLowerCase().contains(texto) == true ||
            c['estado']?.toString().toLowerCase().contains(texto) == true ||
            c['fecha']?.toString().contains(texto) == true)
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
                const Text('Citas',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TextField(
                  style: const TextStyle(color: Colors.white),
                  onChanged: (v) => setState(() => busqueda = v),
                  decoration: InputDecoration(
                    hintText: 'Buscar por cliente, vehículo, estado...',
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
                : citasFiltradas.isEmpty
                    ? const Center(
                        child: Text('No hay citas',
                            style: TextStyle(color: Colors.grey)))
                    : RefreshIndicator(
                        onRefresh: cargarDatos,
                        color: accentColor,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: citasFiltradas.length,
                          itemBuilder: (context, index) {
                            final c = citasFiltradas[index];
                            final estadoColor =
                                estadoColores[c['estado']] ?? Colors.grey;
                            final estadoTexto =
                                estadoTextos[c['estado']] ?? c['estado'];

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: estadoColor.withOpacity(0.2)),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '${c['marca']} ${c['modelo']} - ${c['matricula']}',
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color:
                                                estadoColor.withOpacity(0.15),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(estadoTexto,
                                              style: TextStyle(
                                                  color: estadoColor,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(c['nombre'] ?? '',
                                        style: const TextStyle(
                                            color: Colors.grey, fontSize: 13)),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(
                                            Icons.calendar_today_outlined,
                                            color: Colors.grey,
                                            size: 13),
                                        const SizedBox(width: 4),
                                        Text(c['fecha'] ?? '',
                                            style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 12)),
                                        const SizedBox(width: 12),
                                        const Icon(Icons.access_time_outlined,
                                            color: Colors.grey, size: 13),
                                        const SizedBox(width: 4),
                                        Text(
                                            c['hora']
                                                    ?.toString()
                                                    .substring(0, 5) ??
                                                '',
                                            style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 12)),
                                      ],
                                    ),
                                    if (c['descripcion'] != null &&
                                        c['descripcion']
                                            .toString()
                                            .isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(c['descripcion'],
                                          style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12)),
                                    ],
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Text(
                                          '${double.tryParse(c['coste'].toString())?.toStringAsFixed(2)} €',
                                          style: const TextStyle(
                                              color: Color(0xFF27AE60),
                                              fontWeight: FontWeight.bold),
                                        ),
                                        const Spacer(),
                                        // Cambiar estado
                                        PopupMenuButton<String>(
                                          color: const Color(0xFF333333),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color:
                                                  estadoColor.withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              border: Border.all(
                                                  color: estadoColor
                                                      .withOpacity(0.3)),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text('Estado',
                                                    style: TextStyle(
                                                        color: estadoColor,
                                                        fontSize: 12)),
                                                const SizedBox(width: 4),
                                                Icon(Icons.arrow_drop_down,
                                                    color: estadoColor,
                                                    size: 16),
                                              ],
                                            ),
                                          ),
                                          itemBuilder: (ctx) => [
                                            const PopupMenuItem(
                                                value: 'pendiente',
                                                child: Text('Pendiente',
                                                    style: TextStyle(
                                                        color: Color(
                                                            0xFFF39C12)))),
                                            const PopupMenuItem(
                                                value: 'en_proceso',
                                                child: Text('En proceso',
                                                    style: TextStyle(
                                                        color: Color(
                                                            0xFF2980B9)))),
                                            const PopupMenuItem(
                                                value: 'finalizada',
                                                child: Text('Finalizada',
                                                    style: TextStyle(
                                                        color: Color(
                                                            0xFF27AE60)))),
                                          ],
                                          onSelected: (nuevoEstado) =>
                                              actualizarEstado(
                                                  int.parse(
                                                      c['id_cita'].toString()),
                                                  nuevoEstado),
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline,
                                              color: Colors.red, size: 20),
                                          onPressed: () => eliminarCita(
                                              int.parse(
                                                  c['id_cita'].toString())),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      ],
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
