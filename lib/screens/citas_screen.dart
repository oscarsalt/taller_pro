import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
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

  double get _totalIVA {
    final mo = double.tryParse(manoObraController.text) ?? 0;
    final pi = double.tryParse(piezasController.text) ?? 0;
    final ot = double.tryParse(otrosController.text) ?? 0;
    return (mo + pi + ot) * 1.21;
  }

  Future<void> _abrirPDF(String rutaPDF) async {
    final url = '${ApiService.baseUrl.replaceAll('/index.php', '')}/$rutaPDF';
    print('URL PDF: $url');
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo abrir el PDF: $e')),
        );
      }
    }
  }

  void _mostrarFormulario({dynamic cita}) {
    if (cita != null) {
      descripcionController.text = cita['descripcion'] ?? '';
      manoObraController.text = cita['mano_obra']?.toString() ?? '0';
      piezasController.text = cita['piezas']?.toString() ?? '0';
      otrosController.text = cita['otros']?.toString() ?? '0';
      final pf = cita['fecha']?.split('-');
      if (pf != null && pf.length == 3) {
        fechaSeleccionada =
            DateTime(int.parse(pf[0]), int.parse(pf[1]), int.parse(pf[2]));
      }
      final ph = cita['hora']?.split(':');
      if (ph != null && ph.length >= 2) {
        horaSeleccionada =
            TimeOfDay(hour: int.parse(ph[0]), minute: int.parse(ph[1]));
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
        builder: (ctx, setModal) => SingleChildScrollView(
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
                    setModal(() {
                      vehiculoSeleccionado = v;
                      final veh = vehiculos.firstWhere(
                        (veh) => veh['id_vehiculo'].toString() == v,
                        orElse: () => null,
                      );
                      if (veh != null)
                        clienteSeleccionado = veh['id_cliente'].toString();
                    });
                  },
                ),
                const SizedBox(height: 12),
              ],
              AppTheme.selectorFecha(fechaSeleccionada, () async {
                final f = await showDatePicker(
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
                if (f != null) setModal(() => fechaSeleccionada = f);
              }),
              const SizedBox(height: 12),
              AppTheme.selectorHora(horaSeleccionada, () async {
                final h = await showTimePicker(
                  context: ctx,
                  initialTime: horaSeleccionada ?? TimeOfDay.now(),
                  builder: (ctx, child) => Theme(
                    data: ThemeData.dark().copyWith(
                        colorScheme: const ColorScheme.dark(
                            primary: AppTheme.accentColor)),
                    child: child!,
                  ),
                );
                if (h != null) setModal(() => horaSeleccionada = h);
              }),
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
                  onChanged: (_) => setModal(() {}),
                  decoration:
                      AppTheme.input('Mano de obra (€)', Icons.build_outlined)),
              const SizedBox(height: 8),
              TextField(
                  controller: piezasController,
                  style: AppTheme.cuerpo,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setModal(() {}),
                  decoration: AppTheme.input(
                      'Piezas / Recambios (€)', Icons.inventory_2_outlined)),
              const SizedBox(height: 8),
              TextField(
                  controller: otrosController,
                  style: AppTheme.cuerpo,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setModal(() {}),
                  decoration: AppTheme.input(
                      'Otros conceptos (€)', Icons.add_circle_outline)),
              const SizedBox(height: 8),
              AppTheme.totalIVA(_totalIVA),
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
                        'estado': 'pendiente',
                      });
                    }
                    _limpiar();
                    await cargarDatos();
                  },
                  style: AppTheme.botonPrincipal(),
                  child: Text(
                    cita != null ? 'Guardar cambios' : 'Crear cita',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> eliminarCita(int id) async {
    final ok = await AppTheme.confirmarEliminar(context, 'cita');
    if (ok) {
      await ApiService.delete('/citas/$id');
      await cargarDatos();
    }
  }

  Future<void> actualizarEstado(int id, String estado) async {
    await ApiService.post('/citas/update/$id', {'estado': estado});
    await cargarDatos();
  }

  List<dynamic> get citasFiltradas {
    if (busqueda.isEmpty) return citas;
    final t = busqueda.toLowerCase();
    return citas
        .where((c) =>
            c['nombre']?.toString().toLowerCase().contains(t) == true ||
            c['marca']?.toString().toLowerCase().contains(t) == true ||
            c['modelo']?.toString().toLowerCase().contains(t) == true ||
            c['matricula']?.toString().toLowerCase().contains(t) == true ||
            c['estado']?.toString().toLowerCase().contains(t) == true ||
            c['fecha']?.toString().contains(t) == true)
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
                  decoration: AppTheme.searchInput(
                      'Buscar por cliente, vehículo, estado...'),
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
                                AppTheme.estadoColor(c['estado']?.toString());
                            final tienePDF = c['presupuesto'] != null &&
                                c['presupuesto'].toString().isNotEmpty;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration:
                                  AppTheme.card(borderColor: estadoColor),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Cabecera vehículo + estado
                                    Row(children: [
                                      Expanded(
                                          child: Text(
                                        '${c['marca']} ${c['modelo']} - ${c['matricula']}',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold),
                                      )),
                                      AppTheme.estadoChip(
                                          c['estado']?.toString()),
                                    ]),
                                    const SizedBox(height: 6),
                                    Text(c['nombre'] ?? '',
                                        style: AppTheme.muted),
                                    const SizedBox(height: 4),

                                    // Fecha y hora
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
                                        (c['hora']?.toString() ?? '').length >=
                                                5
                                            ? c['hora']
                                                .toString()
                                                .substring(0, 5)
                                            : '',
                                        style: AppTheme.small,
                                      ),
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

                                    // Botón PDF en línea propia
                                    if (tienePDF) ...[
                                      GestureDetector(
                                        onTap: () => _abrirPDF(
                                            c['presupuesto'].toString()),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: Colors.redAccent
                                                .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            border: Border.all(
                                                color: Colors.redAccent
                                                    .withOpacity(0.3)),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                  Icons.picture_as_pdf_outlined,
                                                  color: Colors.redAccent,
                                                  size: 16),
                                              SizedBox(width: 6),
                                              Text('Ver presupuesto PDF',
                                                  style: TextStyle(
                                                      color: Colors.redAccent,
                                                      fontSize: 12)),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                    ],

                                    // Fila coste + botones
                                    Row(children: [
                                      Text(
                                        '${double.tryParse(c['coste']?.toString() ?? '0')?.toStringAsFixed(2)} €',
                                        style: TextStyle(
                                            color: AppTheme.successColor,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      const Spacer(),

                                      // Cambiar estado
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
                                        onSelected: (e) => actualizarEstado(
                                            int.parse(c['id_cita'].toString()),
                                            e),
                                      ),
                                      const SizedBox(width: 4),

                                      // Editar
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

                                      // Eliminar
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
