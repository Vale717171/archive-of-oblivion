import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RitualTypography {
  static TextStyle display(double size, {Color? color, double? height}) {
    return GoogleFonts.cinzel(
      color: color,
      fontSize: size,
      letterSpacing: 1.15,
      fontWeight: FontWeight.w600,
      height: height,
    );
  }

  static TextStyle ritualSans(double size, {Color? color, FontWeight? weight}) {
    return GoogleFonts.josefinSans(
      color: color,
      fontSize: size,
      letterSpacing: 0.55,
      fontWeight: weight ?? FontWeight.w500,
      height: 1.25,
    );
  }

  static TextStyle narrative(double size, {Color? color, FontWeight? weight}) {
    return GoogleFonts.ebGaramond(
      color: color,
      fontSize: size,
      letterSpacing: 0.18,
      fontWeight: weight ?? FontWeight.w400,
      height: 1.68,
    );
  }

  static TextStyle command(double size, {Color? color}) {
    return GoogleFonts.ibmPlexMono(
      color: color,
      fontSize: size,
      letterSpacing: 0.4,
      fontWeight: FontWeight.w500,
    );
  }
}

class SectorVisualProfile {
  final Color accent;
  final Color glow;
  final Color frame;
  final List<Color> veilGradient;

  const SectorVisualProfile({
    required this.accent,
    required this.glow,
    required this.frame,
    required this.veilGradient,
  });
}

SectorVisualProfile visualProfileForNode(String nodeId) {
  final sector = _sectorForNode(nodeId);
  switch (sector) {
    case 'Threshold':
      return const SectorVisualProfile(
        accent: Color(0xFFD7DCE3),
        glow: Color(0x99C8CED8),
        frame: Color(0x55E2E7EF),
        veilGradient: [Color(0xB20A0D12), Color(0xD006070A), Color(0xE6000000)],
      );
    case 'Garden':
      return const SectorVisualProfile(
        accent: Color(0xFFD8B978),
        glow: Color(0x886CA66A),
        frame: Color(0x55D1B67A),
        veilGradient: [Color(0xAA10160F), Color(0xCD0A100A), Color(0xE6000000)],
      );
    case 'Observatory':
      return const SectorVisualProfile(
        accent: Color(0xFF9FC2FF),
        glow: Color(0x88698BC5),
        frame: Color(0x558BB5FF),
        veilGradient: [Color(0xB00B1320), Color(0xCC080D16), Color(0xE6000000)],
      );
    case 'Gallery':
      return const SectorVisualProfile(
        accent: Color(0xFFE1BD82),
        glow: Color(0x887B6551),
        frame: Color(0x55D9AE70),
        veilGradient: [Color(0xB2110F0C), Color(0xCC0E0A09), Color(0xE6000000)],
      );
    case 'Laboratory':
      return const SectorVisualProfile(
        accent: Color(0xFFB9A2E9),
        glow: Color(0x88649A7C),
        frame: Color(0x559A8DE2),
        veilGradient: [Color(0xB0100B18), Color(0xCC0A0711), Color(0xE6000000)],
      );
    case 'Memory':
      return const SectorVisualProfile(
        accent: Color(0xFFE0C6A5),
        glow: Color(0x887D6654),
        frame: Color(0x55D8B790),
        veilGradient: [Color(0xAF18110D), Color(0xCF0F0B09), Color(0xE6000000)],
      );
    case 'Zone':
      return const SectorVisualProfile(
        accent: Color(0xFFADE6F2),
        glow: Color(0x884DA7BF),
        frame: Color(0x5595D8E8),
        veilGradient: [Color(0xAA0A1419), Color(0xCA060D12), Color(0xE6000000)],
      );
    case 'Finale':
      return const SectorVisualProfile(
        accent: Color(0xFFE5DBC9),
        glow: Color(0x88A8947A),
        frame: Color(0x55D7C5A5),
        veilGradient: [Color(0xB2161310), Color(0xCF0D0A09), Color(0xE6000000)],
      );
    default:
      return const SectorVisualProfile(
        accent: Color(0xFFE3E1DB),
        glow: Color(0x886A6A74),
        frame: Color(0x55DAD8D2),
        veilGradient: [Color(0xAB101116), Color(0xCC0A0B0F), Color(0xE6000000)],
      );
  }
}

String _sectorForNode(String nodeId) {
  if (nodeId == 'intro_void' || nodeId == 'la_soglia') return 'Threshold';
  if (nodeId.startsWith('garden')) return 'Garden';
  if (nodeId.startsWith('obs_')) return 'Observatory';
  if (nodeId.startsWith('gal_') || nodeId.startsWith('gallery_'))
    return 'Gallery';
  if (nodeId.startsWith('lab_')) return 'Laboratory';
  if (nodeId.startsWith('quinto_') || nodeId.startsWith('memory_'))
    return 'Memory';
  if (nodeId.startsWith('finale_') || nodeId == 'il_nucleo') return 'Finale';
  if (nodeId == 'la_zona') return 'Zone';
  return 'Archive';
}
