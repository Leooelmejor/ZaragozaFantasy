// lib/app/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_page.dart';

/// Pantalla de carga inicial de la aplicación (Splash Screen)
/// Se muestra durante 3 segundos con animación de fade-in
/// Proporciona una experiencia de marca profesional antes del login
/// Usa SingleTickerProviderStateMixin para controlar animaciones
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  // ==============================
  // 📌 CONSTANTES DE CONFIGURACIÓN
  // ==============================
  /// Duración de la animación de fade-in del contenido (1.2 segundos)
  static const Duration _animationDuration = Duration(milliseconds: 1200);

  /// Tiempo total que permanece visible el splash screen (3 segundos)
  static const Duration _splashDuration = Duration(seconds: 3);

  /// Duración de la transición hacia la pantalla de login (0.6 segundos)
  static const Duration _transitionDuration = Duration(milliseconds: 600);

  // ==============================
  // 📌 CONTROLADORES DE ANIMACIÓN
  // ==============================
  /// Controla la animación de fade-in de todo el contenido
  late AnimationController _controller;

  /// Animación que gestiona la opacidad del fade-in con curva suave
  late Animation<double> _fadeIn;

  // ==============================
  // 📌 CICLO DE VIDA
  // ==============================
  /// Inicializa las animaciones y programa la navegación al login
  /// Se ejecuta una sola vez cuando se crea el widget
  @override
  void initState() {
    super.initState();
    _initAnimation();
    _navigateToLogin();
  }

  /// Configura el controlador de animación y la animación de fade-in
  /// Usa curva easeIn para un inicio suave y natural
  /// Inicia inmediatamente la animación hacia adelante
  void _initAnimation() {
    _controller = AnimationController(
      vsync: this, // Sincronización con el refresh rate de la pantalla
      duration: _animationDuration,
    );
    _fadeIn = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn, // Curva que inicia lento y acelera
    );
    _controller.forward(); // Inicia la animación inmediatamente
  }

  /// Programa la navegación automática al login después de 3 segundos
  /// Usa PageRouteBuilder para crear una transición personalizada con fade
  /// Verifica 'mounted' para evitar errores si el widget se destruye antes
  void _navigateToLogin() {
    Future.delayed(_splashDuration, () {
      // Verificar que el widget aún existe antes de navegar
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            // Constructor de la nueva página (LoginPage)
            pageBuilder: (_, __, ___) => const LoginPage(),
            // Constructor de la transición personalizada (fade)
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: _transitionDuration,
          ),
        );
      }
    });
  }

  /// Libera el controlador de animación cuando el widget se destruye
  /// Previene memory leaks y errores de animación
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ==============================
  // 📌 WIDGETS DE CONSTRUCCIÓN
  // ==============================
  /// Construye la estructura principal del splash screen
  /// Fondo azul corporativo con contenido centrado y animado
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF003366), // Azul corporativo de la marca
      body: Center(
        child: FadeTransition(
          opacity: _fadeIn, // Aplica la animación de fade-in
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLogo(),
              const SizedBox(height: 24),
              _buildTitle(),
              const SizedBox(height: 16),
              _buildProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }

  /// Construye el logo de la aplicación con sombra y bordes redondeados
  /// Tamaño fijo de 150x150px para mantener proporciones
  /// Sombra negra con opacidad para dar profundidad visual
  Widget _buildLogo() {
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3), // Sombra sutil
            blurRadius: 10, // Difuminado de la sombra
            offset: const Offset(0, 5), // Desplazamiento hacia abajo
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20), // Bordes redondeados
        child: Image.asset(
          'assets/splash/logo_splash.png',
          fit: BoxFit.contain, // Mantiene proporciones del logo
        ),
      ),
    );
  }

  /// Construye el título "Zaragoza Fantasy" con tipografía elegante
  /// Usa Google Fonts Poppins para dar personalidad a la marca
  /// Color blanco para contrastar con el fondo azul
  Widget _buildTitle() {
    return Text(
      'Zaragoza Fantasy',
      style: GoogleFonts.poppins(
        fontSize: 26,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  /// Construye el indicador de progreso linear minimalista
  /// Ancho fijo de 100px para proporcionalidad visual
  /// Colores que contrastan con el fondo para visibilidad
  Widget _buildProgressIndicator() {
    return const SizedBox(
      width: 100,
      child: LinearProgressIndicator(
        color: Colors.white, // Barra de progreso blanca
        backgroundColor: Colors.white24, // Fondo semi-transparente
      ),
    );
  }
}