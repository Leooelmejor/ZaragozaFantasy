// lib/app/registro_page.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class RegistroPage extends StatefulWidget {
  const RegistroPage({super.key});

  @override
  State<RegistroPage> createState() => _RegistroPageState();
}

class _RegistroPageState extends State<RegistroPage> {
  // ==============================
  // 📌 CONSTANTES
  // ==============================
  static const Duration _snackBarDuration = Duration(seconds: 3);
  static const EdgeInsets _containerPadding = EdgeInsets.all(14);
  static const EdgeInsets _scrollPadding = EdgeInsets.symmetric(horizontal: 24);
  static const double _maxWidth = 360;

  // ==============================
  // 📌 CONTROLADORES DE FORMULARIO
  // ==============================
  final _nombreController = TextEditingController();
  final _correoController = TextEditingController();
  final _passController = TextEditingController();
  final _localidadController = TextEditingController();
  final _edadController = TextEditingController();

  bool _cargando = false;

  // ==============================
  // 📌 CONFIGURACIÓN DE RED
  // ==============================
  /// Determina la URL base según la plataforma (Android/iOS)
  /// Android usa IP local, otros usan localhost
  String get _baseUrl {
    return Platform.isAndroid
        ? 'http://192.168.1.132:3000'
        : 'http://localhost:3000';
  }

