import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_service.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  String error = '';
  bool cargando = false;

  Future<void> login() async {
    setState(() {
      cargando = true;
      error = '';
    });
    try {
      final res = await ApiService.post('/login', {
        'email': emailController.text,
        'password': passwordController.text,
      });
      if (res['token'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', res['token']);
        await prefs.setString('user', jsonEncode(res['user']));
        if (mounted) Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        setState(() => error = res['message'] ?? 'Credenciales incorrectas');
      }
    } catch (e) {
      setState(() => error = 'Error al conectar con el servidor');
    } finally {
      setState(() => cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.car_repair,
                      size: 44, color: AppTheme.accentColor),
                ),
                const SizedBox(height: 20),
                const Text('TallerPro',
                    style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(height: 6),
                Text('Gestión de taller mecánico', style: AppTheme.muted),
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: AppTheme.card(),
                  child: Column(
                    children: [
                      TextField(
                        controller: emailController,
                        style: AppTheme.cuerpo,
                        keyboardType: TextInputType.emailAddress,
                        decoration:
                            AppTheme.input('Email', Icons.email_outlined),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        style: AppTheme.cuerpo,
                        decoration:
                            AppTheme.input('Contraseña', Icons.lock_outline),
                      ),
                      if (error.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.dangerColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline,
                                  color: AppTheme.dangerColor, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: Text(error,
                                      style: TextStyle(
                                          color: AppTheme.dangerColor,
                                          fontSize: 13))),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: cargando ? null : login,
                          style: AppTheme.botonPrincipal(),
                          child: cargando
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : const Text('Iniciar sesión',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/register'),
                  child: const Text('¿No tienes cuenta? Regístrate',
                      style:
                          TextStyle(color: AppTheme.accentColor, fontSize: 14)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
