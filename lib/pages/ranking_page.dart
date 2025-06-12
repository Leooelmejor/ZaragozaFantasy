// lib/pages/ranking_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class RankingPage extends StatefulWidget {
  const RankingPage({super.key});

  @override
  State<RankingPage> createState() => _RankingPageState();
}

class _RankingPageState extends State<RankingPage> {
  // ==============================
  // 📌 CONSTANTES
  // ==============================
  static const Color _backgroundColor = Color(0xFF7EC6E4);
  static const Color _primaryColor = Color(0xFF003366);
  static const Color _cardBackgroundColor = Colors.white;
  static const Color _loadingIndicatorColor = Colors.white;

  // Colores para medallas según posición
  static const Color _goldColor = Color(0xFFFFD700);
  static const Color _silverColor = Color(0xFFC0C0C0);
  static const Color _bronzeColor = Color(0xFFCD7F32);

  static const double _cardBorderRadius = 16;
  static const double _avatarRadius = 20;
  static const double _nameFontSize = 16;
  static const double _pointsFontSize = 15;

  static const EdgeInsets _pagePadding = EdgeInsets.symmetric(horizontal: 16);
  static const EdgeInsets _cardMargin = EdgeInsets.only(bottom: 12);
  static const EdgeInsets _cardPadding = EdgeInsets.symmetric(vertical: 16, horizontal: 20);

