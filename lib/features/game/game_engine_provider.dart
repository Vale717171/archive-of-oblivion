// lib/features/game/game_engine_provider.dart
// Author: GitHub Copilot — 2026-04-02 | Extended: 2026-04-03, 2026-04-04, 2026-04-05
// All four sectors + Fifth Sector + Final Boss + La Zona implemented.
// Narrator: DemiurgeService ("All That Is") — deterministic, offline (GDD §5).

import 'dart:math' show Random;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/database_service.dart';
import '../../core/storage/dialogue_history_service.dart';
import '../audio/audio_service.dart';
import '../demiurge/demiurge_service.dart';
import '../parser/parser_service.dart';
import '../parser/parser_state.dart';
import '../state/game_state_provider.dart';
import '../state/psycho_provider.dart';

// ── Node data ─────────────────────────────────────────────────────────────────

class _NodeDef {
  final String title;
  final String description;
  final Map<String, String> exits;
  final Map<String, String> examines;
  final Set<String> takeable;

  const _NodeDef({
    required this.title,
    required this.description,
    required this.exits,
    this.examines = const <String, String>{},
    this.takeable = const <String>{},
  });
}

// ── Simulacra — weightless; dropping them does not reduce burden ──────────────

const Set<String> _simulacraNames = {
  'ataraxia', 'the constant', 'the proportion', 'the catalyst',
};

// ── Boss fight — resolution and surrender keywords (GDD §12) ─────────────────

const Set<String> _resolutionKeywords = {
  'human warmth', 'imperfection', 'observer', 'acceptance',
  'i want to remember', 'i exist', 'irrepeatable', 'breath',
};

const Set<String> _surrenderKeywords = {
  'i accept the void', 'nothing matters', 'surrender', 'i give up',
  'the void is peace', 'i want to forget', 'i accept oblivion', 'oblivion',
};

// ── La Zona — Arseny Tarkovsky verse variants (GDD §10) ──────────────────────

const List<String> _tarkovskyVerses = [
  '"I was ill, or perhaps merely alive,\nand you came from a time that did not yet exist."',
  '"What has been will be again.\nI shall arrange it differently next time."',
  '"Life is not so short,\nand not so long — it is exactly as long as it needs to be."',
  '"The soul has no shoulders\nand cannot carry what the body carried."',
  '"From beyond the mirror, a world\nthat has always been waiting."',
  '"All that glitters is not gold,\nbut all that disappears was real."',
  '"I dreamed the world was a staircase\nand I was neither ascending nor descending."',
  '"Nothing can be taken away\nthat was not, once, truly given."',
];

const List<String> _zoneEnvironments = [
  'A corridor that is also a room. The walls meet at angles that should not exist.',
  'The floor continues past where the floor should end. Below: the same floor, continuing.',
  'Three shadows — yours, and two others whose sources cannot be located.',
  'A staircase descending to the level you are standing on.',
  'The ceiling is very close. Then it is very far. The distance does not change.',
  'A window onto a room exactly like this one, except in that room there is no window.',
  'Sound arrives before the movement that caused it.',
  'The walls are made of the same light as what falls through windows you cannot find.',
];

// ── La Zona — introspective questions (from zona_templates.json) ──────────────

class _ZoneQuestion {
  final String question;
  final String theme;
  final String crypticResponse;
  const _ZoneQuestion({
    required this.question,
    required this.theme,
    required this.crypticResponse,
  });
}

const List<_ZoneQuestion> _zoneQuestions = [
  _ZoneQuestion(
    question: 'What did you leave behind that still has your shape?',
    theme: 'loss',
    crypticResponse:
        'Something in the architecture shifts — very slightly, but permanently.\n\n'
        'The corridor opens back toward the Archive.',
  ),
  _ZoneQuestion(
    question: 'When did you last do something that could not be undone?',
    theme: 'irreversibility',
    crypticResponse:
        'The Zone records this. Not as judgement — as coordinate.\n\n'
        'You know where you are now. The Archive is north.',
  ),
  _ZoneQuestion(
    question: 'Name the moment you would return to, if return were possible.',
    theme: 'memory',
    crypticResponse:
        'The impossibility of return is what makes the moment permanent.\n\n'
        'You may leave.',
  ),
  _ZoneQuestion(
    question: 'What are you carrying that does not belong to you?',
    theme: 'burden',
    crypticResponse:
        'The weight of borrowed things is different. Noted.\n\n'
        'The passage back is clear.',
  ),
  _ZoneQuestion(
    question: 'Who taught you that what you feel is not enough?',
    theme: 'wound',
    crypticResponse:
        'The Zone holds this carefully. It will not repeat the lesson.\n\n'
        'You may return to the Archive.',
  ),
  _ZoneQuestion(
    question: 'What would you say to the version of yourself that cannot be reached?',
    theme: 'time',
    crypticResponse:
        'The unreachable version received it anyway — through the medium of your having said it.\n\n'
        'The Archive is through here.',
  ),
  _ZoneQuestion(
    question: 'In what form does the part of you that resists speak?',
    theme: 'resistance',
    crypticResponse:
        'The Zone recognises resistance as intelligence.\n\n'
        'The question is answered. Return.',
  ),
  _ZoneQuestion(
    question: 'What do you know now that you already knew then?',
    theme: 'recognition',
    crypticResponse:
        'Recognition is the only form of time travel available.\n\n'
        'The Archive is waiting.',
  ),
];

// ── Exit gates: nodeId → {direction → requiredPuzzleId} ──────────────────────

const Map<String, Map<String, String>> _exitGates = {
  'garden_cypress':      {'north': 'leaves_arranged'},
  'garden_fountain':     {'north': 'fountain_waited'},
  'garden_stelae':       {'north': 'stele_inscribed'},
  'obs_antechamber':     {'north': 'lenses_combined'},
  'obs_corridor':        {'west': 'heisenberg_walked', 'east': 'heisenberg_walked'},
  'obs_void':            {'south': 'void_fluctuation_measured'},
  'obs_archive':         {'south': 'archive_constant_entered'},
  'obs_calibration':     {'north': 'obs_calibrated'},
  'gallery_hall':        {'south': 'hall_backward_walked'},
  'gallery_corridor':    {'south': 'corridor_tile_pressed'},
  'gallery_proportions': {
    'east': 'proportion_pentagon_drawn',
    'west': 'proportion_pentagon_drawn',
  },
  'gallery_dark':  {'east': 'gallery_item_abandoned'},
  'gallery_light': {'west': 'gallery_item_abandoned'},
  'lab_vestibule': {'south': 'lab_offers_complete'},
  'lab_furnace':   {'south': 'furnace_calcinated'},
  'lab_alembic':   {'south': 'alembic_temperature_set'},
  'lab_bain_marie':{'south': 'bain_marie_complete'},
  // Fifth Sector — memory price to leave each room (GDD §11)
  'quinto_childhood': {'back': 'memory_childhood'},
  'quinto_youth':     {'back': 'memory_youth'},
  'quinto_maturity':  {'back': 'memory_maturity'},
  'quinto_old_age':   {'back': 'memory_old_age'},
  // Ritual chamber → il_nucleo (drink auto-navigates; go down also gated)
  'quinto_ritual_chamber': {'down': 'ritual_complete'},
};

const Map<String, String> _gateHints = {
  'leaves_arranged':
      'The fallen leaves bar your way. Their disorder is the lock.\n\n'
      'Hint: arrange leaves [seven words in Epicurean order].',
  'fountain_waited':
      'The passage north is not yet open. Something is still arriving.\n\n'
      'Hint: wait — and again, and again.',
  'stele_inscribed':
      'The grove will not receive you. The blank stele stands in judgement.\n\n'
      'Hint: inscribe [the missing maxim] — read the eleven that precede it.',
  'lenses_combined':
      'The corridor is dark. The telescope mount is incomplete.\n\n'
      'Hint: combine lens [Moon] [Mercury] [Sun].',
  'heisenberg_walked':
      'The branches of the corridor are inaccessible. Sight is the obstacle.\n\n'
      'Hint: walk blindfolded.',
  'void_fluctuation_measured':
      'The calibration chamber is sealed. The void has not spoken.\n\n'
      'Hint: wait seven times — then measure fluctuation.',
  'archive_constant_entered':
      'The calibration chamber cannot be reached. The panel awaits.\n\n'
      'Hint: enter [the value that underlies all constants].',
  'obs_calibrated':
      'The dome is locked. The instrument needs its reference point.\n\n'
      'Hint: calibrate [the only honest coordinates].',
  'hall_backward_walked':
      'The gallery corridor is sealed. The way forward is behind you.\n\n'
      'Hint: walk backward.',
  'corridor_tile_pressed':
      'The proportions room is locked. One tile does not belong.\n\n'
      'Hint: press anomalous tile.',
  'proportion_pentagon_drawn':
      'The wings are sealed. A geometric form must be constructed first.\n\n'
      'Hint: construct pentagon.',
  'gallery_item_abandoned':
      'The tunnel between the chambers demands a price.\n\n'
      'Hint: drop [something you carry] — the tunnel requires abandonment.',
  'lab_offers_complete':
      'The Hall of Substances is locked. The three statues wait.\n\n'
      'Hint: offer [concept] — three times, three different offerings.',
  'furnace_calcinated':
      'The furnace path to the Great Work is blocked. Calcination is unfinished.\n\n'
      'Hint: calcinate — then wait (patience is the reagent).',
  'alembic_temperature_set':
      'The alembic path is blocked. The temperature is wrong.\n\n'
      'Hint: set temperature [the gentlest degree of fire].',
  'bain_marie_complete':
      'The bath path is sealed. The transformation has not begun.\n\n'
      'Hint: leave this room — return after you have walked three other roads.',
  // Fifth Sector
  'memory_childhood':
      'The door will not release you. The price of this room is still owed.\n\n'
      'Hint: write [the first word you truly learned].',
  'memory_youth':
      'The promise holds you here. Name it to be freed.\n\n'
      'Hint: write [a promise you did not keep].',
  'memory_maturity':
      'The telephone waits. You cannot leave until you have spoken.\n\n'
      'Hint: say [what you never said] — or write it.',
  'memory_old_age':
      'One last truth before you leave. The room asks this of you.\n\n'
      'Hint: write [what you wish to be remembered as].',
  'ritual_complete':
      'The passage down is sealed. The cup is not ready.\n\n'
      'Hint: place each simulacrum in the cup — then stir — then drink.',
};

// ── Node definitions ──────────────────────────────────────────────────────────
// Nodes are in English as required by GDD §1.
// Future: move text to assets/texts/*.json (GDD §18).

