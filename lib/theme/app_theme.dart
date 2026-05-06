import 'package:flutter/material.dart';

class AppTheme {
  // ─── COLORES ───────────────────────────────────────────────
  static const Color bgColor = Color(0xFF1A1A1A);
  static const Color cardColor = Color(0xFF2A2A2A);
  static const Color inputColor = Color(0xFF333333);
  static const Color accentColor = Color(0xFFE67E22);
  static const Color sidebarColor = Color(0xFF2C3E50);
  static const Color successColor = Color(0xFF27AE60);
  static const Color dangerColor = Color(0xFFE74C3C);
  static const Color infoColor = Color(0xFF2980B9);
  static const Color warningColor = Color(0xFFF39C12);

  // ─── TEXTOS ────────────────────────────────────────────────
  static const TextStyle titulo = TextStyle(
    color: Colors.white,
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );
  static const TextStyle subtitulo = TextStyle(
    color: Colors.white,
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );
  static const TextStyle cuerpo = TextStyle(color: Colors.white, fontSize: 14);
  static const TextStyle muted = TextStyle(color: Colors.grey, fontSize: 13);
  static const TextStyle small = TextStyle(color: Colors.grey, fontSize: 11);
  static const TextStyle accent = TextStyle(
    color: accentColor,
    fontSize: 13,
    fontWeight: FontWeight.bold,
  );
  static const TextStyle success = TextStyle(
    color: successColor,
    fontSize: 13,
    fontWeight: FontWeight.bold,
  );
  static const TextStyle danger = TextStyle(color: dangerColor, fontSize: 13);

  // ─── TARJETAS ──────────────────────────────────────────────
  static BoxDecoration card({Color? borderColor}) => BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: borderColor != null
            ? Border.all(color: borderColor.withOpacity(0.3))
            : null,
      );

  static BoxDecoration accentCard() => BoxDecoration(
        gradient: LinearGradient(
          colors: [accentColor.withOpacity(0.3), accentColor.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withOpacity(0.2)),
      );

  static BoxDecoration colorCard(Color color) => BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      );

  // ─── INPUTS ────────────────────────────────────────────────
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

  static InputDecoration searchInput(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: muted,
        prefixIcon: const Icon(Icons.search, color: Colors.grey),
        filled: true,
        fillColor: cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      );

  // ─── BOTONES ───────────────────────────────────────────────
  static ButtonStyle botonPrincipal() => ElevatedButton.styleFrom(
        backgroundColor: accentColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      );

  static ButtonStyle botonPeligro() => ElevatedButton.styleFrom(
        backgroundColor: dangerColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      );

  // ─── CHIPS DE ESTADO ───────────────────────────────────────
  static Color estadoColor(String? estado) {
    switch (estado) {
      case 'pendiente':
        return warningColor;
      case 'en_proceso':
        return infoColor;
      case 'finalizada':
        return successColor;
      default:
        return Colors.grey;
    }
  }

  static String estadoTexto(String? estado) {
    switch (estado) {
      case 'pendiente':
        return 'Pendiente';
      case 'en_proceso':
        return 'En proceso';
      case 'finalizada':
        return 'Finalizada';
      default:
        return estado ?? '';
    }
  }

  static Widget estadoChip(String? estado) {
    final color = estadoColor(estado);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        estadoTexto(estado),
        style:
            TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  // ─── ICONO DE AVATAR ───────────────────────────────────────
  static Widget avatar(String nombre) => CircleAvatar(
        backgroundColor: accentColor.withOpacity(0.2),
        child: Text(
          nombre.isNotEmpty ? nombre.substring(0, 1).toUpperCase() : '?',
          style:
              const TextStyle(color: accentColor, fontWeight: FontWeight.bold),
        ),
      );

  static Widget vehiculoIcon() => Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: accentColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.directions_car, color: accentColor, size: 22),
      );

  // ─── TARJETA DE ESTADÍSTICA ────────────────────────────────
  static Widget statCard(
      String titulo, String valor, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: colorCard(color),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: small),
                Text(valor,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── DIÁLOGO DE CONFIRMACIÓN ───────────────────────────────
  static Future<bool> confirmarEliminar(
      BuildContext context, String titulo) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardColor,
        title: Text('Eliminar $titulo',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        content: Text('¿Estás seguro? Esta acción no se puede deshacer.',
            style: muted),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar', style: muted),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Eliminar', style: TextStyle(color: dangerColor)),
          ),
        ],
      ),
    );
    return result == true;
  }

  // ─── MODAL BOTTOM SHEET ────────────────────────────────────
  static Future<void> mostrarModal(BuildContext context, Widget child) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: child,
      ),
    );
  }

  // ─── SELECTOR DE FECHA ─────────────────────────────────────
  static Widget selectorFecha(DateTime? fecha, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: inputColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(children: [
          const Icon(Icons.calendar_today_outlined,
              color: Colors.grey, size: 20),
          const SizedBox(width: 12),
          Text(
            fecha != null
                ? '${fecha.day}/${fecha.month}/${fecha.year}'
                : 'Seleccionar fecha *',
            style: TextStyle(color: fecha != null ? Colors.white : Colors.grey),
          ),
        ]),
      ),
    );
  }

  // ─── SELECTOR DE HORA ──────────────────────────────────────
  static Widget selectorHora(TimeOfDay? hora, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: inputColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(children: [
          const Icon(Icons.access_time_outlined, color: Colors.grey, size: 20),
          const SizedBox(width: 12),
          Text(
            hora != null
                ? '${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}'
                : 'Seleccionar hora *',
            style: TextStyle(color: hora != null ? Colors.white : Colors.grey),
          ),
        ]),
      ),
    );
  }

  // ─── TARJETA DE COSTE TOTAL ────────────────────────────────
  static Widget totalIVA(double total) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: successColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: successColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Total con IVA (21%):',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          Text('${total.toStringAsFixed(2)} €',
              style: TextStyle(
                  color: successColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
        ],
      ),
    );
  }
}
