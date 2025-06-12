// lib/app/home_page.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import '../main.dart';
import '../pages/mercado.dart';
import '../pages/mis_equipos_page.dart';
import '../pages/clasificacion_page.dart';
import '../pages/ranking_page.dart';
import '../pages/perfil_page.dart';

class HomePage extends StatefulWidget {
  final String nombreUsuario;

  const HomePage({super.key, required this.nombreUsuario});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with RouteAware {
  // ==============================
  // 📌 CONSTANTES
  // ==============================
  static const Duration _animationDuration = Duration(milliseconds: 300);
  static const EdgeInsets _dashboardPadding = EdgeInsets.symmetric(horizontal: 20, vertical: 24);
  static const EdgeInsets _welcomeCardPadding = EdgeInsets.all(24);
  static const EdgeInsets _resumenCardPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 18);

  static const List<String> _titles = [
    "Inicio",
    "Mercado Jugadores",
    "Once inicial",
    "Puntos por Jornada",
    "Ranking Global",
  ];

  // ==============================
  // 📌 ESTADO DE LA APLICACIÓN
  // ==============================
  int _selectedIndex = 0;
  Map<String, dynamic>? _resumen;
  int _jornadaActual = 1;

  // ==============================
  // 📌 CONFIGURACIÓN DE RED
  // ==============================
  /// Determina la URL base según la plataforma para conectar al backend
  /// Android usa IP local de la red, otras plataformas usan localhost
  String get _baseUrl {
    return Platform.isAndroid
        ? 'http://192.168.1.132:3000'
        : 'http://localhost:3000';
  }

