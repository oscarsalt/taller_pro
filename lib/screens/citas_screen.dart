import 'package:flutter/material.dart';
import '../api_service.dart';
import '../theme/app_theme.dart';

class CitasScreen extends StatefulWidget {
  const CitasScreen({super.key});

  @override
  State<CitasScreen> createState() => _CitasScreenState();
}

class _CitasScreenState extends State<CitasScreen> {
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
    'pendiente': AppTheme.warningColor,
    'en_proceso': AppTheme.infoColor,
    'finalizada': AppTheme.successColor,
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

  void _limpiar() {
    descripcionController.clear();
    manoObraController.clear();
    piezasController.clear();
    otrosController.clear();
    vehiculoSeleccionado = null;
    clienteSeleccionado = null;
    fechaSeleccionada = null;
    horaSeleccionada = null;
  }

  double _totalIVA() {
    final mo = double.tryParse(manoObraController.text) ?? 0;
    final pi = double.tryParse(piezasController.text) ?? 0;
    final ot = double.tryParse(otrosController.text) ?? 0;
    return (mo + pi + ot) * 1.21;
  }

  void _mostrarFormulario({dynamic cita}) {
    if (cita != null) {
      descripcionController.text = cita['descripcion'] ?? '';
      manoObraController.text = cita['mano_obra']?.toString() ?? '0';
      piezasController.text = cita['piezas']?.toString() ?? '0';
      otrosController.text = cita['otros']?.toString() ?? '0';
      final partesFecha = cita['fecha']?.split('-');
      if (partesFecha != null && partesFecha.length == 3) {
        fechaSeleccionada = DateTime(int.parse(partesFecha[0]),
            int.parse(partesFecha[1]), int.parse(partesFecha[2]));
      }
      final partesHora = cita['hora']?.split(':');
      if (partesHora != null && partesHora.length >= 2) {
        horaSeleccionada = TimeOfDay(
            hour: int.parse(partesHora[0]), minute: int.parse(partesHora[1]));
      }
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
        builder: (ctx, setModalState) => SingleChildScrollView(
          padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(cita != null ? 'Editar cita' : 'Nueva cita',
                  style: AppTheme.subtitulo),
              const SizedBox(height: 16),

              if (cita == null) ...[
                DropdownButtonFormField<String>(
                  value: vehiculoSeleccionado,
                  dropdownColor: AppTheme.inputColor,
                  style: AppTheme.cuerpo,
                  decoration: AppTheme.input(
                      'Vehículo *', Icons.directions_car_outlined),
                  items: vehiculos
                      .map<DropdownMenuItem<String>>((v) => DropdownMenuItem(
                            value: v['id_vehiculo'].toString(),
                            child: Text(
                                '${v['marca']} ${v['modelo']} - ${v['matricula']}',
                                style: AppTheme.cuerpo),
                          ))
                      .toList(),
                  onChanged: (v) {
                    setModalState(() {
                      vehiculoSeleccionado = v;
                      final veh = vehiculos.firstWhere(
                          (veh) => veh['id_vehiculo'].toString() == v,
                          orElse: () => null);
                      if (veh != null) {
                        clienteSeleccionado = veh['id_cliente'].toString();
                      }
                    });
                  },
                ),
                const SizedBox(height: 12),
              ],

              // Selector fecha
              GestureDetector(
                onTap: () async {
                  final fecha = await showDatePicker(
                    context: ctx,
                    initialDate: fechaSeleccionada ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    builder: (ctx, child) => Theme(
                      data: ThemeData.dark().copyWith(
                          colorScheme: const ColorScheme.dark(
                              primary: AppTheme.accentColor)),
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
                      color: AppTheme.inputColor,
                      borderRadius: BorderRadius.circular(10)),
                  child: Row(children: [
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
                  ]),
                ),
              ),
              const SizedBox(height: 12),

              // Selector hora
              GestureDetector(
                onTap: () async {
                  final hora = await showTimePicker(
                    context: ctx,
                    initialTime: horaSeleccionada ?? TimeOfDay.now(),
                    builder: (ctx, child) => Theme(
                      data: ThemeData.dark().copyWith(
                          colorScheme: const ColorScheme.dark(
                              primary: AppTheme.accentColor)),
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
                      color: AppTheme.inputColor,
                      borderRadius: BorderRadius.circular(10)),
                  child: Row(children: [
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
                  ]),
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                  controller: descripcionController,
                  style: AppTheme.cuerpo,
                  decoration: AppTheme.input(
                      'Descripción', Icons.description_outlined)),
              const SizedBox(height: 12),
              Text('Desglose de costes', style: AppTheme.muted),
              const SizedBox(height: 8),
              TextField(
                  controller: manoObraController,
                  style: AppTheme.cuerpo,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setModalState(() {}),
                  decoration:
                      AppTheme.input('Mano de obra (€)', Icons.build_outlined)),
              const SizedBox(height: 8),
              TextField(
                  controller: piezasController,
                  style: AppTheme.cuerpo,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setModalState(() {}),
                  decoration: AppTheme.input(
                      'Piezas / Recambios (€)', Icons.inventory_2_outlined)),
              const SizedBox(height: 8),
              TextField(
                  controller: otrosController,
                  style: AppTheme.cuerpo,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setModalState(() {}),
                  decoration: AppTheme.input(
                      'Otros conceptos (€)', Icons.add_circle_outline)),
              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: AppTheme.successColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total con IVA (21%):',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    Text('${_totalIVA().toStringAsFixed(2)} €',
                        style: TextStyle(
                            color: AppTheme.successColor,
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
                  onPressed: () async {
                    if (fechaSeleccionada == null || horaSeleccionada == null)
                      return;
                    Navigator.pop(ctx);
                    final fecha =
                        '${fechaSeleccionada!.year}-${fechaSeleccionada!.month.toString().padLeft(2, '0')}-${fechaSeleccionada!.day.toString().padLeft(2, '0')}';
                    final hora =
                        '${horaSeleccionada!.hour.toString().padLeft(2, '0')}:${horaSeleccionada!.minute.toString().padLeft(2, '0')}:00';
                    final data = {
                      'fecha': fecha,
                      'hora': hora,
                      'descripcion': descripcionController.text,
                      'mano_obra':
                          double.tryParse(manoObraController.text) ?? 0,
                      'piezas': double.tryParse(piezasController.text) ?? 0,
                      'otros': double.tryParse(otrosController.text) ?? 0,
                    };
                    if (cita != null) {
                      await ApiService.put('/citas/${cita['id_cita']}', data);
                    } else {
                      await ApiService.post('/citas', {
                        ...data,
                        'id_vehiculo': vehiculoSeleccionado,
                        'id_cliente': clienteSeleccionado,
                        'estado': 'pendiente'
                      });
                    }
                    _limpiar();
                    await cargarDatos();
                  },
                  style: AppTheme.botonPrincipal(),
                  child: Text(cita != null ? 'Guardar cambios' : 'Crear cita',
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

  Future<void> eliminarCita(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: Text('Eliminar cita', style: AppTheme.subtitulo),
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
      await ApiService.delete('/citas/$id');
      await cargarDatos();
    }
  }

  Future<void> actualizarEstado(int id, String nuevoEstado) async {
    await ApiService.post('/citas/update/$id', {'estado': nuevoEstado});
    await cargarDatos();
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
                Text('Citas', style: AppTheme.titulo),
                const SizedBox(height: 12),
                TextField(
                  style: AppTheme.cuerpo,
                  onChanged: (v) => setState(() => busqueda = v),
                  decoration: InputDecoration(
                    hintText: 'Buscar por cliente, vehículo, estado...',
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
                : citasFiltradas.isEmpty
                    ? Center(child: Text('No hay citas', style: AppTheme.muted))
                    : RefreshIndicator(
                        onRefresh: cargarDatos,
                        color: AppTheme.accentColor,
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
                              decoration:
                                  AppTheme.card(borderColor: estadoColor),
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
                                                    fontWeight:
                                                        FontWeight.bold))),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                              color:
                                                  estadoColor.withOpacity(0.15),
                                              borderRadius:
                                                  BorderRadius.circular(6)),
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
                                        style: AppTheme.muted),
                                    const SizedBox(height: 4),
                                    Row(children: [
                                      const Icon(Icons.calendar_today_outlined,
                                          color: Colors.grey, size: 13),
                                      const SizedBox(width: 4),
                                      Text(c['fecha'] ?? '',
                                          style: AppTheme.small),
                                      const SizedBox(width: 12),
                                      const Icon(Icons.access_time_outlined,
                                          color: Colors.grey, size: 13),
                                      const SizedBox(width: 4),
                                      Text(
                                          c['hora']
                                                  ?.toString()
                                                  .substring(0, 5) ??
                                              '',
                                          style: AppTheme.small),
                                    ]),
                                    if (c['descripcion'] != null &&
                                        c['descripcion']
                                            .toString()
                                            .isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(c['descripcion'],
                                          style: AppTheme.small),
                                    ],
                                    const SizedBox(height: 8),
                                    Row(children: [
                                      Text(
                                          '${double.tryParse(c['coste'].toString())?.toStringAsFixed(2)} €',
                                          style: TextStyle(
                                              color: AppTheme.successColor,
                                              fontWeight: FontWeight.bold)),
                                      const Spacer(),
                                      PopupMenuButton<String>(
                                        color: AppTheme.inputColor,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: estadoColor.withOpacity(0.1),
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
                                              ]),
                                        ),
                                        itemBuilder: (ctx) => [
                                          PopupMenuItem(
                                              value: 'pendiente',
                                              child: Text('Pendiente',
                                                  style: TextStyle(
                                                      color: AppTheme
                                                          .warningColor))),
                                          PopupMenuItem(
                                              value: 'en_proceso',
                                              child: Text('En proceso',
                                                  style: TextStyle(
                                                      color:
                                                          AppTheme.infoColor))),
                                          PopupMenuItem(
                                              value: 'finalizada',
                                              child: Text('Finalizada',
                                                  style: TextStyle(
                                                      color: AppTheme
                                                          .successColor))),
                                        ],
                                        onSelected: (nuevoEstado) =>
                                            actualizarEstado(
                                                int.parse(
                                                    c['id_cita'].toString()),
                                                nuevoEstado),
                                      ),
                                      const SizedBox(width: 4),
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined,
                                            color: AppTheme.accentColor,
                                            size: 20),
                                        onPressed: () =>
                                            _mostrarFormulario(cita: c),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: Icon(Icons.delete_outline,
                                            color: AppTheme.dangerColor,
                                            size: 20),
                                        onPressed: () => eliminarCita(
                                            int.parse(c['id_cita'].toString())),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                    ]),
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
