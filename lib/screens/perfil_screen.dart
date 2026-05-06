import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_service.dart';
import '../theme/app_theme.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final nombreController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final password2Controller = TextEditingController();

  bool cargando = true;
  bool guardando = false;
  bool verPassword = false;
  String mensaje = '';
  bool esError = false;
  String fechaCreacion = '';

  @override
  void initState() {
    super.initState();
    cargarPerfil();
  }

  Future<void> cargarPerfil() async {
    setState(() => cargando = true);
    try {
      final res = await ApiService.get('/perfil');
      if (res is Map) {
        final data = Map<String, dynamic>.from(res);
        nombreController.text = data['nombre'] ?? '';
        emailController.text = data['email'] ?? '';
        fechaCreacion =
            data['fecha_creacion']?.toString().substring(0, 10) ?? '';
      }
    } catch (e) {}
    setState(() => cargando = false);
  }

  Future<void> guardarPerfil() async {
    if (nombreController.text.isEmpty || emailController.text.isEmpty) {
      setState(() {
        mensaje = 'Nombre y email son obligatorios';
        esError = true;
      });
      return;
    }
    if (passwordController.text.isNotEmpty &&
        passwordController.text != password2Controller.text) {
      setState(() {
        mensaje = 'Las contraseñas no coinciden';
        esError = true;
      });
      return;
    }
    if (passwordController.text.isNotEmpty &&
        passwordController.text.length < 6) {
      setState(() {
        mensaje = 'La contraseña debe tener al menos 6 caracteres';
        esError = true;
      });
      return;
    }

    setState(() {
      guardando = true;
      mensaje = '';
    });

    try {
      final body = {
        'nombre': nombreController.text,
        'email': emailController.text,
        if (passwordController.text.isNotEmpty)
          'password': passwordController.text,
      };
      final res = await ApiService.put('/perfil', body);
      if (res['message'] != null) {
        // Actualizar nombre guardado en SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final userStr = prefs.getString('user');
        if (userStr != null) {
          final user = Map<String, dynamic>.from(jsonDecode(userStr));
          user['nombre'] = nombreController.text;
          await prefs.setString('user', jsonEncode(user));
        }
        passwordController.clear();
        password2Controller.clear();
        setState(() {
          mensaje = 'Perfil actualizado correctamente';
          esError = false;
        });
      } else {
        setState(() {
          mensaje = res['error'] ?? 'Error al guardar';
          esError = true;
        });
      }
    } catch (e) {
      setState(() {
        mensaje = 'Error al conectar con el servidor';
        esError = true;
      });
    }

    setState(() => guardando = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        backgroundColor: AppTheme.sidebarColor,
        foregroundColor: Colors.white,
        title: const Text('Perfil del taller',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: cargando
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.accentColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar y nombre
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppTheme.accentColor.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              nombreController.text.isNotEmpty
                                  ? nombreController.text
                                      .substring(0, 1)
                                      .toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                  color: AppTheme.accentColor,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(nombreController.text, style: AppTheme.titulo),
                        if (fechaCreacion.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text('Miembro desde $fechaCreacion',
                              style: AppTheme.muted),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Formulario
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: AppTheme.card(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Información del taller',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        TextField(
                          controller: nombreController,
                          style: AppTheme.cuerpo,
                          decoration: AppTheme.input(
                              'Nombre del taller', Icons.store_outlined),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: emailController,
                          style: AppTheme.cuerpo,
                          keyboardType: TextInputType.emailAddress,
                          decoration:
                              AppTheme.input('Email', Icons.email_outlined),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Cambiar contraseña
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: AppTheme.card(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Cambiar contraseña',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('Deja en blanco para no cambiarla',
                            style: AppTheme.small),
                        const SizedBox(height: 16),
                        TextField(
                          controller: passwordController,
                          obscureText: !verPassword,
                          style: AppTheme.cuerpo,
                          decoration: AppTheme.input(
                                  'Nueva contraseña', Icons.lock_outline)
                              .copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                verPassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: Colors.grey,
                              ),
                              onPressed: () =>
                                  setState(() => verPassword = !verPassword),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: password2Controller,
                          obscureText: !verPassword,
                          style: AppTheme.cuerpo,
                          decoration: AppTheme.input(
                              'Repetir contraseña', Icons.lock_outline),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Mensaje de error o éxito
                  if (mensaje.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (esError
                                ? AppTheme.dangerColor
                                : AppTheme.successColor)
                            .withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: (esError
                                  ? AppTheme.dangerColor
                                  : AppTheme.successColor)
                              .withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            esError
                                ? Icons.error_outline
                                : Icons.check_circle_outline,
                            color: esError
                                ? AppTheme.dangerColor
                                : AppTheme.successColor,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              mensaje,
                              style: TextStyle(
                                  color: esError
                                      ? AppTheme.dangerColor
                                      : AppTheme.successColor,
                                  fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Botón guardar
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: guardando ? null : guardarPerfil,
                      style: AppTheme.botonPrincipal(),
                      child: guardando
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Text('Guardar cambios',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}
