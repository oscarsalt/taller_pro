import 'dart:async';
import 'package:flutter/material.dart';
import '../api_service.dart';
import '../theme/app_theme.dart';

class BusquedaScreen extends StatefulWidget {
  const BusquedaScreen({super.key});

  @override
  State<BusquedaScreen> createState() => _BusquedaScreenState();
}

class _BusquedaScreenState extends State<BusquedaScreen> {
  final searchController = TextEditingController();
  Timer? _debounce;

  List<dynamic> clientes = [];
  List<dynamic> vehiculos = [];
  List<dynamic> citas = [];

  bool cargando = false;
  bool buscado = false;

  @override
  void dispose() {
    _debounce?.cancel();
    searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (query.trim().length >= 2) {
        buscar(query.trim());
      } else {
        setState(() {
          clientes = [];
          vehiculos = [];
          citas = [];
          buscado = false;
        });
      }
    });
  }

  Future<void> buscar(String q) async {
    setState(() => cargando = true);
    try {
      final res = await ApiService.get('/buscar?q=$q');
      if (res is Map) {
        final data = Map<String, dynamic>.from(res);
        setState(() {
          clientes = data['clientes'] is List ? data['clientes'] : [];
          vehiculos = data['vehiculos'] is List ? data['vehiculos'] : [];
          citas = data['citas'] is List ? data['citas'] : [];
          buscado = true;
          cargando = false;
        });
      }
    } catch (e) {
      setState(() => cargando = false);
    }
  }

  int get totalResultados => clientes.length + vehiculos.length + citas.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Búsqueda global', style: AppTheme.titulo),
                const SizedBox(height: 12),
                TextField(
                  controller: searchController,
                  style: AppTheme.cuerpo,
                  autofocus: true,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Buscar clientes, vehículos, citas...',
                    hintStyle: AppTheme.muted,
                    prefixIcon:
                        const Icon(Icons.search, color: AppTheme.accentColor),
                    suffixIcon: searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close, color: Colors.grey),
                            onPressed: () {
                              searchController.clear();
                              setState(() {
                                clientes = [];
                                vehiculos = [];
                                citas = [];
                                buscado = false;
                              });
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppTheme.cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppTheme.accentColor, width: 1.5),
                    ),
                  ),
                ),
                if (buscado && !cargando) ...[
                  const SizedBox(height: 8),
                  Text(
                    totalResultados == 0
                        ? 'Sin resultados para "${searchController.text}"'
                        : '$totalResultados resultado${totalResultados != 1 ? 's' : ''} encontrado${totalResultados != 1 ? 's' : ''}',
                    style: AppTheme.muted,
                  ),
                ],
              ],
            ),
          ),

          // Resultados
          Expanded(
            child: cargando
                ? const Center(
                    child:
                        CircularProgressIndicator(color: AppTheme.accentColor))
                : !buscado
                    ? _buildEstadoInicial()
                    : totalResultados == 0
                        ? _buildSinResultados()
                        : ListView(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            children: [
                              if (clientes.isNotEmpty) ...[
                                _buildSeccionHeader(
                                    'Clientes', Icons.people, clientes.length),
                                ...clientes.map((c) => _buildClienteItem(c)),
                                const SizedBox(height: 8),
                              ],
                              if (vehiculos.isNotEmpty) ...[
                                _buildSeccionHeader('Vehículos',
                                    Icons.directions_car, vehiculos.length),
                                ...vehiculos.map((v) => _buildVehiculoItem(v)),
                                const SizedBox(height: 8),
                              ],
                              if (citas.isNotEmpty) ...[
                                _buildSeccionHeader('Citas',
                                    Icons.calendar_month, citas.length),
                                ...citas.map((c) => _buildCitaItem(c)),
                              ],
                              const SizedBox(height: 24),
                            ],
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstadoInicial() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 72, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text('Escribe al menos 2 caracteres', style: AppTheme.muted),
          const SizedBox(height: 8),
          Text('Busca en clientes, vehículos y citas', style: AppTheme.small),
        ],
      ),
    );
  }

  Widget _buildSinResultados() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 72, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text('No se encontró nada', style: AppTheme.muted),
          const SizedBox(height: 8),
          Text('Prueba con otro término de búsqueda', style: AppTheme.small),
        ],
      ),
    );
  }

  Widget _buildSeccionHeader(String titulo, IconData icon, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.accentColor, size: 16),
          const SizedBox(width: 8),
          Text(titulo,
              style: const TextStyle(
                  color: AppTheme.accentColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('$count',
                style: const TextStyle(
                    color: AppTheme.accentColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildClienteItem(dynamic c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: AppTheme.card(),
      child: ListTile(
        leading: AppTheme.avatar(c['nombre']?.toString() ?? '?'),
        title: Text(c['nombre']?.toString() ?? '', style: AppTheme.cuerpo),
        subtitle: Text(
            c['email']?.toString() ?? c['telefono']?.toString() ?? '',
            style: AppTheme.small),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
      ),
    );
  }

  Widget _buildVehiculoItem(dynamic v) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: AppTheme.card(),
      child: ListTile(
        leading: AppTheme.vehiculoIcon(),
        title: Text(v['nombre']?.toString() ?? '', style: AppTheme.cuerpo),
        subtitle: Text(v['subtitulo']?.toString() ?? '',
            style: const TextStyle(
                color: AppTheme.accentColor,
                fontSize: 12,
                fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
      ),
    );
  }

  Widget _buildCitaItem(dynamic c) {
    final partes = c['subtitulo']?.toString().split(' ') ?? [];
    final fecha = partes.isNotEmpty ? partes[0] : '';
    final estado = partes.length > 1 ? partes[1] : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: AppTheme.card(borderColor: AppTheme.estadoColor(estado)),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.estadoColor(estado).withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.build_outlined,
              color: AppTheme.estadoColor(estado), size: 20),
        ),
        title: Text(c['nombre']?.toString() ?? '', style: AppTheme.cuerpo),
        subtitle: Row(
          children: [
            Text(fecha, style: AppTheme.small),
            const SizedBox(width: 8),
            AppTheme.estadoChip(estado),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
      ),
    );
  }
}
