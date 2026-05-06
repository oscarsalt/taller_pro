import 'package:flutter/material.dart';
import '../api_service.dart';
import '../theme/app_theme.dart';

class HistorialVehiculoScreen extends StatefulWidget {
  final Map<String, dynamic> vehiculo;

  const HistorialVehiculoScreen({super.key, required this.vehiculo});

  @override
  State<HistorialVehiculoScreen> createState() =>
      _HistorialVehiculoScreenState();
}

class _HistorialVehiculoScreenState extends State<HistorialVehiculoScreen> {
  List<dynamic> historial = [];
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    cargarHistorial();
  }

  Future<void> cargarHistorial() async {
    setState(() => cargando = true);
    try {
      final id = widget.vehiculo['id_vehiculo'];
      print('ID vehiculo: $id');
      print('URL: ${ApiService.baseUrl}/vehiculos/$id/historial');
      final res = await ApiService.get('/vehiculos/$id/historial');
      print('Historial respuesta: $res'); // añade esta
      print(
          'Primer item: ${res is List && res.isNotEmpty ? res[0] : 'vacío'}'); // y esta
      setState(() {
        historial = res is List ? res : [];
        cargando = false;
      });
    } catch (e) {
      setState(() => cargando = false);
    }
  }

  double get totalIngresos {
    return historial.fold(
        0.0,
        (sum, c) =>
            sum + (double.tryParse(c['coste']?.toString() ?? '0') ?? 0));
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.vehiculo;

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        backgroundColor: AppTheme.sidebarColor,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${v['marca'] ?? ''} ${v['modelo'] ?? ''}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              v['matricula']?.toString() ?? '',
              style: const TextStyle(fontSize: 12, color: AppTheme.accentColor),
            ),
          ],
        ),
        elevation: 0,
      ),
      body: cargando
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.accentColor))
          : RefreshIndicator(
              onRefresh: cargarHistorial,
              color: AppTheme.accentColor,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Tarjeta del vehículo
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: AppTheme.card(
                                borderColor: AppTheme.accentColor),
                            child: Row(
                              children: [
                                AppTheme.vehiculoIcon(),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${v['marca'] ?? ''} ${v['modelo'] ?? ''}',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(v['matricula']?.toString() ?? '',
                                          style: AppTheme.accent),
                                      if (v['anio'] != null &&
                                          v['anio'].toString().isNotEmpty)
                                        Text('Año ${v['anio']}',
                                            style: AppTheme.small),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Estadísticas
                          Row(
                            children: [
                              Expanded(
                                child: AppTheme.statCard(
                                  'Reparaciones',
                                  historial.length.toString(),
                                  Icons.build_outlined,
                                  AppTheme.infoColor,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: AppTheme.statCard(
                                  'Total gastado',
                                  '${totalIngresos.toStringAsFixed(2)} €',
                                  Icons.euro_outlined,
                                  AppTheme.successColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Título
                          Row(
                            children: [
                              const Text(
                                'Historial de reparaciones',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold),
                              ),
                              const Spacer(),
                              if (historial.isNotEmpty)
                                Text('${historial.length} citas',
                                    style: AppTheme.muted),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Lista vacía
                  if (historial.isEmpty)
                    SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history,
                                color: Colors.grey.withOpacity(0.4), size: 64),
                            const SizedBox(height: 16),
                            Text('Sin reparaciones registradas',
                                style: AppTheme.muted),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final c = historial[index];

                            final estadoColor =
                                AppTheme.estadoColor(c['estado']?.toString());
                            final coste = double.tryParse(
                                    c['coste']?.toString() ?? '0') ??
                                0;
                            final manoObra = double.tryParse(
                                    c['mano_obra']?.toString() ?? '0') ??
                                0;
                            final piezas = double.tryParse(
                                    c['piezas']?.toString() ?? '0') ??
                                0;
                            final otros = double.tryParse(
                                    c['otros']?.toString() ?? '0') ??
                                0;
                            final hora = c['hora']?.toString() ?? '';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration:
                                  AppTheme.card(borderColor: estadoColor),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Cabecera fecha + estado
                                    Row(
                                      children: [
                                        const Icon(
                                            Icons.calendar_today_outlined,
                                            color: Colors.grey,
                                            size: 14),
                                        const SizedBox(width: 6),
                                        Text(
                                          c['fecha']?.toString() ?? '',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(width: 12),
                                        const Icon(Icons.access_time_outlined,
                                            color: Colors.grey, size: 14),
                                        const SizedBox(width: 4),
                                        Text(
                                          hora.length >= 5
                                              ? hora.substring(0, 5)
                                              : hora,
                                          style: AppTheme.muted,
                                        ),
                                        const Spacer(),
                                        AppTheme.estadoChip(
                                            c['estado']?.toString()),
                                      ],
                                    ),
                                    // Descripción
                                    if (c['descripcion'] != null &&
                                        c['descripcion']
                                            .toString()
                                            .isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(c['descripcion'].toString(),
                                          style: AppTheme.muted),
                                    ],
                                    const SizedBox(height: 10),
                                    // Desglose de costes
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        children: [
                                          if (manoObra > 0)
                                            _desglose('Mano de obra', manoObra),
                                          if (piezas > 0)
                                            _desglose(
                                                'Piezas / Recambios', piezas),
                                          if (otros > 0)
                                            _desglose('Otros conceptos', otros),
                                          const Divider(
                                              color: Colors.white12,
                                              height: 12),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text(
                                                'Total con IVA (21%)',
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13),
                                              ),
                                              Text(
                                                '${coste.toStringAsFixed(2)} €',
                                                style: TextStyle(
                                                    color:
                                                        AppTheme.successColor,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          childCount: historial.length,
                        ),
                      ),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ),
            ),
    );
  }

  Widget _desglose(String label, double valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTheme.small),
          Text('${valor.toStringAsFixed(2)} €', style: AppTheme.small),
        ],
      ),
    );
  }
}
