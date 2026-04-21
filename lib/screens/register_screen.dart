import 'package:flutter/material.dart';
import '../api_service.dart';
import '../theme/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nombreController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  String error = '';
  String exito = '';
  bool cargando = false;

  Future<void> registrar() async {
    setState(() {
      cargando = true;
      error = '';
      exito = '';
    });

    if (nombreController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty) {
      setState(() {
        error = 'Todos los campos son obligatorios';
        cargando = false;
      });
      return;
    }
    if (passwordController.text.length < 6) {
      setState(() {
        error = 'La contraseña debe tener al menos 6 caracteres';
        cargando = false;
      });
      return;
    }

    try {
      final res = await ApiService.post('/register', {
        'nombre': nombreController.text,
        'email': emailController.text,
        'password': passwordController.text,
        'rol': 'empleado',
      });
      if (res['message'] == 'Usuario creado') {
        setState(() => exito = 'Cuenta creada correctamente. Inicia sesión.');
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) Navigator.pushReplacementNamed(context, '/');
      } else {
        setState(() => error = res['error'] ?? 'Error al registrar');
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
                Text('Crear cuenta nueva', style: AppTheme.muted),
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: AppTheme.card(),
                  child: Column(
                    children: [
                      TextField(
                          controller: nombreController,
                          style: AppTheme.cuerpo,
                          decoration: AppTheme.input(
                              'Nombre del taller', Icons.store_outlined)),
                      const SizedBox(height: 12),
                      TextField(
                          controller: emailController,
                          style: AppTheme.cuerpo,
                          keyboardType: TextInputType.emailAddress,
                          decoration:
                              AppTheme.input('Email', Icons.email_outlined)),
                      const SizedBox(height: 12),
                      TextField(
                          controller: passwordController,
                          obscureText: true,
                          style: AppTheme.cuerpo,
                          decoration:
                              AppTheme.input('Contraseña', Icons.lock_outline)),
                      if (error.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              color: AppTheme.dangerColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8)),
                          child: Row(children: [
                            Icon(Icons.error_outline,
                                color: AppTheme.dangerColor, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Text(error,
                                    style: TextStyle(
                                        color: AppTheme.dangerColor,
                                        fontSize: 13))),
                          ]),
                        ),
                      ],
                      if (exito.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              color: AppTheme.successColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8)),
                          child: Row(children: [
                            Icon(Icons.check_circle_outline,
                                color: AppTheme.successColor, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Text(exito,
                                    style: TextStyle(
                                        color: AppTheme.successColor,
                                        fontSize: 13))),
                          ]),
                        ),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: cargando ? null : registrar,
                          style: AppTheme.botonPrincipal(),
                          child: cargando
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : const Text('Crear cuenta',
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
                  onPressed: () => Navigator.pushReplacementNamed(context, '/'),
                  child: const Text('¿Ya tienes cuenta? Inicia sesión',
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
