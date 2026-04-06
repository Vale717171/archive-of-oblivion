// lib/features/ui/background_service.dart
// Maps sector/node IDs to background image asset paths.

class BackgroundService {
  /// Returns the background image asset path for the given sector ID, or null
  /// if no image is mapped for that sector.
  static String? getBackgroundForSector(String sectorId) {
    switch (sectorId) {
      case 'soglia':
        return 'assets/images/bg_soglia.jpg';
      case 'giardino':
        return 'assets/images/bg_giardino.jpg';
      case 'osservatorio':
        return 'assets/images/bg_osservatorio.jpg';
      case 'galleria':
        return 'assets/images/bg_galleria.jpg';
      case 'laboratorio':
        return 'assets/images/bg_laboratorio.jpg';
      case 'memoria':
        return 'assets/images/bg_memoria.jpg';
      case 'la_zona':
        return 'assets/images/bg_zona.jpg';
      default:
        return null;
    }
  }

  /// Derives the background sector ID from a game node ID and returns the
  /// corresponding asset path, or null when no image is available.
  static String? getBackgroundForNode(String nodeId) {
    return getBackgroundForSector(_sectorForNode(nodeId));
  }

  static String _sectorForNode(String nodeId) {
    if (nodeId == 'intro_void' || nodeId == 'la_soglia') return 'soglia';
    if (nodeId.startsWith('garden')) return 'giardino';
    if (nodeId.startsWith('obs_')) return 'osservatorio';
    if (nodeId.startsWith('gal_') || nodeId.startsWith('gallery_')) {
      return 'galleria';
    }
    if (nodeId.startsWith('lab_')) return 'laboratorio';
    if (nodeId.startsWith('quinto_') ||
        nodeId == 'il_nucleo' ||
        nodeId.startsWith('finale_') ||
        nodeId.startsWith('memory_')) {
      return 'memoria';
    }
    if (nodeId == 'la_zona') return 'la_zona';
    return '';
  }
}
