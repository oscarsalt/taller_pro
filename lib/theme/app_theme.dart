import 'package:flutter/material.dart';

class AppTheme {
  // Colores
  static const Color bgColor = Color(0xFF1A1A1A);
  static const Color cardColor = Color(0xFF2A2A2A);
  static const Color inputColor = Color(0xFF333333);
  static const Color accentColor = Color(0xFFE67E22);
  static const Color sidebarColor = Color(0xFF2C3E50);
  static const Color successColor = Color(0xFF27AE60);
  static const Color dangerColor = Color(0xFFE74C3C);
  static const Color infoColor = Color(0xFF2980B9);
  static const Color warningColor = Color(0xFFF39C12);

  // Estilos de texto
  static const TextStyle titulo =
      TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold);
  static const TextStyle subtitulo =
      TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold);
  static const TextStyle cuerpo = TextStyle(color: Colors.white, fontSize: 14);
  static const TextStyle muted = TextStyle(color: Colors.grey, fontSize: 13);
  static const TextStyle small = TextStyle(color: Colors.grey, fontSize: 11);

  // Decoraciones de tarjeta
  static BoxDecoration card({Color? borderColor}) => BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: borderColor != null
            ? Border.all(color: borderColor.withOpacity(0.2))
            : null,
      );

  // Decoración de input
  static InputDecoration input(String label, IconData icon) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: Colors.grey),
        filled: true,
        fillColor: inputColor,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.transparent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: accentColor),
        ),
      );

  // Estilo de botón principal
  static ButtonStyle botonPrincipal() => ElevatedButton.styleFrom(
        backgroundColor: accentColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      );
}
