import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/dashboard_screen.dart';
import '../screens/clientes_screen.dart';
import '../screens/perfil_screen.dart';
import '../screens/vehiculos_screen.dart';
import '../screens/citas_screen.dart';
import '../theme/app_theme.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  final List<_NavItem> _items = const [
    _NavItem(
        icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard,
        label: 'Dashboard'),
    _NavItem(
        icon: Icons.people_outline,
        activeIcon: Icons.people,
        label: 'Clientes'),
    _NavItem(
        icon: Icons.directions_car_outlined,
        activeIcon: Icons.directions_car,
        label: 'Vehículos'),
    _NavItem(
        icon: Icons.calendar_month_outlined,
        activeIcon: Icons.calendar_month,
        label: 'Citas'),
  ];

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
    if (mounted) Navigator.pushReplacementNamed(context, '/');
  }

  void _abrirPerfil() {
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => const PerfilScreen()));
  }

  Widget _buildCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return const DashboardScreen();
      case 1:
        return const ClientesScreen();
      case 2:
        return const VehiculosScreen();
      case 3:
        return const CitasScreen();
      default:
        return const DashboardScreen();
    }
  }

  Widget _buildSidebarItem(int index) {
    final item = _items[index];
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.accentColor.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isActive
              ? Border.all(color: AppTheme.accentColor.withOpacity(0.4))
              : null,
        ),
        child: Row(
          children: [
            Icon(isActive ? item.activeIcon : item.icon,
                color: isActive ? AppTheme.accentColor : Colors.white60,
                size: 20),
            const SizedBox(width: 12),
            Text(item.label,
                style: TextStyle(
                  color: isActive ? AppTheme.accentColor : Colors.white60,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildWideLayout() {
    return Row(
      children: [
        Container(
          width: 220,
          color: AppTheme.sidebarColor,
          child: Column(
            children: [
              const SizedBox(height: 40),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.car_repair,
                    size: 30, color: AppTheme.accentColor),
              ),
              const SizedBox(height: 10),
              const Text('TallerPro',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 32),
              ...List.generate(_items.length, _buildSidebarItem),
              const Spacer(),
              // Perfil
              GestureDetector(
                onTap: _abrirPerfil,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(children: [
                    Icon(Icons.person_outline, color: Colors.white60, size: 20),
                    SizedBox(width: 12),
                    Text('Mi perfil',
                        style: TextStyle(color: Colors.white60, fontSize: 14)),
                  ]),
                ),
              ),
              const SizedBox(height: 8),
              // Logout
              GestureDetector(
                onTap: _logout,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.dangerColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(children: [
                    Icon(Icons.logout, color: AppTheme.dangerColor, size: 20),
                    const SizedBox(width: 12),
                    Text('Cerrar sesión',
                        style: TextStyle(
                            color: AppTheme.dangerColor, fontSize: 14)),
                  ]),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
        Expanded(child: _buildCurrentScreen()),
      ],
    );
  }

  Widget _buildNarrowLayout() {
    return Column(
      children: [
        Container(
          color: AppTheme.sidebarColor,
          padding:
              const EdgeInsets.only(top: 48, left: 16, right: 8, bottom: 12),
          child: Row(
            children: [
              const Icon(Icons.car_repair,
                  color: AppTheme.accentColor, size: 28),
              const SizedBox(width: 10),
              const Text('TallerPro',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.person_outline, color: Colors.white70),
                onPressed: _abrirPerfil,
                tooltip: 'Mi perfil',
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white70),
                onPressed: _logout,
              ),
            ],
          ),
        ),
        Expanded(child: _buildCurrentScreen()),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: isWide ? _buildWideLayout() : _buildNarrowLayout(),
      bottomNavigationBar: isWide
          ? null
          : Container(
              decoration: const BoxDecoration(
                color: AppTheme.sidebarColor,
                border: Border(top: BorderSide(color: Colors.white12)),
              ),
              child: BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: (i) => setState(() => _currentIndex = i),
                backgroundColor: Colors.transparent,
                elevation: 0,
                selectedItemColor: AppTheme.accentColor,
                unselectedItemColor: Colors.white38,
                type: BottomNavigationBarType.fixed,
                items: _items
                    .map((item) => BottomNavigationBarItem(
                          icon: Icon(item.icon),
                          activeIcon: Icon(item.activeIcon),
                          label: item.label,
                        ))
                    .toList(),
              ),
            ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem(
      {required this.icon, required this.activeIcon, required this.label});
}