  // ==============================
  // 📌 CICLO DE VIDA
  // ==============================
  @override
  void initState() {
    super.initState();
    _cargarJornadaYResumen();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Suscribe a RouteObserver para detectar cuando se regresa a esta pantalla
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  /// Se ejecuta cuando el usuario regresa a esta pantalla desde otra
  /// Actualiza el resumen si está en la pestaña de inicio
  @override
  void didPopNext() {
    if (_selectedIndex == 0) {
      _cargarJornadaYResumen();
    }
  }

  // ==============================
  // 📌 LÓGICA DE DATOS
  // ==============================
  /// Carga la jornada actual y el resumen del usuario desde el backend
  /// Maneja errores de red y proporciona datos por defecto si es necesario
  Future<void> _cargarJornadaYResumen() async {
    try {
      debugPrint('🔐 usuarioIdGlobal: $usuarioIdGlobal');
      debugPrint('🌐 Solicitando jornada actual...');

      // 1. Obtener jornada actual
      final jornadaResponse = await http.get(Uri.parse('$_baseUrl/jornada-actual'));
      debugPrint('📡 Respuesta jornada: ${jornadaResponse.statusCode} - ${jornadaResponse.body}');

      if (jornadaResponse.statusCode == 200) {
        final jornadaData = json.decode(jornadaResponse.body);
        final nuevaJornada = jornadaData['jornada'] ?? 1;
        debugPrint('🧠 Jornada obtenida: $nuevaJornada');

        // 2. Obtener resumen del usuario para esa jornada
        final resumenResponse = await http.get(
          Uri.parse('$_baseUrl/resumen-inicio/$usuarioIdGlobal/$nuevaJornada'),
        );
        debugPrint('📦 Respuesta resumen: ${resumenResponse.statusCode} - ${resumenResponse.body}');

        if (resumenResponse.statusCode == 200) {
          final parsedResumen = json.decode(resumenResponse.body);
          debugPrint('✅ Resumen cargado: $parsedResumen');

          setState(() {
            _jornadaActual = nuevaJornada;
            _resumen = parsedResumen;
          });
        } else {
          _establecerResumenPorDefecto(nuevaJornada);
        }
      }
    } catch (e) {
      debugPrint('❌ Error de red: $e');
      _establecerResumenPorDefecto(1);
    }
  }

  /// Establece valores por defecto para el resumen en caso de error
  void _establecerResumenPorDefecto(int jornada) {
    debugPrint("❌ Error al cargar resumen, usando valores por defecto");
    setState(() {
      _jornadaActual = jornada;
      _resumen = {
        'fechaRegistro': '-',
        'misPuntos': 0,
        'jugadorDestacado': 'Sin datos',
        'jornadaActual': jornada,
      };
    });
  }

  // ==============================
  // 📌 NAVEGACIÓN
  // ==============================
  /// Maneja el cambio de pestañas en el BottomNavigationBar
  /// Recarga datos si se selecciona la pestaña de inicio
  void _onTabChanged(int index) {
    setState(() => _selectedIndex = index);
    if (index == 0) _cargarJornadaYResumen();
  }

  /// Navega a la pantalla de perfil del usuario
  void _navegarAPerfil() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PerfilPage(
          nombre: usuarioNombreGlobal,
          correo: usuarioCorreoGlobal,
          localidad: usuarioLocalidadGlobal,
          edad: usuarioEdadGlobal,
        ),
      ),
    );
  }

  /// Retorna el widget correspondiente según la pestaña seleccionada
  Widget _getPantalla(int index) {
    switch (index) {
      case 0:
        return _buildDashboard();
      case 1:
        return const MercadoPage();
      case 2:
        return const MiEquipoPage();
      case 3:
        return const ClasificacionPage();
      case 4:
        return const RankingPage();
      default:
        return const Center(child: Text("Pantalla no encontrada"));
    }
  }

  // ==============================
  // 📌 WIDGETS DE CONSTRUCCIÓN
  // ==============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF7EC6E4),
      appBar: _buildAppBar(),
      body: AnimatedSwitcher(
        duration: _animationDuration,
        child: _getPantalla(_selectedIndex),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  /// Construye la AppBar con título dinámico y botón de perfil
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        _titles[_selectedIndex],
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
      centerTitle: true,
      backgroundColor: const Color(0xFF003366),
      elevation: 4,
      actions: [
        IconButton(
          icon: const Icon(Icons.person),
          onPressed: _navegarAPerfil,
        ),
      ],
    );
  }

  /// Construye la barra de navegación inferior con 5 pestañas
  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: _onTabChanged,
      backgroundColor: const Color(0xFF00264D),
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white70,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
        BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_outlined), label: 'Mercado'),
        BottomNavigationBarItem(icon: Icon(Icons.sports_esports), label: 'Mi Equipo'),
        BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: 'Puntos'),
        BottomNavigationBarItem(icon: Icon(Icons.leaderboard), label: 'Ranking'),
      ],
    );
  }

  /// Construye el dashboard principal (pantalla de inicio)
  /// Muestra loading mientras carga datos, luego el resumen completo
  Widget _buildDashboard() {
    if (_resumen == null) {
      return _buildLoadingState();
    }

    return SingleChildScrollView(
      padding: _dashboardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeCard(),
          const SizedBox(height: 24),
          _buildResumenCards(),
        ],
      ),
    );
  }

  /// Muestra estado de carga mientras se obtienen los datos
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text(
            "Cargando tu resumen...",
            style: GoogleFonts.poppins(color: Colors.white),
          ),
        ],
      ),
    );
  }

  /// Construye la tarjeta de bienvenida con gradiente y saludo personalizado
  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: _welcomeCardPadding,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF003366), Color(0xFF005288)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeHeader(),
          const SizedBox(height: 12),
          _buildWelcomeDescription(),
          const SizedBox(height: 16),
          _buildAccentLine(),
        ],
      ),
    );
  }

  /// Construye el encabezado de bienvenida con icono y nombre
  Widget _buildWelcomeHeader() {
    return Row(
      children: [
        const Icon(Icons.waving_hand_rounded, color: Colors.amberAccent, size: 28),
        const SizedBox(width: 8),
        Text(
          "¡Hola, ${widget.nombreUsuario}!",
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  /// Construye la descripción con información de la jornada actual
  Widget _buildWelcomeDescription() {
    return RichText(
      text: TextSpan(
        style: GoogleFonts.poppins(fontSize: 16, color: Colors.white70),
        children: [
          const TextSpan(text: "Aquí tienes el "),
          const TextSpan(
            text: "resumen de tu jornada ",
            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
          ),
          TextSpan(
            text: "${_resumen!['jornadaActual'] ?? _jornadaActual}",
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amberAccent),
          ),
        ],
      ),
    );
  }

  /// Línea decorativa amarilla en la tarjeta de bienvenida
  Widget _buildAccentLine() {
    return Container(
      height: 2,
      width: 60,
      color: Colors.amberAccent,
    );
  }

  /// Construye todas las tarjetas de resumen (fecha, puntos, jugador destacado)
  Widget _buildResumenCards() {
    return Column(
      children: [
        _buildResumenCard(
          icon: Icons.calendar_month,
          title: "Fecha de registro",
          value: _resumen!['fechaRegistro'],
          color: Colors.indigo,
        ),
        _buildResumenCard(
          icon: Icons.bolt,
          title: "Puntos jornada ${_resumen!['jornadaActual'] ?? _jornadaActual}",
          value: _resumen!['misPuntos'].toString(),
          color: Colors.deepOrangeAccent,
        ),
        _buildResumenCard(
          icon: Icons.emoji_events,
          title: "Jugador destacado",
          value: _resumen!['jugadorDestacado'] ?? 'Sin datos',
          color: Colors.amber[800]!,
          boldValue: true,
        ),
      ],
    );
  }

  /// Construye una tarjeta individual de resumen con icono, título y valor
  /// Parámetros personalizables: icono, color, si el valor debe estar en negrita
  Widget _buildResumenCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    bool boldValue = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: _resumenCardPadding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildCardIcon(icon, color),
          const SizedBox(width: 16),
          _buildCardContent(title, value, boldValue),
        ],
      ),
    );
  }

  /// Construye el icono circular con fondo de color para cada tarjeta
  Widget _buildCardIcon(IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      padding: const EdgeInsets.all(10),
      child: Icon(icon, color: color, size: 24),
    );
  }

  /// Construye el contenido de texto de cada tarjeta (título y valor)
  Widget _buildCardContent(String title, String value, bool boldValue) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: boldValue ? FontWeight.bold : FontWeight.w600,
              color: Colors.black87,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}