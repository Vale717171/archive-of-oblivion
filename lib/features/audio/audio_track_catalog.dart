class AudioTrackCatalog {
  static const Map<String, String> ambienceAssets = {
    // Sector bases
    'soglia': 'assets/audio/bach_bwv846_soglia.ogg',
    'giardino': 'assets/audio/bach_goldberg_giardino.ogg',
    'osservatorio': 'assets/audio/bach_contrapunctus_observatory.ogg',
    'galleria': 'assets/audio/bach_bwv846_galleria.ogg',
    'laboratorio': 'assets/audio/bach_bwv1008_laboratorio.ogg',
    'memoria': 'assets/audio/bach_memoria_theme.ogg',
    'zona': 'assets/audio/bach_fugue_883_zona.ogg',

    // Room overrides
    'giardino_fountain': 'assets/audio/garden_fountain_variation.ogg',
    'giardino_stelae': 'assets/audio/garden_stelae_variation.ogg',
    'osservatorio_calibration': 'assets/audio/observatory_calibration_variation.ogg',
    'osservatorio_dome': 'assets/audio/observatory_dome_variation.ogg',
    'galleria_dark': 'assets/audio/gallery_dark_variation.ogg',
    'galleria_light': 'assets/audio/gallery_light_variation.ogg',
    'galleria_mirror': 'assets/audio/gallery_mirror_variation.ogg',
    'laboratorio_bain_marie': 'assets/audio/lab_bain_marie_variation.ogg',
    'laboratorio_sealed': 'assets/audio/lab_sealed_variation.ogg',
    'memoria_ritual': 'assets/audio/memory_ritual_variation.ogg',
    'zona_eternal': 'assets/audio/zona_eternal_variation.ogg',

    // Legacy/special explicit triggers
    'oblivion': 'assets/audio/echo_chamber.ogg',
    'siciliano': 'assets/audio/bach_siciliano_bwv1017.ogg',
    'aria_goldberg': 'assets/audio/bach_aria_goldberg.ogg',
  };

  static const Map<String, String> _sectorBaseKeys = {
    'soglia': 'soglia',
    'giardino': 'giardino',
    'osservatorio': 'osservatorio',
    'galleria': 'galleria',
    'laboratorio': 'laboratorio',
    'memoria': 'memoria',
    'la_zona': 'zona',
  };

  static const Map<String, String> _nodeOverrides = {
    'intro_void': 'soglia',
    'la_soglia': 'soglia',
    'garden_fountain': 'giardino_fountain',
    'garden_stelae': 'giardino_stelae',
    'obs_calibration': 'osservatorio_calibration',
    'obs_dome': 'osservatorio_dome',
    'gallery_dark': 'galleria_dark',
    'gallery_light': 'galleria_light',
    'gallery_central': 'galleria_mirror',
    'lab_bain_marie': 'laboratorio_bain_marie',
    'lab_sealed': 'laboratorio_sealed',
    'quinto_landing': 'siciliano',
    'quinto_ritual_chamber': 'memoria_ritual',
    'il_nucleo': 'oblivion',
    'finale_acceptance': 'aria_goldberg',
    'finale_oblivion': 'silence',
    'finale_eternal_zone': 'zona_eternal',
    'la_zona': 'zona',
  };

  static const Set<String> specialTracks = {
    'siciliano',
    'aria_goldberg',
    'silence',
    'oblivion',
  };

  static String? assetForKey(String key) => ambienceAssets[key];

  static bool isExplicitTrack(String key) =>
      key == 'silence' || ambienceAssets.containsKey(key);

  static String? trackForNode(String nodeId) {
    final override = _nodeOverrides[nodeId];
    if (override != null) return override;
    return _sectorBaseKeys[sectorForNode(nodeId)];
  }

  static String sectorForNode(String nodeId) {
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
    return 'soglia';
  }
}
