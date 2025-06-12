// lib/app/login_page.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import '../main.dart';
import 'home_page.dart';
import 'registro_page.dart';

/// Página de autenticación principal de la aplicación
/// Permite a usuarios existentes acceder con sus credenciales
/// Es la puerta de entrada después del splash screen
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // ==============================
  // 📌 CONSTANTES
  // ==============================
  static const Duration _snackBarDuration = Duration(seconds: 3);
  static const EdgeInsets _containerPadding = EdgeInsets.all(28);
  static const EdgeInsets _scrollPadding = EdgeInsets.symmetric(horizontal: 30);

  // ==============================
  // 📌 CONTROLADORES Y ESTADO
  // ==============================
  final _correoController = TextEditingController();
  final _passController = TextEditingController();
  bool _cargando = false;

  // ==============================
  // 📌 CONFIGURACIÓN DE RED
  // ==============================
  /// Detecta automáticamente la plataforma y retorna la URL correcta del backend
  /// Android usa IP local (192.168.1.132) para dispositivos reales
  /// Otras plataformas usan localhost para emuladores/web
  String get _baseUrl {
    return Platform.isAndroid
        ? 'http://192.168.1.132:3000'
        : 'http://localhost:3000';
  }

  // ==============================
  // 📌 MÉTODOS DE UI
  // ==============================
  /// Muestra notificaciones tipo SnackBar personalizables al usuario
  /// Usado para errores de login, problemas de conexión, etc.
  /// [texto] Mensaje a mostrar
  /// [color] Color de fondo del SnackBar (por defecto rojo para errores)
  /// [icono] Icono a mostrar junto al mensaje
  void _mostrarMensaje(
      String texto, {
        Color color = Colors.red,
        IconData icono = Icons.error_outline,
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
  // 📌 LÓGICA DE AUTENTICACIÓN
  // ==============================
  /// Ejecuta el proceso completo de autenticación con el backend
  /// 1. Activa estado de carga
  /// 2. Envía credenciales al backend via POST
  /// 3. Maneja respuesta exitosa o muestra errores
  /// 4. Desactiva estado de carga
  Future<void> _login() async {
    setState(() => _cargando = true);

    try {
      // Enviar credenciales al backend
      final response = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'correo': _correoController.text.trim(),
          'contraseña': _passController.text.trim(),
        }),
      );

      // Verificar que el widget aún esté montado antes de actualizar estado
      if (!mounted) return;
      setState(() => _cargando = false);

      if (response.statusCode == 200) {
        // Login exitoso - procesar respuesta
        _handleLoginSuccess(response.body);
      } else {
        // Credenciales incorrectas
        _mostrarMensaje(
          'Credenciales incorrectas!',
          icono: Icons.lock_outline,
        );
      }
    } catch (e) {
      // Error de conexión o red
      setState(() => _cargando = false);
      _mostrarMensaje(
        'Error de conexión. Verifica tu red.',
        icono: Icons.wifi_off,
      );
      debugPrint('Error en login: $e');
    }
  }

  /// Procesa una respuesta exitosa del backend después del login
  /// 1. Parsea JSON de respuesta
  /// 2. Almacena datos del usuario en variables globales
  /// 3. Navega a HomePage reemplazando la ruta actual para evitar retorno
  void _handleLoginSuccess(String responseBody) {
    final user = jsonDecode(responseBody);

    // Guardar datos del usuario en variables globales
    usuarioIdGlobal = int.tryParse(user['id'].toString()) ?? 0;
    usuarioNombreGlobal = user['nombre'];
    usuarioCorreoGlobal = user['correo'];
    usuarioLocalidadGlobal = user['localidad'] ?? 'Desconocida';
    usuarioEdadGlobal = user['edad'] ?? 0;

    // Navegar a pantalla principal y reemplazar ruta para evitar volver al login
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => HomePage(nombreUsuario: usuarioNombreGlobal),
      ),
    );
  }

  /// Navega a la pantalla de registro de nuevos usuarios
  /// Usa push normal para permitir retorno al login
  void _navegarARegistro() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegistroPage()),
    );
  }

  // ==============================
  // 📌 WIDGETS DE CONSTRUCCIÓN
  // ==============================
  /// Construye la estructura principal de la pantalla de login
  /// Fondo con gradiente, contenido centrado y scrolleable para adaptarse a diferentes pantallas
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: _buildGradientBackground(),
        child: Center(
          child: SingleChildScrollView(
            padding: _scrollPadding,
            child: _buildLoginCard(),
          ),
        ),
      ),
    );
  }

  /// Crea el fondo con gradiente azul corporativo
  /// Gradiente vertical de azul oscuro a azul medio para dar profundidad
  BoxDecoration _buildGradientBackground() {
    return const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF003366), Color(0xFF0077B6)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    );
  }

  /// Construye el contenedor principal del formulario de login
  /// Tarjeta blanca flotante con sombra y bordes redondeados
  /// Contiene logo, título, campos de entrada y botones
  Widget _buildLoginCard() {
    return Container(
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
          const SizedBox(height: 16),
          _buildTitle(),
          const SizedBox(height: 30),
          _buildCorreoField(),
          const SizedBox(height: 16),
          _buildPasswordField(),
          const SizedBox(height: 24),
          _buildLoginButton(),
          const SizedBox(height: 12),
          _buildRegistroButton(),
        ],
      ),
    );
  }

  /// Muestra el logo de la aplicación
  /// Asset ubicado en assets/splash/logo_splash2.png con altura fija de 120px
  Widget _buildLogo() {
    return Image.asset('assets/splash/logo_splash2.png', height: 120);
  }

  /// Construye el título "Zaragoza Fantasy" con estilo corporativo
  /// Usa Google Fonts Urbanist para consistencia visual
  Widget _buildTitle() {
    return Text(
      'Zaragoza Fantasy',
      style: GoogleFonts.urbanist(
        fontSize: 26,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF003366),
      ),
    );
  }

  /// Campo de entrada para el correo electrónico
  /// Incluye icono de mail, fondo gris claro y bordes redondeados
  /// Conectado al controlador _correoController para gestión de estado
  Widget _buildCorreoField() {
    return TextField(
      controller: _correoController,
      style: GoogleFonts.urbanist(),
      decoration: InputDecoration(
        labelText: 'Correo electrónico',
        labelStyle: GoogleFonts.urbanist(),
        prefixIcon: const Icon(Icons.mail_outline),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  /// Campo de entrada para la contraseña
  /// obscureText: true oculta el texto por seguridad
  /// Icono de candado para indicar campo de seguridad
  Widget _buildPasswordField() {
    return TextField(
      controller: _passController,
      obscureText: true,
      style: GoogleFonts.urbanist(),
      decoration: InputDecoration(
        labelText: 'Contraseña',
        labelStyle: GoogleFonts.urbanist(),
        prefixIcon: const Icon(Icons.lock_outline),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  /// Botón principal para ejecutar el proceso de login
  /// Estados: Normal muestra "Iniciar sesión", Cargando muestra spinner
  /// Se deshabilita durante la carga para evitar múltiples requests
  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _cargando ? null : _login,
        icon: _cargando
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
            : const Icon(Icons.login),
        label: Text(
          _cargando ? 'Accediendo...' : 'Iniciar sesión',
          style: GoogleFonts.urbanist(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF003366),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  /// Botón secundario para navegar a la pantalla de registro
  /// Color azul más claro para diferenciarlo del botón principal
  /// Permite a nuevos usuarios crear una cuenta
  Widget _buildRegistroButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _navegarARegistro,
        icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
        label: Text(
          'Registrarse',
          style: GoogleFonts.urbanist(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0077B6),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  /// Libera recursos cuando el widget se destruye
  /// Importante para evitar memory leaks con los controladores de texto
  @override
  void dispose() {
    _correoController.dispose();
    _passController.dispose();
    super.dispose();
  }
}