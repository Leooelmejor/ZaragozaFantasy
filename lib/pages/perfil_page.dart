// lib/pages/perfil_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app/login_page.dart';
import '../main.dart';

class PerfilPage extends StatelessWidget {
  final String nombre;
  final String correo;
  final String localidad;
  final int edad;

  const PerfilPage({
    super.key,
    required this.nombre,
    required this.correo,
    required this.localidad,
    required this.edad,
  });

  // ==============================
  // 📌 CONSTANTES
  // ==============================
  static const Color _backgroundColor = Color(0xFF7EC6E4);
  static const Color _primaryColor = Color(0xFF003366);
  static const Color _cardBackgroundColor = Colors.white;
  static const Color _logoutButtonColor = Colors.redAccent;
  static const Color _textPrimaryColor = Colors.black87;

  static const double _cardBorderRadius = 24;
  static const double _buttonBorderRadius = 12;
  static const double _profileIconSize = 100;
  static const double _titleFontSize = 22;
  static const double _labelFontSize = 16;
  static const double _valueFontSize = 16;
  static const double _buttonFontSize = 16;

  static const EdgeInsets _pagePadding = EdgeInsets.symmetric(horizontal: 24);
  static const EdgeInsets _cardPadding = EdgeInsets.all(24);
  static const EdgeInsets _buttonPadding = EdgeInsets.symmetric(vertical: 14);

  // ==============================
  // 📌 MÉTODOS DE NAVEGACIÓN
  // ==============================
  /// Cierra la sesión del usuario y navega al login
  /// Limpia todas las variables globales y resetea la pila de navegación
  void _cerrarSesion(BuildContext context) {
    // Mostrar diálogo de confirmación
    showDialog(
      context: context,
      builder: (BuildContext context) => _buildDialogoConfirmacion(context),
    );
  }

  /// Ejecuta el cierre de sesión después de la confirmación
  /// Limpia datos globales y navega al login removiendo toda la pila
  void _ejecutarCierreSesion(BuildContext context) {
    // Limpiar variables globales
    usuarioIdGlobal = 0;
    usuarioNombreGlobal = '';
    usuarioCorreoGlobal = '';
    usuarioLocalidadGlobal = '';
    usuarioEdadGlobal = 0;

    // Navegar al login y limpiar toda la pila de navegación
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
    );
  }

  // ==============================
  // 📌 WIDGETS DE CONSTRUCCIÓN
  // ==============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: _buildAppBar(),
      body: _buildCuerpo(context),
    );
  }

  /// Construye la AppBar transparente con título centrado
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      title: Text(
        "Mi Perfil",
        style: GoogleFonts.urbanist(
          fontSize: _titleFontSize,
          fontWeight: FontWeight.w600,
          color: _primaryColor,
        ),
      ),
      iconTheme: const IconThemeData(color: _primaryColor),
    );
  }

  /// Construye el cuerpo principal con la tarjeta de perfil centrada
  Widget _buildCuerpo(BuildContext context) {
    return Center(
      child: Padding(
        padding: _pagePadding,
        child: _buildTarjetaPerfil(context),
      ),
    );
  }

  /// Construye la tarjeta principal del perfil con todos los datos
  /// Incluye avatar, información personal y botón de cierre de sesión
  Widget _buildTarjetaPerfil(BuildContext context) {
    return Container(
      padding: _cardPadding,
      decoration: _buildCardDecoration(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildAvatarPerfil(),
          const SizedBox(height: 20),
          _buildInformacionPersonal(),
          const SizedBox(height: 30),
          _buildBotonCerrarSesion(context),
        ],
      ),
    );
  }

  /// Decoración de la tarjeta principal con sombra y bordes redondeados
  BoxDecoration _buildCardDecoration() {
    return BoxDecoration(
      color: _cardBackgroundColor,
      borderRadius: BorderRadius.circular(_cardBorderRadius),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.15),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  /// Construye el avatar circular del usuario con icono de perfil
  Widget _buildAvatarPerfil() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _primaryColor.withOpacity(0.1),
      ),
      padding: const EdgeInsets.all(16),
      child: const Icon(
        Icons.account_circle,
        size: _profileIconSize,
        color: _primaryColor,
      ),
    );
  }

  /// Construye toda la información personal del usuario
  /// Incluye nombre, correo, localidad y edad con sus respectivos iconos
  Widget _buildInformacionPersonal() {
    return Column(
      children: [
        _buildCampoInformacion("👤 Nombre", nombre),
        const SizedBox(height: 12),
        _buildCampoInformacion("📧 Correo", correo),
        const SizedBox(height: 12),
        _buildCampoInformacion("📍 Localidad", localidad),
        const SizedBox(height: 12),
        _buildCampoInformacion("🎂 Edad", _formatearEdad()),
      ],
    );
  }

  /// Construye un campo individual de información con etiqueta y valor
  /// Usado para mostrar cada dato del perfil de forma consistente
  Widget _buildCampoInformacion(String etiqueta, String valor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$etiqueta: ",
          style: GoogleFonts.urbanist(
            fontWeight: FontWeight.bold,
            fontSize: _labelFontSize,
            color: _primaryColor,
          ),
        ),
        Expanded(
          child: Text(
            valor,
            style: GoogleFonts.urbanist(
              fontSize: _valueFontSize,
              color: _textPrimaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  /// Construye el botón de cerrar sesión con estilo distintivo
  Widget _buildBotonCerrarSesion(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _cerrarSesion(context),
        icon: const Icon(Icons.logout, color: Colors.white),
        label: Text(
          "Cerrar sesión",
          style: GoogleFonts.urbanist(
            fontSize: _buttonFontSize,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _logoutButtonColor,
          foregroundColor: Colors.white,
          padding: _buttonPadding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_buttonBorderRadius),
          ),
          elevation: 3,
        ),
      ),
    );
  }

  /// Construye el diálogo de confirmación para cerrar sesión
  /// Incluye advertencia y botones de cancelar/confirmar
  Widget _buildDialogoConfirmacion(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.logout, color: _logoutButtonColor),
          const SizedBox(width: 8),
          const Text("Cerrar sesión"),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("¿Estás seguro de que quieres cerrar sesión?"),
          const SizedBox(height: 8),
          Text(
            "Tendrás que volver a iniciar sesión para acceder a tu cuenta.",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            "Cancelar",
            style: GoogleFonts.urbanist(
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context); // Cerrar diálogo
            _ejecutarCierreSesion(context); // Ejecutar cierre de sesión
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _logoutButtonColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            "Cerrar sesión",
            style: GoogleFonts.urbanist(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  // ==============================
  // 📌 MÉTODOS AUXILIARES
  // ==============================
  /// Formatea la edad del usuario añadiendo la palabra "años"
  /// Maneja casos donde la edad puede ser 0 o inválida
  String _formatearEdad() {
    if (edad <= 0) return "No especificada";
    return "$edad años";
  }
}