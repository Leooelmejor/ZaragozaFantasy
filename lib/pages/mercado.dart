// lib/pages/mercado.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';

import '../main.dart';
import '../utils/iconos.dart';

class MercadoPage extends StatefulWidget {
  const MercadoPage({super.key});

  @override
  State<MercadoPage> createState() => _MercadoPageState();
}

class _MercadoPageState extends State<MercadoPage> {
  // ==============================
  // 📌 CONSTANTES
  // ==============================
  static const Color _backgroundColor = Color(0xFF7EC6E4);
  static const Color _cardBackgroundColor = Colors.white;
  static const Color _primaryTextColor = Colors.black87;
  static const Color _accentColor = Colors.amber;

  static const double _cardBorderRadius = 12;
  static const double _containerBorderRadius = 12;
  static const double _titleFontSize = 16;
  static const double _subtitleFontSize = 13;
  static const int _precioPorDefecto = 100;

  static const Duration _snackBarDuration = Duration(seconds: 3);
  static const EdgeInsets _pagePadding = EdgeInsets.all(16);
  static const EdgeInsets _cardMargin = EdgeInsets.symmetric(vertical: 6);
  static const EdgeInsets _dropdownPadding = EdgeInsets.symmetric(horizontal: 12);

  // ==============================
  // 📌 ESTADO DE LA APLICACIÓN
  // ==============================
  List<Map<String, dynamic>> _equipos = [];
  List<Map<String, dynamic>> _jugadores = [];
  Set<int> _jugadoresComprados = <int>{};
  int? _equipoSeleccionadoId;
  int _monedasDisponibles = 0;
  bool _intentadoCargar = false;
  bool _isLoading = false;

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
    _inicializarDatos();
  }

  /// Inicializa todos los datos necesarios para el mercado
  /// Carga monedas, equipos y jugadores comprados en paralelo
  Future<void> _inicializarDatos() async {
    setState(() => _isLoading = true);

    await Future.wait([
      _cargarMonedas(),
      _cargarEquipos(),
      _cargarJugadoresComprados(),
    ]);

    setState(() => _isLoading = false);
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
          borderRadius: BorderRadius.circular(_cardBorderRadius),
        ),
        duration: _snackBarDuration,
      ),
    );
  }

  // ==============================
  // 📌 LÓGICA DE DATOS
  // ==============================
  /// Carga las monedas disponibles del usuario desde el backend
  /// Actualiza el contador de monedas en tiempo real
  Future<void> _cargarMonedas() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/monedas/$usuarioIdGlobal'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('🪙 Monedas actualizadas desde backend: ${data['monedas']}');

        if (mounted) {
          setState(() {
            _monedasDisponibles = data['monedas'] ?? 0;
          });
        }
      }
    } catch (e) {
      debugPrint('Error cargando monedas: $e');
      _mostrarMensaje(
        'Error al cargar las monedas',
        color: Colors.red,
        icono: Icons.error_outline,
      );
    }
  }

  /// Carga la lista de equipos reales disponibles
  /// Selecciona automáticamente el primer equipo si existe
  Future<void> _cargarEquipos() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/equipos'));

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);

        if (mounted) {
          setState(() {
            _equipos = List<Map<String, dynamic>>.from(data);
          });

          // Seleccionar primer equipo automáticamente
          if (_equipos.isNotEmpty) {
            setState(() {
              _equipoSeleccionadoId = _equipos[0]['id'];
            });
            await _cargarJugadoresDelEquipo(_equipos[0]['id']);
          }
        }
      }
    } catch (e) {
      debugPrint('Error cargando equipos: $e');
      _mostrarMensaje(
        'Error al cargar los equipos',
        color: Colors.red,
        icono: Icons.error_outline,
      );
    }
  }

  /// Carga todos los jugadores de un equipo específico
  /// Actualiza la lista de jugadores disponibles para comprar
  Future<void> _cargarJugadoresDelEquipo(int equipoId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/jugadores/$equipoId'),
      );

      setState(() => _intentadoCargar = true);

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);

        if (mounted) {
          setState(() {
            _jugadores = List<Map<String, dynamic>>.from(data);
          });
        }
      } else {
        if (mounted) {
          setState(() => _jugadores = []);
          _mostrarMensaje(
            'No hay jugadores en este equipo',
            color: Colors.orange,
            icono: Icons.warning_amber_rounded,
          );
        }
      }
    } catch (e) {
      debugPrint('Error cargando jugadores: $e');
      if (mounted) {
        setState(() => _jugadores = []);
        _mostrarMensaje(
          'Error al cargar jugadores',
          color: Colors.red,
          icono: Icons.error_outline,
        );
      }
    }
  }

  /// Carga la lista de jugadores que ya posee el usuario
  /// Marca estos jugadores como comprados en la interfaz
  Future<void> _cargarJugadoresComprados() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/jugadores-en-propiedad/$usuarioIdGlobal'),
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);

        if (mounted) {
          setState(() {
            _jugadoresComprados = data
                .map<int>((jugador) => jugador['jugador_id'] as int)
                .toSet();
          });
        }
      }
    } catch (e) {
      debugPrint('Error cargando jugadores comprados: $e');
      _mostrarMensaje(
        'Error al cargar tus jugadores',
        color: Colors.red,
        icono: Icons.error_outline,
      );
    }
  }

  // ==============================
  // 📌 LÓGICA DE COMPRA
  // ==============================
  /// Maneja el proceso completo de compra de un jugador
  /// Incluye validaciones, confirmación y actualización de estado
  Future<void> _comprarJugador(Map<String, dynamic> jugador) async {
    final int precio = jugador['precio'] ?? _precioPorDefecto;
    final int jugadorId = jugador['id'];

    // Verificar si ya está comprado
    if (_jugadoresComprados.contains(jugadorId)) {
      _mostrarMensaje(
        'Ya has comprado este jugador',
        color: Colors.orange,
        icono: Icons.warning_amber_rounded,
      );
      return;
    }

    // Verificar si tiene suficientes monedas
    if (_monedasDisponibles < precio) {
      _mostrarMensaje(
        'No tienes suficientes monedas',
        color: Colors.red,
        icono: Icons.error_outline,
      );
      return;
    }

    try {
      final response = await _enviarCompra(jugadorId, precio);
      await _procesarRespuestaCompra(response, jugador, precio, jugadorId);
    } catch (e) {
      debugPrint('Error al comprar jugador: $e');
      _mostrarMensaje(
        'Error de conexión',
        color: Colors.red,
        icono: Icons.error_outline,
      );
    }
  }

  /// Envía la petición de compra al backend
  Future<http.Response> _enviarCompra(int jugadorId, int precio) async {
    return await http.post(
      Uri.parse('$_baseUrl/comprar-jugador'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'usuarioId': usuarioIdGlobal,
        'jugadorId': jugadorId,
        'precio': precio,
      }),
    );
  }

  /// Procesa la respuesta del servidor después de intentar comprar
  /// Maneja diferentes códigos de estado y actualiza la UI accordingly
  Future<void> _procesarRespuestaCompra(
      http.Response response,
      Map<String, dynamic> jugador,
      int precio,
      int jugadorId,
      ) async {
    if (response.statusCode == 200) {
      // Compra exitosa
      await _cargarMonedas(); // Actualizar monedas
      setState(() {
        _jugadoresComprados.add(jugadorId);
      });
      _mostrarMensaje('${jugador['nombre']} comprado por $precio monedas');
    } else {
      // Error en la compra
      _manejarErrorCompra(response);
    }
  }

  /// Maneja los errores específicos de compra según la respuesta del servidor
  void _manejarErrorCompra(http.Response response) {
    try {
      final data = jsonDecode(response.body);

      if (data['requiereEquipoInicial'] == true) {
        _mostrarMensaje(
          data['error'] ?? 'Debes crear tu equipo inicial antes de poder comprar jugadores en el mercado.',
          color: Colors.red,
          icono: Icons.warning_amber_rounded,
        );
      } else {
        _mostrarMensaje(
          data['error'] ?? 'Error desconocido al comprar jugador',
          color: Colors.red,
          icono: Icons.error_outline,
        );
      }
    } catch (e) {
      _mostrarMensaje(
        'Error inesperado: ${response.body}',
        color: Colors.red,
        icono: Icons.error_outline,
      );
    }
  }

  /// Muestra diálogo de confirmación antes de comprar un jugador
  /// Retorna true si el usuario confirma la compra
  Future<bool> _mostrarDialogoConfirmacion(
      Map<String, dynamic> jugador,
      int precio,
      ) async {
    final bool? confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Confirmar compra?'),
        content: Text(
          '¿Seguro que quieres comprar a ${jugador['nombre']} por $precio monedas?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Comprar'),
          ),
        ],
      ),
    );

    return confirmado ?? false;
  }

  // ==============================
  // 📌 MÉTODOS AUXILIARES
  // ==============================
  /// Maneja el cambio de equipo seleccionado en el dropdown
  void _onEquipoSeleccionado(int? nuevoEquipoId) {
    if (nuevoEquipoId != null) {
      setState(() {
        _equipoSeleccionadoId = nuevoEquipoId;
      });
      _cargarJugadoresDelEquipo(nuevoEquipoId);
    }
  }

  /// Verifica si un jugador específico ya ha sido comprado
  bool _estaComprado(int jugadorId) {
    return _jugadoresComprados.contains(jugadorId);
  }

  // ==============================
  // 📌 WIDGETS DE CONSTRUCCIÓN
  // ==============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Padding(
        padding: _pagePadding,
        child: Column(
          children: [
            _buildEncabezadoMonedas(),
            const SizedBox(height: 16),
            _buildSelectorEquipos(),
            const SizedBox(height: 10),
            Expanded(child: _buildContenidoPrincipal()),
          ],
        ),
      ),
    );
  }

  /// Construye el encabezado con el contador de monedas del usuario
  Widget _buildEncabezadoMonedas() {
    return Row(
      children: [
        const Icon(Icons.monetization_on, color: _accentColor),
        const SizedBox(width: 8),
        Text(
          'Monedas: $_monedasDisponibles',
          style: GoogleFonts.urbanist(
            fontWeight: FontWeight.bold,
            fontSize: _titleFontSize,
            color: _primaryTextColor,
          ),
        ),
      ],
    );
  }

  /// Construye el selector desplegable de equipos
  Widget _buildSelectorEquipos() {
    return Container(
      padding: _dropdownPadding,
      decoration: BoxDecoration(
        color: _cardBackgroundColor,
        borderRadius: BorderRadius.circular(_containerBorderRadius),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _equipoSeleccionadoId,
          hint: Text(
            'Selecciona un equipo real',
            style: GoogleFonts.urbanist(),
          ),
          isExpanded: true,
          items: _equipos.map<DropdownMenuItem<int>>((equipo) {
            return DropdownMenuItem<int>(
              value: equipo['id'],
              child: Text(
                equipo['nombre'],
                style: GoogleFonts.urbanist(),
              ),
            );
          }).toList(),
          onChanged: _onEquipoSeleccionado,
        ),
      ),
    );
  }

  /// Construye el contenido principal según el estado actual
  Widget _buildContenidoPrincipal() {
    if (_isLoading) {
      return _buildEstadoCarga();
    }

    if (_jugadores.isEmpty && _intentadoCargar) {
      return _buildEstadoVacio();
    }

    return _buildListaJugadores();
  }

  /// Muestra indicador de carga mientras se obtienen los datos
  Widget _buildEstadoCarga() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Cargando mercado...'),
        ],
      ),
    );
  }

  /// Muestra mensaje cuando no hay jugadores en el equipo seleccionado
  Widget _buildEstadoVacio() {
    return Center(
      child: Text(
        '⚠️ No hay jugadores para este equipo',
        style: GoogleFonts.urbanist(color: _primaryTextColor),
      ),
    );
  }

  /// Construye la lista scrolleable de jugadores disponibles
  Widget _buildListaJugadores() {
    return ListView.builder(
      itemCount: _jugadores.length,
      itemBuilder: (context, index) => _buildTarjetaJugador(_jugadores[index]),
    );
  }

  /// Construye la tarjeta individual de cada jugador
  /// Muestra información del jugador y botón de compra
  Widget _buildTarjetaJugador(Map<String, dynamic> jugador) {
    final bool comprado = _estaComprado(jugador['id']);
    final int precio = jugador['precio'] ?? _precioPorDefecto;

    return Card(
      color: _cardBackgroundColor,
      margin: _cardMargin,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_cardBorderRadius),
      ),
      child: ListTile(
        leading: _buildAvatarJugador(jugador),
        title: _buildNombreJugador(jugador),
        subtitle: _buildInfoJugador(jugador, precio),
        trailing: _buildAccionJugador(jugador, comprado),
      ),
    );
  }

  /// Construye el avatar del jugador con icono según su posición
  Widget _buildAvatarJugador(Map<String, dynamic> jugador) {
    return CircleAvatar(
      backgroundColor: Colors.blue.shade100,
      child: Text(obtenerIcono(jugador['posicion'])),
    );
  }

  /// Construye el nombre del jugador
  Widget _buildNombreJugador(Map<String, dynamic> jugador) {
    return Text(
      jugador['nombre'],
      style: GoogleFonts.urbanist(fontWeight: FontWeight.w600),
    );
  }

  /// Construye la información del jugador (posición y precio)
  Widget _buildInfoJugador(Map<String, dynamic> jugador, int precio) {
    return Text(
      'Posición: ${jugador['posicion']} • Precio: $precio monedas',
      style: GoogleFonts.urbanist(fontSize: _subtitleFontSize),
    );
  }

  /// Construye la acción del jugador (comprado o botón de compra)
  Widget _buildAccionJugador(Map<String, dynamic> jugador, bool comprado) {
    if (comprado) {
      return const Icon(Icons.check_circle, color: Colors.green);
    }

    return ElevatedButton(
      onPressed: () async {
        final int precio = jugador['precio'] ?? _precioPorDefecto;
        final bool confirmado = await _mostrarDialogoConfirmacion(jugador, precio);

        if (confirmado) {
          await _comprarJugador(jugador);
        }
      },
      child: const Text('Comprar'),
    );
  }
}