  // ==============================
  // 📌 VALIDACIONES
  // ==============================
  /// Valida formato de correo electrónico usando expresión regular
  /// Acepta formatos estándar como usuario@dominio.com
  bool _esCorreoValido(String correo) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(correo);
  }

  /// Valida que todos los campos obligatorios estén completos
  /// Retorna mensaje de error o null si todo está correcto
  String? _validarCampos() {
    final nombre = _nombreController.text.trim();
    final correo = _correoController.text.trim();
    final pass = _passController.text.trim();
    final localidad = _localidadController.text.trim();
    final edad = int.tryParse(_edadController.text.trim()) ?? 0;

    if (nombre.isEmpty || correo.isEmpty || pass.isEmpty ||
        localidad.isEmpty || edad <= 0) {
      return 'Todos los campos son obligatorios!';
    }

    if (!_esCorreoValido(correo)) {
      return 'Introduce un correo válido!';
    }

    return null; // Sin errores
  }

  // ==============================
  // 📌 MÉTODOS DE UI
  // ==============================
  /// Muestra mensaje emergente (SnackBar) con icono y color personalizable
  /// Por defecto muestra mensajes de éxito (verde con check)
  void _mostrarMensaje(
      String texto, {
        Color color = Colors.green,
        IconData icono = Icons.check_circle,
      }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icono, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                texto,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: _snackBarDuration,
      ),
    );
  }

  // ==============================
  // 📌 LÓGICA DE REGISTRO
  // ==============================
  /// Maneja el proceso completo de registro del usuario
  /// 1. Valida campos obligatorios
  /// 2. Envía petición HTTP al backend
  /// 3. Procesa respuesta y muestra mensajes apropiados
  /// 4. Limpia formulario si el registro es exitoso
  Future<void> _registrar() async {
    setState(() => _cargando = true);

    // Validar campos antes de enviar
    final errorValidacion = _validarCampos();
    if (errorValidacion != null) {
      _mostrarMensaje(
        errorValidacion,
        color: errorValidacion.contains('correo')
            ? Colors.orange.shade800
            : Colors.red,
        icono: errorValidacion.contains('correo')
            ? Icons.warning_amber_rounded
            : Icons.error_outline,
      );
      setState(() => _cargando = false);
      return;
    }

    try {
      final response = await _enviarRegistro();

      if (!mounted) return;
      setState(() => _cargando = false);

      _procesarRespuestaRegistro(response);
    } catch (e) {
      setState(() => _cargando = false);
      _mostrarMensaje(
        'Error de conexión. Verifica tu red.',
        color: Colors.red,
        icono: Icons.wifi_off,
      );
      debugPrint('Error en registro: $e');
    }
  }

  /// Envía los datos del formulario al endpoint de registro
  /// Construye el JSON con todos los campos del usuario
  Future<http.Response> _enviarRegistro() async {
    return await http.post(
      Uri.parse('$_baseUrl/registro'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nombre': _nombreController.text.trim(),
        'correo': _correoController.text.trim(),
        'contraseña': _passController.text.trim(),
        'localidad': _localidadController.text.trim(),
        'edad': int.tryParse(_edadController.text.trim()) ?? 0,
      }),
    );
  }

  /// Procesa la respuesta del servidor y muestra mensajes apropiados
  /// - 200: Registro exitoso (limpia formulario)
  /// - 400: Usuario ya existe
  /// - Otros: Error genérico
  void _procesarRespuestaRegistro(http.Response response) {
    switch (response.statusCode) {
      case 200:
        _mostrarMensaje('Registro exitoso. Ahora puedes iniciar sesión.');
        _limpiarFormulario();
        break;
      case 400:
        _mostrarMensaje(
          'Ya existe un usuario con ese correo!',
          color: Colors.orange.shade800,
          icono: Icons.warning_amber_rounded,
        );
        break;
      default:
        _mostrarMensaje(
          'Error al registrar. Inténtalo de nuevo.',
          color: Colors.red.shade700,
          icono: Icons.error_outline,
        );
    }
  }

  /// Limpia todos los campos del formulario después de un registro exitoso
  void _limpiarFormulario() {
    _nombreController.clear();
    _correoController.clear();
    _passController.clear();
    _localidadController.clear();
    _edadController.clear();
  }

  /// Navega de regreso a la pantalla de login
  void _volverAlLogin() {
    Navigator.pop(context);
  }

  // ==============================
  // 📌 WIDGETS DE CONSTRUCCIÓN
  // ==============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: _buildGradientBackground(),
        child: Center(
          child: SingleChildScrollView(
            padding: _scrollPadding,
            child: _buildRegistroCard(),
          ),
        ),
      ),
    );
  }

  /// Crea el fondo con gradiente azul invertido respecto al login
  BoxDecoration _buildGradientBackground() {
    return const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF0077B6), Color(0xFF003366)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    );
  }

  /// Construye la tarjeta principal del formulario de registro
  /// Incluye logo, título y todos los campos del formulario
  Widget _buildRegistroCard() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: _maxWidth),
      child: Container(
        padding: _containerPadding,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.97),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLogo(),
            const SizedBox(height: 12),
            _buildTitle(),
            const SizedBox(height: 16),
            _buildFormulario(),
            const SizedBox(height: 16),
            _buildRegistroButton(),
            const SizedBox(height: 8),
            _buildVolverButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Image.asset('assets/splash/logo_splash2.png', height: 90);
  }

  Widget _buildTitle() {
    return Text(
      'Crear cuenta',
      style: GoogleFonts.urbanist(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF003366),
      ),
    );
  }

  /// Construye todos los campos del formulario de registro
  /// Cada campo tiene su icono y validación específica
  Widget _buildFormulario() {
    return Column(
      children: [
        _buildCampo('Nombre completo', _nombreController, Icons.person),
        _buildCampo('Correo electrónico', _correoController, Icons.mail),
        _buildCampo('Contraseña', _passController, Icons.lock, isPassword: true),
        _buildCampo('Localidad', _localidadController, Icons.location_city),
        _buildCampo('Edad', _edadController, Icons.cake, isNumeric: true),
      ],
    );
  }

  /// Construye un campo individual del formulario con configuración específica
  /// - isPassword: oculta el texto (para contraseñas)
  /// - isNumeric: teclado numérico (para edad)
  Widget _buildCampo(
      String label,
      TextEditingController controller,
      IconData icon, {
        bool isPassword = false,
        bool isNumeric = false,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: GoogleFonts.urbanist(),
        keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.urbanist(),
          prefixIcon: Icon(icon),
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  /// Botón principal para ejecutar el registro
  /// Muestra spinner cuando está cargando
  Widget _buildRegistroButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _cargando ? null : _registrar,
        icon: _cargando
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
            : const Icon(Icons.check, color: Colors.white),
        label: Text(
          _cargando ? 'Registrando...' : 'Aceptar',
          style: GoogleFonts.urbanist(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF003366),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  /// Botón secundario para regresar al login
  Widget _buildVolverButton() {
    return TextButton.icon(
      onPressed: _volverAlLogin,
      icon: const Icon(Icons.arrow_back, color: Color(0xFF003366)),
      label: Text(
        'Volver al inicio de sesión',
        style: GoogleFonts.urbanist(color: const Color(0xFF003366)),
      ),
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _correoController.dispose();
    _passController.dispose();
    _localidadController.dispose();
    _edadController.dispose();
    super.dispose();
  }
}