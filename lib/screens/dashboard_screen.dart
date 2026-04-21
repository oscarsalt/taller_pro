import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
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
  String nombreTaller = '';

  final Map<String, Color> estadoColores = {
    'pendiente': const Color(0xFFF39C12),
    'en_proceso': const Color(0xFF2980B9),
    'finalizada': const Color(0xFF27AE60),
  };

  final List<String> nombresDias = [
    'Lun',
    'Mar',
    'Mié',
    'Jue',
    'Vie',
    'Sáb',
    'Dom'
  ];

  @override
  void initState() {
    super.initState();
    cargarNombre();
    cargarDatos();
  }

  Future<void> cargarNombre() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString('user');
    if (userStr != null) {
      final user = jsonDecode(userStr);
      setState(() => nombreTaller = user['nombre'] ?? '');
    }
  }

  DateTime obtenerLunes() {
    final hoy = DateTime.now();
    final diff = hoy.weekday - 1;
    return DateTime(hoy.year, hoy.month, hoy.day - diff)
        .add(Duration(days: semanaOffset * 7));
  }

  String formatFecha(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  String formatFechaCorta(DateTime d) {
    const meses = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic'
    ];
    return '${d.day} ${meses[d.month - 1]}';
  }

  Future<void> cargarDatos() async {
    setState(() => cargando = true);
    try {
      final s = await ApiService.get('/dashboard');
      setState(() {
        stats = s is Map ? Map<String, dynamic>.from(s) : {};
        cargando = false;
      });
    } catch (e) {
      setState(() => cargando = false);
    }
    await cargarSemana();
  }

  Future<void> cargarSemana() async {
    try {
      final lunes = obtenerLunes();
      final domingo = lunes.add(const Duration(days: 6));
      final inicio = formatFecha(lunes);
      final fin = formatFecha(domingo);
      final c =
          await ApiService.get('/dashboard/semana?inicio=$inicio&fin=$fin');
      setState(() {
        citasSemana = c is List ? c : [];
      });
    } catch (e) {
      setState(() => citasSemana = []);
    }
  }

  List<DateTime> obtenerDiasSemana() {
    final lunes = obtenerLunes();
    return List.generate(7, (i) => lunes.add(Duration(days: i)));
  }

  List<dynamic> citasDelDia(DateTime fecha) {
    final fechaStr = formatFecha(fecha);
    return citasSemana.where((c) => c['fecha'] == fechaStr).toList();
  }

  double ingresosDelDia(DateTime fecha) {
    return citasDelDia(fecha).fold(
        0.0, (sum, c) => sum + (double.tryParse(c['coste'].toString()) ?? 0));
  }

  double get ingresosSemana {
    final dias = obtenerDiasSemana();
    return dias.fold(0.0, (sum, d) => sum + ingresosDelDia(d));
  }

  String get saludo {
    final hora = DateTime.now().hour;
    if (hora < 12) return 'Buenos días';
    if (hora < 20) return 'Buenas tardes';
    return 'Buenas noches';
  }

  String get fechaHoy {
    final hoy = DateTime.now();
    const diasSemana = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo'
    ];
    const meses = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre'
    ];
    return '${diasSemana[hoy.weekday - 1]}, ${hoy.day} de ${meses[hoy.month - 1]} de ${hoy.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return const Center(child: CircularProgressIndicator(color: accentColor));
    }

    final dias = obtenerDiasSemana();
    final hoy = DateTime.now();

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
              // Saludo
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accentColor.withOpacity(0.3),
                      accentColor.withOpacity(0.05)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: accentColor.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$saludo,',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      nombreTaller,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      fechaHoy,
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildMiniStat('Citas hoy',
                            stats['citas_hoy']?.toString() ?? '0', Icons.today),
                        const SizedBox(width: 16),
                        _buildMiniStat(
                            'Total citas',
                            stats['citas']?.toString() ?? '0',
                            Icons.calendar_month),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Gráfico de ingresos semanales
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Ingresos semanales',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        Text(
                          '${ingresosSemana.toStringAsFixed(2)} €',
                          style: const TextStyle(
                              color: Color(0xFF27AE60),
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${formatFechaCorta(dias.first)} — ${formatFechaCorta(dias.last)}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 180,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: () {
                            final valores =
                                dias.map((d) => ingresosDelDia(d)).toList();
                            final maxIngresos =
                                valores.reduce((a, b) => a > b ? a : b);
                            return maxIngresos > 0 ? maxIngresos * 1.3 : 100.0;
                          }(),
                          barTouchData: BarTouchData(
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipItem:
                                  (group, groupIndex, rod, rodIndex) {
                                return BarTooltipItem(
                                  '${rod.toY.toStringAsFixed(2)} €',
                                  const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12),
                                );
                              },
                            ),
                          ),
                          titlesData: FlTitlesData(
                            leftTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final index = value.toInt();
                                  if (index < 0 || index >= 7)
                                    return const SizedBox();
                                  final esHoy = dias[index].day == hoy.day &&
                                      dias[index].month == hoy.month &&
                                      dias[index].year == hoy.year;
                                  return Text(
                                    nombresDias[index],
                                    style: TextStyle(
                                      color: esHoy ? accentColor : Colors.grey,
                                      fontSize: 11,
                                      fontWeight: esHoy
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (value) => FlLine(
                              color: Colors.white10,
                              strokeWidth: 1,
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          barGroups: List.generate(7, (i) {
                            final ingresos = ingresosDelDia(dias[i]);
                            final esHoy = dias[i].day == hoy.day &&
                                dias[i].month == hoy.month &&
                                dias[i].year == hoy.year;
                            return BarChartGroupData(
                              x: i,
                              barRods: [
                                BarChartRodData(
                                  toY: ingresos,
                                  color: esHoy
                                      ? accentColor
                                      : accentColor.withOpacity(0.5),
                                  width: 22,
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(6)),
                                ),
                              ],
                            );
                          }),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Cabecera del calendario
              Row(
                children: [
                  const Text(
                    'Calendario semanal',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: Colors.white),
                    onPressed: () {
                      setState(() => semanaOffset--);
                      cargarSemana();
                    },
                  ),
                  if (semanaOffset != 0)
                    TextButton(
                      onPressed: () {
                        setState(() => semanaOffset = 0);
                        cargarSemana();
                      },
                      child: const Text('Hoy',
                          style: TextStyle(color: accentColor, fontSize: 12)),
                    ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: Colors.white),
                    onPressed: () {
                      setState(() => semanaOffset++);
                      cargarSemana();
                    },
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
                                  fontWeight: FontWeight.bold),
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

  Widget _buildMiniStat(String label, String valor, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: accentColor, size: 16),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(color: Colors.white54, fontSize: 11)),
            Text(valor,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ],
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
