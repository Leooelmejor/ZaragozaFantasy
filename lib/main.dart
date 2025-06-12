// lib/main.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app/splash_screen.dart';

// ==============================
// 📌 VARIABLES GLOBALES DE USUARIO
// ==============================
/// ID único del usuario autenticado (0 = no autenticado)
/// Se asigna durante el login exitoso y se usa en toda la aplicación
int usuarioIdGlobal = 0;

/// Nombre completo del usuario para mostrar en la UI
/// Se obtiene del backend durante el login y se muestra en headers, perfil, etc.
String usuarioNombreGlobal = '';

/// Localidad/ciudad del usuario para información de perfil
/// Campo opcional que puede ser "Desconocida" si no se proporciona
String usuarioLocalidadGlobal = '';

/// Edad del usuario en años (0 = no especificada)
/// Se usa para mostrar información demográfica en el perfil
int usuarioEdadGlobal = 0;

/// Correo electrónico del usuario para identificación y perfil
/// Campo único que se usa como identificador principal en el sistema
String usuarioCorreoGlobal = '';

// ==============================
// 📌 OBSERVADOR DE RUTAS
// ==============================
/// Observador global para detectar cambios de navegación entre pantallas
/// Permite que las páginas se actualicen cuando el usuario regresa a ellas
/// Usado principalmente en HomePage para refrescar datos al volver de otras páginas
final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

/// Función principal que inicializa y ejecuta la aplicación Flutter
/// WidgetsFlutterBinding.ensureInitialized() garantiza que el framework esté listo
/// antes de ejecutar runApp()
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

/// Widget raíz de la aplicación que configura el tema global y la navegación inicial
/// Es un StatelessWidget porque la configuración de la app no cambia durante la ejecución
/// Define todos los estilos, colores y comportamientos globales de la UI
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  /// Construye la configuración principal de MaterialApp
  /// Define título, tema, observadores de navegación y pantalla inicial
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zaragoza Fantasy', // Título mostrado en el task switcher del OS
      debugShowCheckedModeBanner: false, // Oculta el banner "DEBUG" en desarrollo
      navigatorObservers: [routeObserver], // Habilita detección de cambios de ruta
      theme: _buildAppTheme(), // Aplica el tema personalizado de la aplicación
      home: const SplashScreen(), // Pantalla inicial al abrir la app
    );
  }

  // ==============================
  // 📌 TEMA DE LA APLICACIÓN
  // ==============================
  /// Construye el tema global de la aplicación con colores corporativos
  /// Define la paleta de colores, tipografías y estilos de componentes
  /// Garantiza consistencia visual en toda la aplicación
  ThemeData _buildAppTheme() {
    // Colores corporativos de la marca Zaragoza Fantasy
    const primaryColor = Color(0xFF003366);    // Azul oscuro corporativo
    const secondaryColor = Color(0xFF2ECC71);  // Verde para acciones positivas
    const backgroundColor = Color(0xFFF5F7FA); // Gris claro para fondos

    return ThemeData(
      useMaterial3: true, // Usa el sistema de diseño Material 3 más moderno
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor, // Fondo por defecto de pantallas
      fontFamily: GoogleFonts.montserrat().fontFamily, // Tipografía principal

      // Esquema de colores derivado del color primario
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
      ),

      // Configuración detallada de tipografías con Google Fonts
      textTheme: GoogleFonts.montserratTextTheme().copyWith(
        bodySmall: GoogleFonts.montserrat(fontWeight: FontWeight.w500),    // Texto pequeño
        bodyMedium: GoogleFonts.montserrat(fontWeight: FontWeight.w600),   // Texto normal
        bodyLarge: GoogleFonts.montserrat(fontWeight: FontWeight.w600),    // Texto grande
        titleMedium: GoogleFonts.montserrat(fontWeight: FontWeight.bold),  // Títulos medianos
        titleLarge: GoogleFonts.montserrat(fontWeight: FontWeight.bold),   // Títulos grandes
      ).apply(
        bodyColor: Colors.black,    // Color por defecto para texto de cuerpo
        displayColor: Colors.black, // Color por defecto para texto de display
      ),

      // Estilo global para todas las AppBars de la aplicación
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,   // Fondo azul corporativo
        elevation: 0,                   // Sin sombra para look moderno
        centerTitle: true,              // Títulos centrados
        titleTextStyle: GoogleFonts.montserrat(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,         // Texto blanco sobre fondo azul
        ),
        iconTheme: const IconThemeData(color: Colors.white), // Iconos blancos
      ),

      // Estilo global para todos los ElevatedButtons de la aplicación
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: secondaryColor,  // Fondo verde para acciones
          foregroundColor: Colors.white,    // Texto blanco
          textStyle: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), // Bordes redondeados modernos
          ),
        ),
      ),
    );
  }
}