const Map<String, _NodeDef> _nodes = {

  // ── Starting void ────────────────────────────────────────────────────────────
  'intro_void': _NodeDef(
    title: '',
    description: 'Silence.\n\n'
        'Then — awareness.\n\n'
        'You exist. You do not know why. A name surfaces and dissolves '
        'before you can hold it. No floor, no ceiling. '
        'Only a luminescence that comes from everywhere and nowhere.\n\n'
        'In your pocket: a small empty Notebook.\n\n'
        'A path forms ahead.',
    exits: {'north': 'la_soglia', 'forward': 'la_soglia', 'ahead': 'la_soglia'},
    examines: {
      'notebook': 'A small notebook. Pages perfectly blank. '
          'The cover bears a symbol you almost recognise — then do not.',
      'light': 'It does not come from any source. It simply is.',
      'path':  'It was not there before. Now it leads north.',
    },
  ),

  // ── The Threshold (hub) ──────────────────────────────────────────────────────
  'la_soglia': _NodeDef(
    title: 'The Threshold',
    description: 'A circular rotunda of black marble veined with silver.\n\n'
        'Four doors at the cardinal points: amber to the north, '
        'cobalt blue to the east, golden to the south, violet to the west. '
        'At the centre, a pentagonal pedestal holds five recesses — each '
        'shaped for something you have not yet found.\n\n'
        'A clock without hands marks time in no direction you recognise.',
    exits: {
      'north': 'garden_portico',
      'east':  'obs_antechamber',
      'south': 'gallery_hall',
      'west':  'lab_vestibule',
      'up':    'quinto_landing',
    },
    examines: {
      'pedestal':   'Five recesses. Inscribed: Ataraxia. The Constant. '
          'Proportion. The Catalyst. A fifth shape you cannot name.',
      'clock':      'Numerals run counterclockwise. The hands are absent.',
      'north door': 'Amber, warm, slightly ajar. Beyond it: the scent of earth.',
      'east door':  'Cobalt blue, cold. A faint hum behind the glass.',
      'south door': 'Golden, polished to a mirror. Your reflection is slightly wrong.',
      'west door':  'Violet, heavy. The grain of the wood runs upward.',
      'door':       'Four doors. The amber one to the north is ajar.',
    },
  ),

  // ── Garden of Epicurus ───────────────────────────────────────────────────────
  'garden_portico': _NodeDef(
    title: 'The Garden of Epicurus — Portico',
    description: 'The amber door opens onto stillness.\n\n'
        'A portico of worn stone columns. Inscriptions run along each shaft. '
        'A path of pale stone leads north through cypress trees '
        'so tall their crowns disappear.',
    exits: {'north': 'garden_cypress', 'south': 'la_soglia', 'back': 'la_soglia'},
    examines: {
      'columns': 'Each column bears a single word:\n'
          'ataraxia — aponia — philia — phronesis.\n'
          'The order is not alphabetical.',
      'path': 'Cypress trees stand like sentinels.',
    },
  ),

  'garden_cypress': _NodeDef(
    title: 'Cypress Avenue',
    description: 'A long avenue of cypress trees.\n\n'
        'Leaves have fallen across the stone path, each perfectly preserved, '
        'each bearing a single word in faded ink. They are not arranged in '
        'any obvious order.\n\n'
        'To the north, the avenue opens onto a dry fountain.',
    exits: {'north': 'garden_fountain', 'south': 'garden_portico'},
    examines: {
      'leaves': 'You crouch and read the words:\n'
          'pleasure — friendship — prudence — tranquillity — '
          'memory — simplicity — absence.\n\n'
          'They belong to an order. You sense it, but cannot yet name it.',
      'trees': 'Impossibly tall. Their roots disappear into ground with no depth.',
      'words': 'Seven words. One leaf is slightly darker than the rest.',
    },
  ),

  'garden_fountain': _NodeDef(
    title: 'Dry Fountain',
    description: 'A stone fountain, long dry.\n\n'
        'Its basin holds only fine grey dust. '
        'Carved along the rim: "That which satisfies the body is sufficient '
        'for happiness." The stone is worn smooth by many hands.\n\n'
        'To the north: a circle of standing stones.',
    exits: {'north': 'garden_stelae', 'south': 'garden_cypress'},
    examines: {
      'fountain':    'Empty. Worn smooth by many hands before yours.',
      'dust':        'Fine as ash. Breathed on, it forms brief illegible shapes.',
      'inscription': '"That which satisfies the body is sufficient for happiness."',
    },
  ),

  'garden_stelae': _NodeDef(
    title: 'Circle of Stelae',
    description: 'A circle of standing stones, each inscribed with a maxim.\n\n'
        'You count eleven. The twelfth stele is blank — its surface '
        'smooth and waiting. A stylus lies at its base.\n\n'
        'To the south, the dry fountain. To the north, the grove.',
    exits: {'north': 'garden_grove', 'south': 'garden_fountain'},
    examines: {
      'stelae':      'Eleven maxims. The eleventh: "Death is nothing to us." '
          'The twelfth is blank.',
      'blank stele': 'Smooth stone. A stylus at its base. '
          'The missing maxim belongs to those who have understood the others.',
      'stylus':      'A simple instrument. It waits.',
      'maxims':      'Pleasure. Death. The gods. Pain. Virtue. '
          'The soul. Justice. Friendship. Wisdom. Society. The self. '
          'The twelfth stands empty.',
    },
    takeable: {'stylus'},
  ),

  'garden_grove': _NodeDef(
    title: "Central Grove — Epicurus' Statue",
    description: 'A clearing of ancient trees.\n\n'
        'At the centre: a marble statue of a seated figure. '
        'Hands open on its knees, palms upward, holding nothing. '
        'The expression is one of complete, undemonstrative peace.\n\n'
        'To the east and west: two alcoves in the treeline.\n'
        'To the south: the circle of stelae.',
    exits: {
      'east':  'garden_alcove_pleasures',
      'west':  'garden_alcove_pains',
      'south': 'garden_stelae',
    },
    examines: {
      'statue':   'The hands hold nothing. The face asks nothing. '
          'It has been waiting for you specifically.',
      'trees':    'Ancient. Still. Their roots break the stone path.',
      'clearing': 'No wind. Sound arrives slightly after it should.',
    },
  ),

  'garden_alcove_pleasures': _NodeDef(
    title: 'Alcove of Pleasures',
    description: 'A small alcove off the grove.\n\n'
        'Objects on low shelves: a coin worn smooth, '
        'a leather-bound book with gilded edges, a brass compass, '
        'a small oil lamp. Each is beautiful. Each gives you the '
        'faint sense that acquiring it would be a mistake.\n\n'
        'A linden tree grows in the corner. Its flowers are open.',
    exits: {'west': 'garden_grove', 'back': 'garden_grove'},
    examines: {
      'coin':    'A coin from no era you recognise. Heads: a face. Tails: the same face, older.',
      'book':    'The gilded title has worn away. Inside, handwriting '
          'you almost recognise as your own.',
      'compass': 'The needle points in a direction that changes every time you look away.',
      'lamp':    'The flame is lit. You do not remember lighting it.',
      'linden':  'A linden tree in full flower. The scent is very faint — then overwhelming.',
      'flowers': 'Not just flowers. Something older. A door, half-open. A specific afternoon.',
    },
    takeable: {'coin', 'book', 'compass', 'lamp'},
  ),

  'garden_alcove_pains': _NodeDef(
    title: 'Alcove of Pains',
    description: 'A small alcove off the grove.\n\n'
        'Objects: a rusted key, a torn page, '
        'a cracked mirror shard, a handful of dried earth.\n\n'
        'They are less beautiful than those across the grove. '
        'That, somehow, makes them harder to leave.',
    exits: {'east': 'garden_grove', 'back': 'garden_grove'},
    examines: {
      'key':          'Rusted. You do not know what it opens. '
          'You suspect the lock no longer exists.',
      'page':         'A single torn page. One word you understand: remember.',
      'mirror shard': 'Your reflection is correct. '
          'That is somehow the most unsettling thing about this place.',
      'earth':        'Dry. Dark. The smell of the end of summer.',
    },
    takeable: {'key', 'page', 'mirror shard', 'earth'},
  ),

  // ── Observatory ──────────────────────────────────────────────────────────────
  'obs_antechamber': _NodeDef(
    title: 'The Blind Observatory — Antechamber of Lenses',
    description: 'The cobalt door opens to cold glass.\n\n'
        'Three lenses rest in separate cradles along the north wall, '
        'each engraved with a celestial name. A brass telescope mount '
        'at the centre holds three empty slots.\n\n'
        'The labels read: Sun — Mercury — Moon.\n\n'
        'To the north: the Corridor of Hypotheses.',
    exits: {'north': 'obs_corridor', 'west': 'la_soglia', 'back': 'la_soglia'},
    examines: {
      'lenses':       'Three lenses. Sun: large, amber. Mercury: small, dense. '
          'Moon: silvered, cold. The order in which they are combined matters.',
      'sun':          'The largest lens. Its apparent primacy may be the problem.',
      'mercury':      'Small and heavy. The glass feels older.',
      'moon':         'Cold to the touch. It seems to absorb rather than bend.',
      'mount':        'Three slots, vertically arranged. Each accepts only one lens.',
      'slots':        'Upper, middle, lower. Their relative sizes suggest an ordering.',
    },
  ),

  'obs_corridor': _NodeDef(
    title: 'Corridor of Hypotheses',
    description: 'A long corridor. The walls are lined with framed statements, '
        'each crossed out in red. Not false — abandoned.\n\n'
        'The corridor branches: west to a dark hall, east to an archive.\n\n'
        'A placard: "The act of looking disturbs the looked-at. This has been proven."',
    exits: {'south': 'obs_antechamber', 'west': 'obs_void', 'east': 'obs_archive'},
    examines: {
      'hypotheses': '"Light behaves as a wave." Crossed out. '
          '"Light behaves as a particle." Crossed out. '
          'Beneath both: "Light behaves."',
      'placard':    '"The act of looking disturbs the looked-at.\n'
          'Position and momentum resist simultaneous knowledge.\n'
          'Uncertainty is not ignorance. It is precision."',
      'branches':   'West: absolute darkness. East: an archive of glass.',
    },
  ),

  'obs_void': _NodeDef(
    title: 'Hall of Void',
    description: 'A perfectly dark room. No walls visible.\n\n'
        'You know they are there. The silence has texture — '
        'a grain, as if vibrating just below hearing.\n\n'
        'A measurement panel glows faintly: one dial, no pointer.',
    exits: {'east': 'obs_corridor', 'south': 'obs_calibration', 'back': 'obs_corridor'},
    examines: {
      'panel':    'A single dial. No pointer. '
          'Label: QUANTUM FLUCTUATION.\n'
          '"Measure only when the instrument has forgotten it is measuring."',
      'darkness': 'True darkness — the kind that has never been interrupted.',
      'silence':  'The presence of something that has not yet decided '
          'whether to become sound.',
      'dial':     'The needle does not exist. Or does not yet.',
    },
  ),

  'obs_archive': _NodeDef(
    title: 'Archive of Constants',
    description: 'Glass cabinets line every wall, each holding a constant '
        'of nature, labelled and lit.\n\n'
        'The speed of light. Planck constant. '
        'The gravitational constant. The fine-structure constant. Others.\n\n'
        'At the far end: a panel with a single input slot.\n'
        '"Enter the value that underlies them all."',
    exits: {'west': 'obs_corridor', 'south': 'obs_calibration', 'back': 'obs_corridor'},
    examines: {
      'constants':       'Each cabinet: a number, a name, a unit. '
          'In natural units, stripped of measurement, they all reduce.',
      'panel':           '"Enter the value that underlies them all.\n'
          'Not a measurement. A statement."',
      'speed of light':  '"c". In natural units: 1.',
      'planck constant': '"h". In natural units: 1.',
      'fine-structure':  'Approximately 1/137. Dimensionless. '
          'The most fundamental number — still not 1.',
      'input':           'A slot for a single number. What do all constants '
          'become when you stop measuring in human units?',
    },
  ),

  'obs_calibration': _NodeDef(
    title: 'Calibration Chamber',
    description: 'A room of instruments, all zeroed.\n\n'
        'At the centre: a calibration station. Three dials, each reading "???". '
        'A placard: "Set the reference point. '
        'All measurement flows from the chosen origin."\n\n'
        'To the north: the dome.',
    exits: {'north': 'obs_dome', 'west': 'obs_void', 'east': 'obs_archive'},
    examines: {
      'dials':   'Three dials, each marked "???". They accept numeric input.',
      'placard': '"There is no absolute origin. The origin is chosen.\n'
          'The honest instrument knows this and starts from zero."',
      'station': 'Three coordinates: X, Y, Z. All reading "???".',
      'door':    'The dome door is sealed. The calibration must be set first.',
    },
  ),

  'obs_dome': _NodeDef(
    title: 'Telescope Dome',
    description: 'The dome opens to a sky that is not a sky.\n\n'
        'No stars — or all stars at once, so dense they form a white field. '
        'At the centre: the telescope, massive, angled toward the sky.\n\n'
        'A brass plate on the base: "Primary mirror — forward-facing."',
    exits: {'south': 'obs_calibration', 'back': 'obs_calibration'},
    examines: {
      'telescope': 'The primary mirror faces outward — toward that impossible sky. '
          'It has been forward-facing since before you arrived.',
      'sky':       'Not stars. Frequencies. Every point of light is a wave '
          'collapsed by the act of being seen.',
      'mirror':    'Primary mirror, facing outward. '
          '"Inversion requires confirmation."',
      'plate':     '"Primary mirror — forward-facing.\nInversion requires confirmation."',
    },
  ),

  // ── Gallery of Mirrors ───────────────────────────────────────────────────────
  'gallery_hall': _NodeDef(
    title: 'Gallery of Mirrors — Hall of First Impression',
    description: 'The golden door opens to a long hall of mirrors.\n\n'
        'You see yourself from every angle. The reflections agree on '
        'your outline but not on your expression.\n\n'
        'At the south end, where a door should be, there is only mirror. '
        'But once — from the corner of your eye — there was something else.',
    exits: {'north': 'la_soglia', 'back': 'la_soglia', 'south': 'gallery_corridor'},
    examines: {
      'mirrors':    'Thirty versions of the same face, each choosing a different truth.',
      'door':       'Where the south door should be: another mirror. '
          'Yet in the reflection, it is open.',
      'reflection': 'You look directly at it. The door in the reflection is open. '
          'In the real wall, it is closed.',
    },
  ),

  'gallery_corridor': _NodeDef(
    title: 'Corridor of Symmetry',
    description: 'The corridor is floored with a mosaic of perfect symmetry.\n\n'
        'Every tile mirrors another — except one. Near the east wall, '
        'one tile catches the light differently. The mosaic was laid '
        'by someone who knew that perfection, undisturbed, becomes invisible.\n\n'
        'A figure walks slowly ahead of you, always the same distance north, '
        'always facing away.',
    exits: {'north': 'gallery_hall', 'south': 'gallery_proportions'},
    examines: {
      'mosaic':         'Black and white. Perfectly mirrored — except for one tile.',
      'tile':           'Near the east wall. Slightly rougher. '
          'The pattern passes through it as if it were smooth.',
      'anomalous tile': 'This tile is wrong. Or right in the wrong way.',
      'figure':         'It walks exactly as fast as you. '
          'When you look directly, it is always just turned away.',
    },
  ),

  'gallery_proportions': _NodeDef(
    title: 'Room of Proportions',
    description: 'The walls are covered in geometric diagrams.\n\n'
        'Euclid constructions: bisection of angles, regular polygons, '
        'the golden ratio. At the centre: a drafting table with compass, '
        'straightedge, and blank paper.\n\n'
        'The south wall shows two arched doorways: east wing, west wing.',
    exits: {
      'north': 'gallery_corridor',
      'east':  'gallery_copies',
      'west':  'gallery_originals',
    },
    examines: {
      'diagrams':     'Euclid constructions. Each carries the notation: '
          '"Form is prior to matter."',
      'table':        'A drafting table. Compass. Straightedge. Blank paper.',
      'compass':      'Set to a specific radius. The hinge is gold.',
      'paper':        'Blank. Waiting for the construction that does not yet exist here.',
      'doorways':     'Two arches: east for copies, west for originals.',
      'golden ratio': 'Cannot be precisely expressed. Only approached, asymptotically.',
    },
  ),

  'gallery_copies': _NodeDef(
    title: 'Wing of Copies',
    description: 'A gallery of technically perfect reproductions.\n\n'
        'Each one is missing something that cannot be named but can be seen — '
        'the thing the original hand added in the original moment.\n\n'
        'To the south: a stairway to a dark chamber.',
    exits: {'north': 'gallery_proportions', 'south': 'gallery_dark'},
    examines: {
      'paintings':   'Perfect copies. The gaps are visible only if you look for them.',
      'first copy':  'A landscape. All colours correct. The light correct. '
          'Something is missing from the lower left corner.',
      'second copy': 'A portrait. The face reproduced exactly. '
          'The expression is empty in a way the original was not.',
      'third copy':  'An abstract composition. Precise. It communicates nothing.',
    },
  ),

  'gallery_originals': _NodeDef(
    title: 'Wing of Originals',
    description: 'A gallery of blank canvases.\n\n'
        'Primed and ready. Brushes and pigments on a long table. '
        'A small sign: "The work does not require skill. '
        'It requires the truth of the specific moment.\n'
        'Paint something that exists only now, only here, only for you.\n'
        'Minimum fifty words."\n\n'
        'To the south: a stairway to a light chamber.',
    exits: {'north': 'gallery_proportions', 'south': 'gallery_light'},
    examines: {
      'canvases': 'Blank. Primed. Three of them.',
      'brushes':  'Every size. More than needed.',
      'sign':     '"The work does not require skill.\n'
          'It requires the truth of the specific moment.\n'
          'Paint something that exists only now, only here, only for you.\n'
          'Minimum fifty words."',
      'pigments': 'Every colour, mixed and unmixed.',
    },
  ),

  'gallery_dark': _NodeDef(
    title: 'Dark Chamber',
    description: 'A room with no light source. And yet you can see.\n\n'
        'Not because of illumination — because this darkness is a kind '
        'of visibility: seeing from within rather than from without.\n\n'
        'In the east wall: a low tunnel to a lit chamber. '
        'It is blocked. The blockage is not physical.',
    exits: {
      'north': 'gallery_copies',
      'east':  'gallery_light',
      'south': 'gallery_central',
    },
    examines: {
      'darkness': 'Vision without light. Objects defined by what surrounds them.',
      'tunnel':   'A low tunnel, east. The blockage is not a wall — it is a condition.',
      'blockage': 'The tunnel requires something to be left behind.',
    },
  ),

  'gallery_light': _NodeDef(
    title: 'Light Chamber',
    description: 'A room entirely lit.\n\n'
        'Every surface reflects. There are no shadows. '
        'Objects are defined only by what falls on them — no depth, only surface.\n\n'
        'In the west wall: the same tunnel, passable from this side.',
    exits: {
      'north': 'gallery_originals',
      'west':  'gallery_dark',
      'south': 'gallery_central',
    },
    examines: {
      'light':   'Total. Everything visible — therefore nothing has depth.',
      'tunnel':  'A low tunnel, west. It connects this room to its opposite.',
      'objects': 'Perfectly visible. Perfectly flat in the way total light makes things flat.',
    },
  ),

  'gallery_central': _NodeDef(
    title: 'Central Gallery — The Perfect Mirror',
    description: 'A circular room. At its centre: the mirror.\n\n'
        'Not a reflection of the room — a reflection of what the room '
        'would be if it were completely honest. The frame is black wood, '
        'unornamented.\n\n'
        'The figure that was walking ahead of you is here, in the mirror. '
        'It has stopped. It is facing you now.',
    exits: {'north': 'gallery_dark', 'back': 'la_soglia'},
    examines: {
      'mirror':     'Flawless. Shows you — and the figure, closer than it should be.',
      'figure':     'In the mirror: facing you. In the room: nothing. '
          'It makes no attempt to explain itself.',
      'frame':      'Black wood. No ornamentation.',
      'reflection': 'Your reflection does not smile. Neither does it grieve. '
          'It waits for you to decide something.',
    },
  ),

  // ── Alchemical Laboratory ────────────────────────────────────────────────────
  'lab_vestibule': _NodeDef(
    title: 'The Alchemical Laboratory — Vestibule of Principles',
    description: 'The violet door opens onto sulphur and something sweeter.\n\n'
        'A vestibule of grey stone. Three niches, each containing '
        'a statue in posture of reception — hands open, waiting. '
        'Each statue has a different bearing: resigned, expectant, indifferent.\n\n'
        'To the south: the Hall of Substances.',
    exits: {'south': 'lab_substances', 'east': 'la_soglia', 'back': 'la_soglia'},
    examines: {
      'statues':       'Three figures with open hands. They accept without judgement.',
      'niches':        'One resigned. One expectant. One indifferent.',
      'first statue':  'Resigned. Hands open but expecting nothing.',
      'second statue': 'Expectant. Face turned slightly upward.',
      'third statue':  'Indifferent. Hands open because it is the position.',
      'sulphur':       'The base smell of transformation. Beneath it: something '
          'sweeter, harder to place.',
    },
  ),

  'lab_substances': _NodeDef(
    title: 'Hall of Substances',
    description: 'A wide hall, its walls covered in alchemical symbols.\n\n'
        'Hundreds of them — spirals, triangles, crosses. Unlabelled. '
        'Their meaning must be decoded from their relationships.\n\n'
        'Three doorways: west to the furnace, south to the alembic, '
        'east to the bain-marie.',
    exits: {
      'north': 'lab_vestibule',
      'west':  'lab_furnace',
      'south': 'lab_alembic',
      'east':  'lab_bain_marie',
    },
    examines: {
      'symbols':  'A dense field. Some familiar: lead, gold. '
          'Three near the centre form a triangle.',
      'triangle': 'Three symbols: Mercury, Sulphur, Salt — the Tria Prima. '
          'The three principles of alchemical transformation.',
      'doorways': 'Three branches. Each requires a different substance, a different patience.',
    },
  ),

  'lab_furnace': _NodeDef(
    title: 'Furnace',
    description: 'An iron furnace, cold.\n\n'
        'The grate is empty. A tray beside it holds grey-white material. '
        'On the wall: "Calcinate. Reduce to essential ash. '
        'Five turnings of the wheel are required."',
    exits: {'east': 'lab_substances', 'south': 'lab_great_work', 'back': 'lab_substances'},
    examines: {
      'furnace':     'Cold iron. The grate is empty. Ready.',
      'tray':        'Grey-white material. Dense.',
      'instruction': '"Calcinate. Reduce to essential ash.\n'
          'Five turnings of the wheel.\n'
          'Patience is the reagent that cannot be purchased."',
    },
  ),

  'lab_alembic': _NodeDef(
    title: 'Alembic',
    description: 'A glass vessel — wide at the base, drawing to a narrow point.\n\n'
        'A liquid of indeterminate colour rests in the lower bulb. '
        'The temperature control accepts a degree '
        'on the alchemical scale: Cold, Gentle, Warm, Hot, Intense, Fierce, Total.\n\n'
        'A crystalline residue coats the inner walls like dried frost.',
    exits: {'north': 'lab_substances', 'south': 'lab_great_work', 'back': 'lab_substances'},
    examines: {
      'vessel':      'Glass, clear. The liquid shifts colour — not due to chemistry.',
      'temperature': 'The control accepts: Cold, Gentle, Warm, Hot, Intense, Fierce, Total.',
      'liquid':      'Below boiling. Waiting for the correct temperature.',
      'residue':     'Crystalline. Mineral. Ancient.',
      'scale':       '"Each degree named for its effect on the substance, not the vessel."',
    },
  ),

  'lab_bain_marie': _NodeDef(
    title: 'Bain-Marie',
    description: 'A water bath — the gentlest form of heat.\n\n'
        'The outer vessel holds cold water. The inner vessel holds '
        'a preparation that cannot be rushed. A placard:\n'
        '"Leave. Return when the water remembers what it has been asked to do.\n'
        'Some transformations begin only in the absence of the one who wants them."\n\n'
        'The preparation has not yet begun.',
    exits: {'west': 'lab_substances', 'south': 'lab_great_work', 'back': 'lab_substances'},
    examines: {
      'bath':        'Outer vessel: cold water. Inner: a thick opaque preparation.',
      'preparation': 'It has not begun its transformation.',
      'placard':     '"Leave. Return when the water remembers.\n'
          'Some things begin only in absence."',
    },
  ),

  'lab_great_work': _NodeDef(
    title: 'Table of the Great Work',
    description: 'A stone table at the convergence of three channels.\n\n'
        'On its surface: a diagram of seven concentric circles, each labelled '
        'with a planetary name. Each circle has a recess for a prepared substance.\n\n'
        'The order is inscribed at the rim:\n'
        'Saturn — Jupiter — Mars — Sun — Venus — Mercury — Moon.\n\n'
        'At the south end: the sealed chamber.',
    exits: {
      'north': 'lab_furnace',
      'west':  'lab_alembic',
      'east':  'lab_bain_marie',
      'south': 'lab_sealed',
    },
    examines: {
      'circles':  'Seven circles, Saturn outermost, Moon innermost. '
          'The alchemical descent: lead to silver, darkness to light.',
      'recesses': 'Each circle has a recess waiting for a prepared substance.',
      'order':    'Saturn → Jupiter → Mars → Sun → Venus → Mercury → Moon. '
          'The Opus Magnum. The order must be exact.',
      'sealed':   'The sealed chamber is south. '
          'It opens when all seven circles are complete '
          'and all three preparation paths have been followed.',
    },
  ),

  'lab_sealed': _NodeDef(
    title: 'Sealed Chamber',
    description: 'A small chamber, sealed until now.\n\n'
        'At its centre: an alembic of extraordinary delicacy — glass so thin '
        'it is held together by the substance within. '
        'The substance glows faintly, pulsing at irregular intervals.\n\n'
        'A card at the base: "The catalyst is not chemical. '
        'It cannot be purchased or synthesised. '
        'You have carried it since before you arrived. Breathe."',
    exits: {'north': 'lab_great_work', 'back': 'lab_great_work'},
    examines: {
      'alembic':   'Glass so thin the substance seems to float without a container.',
      'substance': 'Luminescent. Pulsing — the way a heartbeat is regular.',
      'card':      '"The catalyst is not chemical.\n'
          'It cannot be purchased or synthesised.\n'
          'You have carried it since before you arrived.\n'
          'Breathe."',
    },
  ),

  // ── Fifth Sector stub — accessible once all four simulacra are in inventory ──
  'quinto_landing': _NodeDef(
    title: 'The Fifth Sector — Memory',
    description: 'A spiral staircase brought you here.\n\n'
        'Each candle on the descent was a different age.\n\n'
        'The smell: Earl Grey, dust, and paper that has held ideas for a long time.\n\n'
        'Distant: the Siciliano in B minor.\n\n'
        '"The real life, the life finally discovered and illuminated, '
        'the only life therefore really lived, is literature."\n\n'
        'Four doors stand at the compass points. Each opens onto a different age.\n\n'
        'Below: a sealed chamber that will open when all four prices have been paid.',
    exits: {
      'east':  'quinto_childhood',
      'west':  'quinto_youth',
      'north': 'quinto_maturity',
      'south': 'quinto_old_age',
      'down':  'quinto_ritual_chamber',
      'up':    'la_soglia',
      'back':  'la_soglia',
    },
    examines: {
      'doors':     'Four doors. East: CHILDHOOD. West: YOUTH. North: MATURITY. South: OLD AGE.',
      'staircase': 'The spiral you descended. Each candle burns at its own age.',
      'smell':     'Earl Grey. Dust. Something written by someone who is no longer here.',
      'candles':   'They burn without depleting. Each is a different temperature of light.',
    },
  ),

  'quinto_childhood': _NodeDef(
    title: 'Childhood',
    description: 'A small room. The light is the exact quality of a morning you almost remember.\n\n'
        'On the table: a madeleine of carved wood. '
        'It does not smell of anything, which is somehow its point.\n\n'
        'A card on the wall:\n\n'
        '"Write the first word you truly learned — '
        'not the first word you were taught, but the first one you understood."\n\n'
        'The price of this room is a word.',
    exits: {'back': 'quinto_landing'},
    examines: {
      'madeleine': 'Carved from pale wood. You know what it refers to.',
      'card':      '"Write the first word you truly learned.\n'
          'Not the one you were taught. The one you understood."',
      'light':     'The quality of Saturday morning, before obligation.',
      'table':     'Simple. The madeleine rests at its centre.',
    },
    takeable: {'madeleine'},
  ),

  'quinto_youth': _NodeDef(
    title: 'Youth',
    description: 'A room with the feeling of being in transit.\n\n'
        'Luggage partially packed. A train schedule half-read and set down.\n\n'
        'On the table: a train ticket to Balbec, never used.\n\n'
        'A card:\n\n'
        '"Write a promise you did not keep — not in accusation, but in acknowledgement."\n\n'
        'The price of this room is an admission.',
    exits: {'back': 'quinto_landing'},
    examines: {
      'ticket':   'Balbec. The date is illegible. It has always been slightly too late.',
      'card':     '"Write a promise you did not keep.\nNot in accusation.\nIn acknowledgement."',
      'luggage':  'Half-packed. As if someone was interrupted before completing the idea.',
      'schedule': 'Times and stations. The departures are all behind you.',
    },
    takeable: {'ticket'},
  ),

  'quinto_maturity': _NodeDef(
    title: 'Maturity',
    description: 'A study. Books on every surface.\n\n'
        'A telephone on the desk, receiver off the hook.\n\n'
        'On the desk: a pair of glasses, fogged from breath.\n\n'
        'A card:\n\n'
        '"Answer the telephone. Say what you have never said to the person on the other end."\n\n'
        'The price of this room is speech.',
    exits: {'back': 'quinto_landing'},
    examines: {
      'telephone': 'Off the hook. The line is open. Someone is waiting.',
      'glasses':   'Fogged. You cannot see through them.\n'
          'That is the point — seeing through your own condensation.',
      'card':      '"Answer the telephone.\nSay what you have never said."',
      'books':     'Every subject. Evidence of a life that tried to understand.',
    },
    takeable: {'glasses'},
  ),

  'quinto_old_age': _NodeDef(
    title: 'Old Age',
    description: 'A room that has settled into itself completely.\n\n'
        'Everything is in its place. Everything has a history visible in its surface.\n\n'
        'On the mantelpiece: a clock. The hands are stopped at 17:00. '
        'The light through the window matches.\n\n'
        'A card:\n\n'
        '"Write what you wish to be remembered as. Not an achievement. A quality."\n\n'
        'The price of this room is a truth.',
    exits: {'back': 'quinto_landing'},
    examines: {
      'clock':       'Stopped at 17:00. The afternoon light through the window is exact.',
      'card':        '"Write what you wish to be remembered as.\nNot an achievement.\nA quality."',
      'mantelpiece': 'The clock. A photograph facing away. A small plant, dried.',
      'light':       'Afternoon, late. The hour just before evening becomes certain.',
    },
    takeable: {'clock'},
  ),

  'quinto_ritual_chamber': _NodeDef(
    title: 'The Ritual Chamber',
    description: 'A circular room, low-ceilinged.\n\n'
        'At the centre: a cup of extraordinary simplicity. '
        'Five-sided, made of no material you can name. '
        'It holds a liquid that is neither clear nor coloured.\n\n'
        'This is what the four simulacra were for. '
        'This is what the four sectors have been building toward.\n\n'
        'Place each simulacrum in the cup. Then stir. Then drink.',
    exits: {'up': 'quinto_landing', 'back': 'quinto_landing', 'down': 'il_nucleo'},
    examines: {
      'cup':     'Five-sided. No joins. The liquid inside anticipates your decision.',
      'liquid':  'Neither clear nor coloured. It is waiting for what you have found.',
      'room':    'Circular. Five-sided symmetry. The geometry is familiar — you have seen it before.',
    },
  ),

  // ── Il Nucleo — The Final Confrontation (GDD §12) ─────────────────────────
  'il_nucleo': _NodeDef(
    title: 'The Nucleus — The Final Confrontation',
    description: 'A space with no walls.\n\n'
        'Before you: a figure without a face. '
        'Its features shift — not as if changing, '
        'but as if the concept of features does not apply here.\n\n'
        'When it speaks, the voice is very calm. Very reasonable.\n\n'
        '"You have come a long way. You have carried a great deal. '
        'You have distilled something, I think, that you believe has value.\n\n'
        'I would like to offer you a different reading of what you\'ve found."\n\n'
        'It waits for you to respond.',
    exits: {},
    examines: {
      'figure': 'It has no fixed form. This is not a threat — it is a property.',
      'voice':  'Calm. Reasonable. This is the most unsettling thing about it.',
      'space':  'No walls. No floor in the usual sense. '
          'Yet you are standing on something that holds.',
    },
  ),

  // ── I Tre Finali ──────────────────────────────────────────────────────────
  'finale_acceptance': _NodeDef(
    title: 'Acceptance — La Rivelazione',
    description: 'The Archive grows transparent.\n\n'
        'Through the walls — walls that were always walls — '
        'a vastness opens that resembles coming home.\n\n'
        'Every tear. Every silence. Every imperfection. '
        'They were not failures: they were the raw materials of a soul.\n\n'
        '"Fuori non c\'è il Vuoto. Fuori c\'è tutto."\n\n'
        'The Aria delle Goldberg resumes from its suspended note.\n\n'
        'Type WAKE UP when you are ready.',
    exits: {},
    examines: {
      'light': 'It is not dramatic. It is simply present.',
      'walls': 'They are still here. They are also something else now.',
    },
  ),

  'finale_oblivion': _NodeDef(
    title: 'Oblivion',
    description: '...\n\n'
        '...\n\n'
        '...\n\n'
        '"Lived. Died. No one will remember."\n\n'
        '— Arseny Tarkovsky',
    exits: {},
    examines: {},
  ),

  'finale_eternal_zone': _NodeDef(
    title: 'The Eternal Zone',
    description: 'You remain.\n\n'
        'The variations begin.\n\n'
        'They do not end.',
    exits: {'back': 'la_zona'},
    examines: {
      'variations': 'Infinite. Procedural. Each one specifically yours.',
    },
  ),

  // ── La Zona (GDD §10) ─────────────────────────────────────────────────────
  'la_zona': _NodeDef(
    title: 'The Zone',
    description: 'Impossible geometry.\n\n'
        'A corridor that is also a room. '
        'The walls meet at an angle that should not exist.\n\n'
        'Something is asking you something.',
    exits: {'back': 'la_soglia'},
    examines: {
      'geometry': 'The walls agree only in the angle they refuse to make.',
      'walls':    'Present — but defined by their own impossibility.',
      'space':    'It is inside something. It is also outside it.',
    },
  ),

};

