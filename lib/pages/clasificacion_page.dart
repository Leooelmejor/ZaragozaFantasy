// lib/pages/clasificacion_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

import '../main.dart';

class ClasificacionPage extends StatefulWidget {
  const ClasificacionPage({super.key});

  @override
  State<ClasificacionPage> createState() => _ClasificacionPageState();
}

class _ClasificacionPageState extends State<ClasificacionPage> {
  // ==============================
  // 📌 CONSTANTES
  // ==============================
  static const Color _backgroundColor = Color(0xFF7EC6E4);
  static const Color _primaryColor = Color(0xFF003366);
  static const Color _cardBackgroundColor = Colors.white;

  static const double _cardBorderRadius = 18;
  static const double _avatarRadius = 24;
  static const double _titleFontSize = 16;
  static const double _pointsFontSize = 16;

  static const EdgeInsets _pagePadding = EdgeInsets.all(16);
  static const EdgeInsets _cardPadding = EdgeInsets.symmetric(horizontal: 20, vertical: 14);
  static const EdgeInsets _cardMargin = EdgeInsets.symmetric(vertical: 10);

  // Umbrales para colores de puntos
  static const int _umbralPuntosAltos = 8;
  static const int _umbralPuntosMedios = 5;

  // ==============================
  // 📌 ESTADO DE LA APLICACIÓN
  // ==============================
  List<Map<String, dynamic>> _puntosPorJornada = [];
  bool _isLoading = true;

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
    _cargarPuntosPorJornada();
  }

  // ==============================
  // 📌 LÓGICA DE DATOS
  // ==============================
  /// Obtiene todos los puntos por jornada del usuario desde el backend
  /// Carga el historial completo de puntuación del usuario en todas las jornadas finalizadas
  Future<void> _cargarPuntosPorJornada() async {
    try {
      debugPrint('📊 Cargando puntos por jornada para usuario: $usuarioIdGlobal');

      final response = await http.get(
        Uri.parse('$_baseUrl/puntos-principal-todas/$usuarioIdGlobal'),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        debugPrint('✅ Puntos cargados: ${data.length} jornadas');

        setState(() {
          _puntosPorJornada = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      } else {
        debugPrint('❌ Error del servidor: ${response.statusCode}');
        _establecerEstadoError();
      }
    } catch (e) {
      debugPrint('❌ Error al obtener puntos por jornada: $e');
      if (mounted) {
        _establecerEstadoError();
      }
    }
  }

  /// Establece el estado de error cuando no se pueden cargar los datos
  void _establecerEstadoError() {
    setState(() {
      _puntosPorJornada = [];
      _isLoading = false;
    });
  }

  /// Recarga los datos cuando el usuario hace pull-to-refresh
  Future<void> _recargarDatos() async {
    setState(() => _isLoading = true);
    await _cargarPuntosPorJornada();
  }

  // ==============================
  // 📌 MÉTODOS AUXILIARES
  // ==============================
  /// Determina el color de los puntos según su valor
  /// Verde: 8+ puntos (excelente), Naranja: 5-7 puntos (bueno), Rojo: <5 puntos (malo)
  Color _obtenerColorPuntos(int puntos) {
    if (puntos >= _umbralPuntosAltos) return Colors.green;
    if (puntos >= _umbralPuntosMedios) return Colors.orange;
    return Colors.red;
  }

  /// Convierte de forma segura los puntos a entero
  /// Maneja casos donde los puntos pueden venir como string o ser null
  int _parsearPuntos(dynamic puntos) {
    return int.tryParse(puntos.toString()) ?? 0;
  }

  // ==============================
  // 📌 WIDGETS DE CONSTRUCCIÓN
  // ==============================
  @override
  Widget build(BuildContext context) {
    return Container(
      color: _backgroundColor,
      child: SafeArea(
        child: Padding(
          padding: _pagePadding,
          child: Column(
            children: [
              const SizedBox(height: 20),
              Expanded(child: _buildContenidoPrincipal()),
            ],
          ),
        ),
      ),
    );
  }

  /// Construye el contenido principal según el estado de carga
  /// Muestra loading, lista de puntos o mensaje de error
  Widget _buildContenidoPrincipal() {
    if (_isLoading) {
      return _buildEstadoCarga();
    }

    if (_puntosPorJornada.isEmpty) {
      return _buildEstadoVacio();
    }

    return _buildListaPuntos();
  }

  /// Muestra el indicador de carga mientras se obtienen los datos
  Widget _buildEstadoCarga() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: _primaryColor),
          SizedBox(height: 16),
          Text(
            'Cargando puntos por jornada...',
            style: TextStyle(
              color: _primaryColor,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Muestra mensaje cuando no hay datos disponibles
  Widget _buildEstadoVacio() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.emoji_events_outlined,
            size: 64,
            color: _primaryColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No hay jornadas finalizadas aún',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tus puntos aparecerán aquí cuando termine una jornada',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: _primaryColor.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Construye la lista scrolleable con los puntos de cada jornada
  /// Incluye pull-to-refresh para recargar datos
  Widget _buildListaPuntos() {
    return RefreshIndicator(
      onRefresh: _recargarDatos,
      color: _primaryColor,
      child: ListView.builder(
        itemCount: _puntosPorJornada.length,
        itemBuilder: (context, index) => _buildTarjetaJornada(index),
      ),
    );
  }

  /// Construye la tarjeta individual para cada jornada
  /// Muestra número de jornada, puntos obtenidos y color según rendimiento
  Widget _buildTarjetaJornada(int index) {
    final jornada = _puntosPorJornada[index];
    final int puntos = _parsearPuntos(jornada['puntos']);
    final Color colorPuntos = _obtenerColorPuntos(puntos);

    return Container(
      margin: _cardMargin,
      decoration: _buildCardDecoration(),
      child: ListTile(
        contentPadding: _cardPadding,
        leading: _buildAvatarJornada(),
        title: _buildTituloJornada(jornada),
        trailing: _buildPuntosJornada(puntos, colorPuntos),
      ),
    );
  }

  /// Decoración de las tarjetas con sombra y bordes redondeados
  BoxDecoration _buildCardDecoration() {
    return BoxDecoration(
      color: _cardBackgroundColor,
      borderRadius: BorderRadius.circular(_cardBorderRadius),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 6,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  /// Construye el avatar circular con ícono de fútbol para cada jornada
  Widget _buildAvatarJornada() {
    return CircleAvatar(
      radius: _avatarRadius,
      backgroundColor: _primaryColor.withOpacity(0.12),
      child: const Icon(
        Icons.sports_soccer,
        color: _primaryColor,
        size: 28,
      ),
    );
  }

  /// Construye el título con el número de jornada
  Widget _buildTituloJornada(Map<String, dynamic> jornada) {
    return Text(
      'Jornada ${jornada['jornada']}',
      style: GoogleFonts.poppins(
        fontWeight: FontWeight.w600,
        fontSize: _titleFontSize,
        color: _primaryColor,
      ),
    );
  }

  /// Construye el texto de puntos con color según rendimiento
  /// El color cambia según los umbrales definidos (verde/naranja/rojo)
  Widget _buildPuntosJornada(int puntos, Color colorPuntos) {
    return Text(
      '$puntos pts',
      style: GoogleFonts.poppins(
        fontWeight: FontWeight.bold,
        fontSize: _pointsFontSize,
        color: colorPuntos,
      ),
    );
  }
}