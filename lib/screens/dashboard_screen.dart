import 'package:flutter/material.dart';
import '../api_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const Color bgColor = Color(0xFF1A1A1A);
  static const Color cardColor = Color(0xFF2A2A2A);
  static const Color accentColor = Color(0xFFE67E22);

  Map<String, dynamic> stats = {};
  List<dynamic> citasSemana = [];
  bool cargando = true;
  int semanaOffset = 0;

  final Map<String, Color> estadoColores = {
    'pendiente': const Color(0xFFF39C12),
    'en_proceso': const Color(0xFF2980B9),
    'finalizada': const Color(0xFF27AE60),
  };

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  Future<void> cargarDatos() async {
    setState(() => cargando = true);
    try {
      final s = await ApiService.get('/dashboard');
      final c = await ApiService.get('/dashboard/semana');
      setState(() {
        stats = s is Map ? Map<String, dynamic>.from(s) : {};
        citasSemana = c is List ? c : [];
        cargando = false;
      });
    } catch (e) {
      setState(() => cargando = false);
    }
  }

  DateTime obtenerLunes() {
    final hoy = DateTime.now();
    final diff = hoy.weekday - 1;
    return DateTime(hoy.year, hoy.month, hoy.day - diff)
        .add(Duration(days: semanaOffset * 7));
  }

  List<DateTime> obtenerDiasSemana() {
    final lunes = obtenerLunes();
    return List.generate(7, (i) => lunes.add(Duration(days: i)));
  }

  List<dynamic> citasDelDia(DateTime fecha) {
    final fechaStr =
        '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';
    return citasSemana.where((c) => c['fecha'] == fechaStr).toList();
  }

  double ingresosDelDia(DateTime fecha) {
    return citasDelDia(fecha)
        .fold(0.0, (sum, c) => sum + double.tryParse(c['coste'].toString())!);
  }

  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return const Center(child: CircularProgressIndicator(color: accentColor));
    }

    final dias = obtenerDiasSemana();
    final hoy = DateTime.now();
    final nombresDias = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

    return Scaffold(
      backgroundColor: bgColor,
      body: RefreshIndicator(
        onRefresh: cargarDatos,
        color: accentColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Dashboard',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Tarjetas de estadísticas
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.6,
                children: [
                  _buildStatCard(
                      'Clientes',
                      stats['clientes']?.toString() ?? '0',
                      Icons.people,
                      const Color(0xFF3498DB)),
                  _buildStatCard(
                      'Vehículos',
                      stats['vehiculos']?.toString() ?? '0',
                      Icons.directions_car,
                      const Color(0xFF9B59B6)),
                  _buildStatCard('Citas', stats['citas']?.toString() ?? '0',
                      Icons.calendar_month, accentColor),
                  _buildStatCard(
                      'Citas hoy',
                      stats['citas_hoy']?.toString() ?? '0',
                      Icons.today,
                      const Color(0xFFE74C3C)),
                ],
              ),

              const SizedBox(height: 12),

              // Tarjeta de ingresos
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF27AE60).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFF27AE60).withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.euro, color: Color(0xFF27AE60), size: 32),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Ingresos totales',
                            style: TextStyle(color: Colors.grey, fontSize: 13)),
                        Text(
                          '${double.tryParse(stats['ingresos']?.toString() ?? '0')?.toStringAsFixed(2)} €',
                          style: const TextStyle(
                            color: Color(0xFF27AE60),
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Cabecera del calendario
              Row(
                children: [
                  const Text(
                    'Calendario semanal',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: Colors.white),
                    onPressed: () => setState(() => semanaOffset--),
                  ),
                  if (semanaOffset != 0)
                    TextButton(
                      onPressed: () => setState(() => semanaOffset = 0),
                      child: const Text('Hoy',
                          style: TextStyle(color: accentColor)),
                    ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: Colors.white),
                    onPressed: () => setState(() => semanaOffset++),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Calendario semanal
              SizedBox(
                height: 220,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 7,
                  itemBuilder: (context, i) {
                    final dia = dias[i];
                    final esHoy = dia.day == hoy.day &&
                        dia.month == hoy.month &&
                        dia.year == hoy.year;
                    final citas = citasDelDia(dia);
                    final ingresos = ingresosDelDia(dia);

                    return Container(
                      width: 130,
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: esHoy ? const Color(0xFF1A2A3A) : cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: esHoy ? accentColor : Colors.white12,
                          width: esHoy ? 1.5 : 0.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nombresDias[i],
                            style: TextStyle(
                              color: esHoy ? accentColor : Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            '${dia.day}/${dia.month}',
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 11),
                          ),
                          const SizedBox(height: 6),
                          Expanded(
                            child: citas.isEmpty
                                ? const Text('Sin citas',
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 11))
                                : ListView(
                                    children: citas.map((c) {
                                      final color =
                                          estadoColores[c['estado']] ??
                                              Colors.grey;
                                      return Container(
                                        margin:
                                            const EdgeInsets.only(bottom: 4),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: color.withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          border: Border.all(
                                              color: color.withOpacity(0.4)),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              c['hora']
                                                      ?.toString()
                                                      .substring(0, 5) ??
                                                  '',
                                              style: TextStyle(
                                                  color: color,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            Text(
                                              c['nombre'] ?? '',
                                              style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 10),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                          ),
                          if (citas.isNotEmpty) ...[
                            const Divider(color: Colors.white12, height: 8),
                            Text(
                              '${ingresos.toStringAsFixed(2)} €',
                              style: const TextStyle(
                                color: Color(0xFF27AE60),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ]
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Leyenda
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildLeyenda('Pendiente', const Color(0xFFF39C12)),
                  const SizedBox(width: 12),
                  _buildLeyenda('En proceso', const Color(0xFF2980B9)),
                  const SizedBox(width: 12),
                  _buildLeyenda('Finalizada', const Color(0xFF27AE60)),
                ],
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String titulo, String valor, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(titulo,
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
              Text(valor,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLeyenda(String texto, Color color) {
    return Row(
      children: [
        Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text(texto, style: const TextStyle(color: Colors.grey, fontSize: 11)),
      ],
    );
  }
}