// ── Engine state ──────────────────────────────────────────────────────────────

class GameEngineState {
  final List<GameMessage> messages;
  final ParserPhase phase;
  final int psychoWeight;
  final List<String> inventory;

  /// Puzzle IDs that have been solved, e.g. 'leaves_arranged'.
  final Set<String> completedPuzzles;

  /// Integer counters for multi-step puzzles, e.g. 'fountain_waits': 2.
  final Map<String, int> puzzleCounters;

  const GameEngineState({
    this.messages = const [],
    this.phase = ParserPhase.idle,
    this.psychoWeight = 0,
    this.inventory = const [],
    this.completedPuzzles = const {},
    this.puzzleCounters = const {},
  });

  GameEngineState copyWith({
    List<GameMessage>? messages,
    ParserPhase? phase,
    int? psychoWeight,
    List<String>? inventory,
    Set<String>? completedPuzzles,
    Map<String, int>? puzzleCounters,
  }) {
    return GameEngineState(
      messages:         messages         ?? this.messages,
      phase:            phase            ?? this.phase,
      psychoWeight:     psychoWeight     ?? this.psychoWeight,
      inventory:        inventory        ?? this.inventory,
      completedPuzzles: completedPuzzles ?? this.completedPuzzles,
      puzzleCounters:   puzzleCounters   ?? this.puzzleCounters,
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class GameEngineNotifier extends AsyncNotifier<GameEngineState> {
  final _history = DialogueHistoryService.instance;

  // Maximum value for psychological weight and psycho-profile sliders.
  static const int _maxPsychoValue = 100;

  // Correct leaf order for the Cypress Avenue puzzle (GDD §8 — Epicurean hierarchy).
  // The column words read in reverse (phronesis→philia→aponia→ataraxia) give
  // the means: prudence→friendship→[absence of pain]→tranquillity.
  // Full seven-word progression:
  static const _correctLeafOrder =
      'prudence friendship pleasure simplicity absence tranquillity memory';

  // Planetary order for the Great Work circles (alchemical Opus Magnum descent).
  static const List<String> _planetOrder = [
    'saturn', 'jupiter', 'mars', 'sun', 'venus', 'mercury', 'moon',
  ];

  // ── Small helpers ───────────────────────────────────────────────────────────

  /// Returns true if [itemName] is one of the four weightless simulacra.
  static bool _isSimulacrum(String itemName) => _simulacraNames.contains(itemName);

  /// Strips commas, hyphens and collapses whitespace for puzzle input matching.
  static String _normalizeInput(String input) =>
      input.replaceAll(',', '').replaceAll('-', ' ').replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();

  /// Counts words in [raw] after skipping the first token (the command verb).
  static int _wordCountExcludingVerb(String raw) =>
      raw.trim().split(RegExp(r'\s+')).skip(1).length;

  @override
  Future<GameEngineState> build() async {
    final savedState = await ref.read(gameStateProvider.future);
    final node  = _nodes[savedState.currentNode] ?? _nodes['intro_void']!;
    final intro = _enterNode(node);
    await _history.save(role: 'system', content: 'Session started: ${node.title}');
    return GameEngineState(
      messages:         [GameMessage(text: intro, role: MessageRole.narrative)],
      phase:            ParserPhase.idle,
      inventory:        savedState.inventory.isNotEmpty
                            ? savedState.inventory
                            : const ['notebook'],
      completedPuzzles: savedState.completedPuzzles,
      puzzleCounters:   savedState.puzzleCounters,
      psychoWeight:     savedState.psychoWeight,
    );
  }

  // ── processInput ────────────────────────────────────────────────────────────

  Future<void> processInput(String raw) async {
    final current = state.valueOrNull;
    if (current == null || current.phase != ParserPhase.idle) return;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return;

    state = AsyncValue.data(current.copyWith(phase: ParserPhase.parsing));
    final cmd = ParserService.parse(trimmed);

    final withPlayer = _appendMessage(
      current.copyWith(phase: ParserPhase.evaluating),
      GameMessage(text: '> $trimmed', role: MessageRole.player),
    );
    state = AsyncValue.data(withPlayer);
    await _history.save(role: 'user', content: trimmed);

    final savedState    = await ref.read(gameStateProvider.future);
    final currentNodeId = savedState.currentNode;
    final evaluationResponse = _evaluate(cmd, currentNodeId, withPlayer);

    // ── La Zona activation (GDD §10) ────────────────────────────────────────
    final response = (evaluationResponse.newNode != null)
        ? _maybeActivateZone(evaluationResponse, currentNodeId, withPlayer)
        : evaluationResponse;

    state = AsyncValue.data(withPlayer.copyWith(phase: ParserPhase.eventResolved));

    // ── Apply weight (never below 0 or above _maxPsychoValue) ──────────────
    int newWeight = (withPlayer.psychoWeight + response.weightDelta).clamp(0, _maxPsychoValue);

    // ── Apply inventory changes ─────────────────────────────────────────────
    List<String> newInventory = List.from(withPlayer.inventory);
    if (response.grantItem != null && !newInventory.contains(response.grantItem!)) {
      newInventory.add(response.grantItem!);
    }
    // drop removes from inventory (except Great Work and Ritual Chamber placements)
    if (cmd.verb == CommandVerb.drop && cmd.args.isNotEmpty &&
        currentNodeId != 'lab_great_work' &&
        currentNodeId != 'quinto_ritual_chamber') {
      newInventory.remove(cmd.args.join(' '));
    }
    // deposit clears mundane items only when the deposit actually succeeds.
    // Failed deposits (wrong node, alcoves not walked, etc.) must NOT clear
    // inventory — the player would lose all items with no benefit.
    // In boss context (il_nucleo): preserve simulacra — only remove mundane items.
    if (cmd.verb == CommandVerb.deposit && response.clearInventoryOnDeposit) {
      if (currentNodeId == 'il_nucleo') {
        newInventory = newInventory.where(_isSimulacrum).toList();
      } else {
        newInventory.clear();
      }
      newWeight = 0;
      if (response.grantItem != null) newInventory.add(response.grantItem!);
    }

    // ── Apply puzzle state ──────────────────────────────────────────────────
    final Set<String>      newPuzzles  = Set<String>.from(withPlayer.completedPuzzles);
    final Map<String, int> newCounters = Map<String, int>.from(withPlayer.puzzleCounters);

    if (response.completePuzzle != null)  newPuzzles.add(response.completePuzzle!);
    if (response.incrementCounter != null) {
      newCounters[response.incrementCounter!] =
          (newCounters[response.incrementCounter!] ?? 0) + 1;
    }

    // ── Navigation + bain-marie tracking + zone tracking ───────────────────
    if (response.newNode != null) {
      // Node persistence is deferred to saveEngineState at the end of this method
      // so that all state changes (puzzles, counters, inventory) are written atomically.

      // Mark bain-marie departure
      if (currentNodeId == 'lab_bain_marie' &&
          !newPuzzles.contains('bain_marie_left')) {
        newPuzzles.add('bain_marie_left');
      }
      // Count external (non-lab) visits for bain-marie return puzzle
      if (!response.newNode!.startsWith('lab_') &&
          newPuzzles.contains('bain_marie_left') &&
          !newPuzzles.contains('bain_marie_complete')) {
        final visits = (newCounters['bain_marie_external'] ?? 0) + 1;
        newCounters['bain_marie_external'] = visits;
        if (visits >= 3) newPuzzles.add('bain_marie_complete');
      }

      // Zone encounter tracking
      if (response.newNode == 'la_zona') {
        newCounters['zone_encounters'] = (newCounters['zone_encounters'] ?? 0) + 1;
        newCounters['consecutive_transits'] = 0;
      }

      // Consecutive transit tracking (la_soglia ↔ sectors)
      final isTransit = currentNodeId == 'la_soglia' || response.newNode == 'la_soglia';
      if (isTransit && response.newNode != 'la_zona') {
        newCounters['consecutive_transits'] =
            (newCounters['consecutive_transits'] ?? 0) + 1;
      } else if (!isTransit && response.newNode != 'la_zona') {
        newCounters['consecutive_transits'] = 0;
      }
    }

    // ── Apply psycho profile ────────────────────────────────────────────────
    if (response.anxietyDelta != null ||
        response.lucidityDelta != null ||
        response.oblivionDelta != null) {
      final profile = await ref.read(psychoProfileProvider.future);
      await ref.read(psychoProfileProvider.notifier).updateParameter(
        lucidity: response.lucidityDelta != null
            ? (profile.lucidity + response.lucidityDelta!).clamp(0, _maxPsychoValue)
            : null,
        anxiety: response.anxietyDelta != null
            ? (profile.anxiety + response.anxietyDelta!).clamp(0, _maxPsychoValue)
            : null,
        oblivionLevel: response.oblivionDelta != null
            ? (profile.oblivionLevel + response.oblivionDelta!).clamp(0, _maxPsychoValue)
            : null,
      );
    }

    // ── Audio trigger ────────────────────────────────────────────────────────
    await AudioService().handleTrigger(response.audioTrigger);

    // ── Player memory (proustian responses + zone responses) ─────────────────
    if (response.playerMemoryKey != null) {
      final memoryContent = cmd.verb == CommandVerb.unknown
          ? trimmed
          : cmd.args.join(' ').trim();
      if (memoryContent.isNotEmpty) {
        await DatabaseService.instance.saveMemory(
          key:     response.playerMemoryKey!,
          content: memoryContent,
        );
      }
    }

    // ── Display ─────────────────────────────────────────────────────────────
    final demiurgeNodeId = response.newNode ?? currentNodeId;
    final narrativeText = response.needsLlm
        ? _callDemiurge(response.narrativeText, demiurgeNodeId)
        : response.narrativeText;
    await _history.save(role: 'demiurge', content: narrativeText);

    final finalState = withPlayer.copyWith(
      phase:            ParserPhase.displaying,
      psychoWeight:     newWeight,
      inventory:        newInventory,
      completedPuzzles: newPuzzles,
      puzzleCounters:   newCounters,
    );

    // ── Persist full engine state ─────────────────────────────────────────────
    final savedNodeId = response.newNode ?? currentNodeId;
    await ref.read(gameStateProvider.notifier).saveEngineState(
      currentNode:      savedNodeId,
      completedPuzzles: newPuzzles,
      puzzleCounters:   newCounters,
      inventory:        newInventory,
      psychoWeight:     newWeight,
    );

    final withNarrative = _appendMessage(
      finalState,
      GameMessage(text: narrativeText, role: MessageRole.narrative),
    );
    state = AsyncValue.data(withNarrative);
    await Future.delayed(const Duration(milliseconds: 100));
    state = AsyncValue.data(withNarrative.copyWith(phase: ParserPhase.idle));
  }

  // ── _evaluate ───────────────────────────────────────────────────────────────

  EngineResponse _evaluate(
    ParsedCommand cmd,
    String nodeId,
    GameEngineState s,
  ) {
    final node = _nodes[nodeId];
    if (node == null) {
      return const EngineResponse(narrativeText: 'The Archive does not recognise this place.');
    }

    // ── Il Nucleo: route most commands through boss handler (GDD §12) ────────
    if (nodeId == 'il_nucleo' &&
        cmd.verb != CommandVerb.inventory &&
        cmd.verb != CommandVerb.examine &&
        cmd.verb != CommandVerb.help) {
      return _handleBossInput(cmd, s);
    }

    // ── Finale nodes: minimal interactions ───────────────────────────────────
    if (nodeId == 'finale_acceptance' || nodeId == 'finale_oblivion' ||
        nodeId == 'finale_eternal_zone') {
      if (cmd.verb == CommandVerb.inventory || cmd.verb == CommandVerb.examine ||
          cmd.verb == CommandVerb.help) {
        // Fall through to normal handling
      } else {
        return _handleFinaleInput(cmd, nodeId, s);
      }
    }

    switch (cmd.verb) {
      case CommandVerb.help:
        return const EngineResponse(narrativeText: _helpText);

      case CommandVerb.inventory:
        return EngineResponse(
          narrativeText: s.inventory.isEmpty
              ? 'You carry nothing but a sense of incompleteness.'
              : 'You carry: ${s.inventory.join(", ")}.\n\n'
                'Psychological weight: ${s.psychoWeight}.',
        );

      case CommandVerb.examine:
        return _handleExamine(cmd, node);

      case CommandVerb.go:
        return _handleGo(cmd, node, nodeId, s);

      case CommandVerb.wait:
        return _handleWait(nodeId, s);

      case CommandVerb.take:
        return _handleTake(cmd, node, s);

      case CommandVerb.drop:
        return _handleDrop(cmd, nodeId, s);

      case CommandVerb.deposit:
        return _handleDeposit(nodeId, s);

      case CommandVerb.smell:
        return _handleSmell(nodeId);

      case CommandVerb.taste:
        return _handleTaste(nodeId);

      case CommandVerb.walk:
        return _handleWalk(cmd, nodeId, s);

      case CommandVerb.arrange:
        return _handleArrange(cmd, nodeId, s);

      case CommandVerb.write:
        return _handleWrite(cmd, nodeId, s);

      case CommandVerb.combine:
        return _handleCombine(cmd, nodeId, s);

      case CommandVerb.press:
        return _handlePress(cmd, nodeId, s);

      case CommandVerb.offer:
        return _handleOffer(cmd, nodeId, s);

      case CommandVerb.measure:
        return _handleMeasure(cmd, nodeId, s);

      case CommandVerb.calibrate:
        return _handleCalibrate(cmd, nodeId, s);

      case CommandVerb.invert:
        return _handleInvert(cmd, nodeId, s);

      case CommandVerb.confirm:
        return _handleConfirm(nodeId, s);

      case CommandVerb.breakObj:
        return _handleBreak(cmd, nodeId, s);

      case CommandVerb.blow:
        return _handleBlow(nodeId, s);

      case CommandVerb.setParam:
        return _handleSetParam(cmd, nodeId, s);

      case CommandVerb.drink:
        return _handleDrink(nodeId, s);

      case CommandVerb.stir:
        return _handleStir(nodeId, s);

      case CommandVerb.unknown:
        return _handleUnknown(cmd, nodeId, s);

      default:
        return const EngineResponse(
          narrativeText: 'Nothing happens. Perhaps the moment has not come.',
        );
    }
  }

  // ── Handlers ─────────────────────────────────────────────────────────────────

  EngineResponse _handleExamine(ParsedCommand cmd, _NodeDef node) {
    if (cmd.args.isEmpty) {
      return EngineResponse(narrativeText: _enterNode(node), needsLlm: true);
    }
    final target = cmd.args.join(' ');
    final match = node.examines.entries
        .where((e) => e.key.contains(target) || target.contains(e.key))
        .map((e) => e.value)
        .firstOrNull;
    if (match != null) return EngineResponse(narrativeText: match, needsLlm: true);
    return const EngineResponse(narrativeText: 'You observe it closely. It offers nothing new.');
  }

  EngineResponse _handleGo(
    ParsedCommand cmd,
    _NodeDef node,
    String nodeId,
    GameEngineState s,
  ) {
    if (cmd.args.isEmpty) {
      return const EngineResponse(narrativeText: 'Where do you wish to go?');
    }
    final direction = cmd.args.first;

    // Special: Quinto Settore requires all four simulacra
    if (direction == 'up' && nodeId == 'la_soglia') {
      final hasAll = _simulacraNames.every((n) => s.inventory.contains(n));
      if (!hasAll) {
        final missing = _simulacraNames
            .where((n) => !s.inventory.contains(n))
            .join(', ');
        return EngineResponse(
          narrativeText: 'The fifth recess on the pedestal is dark.\n\n'
              'Four simulacra must be held before the staircase forms.\n\n'
              'You are missing: $missing.',
        );
      }
    }

    if (nodeId == 'la_zona' && direction == 'back') {
      final encounters = s.puzzleCounters['zone_encounters'] ?? 0;
      final respondedKey = 'zone_responded_$encounters';
      if (!s.completedPuzzles.contains(respondedKey)) {
        return const EngineResponse(
          narrativeText: 'The Zone does not release you yet.\n\n'
              'It is still waiting for your answer.',
        );
      }
    }

    // Special: lab_great_work → lab_sealed requires all three lab paths done
    if (nodeId == 'lab_great_work' && direction == 'south') {
      final done = s.completedPuzzles;
      if (!done.contains('furnace_calcinated') ||
          !done.contains('alembic_temperature_set') ||
          !done.contains('bain_marie_complete') ||
          !done.contains('lab_great_work_complete')) {
        return const EngineResponse(
          narrativeText: 'The sealed chamber will not open.\n\n'
              'Three channels must converge and the Great Work be complete '
              'before the door yields.',
        );
      }
    }

    // Special: quinto_landing → quinto_ritual_chamber requires all 4 memory prices
    if (nodeId == 'quinto_landing' && direction == 'down') {
      const memories = {
        'memory_childhood', 'memory_youth', 'memory_maturity', 'memory_old_age',
      };
      if (!memories.every(s.completedPuzzles.contains)) {
        final missing = memories
            .where((m) => !s.completedPuzzles.contains(m))
            .map((m) => m.replaceFirst('memory_', '').replaceAll('_', ' '))
            .join(', ');
        return EngineResponse(
          narrativeText: 'The lower chamber is sealed.\n\n'
              'Four prices remain unpaid: $missing.\n\n'
              'Return through each room and pay the price.',
        );
      }
    }

    // Special: lab_substances branches require all three substances collected
    if (nodeId == 'lab_substances' && direction != 'north') {
      final done = s.completedPuzzles;
      if (!done.contains('lab_mercury_collected') ||
          !done.contains('lab_sulphur_collected') ||
          !done.contains('lab_salt_collected')) {
        return const EngineResponse(
          narrativeText: 'The branches are sealed. The substances must be gathered first.\n\n'
              'Hint: decipher symbols — then collect each substance.',
        );
      }
    }

    // Exit gate check (all other gates)
    final requiredPuzzle = _exitGates[nodeId]?[direction];
    if (requiredPuzzle != null && !s.completedPuzzles.contains(requiredPuzzle)) {
      return EngineResponse(
        narrativeText: _gateHints[requiredPuzzle] ??
            'Something holds you back. A condition has not yet been met.',
      );
    }

    final dest = node.exits[direction];
    if (dest == null) {
      return const EngineResponse(narrativeText: 'There is nothing in that direction.');
    }
    final destNode = _nodes[dest];
    if (destNode == null) {
      return const EngineResponse(narrativeText: 'That way is not yet open.');
    }

    // Special: bain-marie return after three external visits
    if (dest == 'lab_bain_marie' &&
        s.completedPuzzles.contains('bain_marie_left') &&
        s.completedPuzzles.contains('bain_marie_complete')) {
      return EngineResponse(
        narrativeText: 'Bain-Marie\n\n'
            'The outer water has changed. It is warm — not because of heat, '
            'but because of time.\n\n'
            'The inner preparation is moving. Slowly, it has become '
            'what it needed to become.\n\n'
            'The path south to the Great Work opens.',
        newNode: dest,
        needsLlm: true,
      );
    }

    return EngineResponse(
      narrativeText: _enterNode(destNode),
      newNode: dest,
      needsLlm: true,
      // Siciliano BWV 1017 when entering the Fifth Sector; silence for Oblivion finale
      audioTrigger: dest == 'quinto_landing'     ? 'siciliano'
                  : dest == 'finale_acceptance'  ? 'aria_goldberg'
                  : dest == 'finale_oblivion'    ? 'silence'
                  : dest == 'il_nucleo'          ? 'oblivion'
                  : null,
    );
  }

  EngineResponse _handleWait(String nodeId, GameEngineState s) {
    // Garden fountain: three waits open the passage north
    if (nodeId == 'garden_fountain') {
      if (s.completedPuzzles.contains('fountain_waited')) {
        return const EngineResponse(
          narrativeText: 'The fountain has already given what it had. The path north is open.',
        );
      }
      final waits = (s.puzzleCounters['fountain_waits'] ?? 0) + 1;
      if (waits < 3) {
        return EngineResponse(
          narrativeText: waits == 1
              ? 'You wait.\n\nNothing comes. The dust settles back into itself.'
              : 'You wait again.\n\nA faint condensation forms at the lip of the fountain.',
          incrementCounter: 'fountain_waits',
        );
      }
      return const EngineResponse(
        narrativeText: 'A third time — and in the silence, a single drop of condensation '
            'slides down the stone and disappears into the dust.\n\n'
            'You have learned something. You are not sure what.\n\n'
            'The path north opens.',
        needsLlm: true,
        incrementCounter: 'fountain_waits',
        completePuzzle:   'fountain_waited',
        lucidityDelta:    3,
      );
    }

    // Observatory void: seven waits → Proustian bagliore → enable measure
    if (nodeId == 'obs_void') {
      if (s.completedPuzzles.contains('void_silence_complete')) {
        return const EngineResponse(
          narrativeText: 'The void has already spoken. '
              'Measure fluctuation to proceed.',
        );
      }
      final silence = (s.puzzleCounters['void_silence'] ?? 0) + 1;
      if (silence < 7) {
        return EngineResponse(
          narrativeText: 'You do nothing.\n\nThe void notes this. '
              '$silence of seven turnings.',
          incrementCounter: 'void_silence',
        );
      }
      return const EngineResponse(
        narrativeText: 'The seventh turning.\n\n'
            'A light — brief, inexplicable — crosses the darkness from no direction. '
            'You are briefly not here. A road between two church steeples at dusk, '
            'a light that moved and became something else.\n\n'
            'The dial now has a pointer. It is trembling.\n\n'
            'Now: measure fluctuation.',
        needsLlm:         true,
        incrementCounter: 'void_silence',
        completePuzzle:   'void_silence_complete',
        lucidityDelta:    -5,
        anxietyDelta:     5,
        audioTrigger:     'sfx:proustian_trigger',
      );
    }

    // Lab furnace: five waits while calcinating → calcination complete
    if (nodeId == 'lab_furnace') {
      if (!s.completedPuzzles.contains('furnace_calcinating')) {
        return const EngineResponse(
          narrativeText: 'The furnace is cold. Nothing is calcinating yet.\n\n'
              'Hint: calcinate first.',
        );
      }
      if (s.completedPuzzles.contains('furnace_calcinated')) {
        return const EngineResponse(
          narrativeText: 'The calcination is complete. The ash awaits the next stage.',
        );
      }
      final turns = (s.puzzleCounters['furnace_waits'] ?? 0) + 1;
      if (turns < 5) {
        return EngineResponse(
          narrativeText: 'The furnace glows. The material reduces. '
              '$turns of five turnings.',
          incrementCounter: 'furnace_waits',
        );
      }
      return const EngineResponse(
        narrativeText: 'The fifth turning.\n\n'
            'The material has reduced to fine white ash — no longer what it was. '
            'Something essential remains.\n\n'
            'The furnace path south is clear.',
        needsLlm:         true,
        incrementCounter: 'furnace_waits',
        completePuzzle:   'furnace_calcinated',
        lucidityDelta:    5,
      );
    }

    return const EngineResponse(narrativeText: 'Time passes. The Archive observes.');
  }

  EngineResponse _handleTake(ParsedCommand cmd, _NodeDef node, GameEngineState s) {
    if (cmd.args.isEmpty) return const EngineResponse(narrativeText: 'Take what?');
    final target = cmd.args.join(' ');

    // Takeable objects (+1 weight)
    final takeMatch = node.takeable
        .where((t) => t.contains(target) || target.contains(t))
        .firstOrNull;
    if (takeMatch != null) {
      if (s.inventory.contains(takeMatch)) {
        return EngineResponse(narrativeText: 'You already carry the $takeMatch.');
      }
      return EngineResponse(
        narrativeText: 'You pick up the $takeMatch.\n\n'
            'It settles into your hands with the weight of a decision.',
        needsLlm:   true,
        weightDelta: 1,
        anxietyDelta: 2,
        grantItem:   takeMatch,
      );
    }

    return const EngineResponse(narrativeText: 'You cannot take that.');
  }

  EngineResponse _handleDrop(ParsedCommand cmd, String nodeId, GameEngineState s) {
    if (cmd.args.isEmpty) return const EngineResponse(narrativeText: 'Drop what?');
    final target = cmd.args.join(' ');

    // Lab Great Work: placement puzzle
    if (nodeId == 'lab_great_work') return _handleGreatWorkPlacement(cmd, s);

    // Ritual Chamber: place simulacra in cup
    if (nodeId == 'quinto_ritual_chamber') return _handleRitualPlacement(cmd, s);

    final match = s.inventory
        .where((i) => i.contains(target) || target.contains(i))
        .firstOrNull;
    if (match == null) return const EngineResponse(narrativeText: 'You are not carrying that.');

    final isSimulacrum = _isSimulacrum(match);

    // Gallery dark chamber: dropping anything opens the tunnel
    if (nodeId == 'gallery_dark' && !s.completedPuzzles.contains('gallery_item_abandoned')) {
      return EngineResponse(
        narrativeText: 'You set down the $match.\n\n'
            'It remains on the floor. The tunnel between the chambers opens — '
            'as if the act of leaving something was all it required.',
        weightDelta:    isSimulacrum ? 0 : -1,
        anxietyDelta:   isSimulacrum ? 0 : -1,
        completePuzzle: 'gallery_item_abandoned',
        lucidityDelta:  5,
        needsLlm:       true,
      );
    }

    return EngineResponse(
      narrativeText: 'You set down the $match. '
          'It seems smaller without your hands around it.',
      weightDelta:  isSimulacrum ? 0 : -1,
      anxietyDelta: isSimulacrum ? 0 : -1,
    );
  }

  EngineResponse _handleGreatWorkPlacement(ParsedCommand cmd, GameEngineState s) {
    if (s.completedPuzzles.contains('lab_great_work_complete')) {
      return const EngineResponse(narrativeText: 'The Great Work is already complete.');
    }
    final step = s.puzzleCounters['great_work_step'] ?? 0;
    if (step >= 7) {
      return const EngineResponse(narrativeText: 'The Great Work is already complete.');
    }
    final expectedPlanet = _planetOrder[step];
    if (!cmd.args.join(' ').contains(expectedPlanet)) {
      return EngineResponse(
        narrativeText: 'That is not the correct circle.\n\n'
            'The $expectedPlanet circle must receive its substance next.\n\n'
            'Order: ${_planetOrder.join(" → ")}',
      );
    }
    final isLast = step == 6;
    return EngineResponse(
      narrativeText: isLast
          ? 'The seventh placement.\n\n'
            'All seven circles glow with amber light. '
            'The Great Work is complete.\n\n'
            'The sealed chamber door opens to the south.'
          : 'You place the substance in the $expectedPlanet circle.\n\n'
            '${6 - step} more placement${6 - step == 1 ? "" : "s"} remain.',
      needsLlm:         isLast,
      incrementCounter: 'great_work_step',
      completePuzzle:   isLast ? 'lab_great_work_complete' : null,
      lucidityDelta:    isLast ? 10 : null,
    );
  }

  EngineResponse _handleDeposit(String nodeId, GameEngineState s) {
    if (nodeId != 'garden_grove') {
      return const EngineResponse(narrativeText: 'There is nowhere here to deposit anything.');
    }
    // Both alcoves must have been walked through (GDD §8 — puzzle 4 before puzzle 5)
    if (!s.completedPuzzles.contains('alcove_pleasures_walked') ||
        !s.completedPuzzles.contains('alcove_pains_walked')) {
      return const EngineResponse(
        narrativeText: 'Something holds you back.\n\n'
            'You have not yet passed through both alcoves. '
            'The statue accepts only those who have faced pleasure and pain '
            'and chosen to walk through each without grasping.',
      );
    }
    if (s.inventory.every((i) => _simulacraNames.contains(i))) {
      return const EngineResponse(
        narrativeText: 'You carry only what you cannot deposit.\n\n'
            'The statue\'s open hands seem to already know this.',
        needsLlm: true,
      );
    }
    return const EngineResponse(
      narrativeText: 'You place everything at the statue\'s feet.\n\n'
          'The objects arrange themselves in a loose circle. '
          'They look smaller than you remember.\n\n'
          'The expression on the statue\'s face does not change. '
          'You feel, for the first time in this place, something that resembles relief.\n\n'
          'In one of the open hands: a glass sphere, perfectly empty. Ataraxia.',
      needsLlm:               true,
      lucidityDelta:          10,
      anxietyDelta:           -20,
      audioTrigger:           'calm',
      grantItem:              'ataraxia',
      completePuzzle:         'garden_complete',
      clearInventoryOnDeposit: true,
    );
  }

  EngineResponse _handleSmell(String nodeId) {
    if (nodeId == 'garden_alcove_pleasures') {
      return const EngineResponse(
        narrativeText: 'The scent of linden blossom.\n\n'
            'And then — without transition — a room you knew once. '
            'Not this Archive. A door, half-open, and afternoon light through it.\n\n'
            '"l\'odore e il sapore restano ancora a lungo, come anime."\n\n'
            'The smell fades. The room does not.',
        needsLlm:     true,
        lucidityDelta: -5,
        anxietyDelta:  5,
        audioTrigger:  'sfx:proustian_trigger',
      );
    }
    return const EngineResponse(narrativeText: 'The air here carries only itself.');
  }

  EngineResponse _handleTaste(String nodeId) {
    // Proustian trigger: crystal residue in lab furnace (GDD §9)
    if (nodeId == 'lab_furnace') {
      return const EngineResponse(
        narrativeText: 'A taste of something burnt and impossibly sweet.\n\n'
            'You are elsewhere — briefly. A kitchen. A morning. '
            'Something ordinary that was, in fact, everything.\n\n'
            '"La madeleine de Combray."\n\n'
            'You return. The ash on your lips is cold.',
        needsLlm:     true,
        lucidityDelta: -8,
        anxietyDelta:  8,
        audioTrigger:  'sfx:proustian_trigger',
      );
    }
    return const EngineResponse(narrativeText: 'You taste nothing of consequence.');
  }

  EngineResponse _handleWalk(ParsedCommand cmd, String nodeId, GameEngineState s) {
    final mode = cmd.args.join(' ');

    // Garden alcoves: walk through without grasping (GDD §8 — puzzle 4)
    if (nodeId == 'garden_alcove_pleasures' && mode == 'through') {
      if (s.completedPuzzles.contains('alcove_pleasures_walked')) {
        return const EngineResponse(narrativeText: 'You have already walked through here.');
      }
      return const EngineResponse(
        narrativeText: 'You walk through without touching anything.\n\n'
            'It is harder than it sounds. '
            'The objects pull at a version of you that you choose not to be.',
        needsLlm:       true,
        lucidityDelta:  7,
        completePuzzle: 'alcove_pleasures_walked',
      );
    }
    if (nodeId == 'garden_alcove_pains' && mode == 'through') {
      if (s.completedPuzzles.contains('alcove_pains_walked')) {
        return const EngineResponse(narrativeText: 'You have already walked through here.');
      }
      return const EngineResponse(
        narrativeText: 'You walk through without taking anything.\n\n'
            'The objects here pull differently — not with beauty but with familiarity. '
            'Walking past them feels like a small betrayal and a small liberation.',
        needsLlm:       true,
        lucidityDelta:  7,
        completePuzzle: 'alcove_pains_walked',
      );
    }

    // Gallery hall: walk backward to find the hidden door (GDD §8 — puzzle 1)
    if (nodeId == 'gallery_hall' &&
        (mode.contains('backward') || mode.contains('back'))) {
      if (s.completedPuzzles.contains('hall_backward_walked')) {
        return const EngineResponse(
          narrativeText: 'The corridor south is already open.',
        );
      }
      return const EngineResponse(
        narrativeText: 'You walk backward, facing north, watching your reflection recede.\n\n'
            'Something shifts. Behind you — south — a door appears in the mirror. '
            'It was there all along. You were facing the wrong way.\n\n'
            'The corridor south is open.',
        needsLlm:       true,
        lucidityDelta:  5,
        completePuzzle: 'hall_backward_walked',
      );
    }

    // Observatory corridor: walk blindfolded — Heisenberg puzzle (GDD §8 — puzzle 2)
    if (nodeId == 'obs_corridor' &&
        (mode.contains('blind') || mode == 'blindfolded')) {
      if (s.completedPuzzles.contains('heisenberg_walked')) {
        return const EngineResponse(
          narrativeText: 'You have already demonstrated this understanding. '
              'Both branches are open.',
        );
      }
      return const EngineResponse(
        narrativeText: 'You close your eyes — then something more than eyes.\n\n'
            'You walk. Without looking, you arrive. '
            'You do not know exactly where. You do not know exactly how.\n\n'
            'That is the point.\n\n'
            'The branches open: west to the void, east to the archive.',
        needsLlm:       true,
        lucidityDelta:  8,
        anxietyDelta:   -5,
        completePuzzle: 'heisenberg_walked',
      );
    }

    return const EngineResponse(narrativeText: 'Nothing happens. Perhaps the moment has not come.');
  }

  EngineResponse _handleArrange(ParsedCommand cmd, String nodeId, GameEngineState s) {
    if (nodeId != 'garden_cypress') {
      return const EngineResponse(narrativeText: 'There is nothing here to arrange.');
    }
    if (s.completedPuzzles.contains('leaves_arranged')) {
      return const EngineResponse(
        narrativeText: 'The leaves are already in their correct order. The path north is open.',
      );
    }
    if (cmd.args.isEmpty) {
      return const EngineResponse(
        narrativeText: 'The leaves shift but settle back unchanged.\n\n'
            'Seven words, in Epicurean order.\n\n'
            'Hint: arrange leaves [word word word word word word word]',
      );
    }
    // Normalise: strip commas, hyphens, extra spaces (shared helper)
    final input = _normalizeInput(cmd.args.join(' '));

    if (input == _correctLeafOrder) {
      return const EngineResponse(
        narrativeText: 'The leaves move — or you move them. They settle into a line '
            'that feels, now that you see it, obvious.\n\n'
            'prudence — friendship — pleasure — simplicity — '
            'absence — tranquillity — memory.\n\n'
            'The path north opens.',
        needsLlm:       true,
        lucidityDelta:  10,
        completePuzzle: 'leaves_arranged',
        audioTrigger:   'calm',
      );
    }
    return const EngineResponse(
      narrativeText: 'The leaves arrange themselves briefly — then scatter.\n\n'
          'The order is not correct. '
          'Consider: what comes first in Epicurean thought? '
          'What enables everything else?\n\n'
          'Read the column words in the portico — in reverse.',
    );
  }

  EngineResponse _handleWrite(ParsedCommand cmd, String nodeId, GameEngineState s) {
    // Garden stelae: inscribe the missing maxim (GDD §8 — puzzle 3)
    if (nodeId == 'garden_stelae') {
      if (s.psychoWeight > 0) {
        return const EngineResponse(
          narrativeText: 'The blank stele\'s surface is illegible to you.\n\n'
              'The burden you carry clouds your perception. '
              'The maxim cannot be inscribed by one who has grasped at things.',
        );
      }
      if (s.completedPuzzles.contains('stele_inscribed')) {
        return const EngineResponse(narrativeText: 'The stele is already inscribed.');
      }
      if (cmd.args.isEmpty) {
        return const EngineResponse(
          narrativeText: 'Inscribe what? The stylus is ready, but the maxim must be supplied.\n\n'
              'Read the eleven that came before. Understand what they build toward.',
        );
      }
      // Use word-boundary regex so "friendship" inside e.g. "no friendship" still
      // counts but "unfriendship" would not — consistent with the puzzle intent.
      if (RegExp(r'\bfriendship\b').hasMatch(cmd.rawInput.toLowerCase())) {
        return const EngineResponse(
          narrativeText: 'The stylus moves. The words appear:\n\n'
              '"Of all wisdom\'s gifts to a happy life, '
              'the greatest is the possession of friendship."\n\n'
              'The twelfth stele is complete. The grove opens.',
          needsLlm:       true,
          lucidityDelta:  12,
          completePuzzle: 'stele_inscribed',
          audioTrigger:   'calm',
        );
      }
      return const EngineResponse(
        narrativeText: 'The marks fade.\n\n'
            'The maxim is not yet right. '
            'Consider the column words in the portico. '
            'One of the seven leaf words is what the statue\'s open hands are asking for.',
      );
    }

    // Gallery proportions: construct pentagon (GDD §8 — puzzle 3)
    if (nodeId == 'gallery_proportions') {
      if (cmd.rawInput.toLowerCase().contains('pentagon')) {
        if (s.completedPuzzles.contains('proportion_pentagon_drawn')) {
          return const EngineResponse(
            narrativeText: 'The pentagon is already constructed. Both wings are open.',
          );
        }
        return const EngineResponse(
          narrativeText: 'You construct the pentagon — compass, straightedge, '
              'the ancient method. It forms with a precision that feels inevitable.\n\n'
              'The two wings open: east for copies, west for originals.',
          needsLlm:       true,
          lucidityDelta:  8,
          completePuzzle: 'proportion_pentagon_drawn',
          audioTrigger:   'calm',
        );
      }
    }

    // Gallery copies: describe the missing elements — three times (GDD §8 — puzzle 4)
    if (nodeId == 'gallery_copies') {
      if (s.completedPuzzles.contains('gallery_copies_complete')) {
        return const EngineResponse(
          narrativeText: 'You have already described the three missing elements.',
        );
      }
      if (cmd.args.isEmpty) {
        return const EngineResponse(
          narrativeText: 'Describe what is missing from one of the copies.',
        );
      }
      final described = (s.puzzleCounters['gallery_copies_described'] ?? 0) + 1;
      if (described < 3) {
        return EngineResponse(
          narrativeText: 'You name the absence.\n\n'
              'The copy brightens slightly — as if acknowledging '
              'that someone noticed. $described of three.',
          incrementCounter: 'gallery_copies_described',
        );
      }
      return const EngineResponse(
        narrativeText: 'The third description.\n\n'
            'All three gaps have been seen and named. '
            'The wing opens the passage south.',
        needsLlm:         true,
        incrementCounter: 'gallery_copies_described',
        completePuzzle:   'gallery_copies_complete',
        lucidityDelta:    8,
      );
    }

    // Gallery originals: paint an imaginary work — minimum 50 words (GDD §8 — puzzle 5)
    if (nodeId == 'gallery_originals') {
      if (s.completedPuzzles.contains('gallery_originals_complete')) {
        return const EngineResponse(narrativeText: 'The canvas already holds your work.');
      }
      // _wordCountExcludingVerb skips the first token (the command word itself).
      final wordCount = _wordCountExcludingVerb(cmd.rawInput);
      if (wordCount < 50) {
        return EngineResponse(
          narrativeText: 'The canvas does not accept this.\n\n'
              'The sign says the truth of the specific moment. '
              'You have given $wordCount words. '
              'Fifty are required — not for quantity, but because brevity here is evasion.',
        );
      }
      return const EngineResponse(
        narrativeText: 'You paint.\n\n'
            'Not the painting itself — the act of it. '
            'When you stop, something exists that did not exist before.\n\n'
            'The passage south opens.',
        needsLlm:       true,
        completePuzzle: 'gallery_originals_complete',
        lucidityDelta:  10,
        audioTrigger:   'calm',
      );
    }

    // Fifth Sector — memory price for each room (GDD §11)
    if (nodeId == 'quinto_childhood') {
      return _handleMemoryWrite(cmd, s, 'memory_childhood',
          gate: 'The first word you truly learned — not taught, but understood.');
    }
    if (nodeId == 'quinto_youth') {
      return _handleMemoryWrite(cmd, s, 'memory_youth',
          gate: 'A promise you did not keep — not in accusation, but in acknowledgement.');
    }
    if (nodeId == 'quinto_old_age') {
      return _handleMemoryWrite(cmd, s, 'memory_old_age',
          gate: 'What you wish to be remembered as — not an achievement, a quality.');
    }
    // Maturity room also accepts 'write' (in addition to 'say'/'answer' in _handleUnknown)
    if (nodeId == 'quinto_maturity') {
      return _handleMemoryWrite(cmd, s, 'memory_maturity',
          gate: 'What you have never said — the telephone is waiting.');
    }

    return const EngineResponse(
      narrativeText: 'Nothing happens. The Archive observes your writing.',
    );
  }

  /// Shared helper for the four memory room writing puzzles.
  EngineResponse _handleMemoryWrite(
    ParsedCommand cmd,
    GameEngineState s,
    String puzzleId, {
    required String gate,
  }) {
    if (s.completedPuzzles.contains(puzzleId)) {
      return const EngineResponse(
        narrativeText: 'The price has been paid. You may leave.',
      );
    }
    if (cmd.args.isEmpty) {
      return EngineResponse(
        narrativeText: 'Write what?\n\n$gate',
      );
    }
    final words = cmd.args.join(' ');
    return EngineResponse(
      narrativeText: 'You write.\n\n'
          '"$words"\n\n'
          'The word settles into the room. '
          'Something in the architecture acknowledges it without comment.\n\n'
          'You may now leave.',
      needsLlm:        true,
      lucidityDelta:   6,
      completePuzzle:  puzzleId,
      audioTrigger:    'calm',
      playerMemoryKey: puzzleId, // salva la risposta in player_memories
    );
  }

  EngineResponse _handleCombine(ParsedCommand cmd, String nodeId, GameEngineState s) {
    if (nodeId != 'obs_antechamber') {
      return const EngineResponse(narrativeText: 'Nothing here to combine.');
    }
    if (s.completedPuzzles.contains('lenses_combined')) {
      return const EngineResponse(
        narrativeText: 'The lenses are already in place. The corridor north is open.',
      );
    }
    final a = cmd.args.join(' ').toLowerCase();
    final hasMoon    = a.contains('moon');
    final hasMercury = a.contains('mercury');
    final hasSun     = a.contains('sun');
    final moonFirst  = hasMoon && hasMercury && hasSun &&
        a.indexOf('moon') < a.indexOf('mercury') &&
        a.indexOf('mercury') < a.indexOf('sun');

    if (moonFirst) {
      return const EngineResponse(
        narrativeText: 'You slot the lenses in inverted order: Moon, Mercury, Sun.\n\n'
            'The mount clicks. A faint hum — as if the instrument '
            'recognised that the obvious order was the wrong one.\n\n'
            'The corridor north is open.',
        needsLlm:       true,
        lucidityDelta:  8,
        completePuzzle: 'lenses_combined',
      );
    }
    if (hasMoon && hasMercury && hasSun) {
      return const EngineResponse(
        narrativeText: 'The mount rejects this order.\n\n'
            'The apparent hierarchy — Sun first — may need to be inverted.',
      );
    }
    return const EngineResponse(
      narrativeText: 'The mount does not accept this.\n\n'
          'Three lenses: Moon, Mercury, Sun. '
          'Their order is the inverse of what seems natural.',
    );
  }

  EngineResponse _handlePress(ParsedCommand cmd, String nodeId, GameEngineState s) {
    if (nodeId != 'gallery_corridor') {
      return const EngineResponse(narrativeText: 'Nothing here to press.');
    }
    if (s.completedPuzzles.contains('corridor_tile_pressed')) {
      return const EngineResponse(narrativeText: 'The tile has been pressed. The way south is open.');
    }
    final a = cmd.args.join(' ').toLowerCase();
    if (a.contains('tile') || a.contains('anomalous') || a.contains('wrong')) {
      return const EngineResponse(
        narrativeText: 'You press the anomalous tile.\n\n'
            'It gives — slightly, decisively. '
            'The south end of the corridor opens.\n\n'
            'The figure ahead is no longer visible.',
        needsLlm:       true,
        lucidityDelta:  5,
        completePuzzle: 'corridor_tile_pressed',
      );
    }
    return const EngineResponse(
      narrativeText: 'The tiles do not respond.\n\n'
          'Look for the tile that differs from its neighbours.',
    );
  }

  EngineResponse _handleOffer(ParsedCommand cmd, String nodeId, GameEngineState s) {
    if (nodeId != 'lab_vestibule') {
      return const EngineResponse(narrativeText: 'There is no one here to receive an offering.');
    }
    if (s.completedPuzzles.contains('lab_offers_complete')) {
      return const EngineResponse(
        narrativeText: 'The three statues have received. The Hall of Substances is open.',
      );
    }
    if (cmd.args.isEmpty) {
      return const EngineResponse(
        narrativeText: 'Offer what? The statues wait with open hands.\n\n'
            'They accept concepts, not objects.',
      );
    }
    final count   = (s.puzzleCounters['lab_offers_count'] ?? 0) + 1;
    final concept = cmd.args.join(' ');
    if (count < 3) {
      return EngineResponse(
        narrativeText: 'You offer $concept.\n\n'
            'The statue\'s hands close briefly, then open again, empty. '
            '$count of three offerings.',
        incrementCounter: 'lab_offers_count',
      );
    }
    return EngineResponse(
      narrativeText: 'You offer $concept.\n\n'
          'The third statue closes its hands. All three have received.\n\n'
          'The Hall of Substances opens to the south.',
      needsLlm:         true,
      incrementCounter: 'lab_offers_count',
      completePuzzle:   'lab_offers_complete',
      lucidityDelta:    5,
    );
  }

  EngineResponse _handleMeasure(ParsedCommand cmd, String nodeId, GameEngineState s) {
    if (nodeId != 'obs_void') {
      return const EngineResponse(narrativeText: 'Nothing here to measure.');
    }
    if (!s.completedPuzzles.contains('void_silence_complete')) {
      return const EngineResponse(
        narrativeText: 'The dial has no pointer yet.\n\n'
            'The void must be given time. Wait.',
      );
    }
    if (s.completedPuzzles.contains('void_fluctuation_measured')) {
      return const EngineResponse(
        narrativeText: 'The fluctuation has been measured. The passage south is open.',
      );
    }
    return const EngineResponse(
      narrativeText: 'You read the dial.\n\n'
          'The pointer rests at a value that cannot be zero and cannot be fixed. '
          'It fluctuates between two states that should exclude each other.\n\n'
          'You absorb it. The difference between noting and understanding is not large here.\n\n'
          'The passage south opens.',
      needsLlm:       true,
      lucidityDelta:  8,
      completePuzzle: 'void_fluctuation_measured',
    );
  }

  EngineResponse _handleCalibrate(ParsedCommand cmd, String nodeId, GameEngineState s) {
    if (nodeId != 'obs_calibration') {
      return const EngineResponse(narrativeText: 'Nothing here to calibrate.');
    }
    if (s.completedPuzzles.contains('obs_calibrated')) {
      return const EngineResponse(narrativeText: 'The calibration is set. The dome is open.');
    }
    final a = _normalizeInput(cmd.args.join(' '));
    final isZero = RegExp(r'^0\s+0\s+0$').hasMatch(a) || a == '0 0 0';
    if (isZero) {
      return const EngineResponse(
        narrativeText: 'You set all three dials to zero.\n\n'
            'A hum from the mount above. The dome door opens.\n\n'
            'The reference point is chosen. Everything flows from here.',
        needsLlm:       true,
        lucidityDelta:  10,
        completePuzzle: 'obs_calibrated',
      );
    }
    return const EngineResponse(
      narrativeText: 'The mount rejects those coordinates.\n\n'
          'The only honest origin makes no claim to be absolute.\n\n'
          'Hint: calibrate [X] [Y] [Z]',
    );
  }

  EngineResponse _handleInvert(ParsedCommand cmd, String nodeId, GameEngineState s) {
    if (nodeId != 'obs_dome') {
      return const EngineResponse(narrativeText: 'Nothing here to invert.');
    }
    if (s.completedPuzzles.contains('obs_confirmed')) {
      return const EngineResponse(
        narrativeText: 'The mirror is inverted and confirmed. You may observe.',
      );
    }
    if (s.completedPuzzles.contains('obs_mirror_inverted')) {
      return const EngineResponse(
        narrativeText: 'The inversion is in progress. Confirm three times to commit.',
      );
    }
    if (cmd.rawInput.toLowerCase().contains('mirror')) {
      return const EngineResponse(
        narrativeText: 'You reach for the inversion mechanism.\n\n'
            'The primary mirror rotates — slowly, '
            'with the sound of something large being reconsidered.\n\n'
            'It now faces inward. The telescope looks at the room, not the sky.\n\n'
            '"Inversion requires confirmation. Confirm three times to proceed."',
        completePuzzle: 'obs_mirror_inverted',
      );
    }
    return const EngineResponse(narrativeText: 'Invert what? The primary mirror is the instrument.');
  }

  EngineResponse _handleConfirm(String nodeId, GameEngineState s) {
    if (nodeId != 'obs_dome') {
      return const EngineResponse(narrativeText: 'Nothing here to confirm.');
    }
    if (!s.completedPuzzles.contains('obs_mirror_inverted')) {
      return const EngineResponse(narrativeText: 'There is nothing awaiting confirmation.');
    }
    if (s.completedPuzzles.contains('obs_confirmed')) {
      return const EngineResponse(
        narrativeText: 'Already confirmed. The telescope is ready. You may observe.',
      );
    }
    final count = (s.puzzleCounters['obs_confirm_count'] ?? 0) + 1;
    if (count < 3) {
      return EngineResponse(
        narrativeText: 'Confirmation $count of three.\n\nThe mechanism holds.',
        incrementCounter: 'obs_confirm_count',
      );
    }
    return const EngineResponse(
      narrativeText: 'Third confirmation.\n\n'
          'The mechanism locks. The mirror is committed.\n\n'
          'The telescope is ready. You may now observe.',
      incrementCounter: 'obs_confirm_count',
      completePuzzle:   'obs_confirmed',
    );
  }

  EngineResponse _handleBreak(ParsedCommand cmd, String nodeId, GameEngineState s) {
    if (nodeId != 'gallery_central') {
      return const EngineResponse(narrativeText: 'There is nothing here to break.');
    }
    if (!cmd.rawInput.toLowerCase().contains('mirror')) {
      return const EngineResponse(
        narrativeText: 'Break what? The mirror is the only thing here that waits for this.',
      );
    }
    if (s.completedPuzzles.contains('gallery_complete') ||
        s.completedPuzzles.contains('gallery_mirror_broken_chaos')) {
      return const EngineResponse(narrativeText: 'The mirror is already broken.');
    }
    if (s.psychoWeight > 0) {
      // Chaotic break — no simulacrum granted (GDD §8)
      return const EngineResponse(
        narrativeText: 'You break the mirror.\n\n'
            'It does not shatter cleanly. The fragments scatter, each reflecting '
            'a different version of you carrying something you should have left behind.\n\n'
            'No simulacrum appears. The proportion requires empty hands.\n\n'
            'The Gallery cannot be completed in this state.',
        needsLlm:       true,
        lucidityDelta:  -15,
        anxietyDelta:   20,
        oblivionDelta:  10,
        audioTrigger:   'anxious',
        completePuzzle: 'gallery_mirror_broken_chaos',
      );
    }
    // Clean break — grant The Proportion
    return const EngineResponse(
      narrativeText: 'You break the mirror.\n\n'
          'It shatters with a sound that is not glass — '
          'the sound of something that was pretending to be a boundary.\n\n'
          'The fragments arrange themselves on the floor in the shape of a pentagon, '
          'each piece a precise fraction of the whole.\n\n'
          'In the centre: a golden compass with no hinge. The Proportion.',
      needsLlm:       true,
      lucidityDelta:  15,
      anxietyDelta:   -10,
      audioTrigger:   'calm',
      grantItem:      'the proportion',
      completePuzzle: 'gallery_complete',
    );
  }

  EngineResponse _handleBlow(String nodeId, GameEngineState s) {
    if (nodeId != 'lab_sealed') {
      return const EngineResponse(narrativeText: 'Nothing here to blow into.');
    }
    if (s.completedPuzzles.contains('lab_complete')) {
      return const EngineResponse(narrativeText: 'The Catalyst has already been released.');
    }
    return const EngineResponse(
      narrativeText: 'You breathe into the alembic.\n\n'
          'Your breath — warm, carbon, water, the trace chemistry of a life '
          'lived — enters the glass and touches the substance.\n\n'
          'The substance changes. Not with a reaction — with a recognition. '
          'The pulsing steadies. The glow intensifies.\n\n'
          'In your hands: a small flask of luminescent liquid, '
          'beating in time with your heart. The Catalyst.',
      needsLlm:       true,
      lucidityDelta:  12,
      anxietyDelta:   -15,
      audioTrigger:   'calm',
      grantItem:      'the catalyst',
      completePuzzle: 'lab_complete',
    );
  }

  EngineResponse _handleSetParam(ParsedCommand cmd, String nodeId, GameEngineState s) {
    if (nodeId != 'lab_alembic') {
      return const EngineResponse(narrativeText: 'Nothing here accepts parameter adjustments.');
    }
    if (s.completedPuzzles.contains('alembic_temperature_set')) {
      return const EngineResponse(
        narrativeText: 'The temperature is already set. The alembic path south is open.',
      );
    }
    final a = cmd.args.join(' ').toLowerCase();
    if (a.contains('temp')) {
      final value = a.replaceAll('temperature', '').trim();
      if (value == 'gentle' || value == '1' || value == 'first' || value == 'balneum') {
        return const EngineResponse(
          narrativeText: 'You set the temperature to Gentle.\n\n'
              'The liquid responds — not by boiling, by opening. '
              'It becomes willing.\n\n'
              'The alembic path south opens.',
          needsLlm:       true,
          lucidityDelta:  8,
          completePuzzle: 'alembic_temperature_set',
        );
      }
      return const EngineResponse(
        narrativeText: 'The liquid recoils.\n\n'
            'The scale: Cold, Gentle, Warm, Hot, Intense, Fierce, Total.\n'
            'The bain-marie of alchemical tradition uses the gentlest degree.',
      );
    }
    return const EngineResponse(
      narrativeText: 'Set what? The temperature control awaits.\n\n'
          'Hint: set temperature [degree on the alchemical scale]',
    );
  }

  /// Handles commands not recognised by the parser (contextual raw-input parsing).
  EngineResponse _handleUnknown(ParsedCommand cmd, String nodeId, GameEngineState s) {
    final raw = cmd.rawInput.toLowerCase().trim();

    // Observatory dome: observe
    if ((raw == 'observe' || raw.startsWith('observe ')) && nodeId == 'obs_dome') {
      if (!s.completedPuzzles.contains('obs_confirmed')) {
        return const EngineResponse(
          narrativeText: 'The telescope is not ready.\n\n'
              'Invert the primary mirror and confirm three times first.',
        );
      }
      if (s.completedPuzzles.contains('obs_complete')) {
        return const EngineResponse(
          narrativeText: 'The observation is complete. The Constant is already in your hands.',
        );
      }
      return const EngineResponse(
        narrativeText: 'You look into the inverted telescope.\n\n'
            'It shows you the room — and within the room, yourself. '
            'A figure of precise but unmeasurable dimensions.\n\n'
            'At the centre of the image, superimposed on your chest: '
            'a light source the instrument cannot locate, '
            'because it is no longer looking outward.\n\n'
            'In your hands: a prism of tangible light. It is warm. '
            'It refracts you. The Constant.',
        needsLlm:       true,
        lucidityDelta:  15,
        anxietyDelta:   -10,
        audioTrigger:   'calm',
        grantItem:      'the constant',
        completePuzzle: 'obs_complete',
      );
    }

    // Observatory archive: enter [value]
    if (raw.startsWith('enter ') && nodeId == 'obs_archive') {
      final value = raw.substring(6).trim();
      if (s.completedPuzzles.contains('archive_constant_entered')) {
        return const EngineResponse(
          narrativeText: 'The panel already has its answer. The passage south is open.',
        );
      }
      if (value == '1') {
        return const EngineResponse(
          narrativeText: 'You enter: 1.\n\n'
              'The panel accepts it without comment.\n\n'
              'In natural units, all constants equal one — not because they are '
              'the same, but because measurement is always a comparison, '
              'and the only honest comparison is with the thing itself.\n\n'
              'The passage south opens.',
          needsLlm:       true,
          lucidityDelta:  10,
          completePuzzle: 'archive_constant_entered',
        );
      }
      return EngineResponse(
        narrativeText: '"$value" is not accepted.\n\n'
            'What do all constants become when you stop measuring in human units?',
      );
    }

    // Lab substances: decipher symbols
    if ((raw == 'decipher symbols' || raw == 'decipher') && nodeId == 'lab_substances') {
      if (s.completedPuzzles.contains('lab_symbols_deciphered')) {
        return const EngineResponse(
          narrativeText: 'The symbols are already decoded: mercury, sulphur, salt.\n\n'
              'Collect each to proceed.',
        );
      }
      return const EngineResponse(
        narrativeText: 'You study the central triangle.\n\n'
            'The three vertices decode:\n'
            'Mercury — the spirit, quicksilver, volatility.\n'
            'Sulphur — the soul, combustion, will.\n'
            'Salt — the body, fixity, matter.\n\n'
            'The Tria Prima. All transformation passes through these three.\n\n'
            'Now: collect mercury — collect sulphur — collect salt.',
        lucidityDelta:  5,
        completePuzzle: 'lab_symbols_deciphered',
      );
    }

    // Lab substances: collect [substance]
    if (raw.startsWith('collect ') && nodeId == 'lab_substances') {
      final sub = raw.substring(8).trim();
      if (!s.completedPuzzles.contains('lab_symbols_deciphered')) {
        return const EngineResponse(
          narrativeText: 'You do not yet know what to collect.\n\nDecipher the symbols first.',
        );
      }
      // Normalise sulfur/sulphur
      final key = (sub == 'sulfur' || sub == 'sulphur') ? 'sulphur' : sub;
      final valid = {'mercury', 'sulphur', 'salt'};
      if (!valid.contains(key)) {
        return EngineResponse(
          narrativeText: '"$sub" is not one of the three substances.\n\n'
              'Collect: mercury, sulphur, or salt.',
        );
      }
      final puzzleId = 'lab_${key}_collected';
      if (s.completedPuzzles.contains(puzzleId)) {
        return EngineResponse(narrativeText: 'You have already collected the $key.');
      }
      // Check whether this is the final substance using a Set so all three
      // required IDs are expressed in one place.
      const required = {'lab_mercury_collected', 'lab_sulphur_collected', 'lab_salt_collected'};
      final afterThis = s.completedPuzzles.union({puzzleId});
      final isLast = required.every(afterThis.contains);
      // Always record the individual substance ID; _handleGo checks all three.
      return EngineResponse(
        narrativeText: isLast
            ? 'You collect the $key.\n\n'
              'All three substances of the Tria Prima are gathered.\n\n'
              'The three branches open: the furnace, the alembic, the bain-marie.'
            : 'You collect the $key. It settles with a faint warmth.',
        needsLlm:       isLast,
        completePuzzle: puzzleId,
        lucidityDelta:  isLast ? 8 : null,
      );
    }

    // Lab furnace: calcinate
    if (raw == 'calcinate' && nodeId == 'lab_furnace') {
      if (s.completedPuzzles.contains('furnace_calcinating')) {
        return const EngineResponse(
          narrativeText: 'The calcination is already in progress. Wait for five turnings.',
        );
      }
      return const EngineResponse(
        narrativeText: 'You light the furnace.\n\n'
            'The material begins its reduction. '
            'Grey smoke — the smell of something essential escaping.\n\n'
            'Five turnings are required. Wait.',
        completePuzzle: 'furnace_calcinating',
      );
    }

    // Gallery hall: observe reflection (2nd Proustian trigger, GDD §9)
    if ((raw == 'observe reflection' || raw.startsWith('observe reflection') ||
            raw == 'observe' || raw.startsWith('observe ')) &&
        nodeId == 'gallery_hall') {
      if (s.completedPuzzles.contains('hall_backward_walked') &&
          !s.completedPuzzles.contains('gallery_reflection_triggered')) {
        return const EngineResponse(
          narrativeText: 'You look into the mirrors a second time.\n\n'
              'Your reflection looks back — and it is not quite the one you left.\n\n'
              '"Plus fragiles mais plus vivaces, plus immatérielles, '
              'plus persistantes, plus fidèles."\n\n'
              'The images hold something you had forgotten was yours.',
          needsLlm:       true,
          lucidityDelta:  -5,
          anxietyDelta:   5,
          audioTrigger:   'sfx:proustian_trigger',
          completePuzzle: 'gallery_reflection_triggered',
        );
      }
      return const EngineResponse(
        narrativeText: 'The mirrors reflect you from every angle. '
            'None of them shows you looking at them.',
      );
    }

    // Quinto maturity: answer telephone (say/answer/tell)
    if (nodeId == 'quinto_maturity' &&
        (raw.startsWith('say ') || raw.startsWith('answer ') || raw.startsWith('tell '))) {
      final content = raw.replaceFirst(RegExp(r'^(say|answer|tell)\s+'), '');
      if (s.completedPuzzles.contains('memory_maturity')) {
        return const EngineResponse(narrativeText: 'The price has been paid. You may leave.');
      }
      if (content.trim().isEmpty) {
        return const EngineResponse(
          narrativeText: 'Say what? The line is open. Someone is waiting.',
        );
      }
      return EngineResponse(
        narrativeText: 'You speak into the telephone.\n\n'
            '"$content"\n\n'
            'There is a silence on the line — not empty, but full.\n\n'
            'Then a soft sound that might be acknowledgement.\n\n'
            'The glasses on the desk clear. You may leave.',
        needsLlm:       true,
        lucidityDelta:  8,
        completePuzzle: 'memory_maturity',
        audioTrigger:   'calm',
        playerMemoryKey: 'memory_maturity',
      );
    }

    // La Zona: free-text response to the introspective question (GDD §10)
    if (nodeId == 'la_zona') {
      return _handleZoneResponse(raw, s);
    }

    // Finale 1: WAKE UP epilogue (GDD §12)
    if ((raw == 'wake up' || raw == 'wakeup') && nodeId == 'finale_acceptance') {
      return const EngineResponse(
        narrativeText: '"The Archive is empty.\n\n'
            'Time has started flowing again.\n\n'
            'Outside it is cold, but you are no longer alone."\n\n'
            '— FINE —',
        audioTrigger: 'calm',
        lucidityDelta: 20,
      );
    }

    return const EngineResponse(
      narrativeText: 'The Archive does not understand.',
      needsLlm: true,
    );
  }

  // ── New handlers ─────────────────────────────────────────────────────────────

  EngineResponse _handleDrink(String nodeId, GameEngineState s) {
    if (nodeId != 'quinto_ritual_chamber') {
      return const EngineResponse(narrativeText: 'There is nothing to drink here.');
    }
    const cup = {
      'cup_ataraxia', 'cup_the_constant', 'cup_the_proportion', 'cup_the_catalyst',
    };
    if (!cup.every(s.completedPuzzles.contains)) {
      final missing = <String>[];
      if (!s.completedPuzzles.contains('cup_ataraxia'))       missing.add('Ataraxia');
      if (!s.completedPuzzles.contains('cup_the_constant'))   missing.add('The Constant');
      if (!s.completedPuzzles.contains('cup_the_proportion')) missing.add('The Proportion');
      if (!s.completedPuzzles.contains('cup_the_catalyst'))   missing.add('The Catalyst');
      return EngineResponse(
        narrativeText: 'The cup is not complete.\n\n'
            'Still to be placed: ${missing.join(", ")}.',
      );
    }
    if (!s.completedPuzzles.contains('ritual_stirred')) {
      return const EngineResponse(
        narrativeText: 'Stir the infusion before drinking.',
      );
    }
    if (s.completedPuzzles.contains('ritual_complete')) {
      return const EngineResponse(
        narrativeText: 'You have already drunk the infusion. The passage below is open.',
      );
    }
    return const EngineResponse(
      narrativeText: 'You drink.\n\n'
          'The taste is impossible — all four at once and separately: '
          'emptiness, light, proportion, and the warm quickening of breath.\n\n'
          'For a moment the cup is the Archive and the Archive is the cup '
          'and you are neither the one who holds it nor the one held.\n\n'
          'Then: the silence before a question that has waited a very long time.\n\n'
          'The passage below opens.',
      needsLlm:       true,
      lucidityDelta:  15,
      anxietyDelta:   -20,
      audioTrigger:   'calm',
      completePuzzle: 'ritual_complete',
      newNode:        'il_nucleo',
    );
  }

  EngineResponse _handleStir(String nodeId, GameEngineState s) {
    if (nodeId != 'quinto_ritual_chamber') {
      return const EngineResponse(narrativeText: 'Nothing here to stir.');
    }
    const cup = {
      'cup_ataraxia', 'cup_the_constant', 'cup_the_proportion', 'cup_the_catalyst',
    };
    if (!cup.every(s.completedPuzzles.contains)) {
      final missing = <String>[];
      if (!s.completedPuzzles.contains('cup_ataraxia'))       missing.add('ataraxia');
      if (!s.completedPuzzles.contains('cup_the_constant'))   missing.add('the constant');
      if (!s.completedPuzzles.contains('cup_the_proportion')) missing.add('the proportion');
      if (!s.completedPuzzles.contains('cup_the_catalyst'))   missing.add('the catalyst');
      return EngineResponse(
        narrativeText: 'The cup is not ready.\n\n'
            'Still to be placed: ${missing.join(", ")}.',
      );
    }
    if (s.completedPuzzles.contains('ritual_stirred')) {
      return const EngineResponse(
        narrativeText: 'The infusion has been stirred. Now drink.',
      );
    }
    return const EngineResponse(
      narrativeText: 'You stir the infusion.\n\n'
          'The four elements spiral together — each distinct, all one. '
          'A scent rises: specific, personal, the sum of everything encountered.\n\n'
          'The infusion is ready. Drink.',
      needsLlm:       true,
      lucidityDelta:  8,
      completePuzzle: 'ritual_stirred',
      audioTrigger:   'calm',
    );
  }

  EngineResponse _handleRitualPlacement(ParsedCommand cmd, GameEngineState s) {
    final raw = cmd.rawInput.toLowerCase();

    // Must reference the cup to be a ritual placement (vs a normal drop)
    if (!raw.contains('cup')) {
      // Normal drop behaviour in ritual chamber
      final target = cmd.args.join(' ');
      final match = s.inventory
          .where((i) => i.contains(target) || target.contains(i))
          .firstOrNull;
      if (match == null) {
        return const EngineResponse(narrativeText: 'You are not carrying that.');
      }
      return EngineResponse(
        narrativeText: 'You set down the $match.',
        weightDelta: _isSimulacrum(match) ? 0 : -1,
        anxietyDelta: _isSimulacrum(match) ? 0 : -1,
      );
    }

    // Identify which simulacrum is being placed
    String? simFound;
    for (final sim in _simulacraNames) {
      if (raw.contains(sim) && s.inventory.contains(sim)) {
        simFound = sim;
        break;
      }
    }

    if (simFound == null) {
      // Check if player is trying to place a mundane item
      final mundane = s.inventory.where((i) => !_isSimulacrum(i));
      for (final item in mundane) {
        if (raw.contains(item)) {
          return const EngineResponse(
            narrativeText: 'The cup does not accept mundane things.\n\n'
                'Only the four simulacra belong here.',
          );
        }
      }
      return const EngineResponse(
        narrativeText: 'Place what in the cup?\n\n'
            'The four simulacra must be placed: '
            'ataraxia, the constant, the proportion, the catalyst.',
      );
    }

    // Encode puzzle ID: 'cup_ataraxia', 'cup_the_constant', etc.
    final puzzleId = 'cup_${simFound.replaceAll(' ', '_')}';
    if (s.completedPuzzles.contains(puzzleId)) {
      return EngineResponse(
        narrativeText: 'You have already placed the $simFound in the cup.',
      );
    }

    const cup = {
      'cup_ataraxia', 'cup_the_constant', 'cup_the_proportion', 'cup_the_catalyst',
    };
    final afterThis = Set<String>.from(s.completedPuzzles)..add(puzzleId);
    final isLast = cup.every(afterThis.contains);
    final remaining = cup.where((c) => !afterThis.contains(c)).length;

    return EngineResponse(
      narrativeText: isLast
          ? 'You place the $simFound in the cup.\n\n'
            'All four simulacra rest together in the liquid. '
            'It shimmers — a colour you cannot name.\n\n'
            'Something has shifted in the architecture of the Archive.\n\n'
            'Now: stir.'
          : 'You place the $simFound in the cup.\n\n'
            'The liquid brightens briefly. '
            '$remaining more to place.',
      needsLlm:       isLast,
      completePuzzle: puzzleId,
      lucidityDelta:  isLast ? 5 : null,
    );
  }

  // ── Il Nucleo handlers ────────────────────────────────────────────────────

  EngineResponse _handleBossInput(ParsedCommand cmd, GameEngineState s) {
    final raw = cmd.rawInput.toLowerCase().trim();

    // Surrender → Finale 2 (GDD §12)
    if (_surrenderKeywords.any(raw.contains)) {
      return const EngineResponse(
        narrativeText: 'You speak the word.\n\n'
            'The Antagonist does not triumph. It simply waits.\n\n'
            '...\n\n'
            '...\n\n'
            '"Lived. Died. No one will remember."\n\n'
            '— Arseny Tarkovsky',
        needsLlm:     false,
        newNode:      'finale_oblivion',
        audioTrigger: 'silence',
        oblivionDelta: 30,
      );
    }

    // Remain / stay → Finale 3 (Eternal Zone)
    if (raw == 'stay' || raw == 'remain' || raw == 'i remain' ||
        raw.contains('eternal zone') || raw == 'i want to stay') {
      return const EngineResponse(
        narrativeText: 'You stay.\n\n'
            'The Antagonist says nothing. It may not have noticed.\n\n'
            'The Archive continues. The variations are infinite. '
            'You will encounter them all, eventually.\n\n'
            'The Zone does not end. Neither do you.',
        needsLlm:     true,
        newNode:      'finale_eternal_zone',
        audioTrigger: 'oblivion',
      );
    }

    // Resolution keyword check (GDD §12 — Regola del Tre)
    final hasResolution = _resolutionKeywords.any(raw.contains);
    if (hasResolution) {
      if (s.psychoWeight == 0) {
        // Weight is zero — resolution accepted → Finale 1
        return const EngineResponse(
          narrativeText: 'You say it.\n\n'
              'The Antagonist is silent for a long time.\n\n'
              'Then:\n\n'
              '"You are correct. I have no argument against that."\n\n'
              'The voice does not disappear — it simply stops trying.\n\n'
              'Something in the space changes. The Archive, which had been '
              'holding itself very carefully, relaxes.\n\n'
              'A light — not dramatic, not final — '
              'the light of an ordinary room at dusk.',
          needsLlm:       true,
          newNode:        'finale_acceptance',
          lucidityDelta:  20,
          audioTrigger:   'aria_goldberg',
          completePuzzle: 'boss_resolved',
        );
      }

      // Weight > 0 — Regola del Tre
      final attempts = (s.puzzleCounters['boss_attempts'] ?? 0) + 1;
      final String responseText;
      if (attempts == 1) {
        responseText = 'The words form — and dissolve.\n\n'
            'Something in you does not believe them yet. '
            'They are true, but you are carrying too much for them to land.\n\n'
            'The Antagonist says: "You almost had it."\n\n'
            'It waits. It is patient.';
      } else if (attempts == 2) {
        final inv = s.inventory.where((i) => !_isSimulacrum(i)).join(', ');
        final invText = inv.isEmpty ? 'nothing you can name' : inv;
        responseText = 'Again the words — and again they cannot reach.\n\n'
            'The Antagonist tilts its face:\n\n'
            '"You carry: $invText.\n\n'
            'Each one is a small argument against what you are trying to say. '
            'They are yours. They are also in the way."\n\n'
            'It waits.';
      } else {
        // Attempt 3+: [INVENTORY] visible
        final inv = s.inventory.where((i) => !_isSimulacrum(i)).join(', ');
        final invBlock = inv.isEmpty ? '' : '\n\n[INVENTORY: $inv]';
        responseText = 'A third time.\n\n'
            'The words will not cohere.$invBlock\n\n'
            '"The weight is the proof," the Antagonist says. '
            '"You know what it is asking you to put down."';
      }
      return EngineResponse(
        narrativeText: responseText,
        needsLlm:         attempts < 2,
        incrementCounter: 'boss_attempts',
        anxietyDelta:     attempts * 3,
      );
    }

    // Drop in boss context — catarsis (GDD §12)
    if (cmd.verb == CommandVerb.drop) {
      return _handleBossDrop(cmd, s);
    }

    // Deposit in boss context — clear all mundane items (processInput handles the inventory)
    if (cmd.verb == CommandVerb.deposit) {
      final hasMundane = s.inventory.any((i) => !_isSimulacrum(i));
      if (!hasMundane) {
        return const EngineResponse(
          narrativeText: 'You carry nothing that can be set down here.\n\n'
              'The simulacra are yours. They are not the weight.',
        );
      }
      return const EngineResponse(
        narrativeText: 'You set everything down.\n\n'
            'Your hands are empty. The weight is gone.\n\n'
            'The Antagonist looks at you differently.\n\n'
            '"That," it says, "changes the argument."',
        lucidityDelta:           10,
        anxietyDelta:            -15,
        needsLlm:                true,
        audioTrigger:            'calm',
        clearInventoryOnDeposit: true,
      );
    }

    // Generic: Antagonist continues its argument
    return _antagonistArgue(s);
  }

  EngineResponse _handleBossDrop(ParsedCommand cmd, GameEngineState s) {
    if (cmd.args.isEmpty) {
      return const EngineResponse(
        narrativeText: 'What do you wish to set down?',
      );
    }
    final target = cmd.args.join(' ');
    final match = s.inventory
        .where((i) => !_isSimulacrum(i) && (i.contains(target) || target.contains(i)))
        .firstOrNull;
    if (match == null) {
      return const EngineResponse(
        narrativeText: 'You do not carry that — or perhaps you carry it '
            'in a way that cannot be put down here.',
      );
    }
    final remaining = s.inventory
        .where((i) => !_isSimulacrum(i) && i != match)
        .length;
    if (remaining == 0) {
      return EngineResponse(
        narrativeText: 'You set down the $match.\n\n'
            'Your hands are empty. The weight is zero.\n\n'
            'The Antagonist looks at you for a long time.\n\n'
            '"That," it says, "changes the argument."',
        weightDelta:  -1,
        lucidityDelta: 10,
        anxietyDelta:  -10,
        needsLlm:      true,
        audioTrigger:  'calm',
      );
    }
    return EngineResponse(
      narrativeText: 'You set down the $match.\n\n'
          'The Antagonist observes this. "There is still weight," it says.\n\n'
          '$remaining thing${remaining == 1 ? "" : "s"} '
          'remain${remaining == 1 ? "s" : ""}.',
      weightDelta:  -1,
      anxietyDelta: -2,
      lucidityDelta: 3,
    );
  }

  EngineResponse _antagonistArgue(GameEngineState s) {
    final attempts = s.puzzleCounters['boss_attempts'] ?? 0;
    if (attempts == 0) {
      return const EngineResponse(
        narrativeText: 'The Antagonist speaks without raising its voice.\n\n'
            '"Consider: every thought you value was the product of electro-chemistry. '
            'Every love: oxytocin, dopamine, the firing of neurons that did not '
            'choose to fire. Every memory: a reconstruction, inaccurate, '
            'serving the survival of an organism that will not survive.\n\n'
            'I am not your enemy. I am the mercy you have been afraid to accept."',
        needsLlm:    true,
        anxietyDelta: 5,
      );
    }
    return const EngineResponse(
      narrativeText: 'The Antagonist listens.\n\n'
          '"You speak as if the words could change what is true.\n\n'
          'What do you carry that proves you wrong?"',
      needsLlm:    true,
      anxietyDelta: 2,
    );
  }

  EngineResponse _handleFinaleInput(
      ParsedCommand cmd, String nodeId, GameEngineState s) {
    // In finales: most commands return flavour text; WAKE UP handled in _handleUnknown
    if (nodeId == 'finale_acceptance') {
      return const EngineResponse(
        narrativeText: 'The Archive is still. Type WAKE UP when you are ready.',
      );
    }
    if (nodeId == 'finale_oblivion') {
      return const EngineResponse(narrativeText: '...');
    }
    // finale_eternal_zone: zone continues
    return const EngineResponse(
      narrativeText: 'The variations continue. There is no command that ends this.',
    );
  }

  // ── La Zona handlers ──────────────────────────────────────────────────────

  EngineResponse _handleZoneResponse(String raw, GameEngineState s) {
    final encounters = s.puzzleCounters['zone_encounters'] ?? 0;
    final respondedKey = 'zone_responded_$encounters';
    if (s.completedPuzzles.contains(respondedKey)) {
      return const EngineResponse(
        narrativeText: 'The Zone has heard you. The Archive is back.',
        newNode: 'la_soglia',
      );
    }

    final wordCount = raw.trim().split(RegExp(r'\s+')).length;
    if (wordCount < 3) {
      return const EngineResponse(
        narrativeText: 'The Zone does not accept the half-answer.\n\n'
            'It waits. Something in the geometry tightens.\n\n'
            'Try again — more fully.',
        anxietyDelta: 5,
      );
    }

    final q = _zoneQuestions[encounters % _zoneQuestions.length];
    return EngineResponse(
      narrativeText: 'The Zone receives your answer without comment.\n\n'
          '${q.crypticResponse}',
      needsLlm:        true,
      newNode:         'la_soglia',
      completePuzzle:  respondedKey,
      lucidityDelta:   -3,
      anxietyDelta:    -5,
      playerMemoryKey: 'zone_$encounters', // salva la risposta alla Zona
    );
  }

  /// Probabilistic La Zona activation on navigation (GDD §10).
  EngineResponse _maybeActivateZone(
    EngineResponse resp,
    String fromNodeId,
    GameEngineState s,
  ) {
    final dest = resp.newNode!;
    // Do not activate when entering/leaving finales, nucleo, or zone itself
    if (dest.startsWith('finale_') || dest == 'il_nucleo' || dest == 'la_zona') {
      return resp;
    }
    if (fromNodeId == 'la_zona' || fromNodeId.startsWith('finale_') ||
        fromNodeId == 'il_nucleo') {
      return resp;
    }
    // Also skip Zone for quinto sector (narrative flow must not be interrupted)
    if (dest.startsWith('quinto_') || fromNodeId.startsWith('quinto_')) {
      return resp;
    }

    final prob = _zoneActivationProbability(fromNodeId, dest, s);
    if (prob <= 0) return resp;
    if (Random().nextDouble() >= prob) return resp;

    // Zone activates — build entry text
    final encounters = s.puzzleCounters['zone_encounters'] ?? 0;
    final verse = _tarkovskyVerses[encounters % _tarkovskyVerses.length];
    final env   = _zoneEnvironments[encounters % _zoneEnvironments.length];
    final q     = _zoneQuestions[encounters % _zoneQuestions.length];

    return EngineResponse(
      narrativeText: '$verse\n\n$env\n\n${q.question}',
      newNode:   'la_zona',
      needsLlm:  true,
      anxietyDelta: 5,
    );
  }

  double _zoneActivationProbability(
      String fromNode, String destNode, GameEngineState s) {
    final encounters      = s.puzzleCounters['zone_encounters'] ?? 0;
    final consecutive     = s.puzzleCounters['consecutive_transits'] ?? 0;
    final simulacraCount  = _simulacraNames.where(s.inventory.contains).length;
    final hasAllSimulacra = simulacraCount == 4;

    // Avoid triggering while a zone response is still pending
    if (encounters > 0) {
      final pendingKey = 'zone_responded_$encounters';
      if (!s.completedPuzzles.contains(pendingKey)) {
        return 0; // Still in zone (haven't responded yet)
      }
    }

    double prob;

    if (hasAllSimulacra && encounters == 0) {
      // Pre-fifth sector: no zone encounters yet — inevitable first time (GDD §10 — 75%)
      return 0.75;
    } else if (simulacraCount >= 3) {
      prob = 0.50; // After third simulacrum
    } else if (consecutive >= 2) {
      prob = 0.40; // Third consecutive transit
    } else if (_isSectorCompletion(fromNode, destNode, s)) {
      prob = 0.25; // After sector completion
    } else if (fromNode == 'la_soglia' || destNode == 'la_soglia') {
      prob = 0.15; // Normal threshold transit
    } else {
      return 0;
    }

    // +5% per simulacrum
    prob += simulacraCount * 0.05;
    return prob.clamp(0.0, 0.9);
  }

  bool _isSectorCompletion(
      String fromNode, String destNode, GameEngineState s) {
    final done = s.completedPuzzles;
    if (fromNode == 'garden_grove'    && done.contains('garden_complete'))   return true;
    if (fromNode == 'obs_dome'        && done.contains('obs_complete'))      return true;
    if (fromNode == 'gallery_central' && done.contains('gallery_complete'))  return true;
    if (fromNode == 'lab_sealed'      && done.contains('lab_complete'))      return true;
    return false;
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  String _enterNode(_NodeDef node) {
    final title = node.title.isEmpty ? '' : '${node.title}\n\n';
    return '$title${node.description}';
  }

  GameEngineState _appendMessage(GameEngineState s, GameMessage msg) {
    return s.copyWith(messages: [...s.messages, msg]);
  }

  /// Returns a Demiurge ("All That Is") narrative response for the given node.
  /// Selects from curated citation bundles keyed to [nodeId]'s sector.
  /// Falls back to [fallbackText] when bundles are not yet loaded or empty.
  String _callDemiurge(String fallbackText, String nodeId) {
    final sector = DemiurgeService.sectorForNode(nodeId);
    return DemiurgeService.instance.respond(
      sector: sector,
      fallbackText: fallbackText,
    );
  }
}

// ── Help text ─────────────────────────────────────────────────────────────────

const _helpText = '''Commands:
  go [north/south/east/west/up/down]   — move
  examine [object]  /  look            — inspect
  take [object]                        — pick up (increases psychological weight)
  drop [object]                        — set down
  deposit everything                   — leave all at the statue (Garden finale)
  wait  /  z                           — let time pass
  smell [object]                       — attend to a scent
  taste [object]                       — attend to a flavour
  arrange leaves [order]               — Cypress Avenue puzzle
  walk [mode]      — "walk blindfolded", "walk backward", "walk through"
  combine [items]                      — Observatory Antechamber puzzle
  press [target]                       — Gallery Corridor puzzle
  construct / describe / paint / write [content]   — writing puzzles
  offer [concept]                      — Lab Vestibule puzzle
  calibrate [x] [y] [z]               — Observatory Calibration puzzle
  invert [target]                      — Observatory Dome puzzle
  confirm  /  yes                      — multi-step confirmation
  break [target]                       — Gallery finale
  blow                                 — Lab sealed chamber finale
  set temperature [value]              — Lab Alembic puzzle
  decipher symbols                     — Lab Substances puzzle
  collect [substance]                  — Lab Substances puzzle
  calcinate                            — Lab Furnace puzzle
  enter [value]                        — Observatory Archive puzzle
  observe                              — Observatory Dome finale
  place [simulacrum] in cup            — Fifth Sector ritual
  stir                                 — Fifth Sector ritual
  drink                                — Fifth Sector ritual
  say [words]                          — Maturity room (Fifth Sector)
  inventory  /  i                      — list what you carry
  wake up                              — Finale 1 epilogue
  help  /  ?                           — this message''';

// ── Provider ──────────────────────────────────────────────────────────────────

final gameEngineProvider =
    AsyncNotifierProvider<GameEngineNotifier, GameEngineState>(
        GameEngineNotifier.new);
