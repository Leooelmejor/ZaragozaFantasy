// lib/pages/mis_equipos_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../main.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';

class MiEquipoPage extends StatefulWidget {
  const MiEquipoPage({super.key});

  @override
  State<MiEquipoPage> createState() => _MiEquipoPageState();
}

class _MiEquipoPageState extends State<MiEquipoPage> {
  // ==============================
  // 📌 CONSTANTES
  // ==============================
  static const Color _primaryColor = Color(0xFF64BCEC);
  static const Color _darkBlue = Color(0xFF043463);
  static const Color _cardBackgroundColor = Color(0xFFF5F7FA);
  static const Color _borderColor = Color(0xFF1976D2);
  static const Color _backgroundOverlayColor = Color(0xFFF7F9FC);

  static const double _cardWidth = 85;
  static const double _cardHeight = 85;
  static const double _cardBorderRadius = 14;
  static const double _iconSize = 26;
  static const double _headerFontSize = 18;
  static const double _formationFontSize = 20;
  static const double _playerNameFontSize = 12;

  static const Duration _snackBarDuration = Duration(seconds: 3);
  static const EdgeInsets _headerPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 12);
  static const EdgeInsets _cardMargin = EdgeInsets.symmetric(horizontal: 4, vertical: 6);
  static const EdgeInsets _dialogPadding = EdgeInsets.all(20);

  /// Formaciones disponibles con sus posiciones específicas
  /// Cada formación define exactamente qué posiciones necesita
  static const Map<String, List<String>> _formacionesDisponibles = {
    '4-4-2': [
      'Portero',
      'Defensa 1', 'Defensa 2', 'Defensa 3', 'Defensa 4',
      'Centrocampista 1', 'Centrocampista 2', 'Centrocampista 3', 'Centrocampista 4',
      'Delantero 1', 'Delantero 2'
    ],
    '4-3-3': [
      'Portero',
      'Defensa 1', 'Defensa 2', 'Defensa 3', 'Defensa 4',
      'Centrocampista 1', 'Centrocampista 2', 'Centrocampista 3',
      'Delantero 1', 'Delantero 2', 'Delantero 3'
    ],
    '3-5-2': [
      'Portero',
      'Defensa 1', 'Defensa 2', 'Defensa 3',
      'Centrocampista 1', 'Centrocampista 2', 'Centrocampista 3', 'Centrocampista 4', 'Centrocampista 5',
      'Delantero 1', 'Delantero 2'
    ],
  };

  // ==============================
  // 📌 ESTADO DE LA APLICACIÓN
  // ==============================
  final TextEditingController _nombreController = TextEditingController();
  String _formacionSeleccionada = '4-4-2';
  Map<String, Map<String, dynamic>?> _alineacion = {};
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
    _inicializarEquipo();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  /// Inicializa la configuración del equipo al cargar la página
  /// Actualiza la alineación según la formación y carga datos del backend
  Future<void> _inicializarEquipo() async {
    _actualizarAlineacion();
    await _cargarEquipoDesdeBackend();
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
  // 📌 LÓGICA DE DATOS
  // ==============================
  /// Carga el equipo existente del usuario desde el backend
  /// Actualiza el nombre y la alineación con los datos guardados
  Future<void> _cargarEquipoDesdeBackend() async {
    try {
      setState(() => _isLoading = true);

      final response = await http.get(
        Uri.parse('$_baseUrl/mi-equipo/$usuarioIdGlobal'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _procesarDatosEquipo(data);
      }
    } catch (e) {
      debugPrint('Error al cargar equipo: $e');
      _mostrarMensaje(
        'Error al cargar el equipo',
        color: Colors.red,
        icono: Icons.error_outline,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Procesa los datos del equipo recibidos del backend
  /// Actualiza el nombre del controlador y asigna jugadores a posiciones
  void _procesarDatosEquipo(Map<String, dynamic> data) {
    _nombreController.text = data['nombre'] ?? '';

    final jugadores = List<Map<String, dynamic>>.from(data['jugadores'] ?? []);
    final nuevaAlineacion = <String, Map<String, dynamic>?>{};
    final posiciones = _formacionesDisponibles[_formacionSeleccionada]!;

    // Asignar jugadores a posiciones secuencialmente
    for (var i = 0; i < jugadores.length && i < posiciones.length; i++) {
      nuevaAlineacion[posiciones[i]] = jugadores[i];
    }

    setState(() {
      _alineacion = nuevaAlineacion;
    });
  }

  /// Carga el equipo existente y lo adapta a la formación actual
  /// Utilizado cuando cambia la formación para mantener los jugadores
  Future<void> _cargarEquipoExistente() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/mi-equipo/$usuarioIdGlobal'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['equipo'] != null) {
          _nombreController.text = data['equipo']['nombre'];
          _adaptarJugadoresAFormacion(data['jugadores']);
        }
      }
    } catch (e) {
      debugPrint('Error al cargar equipo existente: $e');
    }
  }

  /// Adapta los jugadores existentes a la nueva formación seleccionada
  void _adaptarJugadoresAFormacion(List<dynamic> jugadores) {
    final jugadoresList = List<Map<String, dynamic>>.from(jugadores);
    final nuevoMapa = <String, Map<String, dynamic>?>{};

    for (var jugador in jugadoresList) {
      nuevoMapa[jugador['posicion']] = jugador;
    }

    setState(() {
      _alineacion = {
        for (var posicion in _formacionesDisponibles[_formacionSeleccionada]!)
          posicion: nuevoMapa[posicion],
      };
    });
  }

  /// Obtiene jugadores disponibles para una posición específica desde el backend
  /// Retorna lista de jugadores que el usuario puede seleccionar
  Future<List<Map<String, dynamic>>> _obtenerJugadoresDisponibles(String posicion) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/jugadores-disponibles/$usuarioIdGlobal/$posicion'),
      );

      if (response.statusCode == 200) {
        final List datos = json.decode(response.body);
        return List<Map<String, dynamic>>.from(datos);
      }
    } catch (e) {
      debugPrint('Error al obtener jugadores: $e');
    }
    return [];
  }

  // ==============================
  // 📌 LÓGICA DE FORMACIÓN
  // ==============================
  /// Actualiza la alineación cuando cambia la formación
  /// Mantiene los jugadores en posiciones compatibles
  void _actualizarAlineacion() {
    final nuevaAlineacion = {
      for (var posicion in _formacionesDisponibles[_formacionSeleccionada]!)
        posicion: _alineacion[posicion]
    };
    setState(() {
      _alineacion = nuevaAlineacion;
    });
  }

  /// Determina el tipo de posición basado en el nombre de la posición
  /// Convierte posiciones específicas (ej: "Defensa 1") a tipos generales (ej: "Defensa")
  String _obtenerTipoPosicion(String nombrePosicion) {
    if (nombrePosicion.contains('Portero')) return 'Portero';
    if (nombrePosicion.contains('Defensa')) return 'Defensa';
    if (nombrePosicion.contains('Centrocampista')) return 'Centrocampista';
    return 'Delantero';
  }

  /// Maneja el cambio de formación seleccionada
  /// Actualiza la alineación y recarga el equipo para adaptarlo
  void _onFormacionCambiada(String? nuevaFormacion) {
    if (nuevaFormacion != null) {
      setState(() {
        _formacionSeleccionada = nuevaFormacion;
        _actualizarAlineacion();
      });
      _cargarEquipoExistente();
    }
  }

  // ==============================
  // 📌 LÓGICA DE SELECCIÓN DE JUGADORES
  // ==============================
  /// Maneja la selección de jugador para una posición específica
  /// Muestra bottom sheet con jugadores disponibles y evita duplicados
  Future<void> _seleccionarJugador(String cartaPosicion) async {
    final tipo = _obtenerTipoPosicion(cartaPosicion);
    final jugadoresDisponibles = await _obtenerJugadoresDisponibles(tipo);

    if (!mounted) return;

    // Obtener IDs de jugadores ya ocupados en la misma posición
    final idsOcupados = _obtenerIdsOcupados(cartaPosicion, tipo);

    // Filtrar jugadores disponibles excluyendo los ya ocupados
    final disponibles = jugadoresDisponibles
        .where((jugador) => !idsOcupados.contains(jugador['id']))
        .toList();

    if (disponibles.isEmpty) {
      _mostrarMensaje(
        'No hay más jugadores disponibles',
        color: Colors.orange,
        icono: Icons.warning_amber_rounded,
      );
      return;
    }

    final jugadorSeleccionado = await _mostrarSelectorJugadores(disponibles);

    if (jugadorSeleccionado != null && mounted) {
      setState(() {
        _alineacion[cartaPosicion] = jugadorSeleccionado;
      });
    }
  }

  /// Obtiene los IDs de jugadores ya ocupados en posiciones del mismo tipo
  /// Evita que el mismo jugador se asigne a múltiples posiciones
  Set<int> _obtenerIdsOcupados(String cartaPosicion, String tipo) {
    return _alineacion.entries
        .where((entry) => entry.key != cartaPosicion)
        .where((entry) => _obtenerTipoPosicion(entry.key) == tipo)
        .where((entry) => entry.value != null)
        .map((entry) => entry.value!['id'] as int)
        .toSet();
  }

  /// Muestra bottom sheet con lista de jugadores disponibles para seleccionar
  /// Retorna el jugador seleccionado o null si se cancela
  Future<Map<String, dynamic>?> _mostrarSelectorJugadores(
      List<Map<String, dynamic>> disponibles,
      ) async {
    return await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: _backgroundOverlayColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 14),
            child: Text(
              "Selecciona un jugador",
              style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold),
            ),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.all(12),
              itemCount: disponibles.length,
              itemBuilder: (context, index) => _buildJugadorItem(disponibles[index]),
            ),
          ),
        ],
      ),
    );
  }

  /// Construye el item individual de jugador en el selector
  Widget _buildJugadorItem(Map<String, dynamic> jugador) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: const Icon(Icons.person),
        title: Text(
          jugador['nombre'],
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${jugador['posicion']} • ${jugador['equipo']}',
          style: const TextStyle(fontSize: 13),
        ),
        trailing: Text(
          '💰 ${jugador['valor']} €',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
        ),
        onTap: () => Navigator.pop(context, jugador),
      ),
    );
  }

  // ==============================
  // 📌 LÓGICA DE GUARDADO
  // ==============================
  /// Guarda el equipo completo en el backend
  /// Valida que todos los campos estén completos antes de enviar
  Future<void> _guardarEquipo() async {
    final nombre = _nombreController.text.trim();

    if (!_validarEquipoCompleto(nombre)) return;

    final jugadores = _construirListaJugadores();

    try {
      setState(() => _isLoading = true);

      final response = await _enviarEquipoAlBackend(nombre, jugadores);
      _procesarRespuestaGuardado(response);
    } catch (e) {
      _mostrarMensaje(
        'Error de conexión con el servidor',
        color: Colors.red,
        icono: Icons.error_outline,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Valida que el equipo esté completo antes de guardar
  /// Verifica nombre no vacío y todas las posiciones ocupadas
  bool _validarEquipoCompleto(String nombre) {
    if (nombre.isEmpty || _alineacion.values.any((jugador) => jugador == null)) {
      _mostrarMensaje(
        'Completa todos los campos y elige todos los jugadores',
        color: Colors.orange,
        icono: Icons.warning_amber_rounded,
      );
      return false;
    }
    return true;
  }

  /// Construye la lista de jugadores en formato requerido por el backend
  List<Map<String, dynamic>> _construirListaJugadores() {
    return _alineacion.entries
        .map((entry) => {
      'jugadorId': entry.value!['id'],
      'posicion': entry.key,
    })
        .toList();
  }

  /// Envía el equipo al backend para guardarlo
  Future<http.Response> _enviarEquipoAlBackend(
      String nombre,
      List<Map<String, dynamic>> jugadores,
      ) async {
    return await http.post(
      Uri.parse('$_baseUrl/guardar-equipo'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'usuarioId': usuarioIdGlobal,
        'nombre': nombre,
        'jugadores': jugadores,
      }),
    );
  }

  /// Procesa la respuesta del servidor después de intentar guardar
  void _procesarRespuestaGuardado(http.Response response) {
    final body = json.decode(response.body);

    if (response.statusCode == 200) {
      _mostrarMensaje(body['mensaje'] ?? 'Equipo guardado correctamente!');
    } else {
      _mostrarMensaje(
        body['error'] ?? 'Error al guardar el equipo',
        color: Colors.red,
        icono: Icons.error_outline,
      );
    }
  }

  // ==============================
  // 📌 WIDGETS DE CONSTRUCCIÓN
  // ==============================
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final anchoCarta = (screenWidth - 48) / 5;

    return Scaffold(
      body: Column(
        children: [
          _buildCabecera(),
          _buildCampoYAlineacion(anchoCarta),
        ],
      ),
    );
  }

  /// Construye la cabecera con nombre del equipo y selector de formación
  Widget _buildCabecera() {
    return Container(
      color: _primaryColor,
      padding: _headerPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSeccionNombreEquipo(),
          const SizedBox(height: 10),
          _buildSeccionFormacion(),
        ],
      ),
    );
  }

  /// Construye la sección del nombre del equipo con botón de edición
  Widget _buildSeccionNombreEquipo() {
    return Row(
      children: [
        const Icon(Icons.shield_outlined, color: Colors.white, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _nombreController.text.isEmpty ? "Nombre del equipo" : _nombreController.text,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: _headerFontSize,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.edit, color: Colors.white70, size: 20),
          onPressed: _mostrarDialogoEditarNombre,
        ),
      ],
    );
  }

  /// Construye la sección de selección de formación
  Widget _buildSeccionFormacion() {
    return Row(
      children: [
        const Icon(Icons.tune, color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Text(
          "Formación",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: _formationFontSize,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        _buildSelectorFormacion(),
      ],
    );
  }

  /// Construye el selector desplegable de formación
  Widget _buildSelectorFormacion() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white24),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _formacionSeleccionada,
          dropdownColor: Colors.white,
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
          onChanged: _onFormacionCambiada,
          items: _formacionesDisponibles.keys.map((formacion) {
            return DropdownMenuItem(
              value: formacion,
              child: Text(formacion),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Construye el campo de fútbol con la alineación
  Widget _buildCampoYAlineacion(double anchoCarta) {
    return Expanded(
      child: Stack(
        children: [
          _buildFondoCampo(),
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: _generarFilasPorFormacion(anchoCarta),
                ),
              ),
              _buildBotonGuardar(),
            ],
          ),
        ],
      ),
    );
  }

  /// Construye el fondo del campo de fútbol
  Widget _buildFondoCampo() {
    return Positioned.fill(
      child: Image.asset(
        'assets/futbol.png',
        fit: BoxFit.cover,
        width: double.infinity,
      ),
    );
  }

  /// Construye el botón para guardar el equipo
  Widget _buildBotonGuardar() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _guardarEquipo,
        icon: _isLoading
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
            : const Icon(Icons.save, color: _darkBlue),
        label: Text(
          _isLoading ? "Guardando..." : "Guardar equipo",
          style: const TextStyle(
            color: _darkBlue,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: _darkBlue, width: 1.5),
          ),
          elevation: 3,
        ),
      ),
    );
  }

  /// Muestra diálogo para editar el nombre del equipo
  Future<void> _mostrarDialogoEditarNombre() async {
    final nuevoNombre = await showGeneralDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Editar nombre",
      pageBuilder: (context, animation, secondaryAnimation) {
        final controller = TextEditingController(text: _nombreController.text);
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              padding: _dialogPadding,
              decoration: BoxDecoration(
                color: _primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Editar nombre",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: "Introduce el nombre",
                      hintStyle: TextStyle(color: Colors.white54),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white30),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          "Cancelar",
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, controller.text),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          "Guardar",
                          style: TextStyle(color: _darkBlue),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (nuevoNombre != null && nuevoNombre.trim().isNotEmpty) {
      setState(() {
        _nombreController.text = nuevoNombre.trim();
      });
    }
  }

  /// Genera las filas de jugadores según la formación seleccionada
  /// Organiza los jugadores por tipo de posición (portero, defensas, etc.)
  Widget _generarFilasPorFormacion(double anchoCarta) {
    final filas = <Widget>[];
    final posiciones = _formacionesDisponibles[_formacionSeleccionada]!;

    final bloques = {
      'Portero': posiciones.where((p) => p.contains('Portero')).toList(),
      'Defensas': posiciones.where((p) => p.contains('Defensa')).toList(),
      'Centrocampistas': posiciones.where((p) => p.contains('Centrocampista')).toList(),
      'Delanteros': posiciones.where((p) => p.contains('Delantero')).toList(),
    };

    bloques.forEach((_, posList) {
      filas.add(_buildFilaJugadores(posList, anchoCarta));
    });

    return Column(children: filas);
  }

  /// Construye una fila de jugadores para una posición específica
  Widget _buildFilaJugadores(List<String> posiciones, double anchoCarta) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: posiciones
          .map((posicion) => _buildCartaJugador(posicion, anchoCarta))
          .toList(),
    );
  }

  /// Construye la carta individual de un jugador
  /// Muestra el nombre del jugador o está vacía si no hay jugador asignado
  Widget _buildCartaJugador(String posicion, double anchoCarta) {
    final jugador = _alineacion[posicion];

    return GestureDetector(
      onTap: () => _seleccionarJugador(posicion),
      child: Container(
        width: anchoCarta,
        height: _cardHeight,
        margin: _cardMargin,
        decoration: BoxDecoration(
          color: _cardBackgroundColor,
          borderRadius: BorderRadius.circular(_cardBorderRadius),
          border: Border.all(color: _borderColor, width: 1.8),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(2, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person, size: _iconSize, color: _borderColor),
            const SizedBox(height: 6),
            Text(
              jugador != null ? jugador['nombre'] : '',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: _playerNameFontSize,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}