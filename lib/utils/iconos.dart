// lib/utils/iconos.dart
String obtenerIcono(String? posicion) {
  switch (posicion?.toLowerCase()) {
    case 'portero':
      return '🧤';
    case 'defensa':
      return '🛡️';
    case 'centrocampista':
      return '🎯';
    case 'delantero':
      return '⚽';
    default:
      return '❓';
  }
}