  // ==============================
  // 📌 ESTADO DE LA APLICACIÓN
  // ==============================
  List<Map<String, dynamic>> _ranking = [];
  bool _isLoading = true;
  bool _hasError = false;

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
    _cargarRanking();
  }

  // ==============================
  // 📌 LÓGICA DE DATOS
  // ==============================
  /// Carga el ranking global de todos los usuarios desde el backend
  /// Ordena por puntos totales de todas las jornadas finalizadas
  Future<void> _cargarRanking() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      debugPrint('🏆 Cargando ranking global...');

      final response = await http.get(Uri.parse('$_baseUrl/ranking'));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);

        setState(() {
          _ranking = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });

        debugPrint('✅ Ranking cargado: ${_ranking.length} usuarios');
      } else {
        debugPrint('❌ Error del servidor: ${response.statusCode}');
        _establecerEstadoError();
      }
    } catch (e) {
      debugPrint('❌ Error al cargar ranking: $e');
      if (mounted) {
        _establecerEstadoError();
      }
    }
  }

  /// Establece el estado de error cuando no se puede cargar el ranking
  void _establecerEstadoError() {
    setState(() {
      _isLoading = false;
      _hasError = true;
    });
  }

  /// Recarga el ranking cuando el usuario hace pull-to-refresh
  Future<void> _recargarRanking() async {
    await _cargarRanking();
  }

  // ==============================
  // 📌 MÉTODOS AUXILIARES
  // ==============================
  /// Determina el color de la medalla según la posición en el ranking
  /// Oro: 1°, Plata: 2°, Bronce: 3°, Azul estándar: resto
  Color _obtenerColorPosicion(int posicion) {
    switch (posicion) {
      case 1:
        return _goldColor;
      case 2:
        return _silverColor;
      case 3:
        return _bronzeColor;
      default:
        return _primaryColor;
    }
  }

  /// Obtiene el icono apropiado según la posición en el ranking
  /// Trofeo para el podium (top 3), número para el resto
  IconData _obtenerIconoPosicion(int posicion) {
    return posicion <= 3 ? Icons.emoji_events : Icons.person;
  }

  /// Formatea los puntos para mostrar de forma consistente
  String _formatearPuntos(dynamic puntos) {
    final puntosInt = int.tryParse(puntos.toString()) ?? 0;
    return '$puntosInt pts';
  }

  // ==============================
  // 📌 WIDGETS DE CONSTRUCCIÓN
  // ==============================
  @override
  Widget build(BuildContext context) {
    return Container(
      color: _backgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            const SizedBox(height: 16),
            Expanded(child: _buildContenidoPrincipal()),
          ],
        ),
      ),
    );
  }



  /// Construye el contenido principal según el estado actual
  Widget _buildContenidoPrincipal() {
    if (_isLoading) {
      return _buildEstadoCarga();
    }

    if (_hasError) {
      return _buildEstadoError();
    }

    if (_ranking.isEmpty) {
      return _buildEstadoVacio();
    }

    return _buildListaRanking();
  }

  /// Muestra indicador de carga centrado con mensaje
  Widget _buildEstadoCarga() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: _loadingIndicatorColor),
          SizedBox(height: 16),
          Text(
            'Cargando ranking...',
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

  /// Muestra mensaje de error con opción de reintentar
  Widget _buildEstadoError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text(
            'Error al cargar el ranking',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Verifica tu conexión a internet',
            style: TextStyle(
              fontSize: 14,
              color: _primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _recargarRanking,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  /// Muestra mensaje cuando no hay usuarios en el ranking
  Widget _buildEstadoVacio() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.leaderboard_outlined,
            size: 64,
            color: _primaryColor,
          ),
          const SizedBox(height: 16),
          const Text(
            'No hay datos de ranking',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'El ranking aparecerá cuando los usuarios completen jornadas',
            style: TextStyle(
              fontSize: 14,
              color: _primaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _recargarRanking,
            icon: const Icon(Icons.refresh),
            label: const Text('Actualizar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Construye la lista scrolleable del ranking con pull-to-refresh
  Widget _buildListaRanking() {
    return RefreshIndicator(
      onRefresh: _recargarRanking,
      color: _primaryColor,
      child: ListView.builder(
        padding: _pagePadding,
        itemCount: _ranking.length,
        itemBuilder: (context, index) => _buildTarjetaUsuario(index),
      ),
    );
  }

  /// Construye la tarjeta individual de cada usuario en el ranking
  /// Muestra posición, nombre y puntos totales con colores según posición
  Widget _buildTarjetaUsuario(int index) {
    final usuario = _ranking[index];
    final posicion = index + 1;
    final colorPosicion = _obtenerColorPosicion(posicion);

    return Container(
      margin: _cardMargin,
      padding: _cardPadding,
      decoration: _buildCardDecoration(),
      child: Row(
        children: [
          _buildAvatarPosicion(posicion, colorPosicion),
          const SizedBox(width: 16),
          _buildNombreUsuario(usuario),
          _buildPuntosUsuario(usuario),
        ],
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
          offset: const Offset(0, 3),
        ),
      ],
    );
  }

  /// Construye el avatar con la posición del usuario
  /// Usa colores especiales para el podium (oro, plata, bronce)
  Widget _buildAvatarPosicion(int posicion, Color colorPosicion) {
    return CircleAvatar(
      radius: _avatarRadius,
      backgroundColor: colorPosicion.withOpacity(0.12),
      child: posicion <= 3
          ? Icon(
        Icons.emoji_events,
        color: colorPosicion,
        size: 24,
      )
          : Text(
        '#$posicion',
        style: GoogleFonts.poppins(
          color: colorPosicion,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  /// Construye el nombre del usuario con estilo consistente
  Widget _buildNombreUsuario(Map<String, dynamic> usuario) {
    return Expanded(
      child: Text(
        usuario['nombre'] ?? 'Sin nombre',
        style: GoogleFonts.poppins(
          fontSize: _nameFontSize,
          fontWeight: FontWeight.w600,
          color: _primaryColor,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  /// Construye los puntos del usuario con color destacado
  Widget _buildPuntosUsuario(Map<String, dynamic> usuario) {
    return Text(
      _formatearPuntos(usuario['puntos']),
      style: GoogleFonts.poppins(
        fontWeight: FontWeight.bold,
        fontSize: _pointsFontSize,
        color: Colors.green[700],
      ),
    );
  }
}