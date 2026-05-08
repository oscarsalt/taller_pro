import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../api_service.dart';
import '../theme/app_theme.dart';

class HistorialClienteScreen extends StatefulWidget {
  final Map<String, dynamic> cliente;

  const HistorialClienteScreen({super.key, required this.cliente});

  @override
  State<HistorialClienteScreen> createState() => _HistorialClienteScreenState();
}

class _HistorialClienteScreenState extends State<HistorialClienteScreen> {
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
      final id = widget.cliente['id_cliente'];
      final res = await ApiService.get('/clientes/$id/historial');
      setState(() {
        historial = res is List ? res : [];
        cargando = false;
      });
    } catch (e) {
      setState(() => cargando = false);
    }
  }

  double get totalGastado => historial.fold(0.0,
      (sum, c) => sum + (double.tryParse(c['coste']?.toString() ?? '0') ?? 0));

  Future<void> _abrirPDF(String rutaPDF) async {
    final url = '${ApiService.baseUrl.replaceAll('/index.php', '')}/$rutaPDF';
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el PDF')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cl = widget.cliente;

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        backgroundColor: AppTheme.sidebarColor,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(cl['nombre']?.toString() ?? '',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(cl['email']?.toString() ?? cl['telefono']?.toString() ?? '',
                style: const TextStyle(fontSize: 12, color: Colors.white60)),
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
                          // Tarjeta del cliente
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: AppTheme.card(
                                borderColor: AppTheme.accentColor),
                            child: Row(
                              children: [
                                AppTheme.avatar(
                                    cl['nombre']?.toString() ?? '?'),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(cl['nombre']?.toString() ?? '',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16)),
                                      if (cl['telefono'] != null &&
                                          cl['telefono'].toString().isNotEmpty)
                                        Text(cl['telefono'].toString(),
                                            style: AppTheme.muted),
                                      if (cl['email'] != null &&
                                          cl['email'].toString().isNotEmpty)
                                        Text(cl['email'].toString(),
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
                                'Visitas',
                                historial.length.toString(),
                                Icons.calendar_month_outlined,
                                AppTheme.infoColor,
                              )),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: AppTheme.statCard(
                                'Total gastado',
                                '${totalGastado.toStringAsFixed(2)} €',
                                Icons.euro_outlined,
                                AppTheme.successColor,
                              )),
                            ],
                          ),
                          const SizedBox(height: 16),

                          Row(
                            children: [
                              const Text('Historial de citas',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
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
                            Text('Sin citas registradas',
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
                            final tienePDF = c['presupuesto'] != null &&
                                c['presupuesto'].toString().isNotEmpty;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration:
                                  AppTheme.card(borderColor: estadoColor),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Vehículo + estado
                                    Row(children: [
                                      Expanded(
                                        child: Text(
                                          '${c['marca']} ${c['modelo']} - ${c['matricula']}',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      AppTheme.estadoChip(
                                          c['estado']?.toString()),
                                    ]),
                                    const SizedBox(height: 6),

                                    // Fecha y hora
                                    Row(children: [
                                      const Icon(Icons.calendar_today_outlined,
                                          color: Colors.grey, size: 13),
                                      const SizedBox(width: 4),
                                      Text(c['fecha']?.toString() ?? '',
                                          style: AppTheme.small),
                                      const SizedBox(width: 12),
                                      const Icon(Icons.access_time_outlined,
                                          color: Colors.grey, size: 13),
                                      const SizedBox(width: 4),
                                      Text(
                                          hora.length >= 5
                                              ? hora.substring(0, 5)
                                              : hora,
                                          style: AppTheme.small),
                                    ]),

                                    if (c['descripcion'] != null &&
                                        c['descripcion']
                                            .toString()
                                            .isNotEmpty) ...[
                                      const SizedBox(height: 4),
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
                                              const Text('Total con IVA (21%)',
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 13)),
                                              Text(
                                                  '${coste.toStringAsFixed(2)} €',
                                                  style: TextStyle(
                                                      color:
                                                          AppTheme.successColor,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 15)),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Botón PDF
                                    if (tienePDF) ...[
                                      const SizedBox(height: 8),
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
                                    ],
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
