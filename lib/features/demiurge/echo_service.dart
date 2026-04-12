// lib/features/demiurge/echo_service.dart
// The three Echoes — narrative voices that emerge as the player's awareness grows.
//
// Proust   (Phase 2) — involuntary memory, sensory awakening
// Tarkovskij (Phase 3) — sculpted time, image, slowness
// Seth     (Phase 4) — belief creates reality, the point of power is now
//
// Proust citations: public domain (died 1922).
// Tarkovskij: paraphrases of Sculpting in Time (still in copyright).
// Seth: original sentences inspired by the Seth/Jane Roberts philosophy;
//       not direct quotes, to respect the estate's copyright.
//
// EchoService is a pure-Dart singleton — no I/O, no state, safe to call anywhere.

import 'dart:math' show Random;

class EchoService {
  EchoService._();
  static final EchoService instance = EchoService._();

  final _rng = Random();

  // ── Proust — sensory commands (smell, taste, remember, listen) ──────────────
  // Source: À la Recherche du Temps Perdu (1913-1927). Public domain.
  static const _proustResponses = [
    _EchoEntry(
      preamble: 'A scent reaches you across forgotten time.',
      citation:
          'The smell and taste of things remain poised a long time, like souls, '
          'ready to remind us, waiting and hoping for their moment, amid the ruins '
          'of all the rest.',
      coda: 'The Archive holds what your senses remember before your mind does.',
    ),
    _EchoEntry(
      preamble: 'Involuntary memory does not announce itself.',
      citation:
          'The past is hidden somewhere outside the realm of our intelligence '
          'and beyond its reach, in some material object which we do not suspect.',
      coda: 'What you are looking for has been here all along.',
    ),
    _EchoEntry(
      preamble: 'The Echo of Proust stirs in the Archive.',
      citation:
          'We do not receive wisdom, we must discover it for ourselves, '
          'after a journey through the wilderness which no one else can make for us.',
      coda: 'Every wrong command is part of that journey.',
    ),
    _EchoEntry(
      preamble: 'Time folds here. A flavour becomes a doorway.',
      citation:
          'In theory one is aware that the earth revolves, but in practice one does not '
          'perceive it, the ground upon which one treads seems not to move, and one can '
          'live undisturbed. So it is with time in one\'s life.',
      coda: 'Stand still long enough and you will feel it turn.',
    ),
    _EchoEntry(
      preamble: 'The Echo listens to what you touched, not what you typed.',
      citation:
          'Let us be grateful to the people who make us happy; they are the charming '
          'gardeners who make our souls blossom.',
      coda: 'Even the Archive can be a garden, if you let it.',
    ),
    _EchoEntry(
      preamble: 'Something surfaces from before the Archive.',
      citation:
          'A little tap at the window, as though some missile had struck it, '
          'followed by a plentiful, falling sound, as light, though, as if a shower '
          'of sand was being sprinkled from a window above.',
      coda: 'The senses do not deceive. Only the mind interprets.',
    ),
    _EchoEntry(
      preamble: 'Proust speaks from the corridor of recovered time.',
      citation:
          'The real voyage of discovery consists not in seeking new landscapes, '
          'but in having new eyes.',
      coda: 'You do not need to move. You need to see differently.',
    ),
  ];

  // ── Tarkovskij — observation commands (look, examine, wait) ────────────────
  // Paraphrases of Sculpting in Time (Andrei Tarkovskij, 1986).
  // Wording is original; only the ideas are drawn from the source.
  static const _tarkovskijResponses = [
    _EchoEntry(
      preamble: 'Tarkovskij\'s Echo slows the Archive around you.',
      citation:
          'Time is not a river flowing in one direction. '
          'The artist sculpts it, seizing the fragment that holds the pressure of lived life.',
      coda: 'Every image you observe here has already been sculpted by your longing.',
    ),
    _EchoEntry(
      preamble: 'Patience is the only tool that works here.',
      citation:
          'The screen image must carry within it the mark of time — '
          'not the passage of time, but time itself, its texture, its resistance.',
      coda: 'Do not hurry. The Archive will not open any faster.',
    ),
    _EchoEntry(
      preamble: 'The Echo of the image-maker addresses you.',
      citation:
          'In cinema, as in poetry, the idea exists only through the image. '
          'The image does not illustrate. It is the thought itself.',
      coda: 'What you see in this room is not decoration. It is an argument.',
    ),
    _EchoEntry(
      preamble: 'The Archive holds its breath when you truly look.',
      citation:
          'The past is not behind us. It is more real than the present, '
          'because it can no longer be altered. The present is always escaping.',
      coda: 'Look at what is here. It has already become permanent.',
    ),
    _EchoEntry(
      preamble: 'Tarkovskij\'s voice: deliberate, unhurried.',
      citation:
          'A work of art, like a human life, carries within it the experience '
          'of mortality — and the desperate, burning wish to transcend it.',
      coda: 'The Archive was built by someone who wanted to be remembered. So were you.',
    ),
    _EchoEntry(
      preamble: 'Slowness is not failure. It is the correct speed for this place.',
      citation:
          'True observation means surrendering to what is there — '
          'not what you expected, not what you hoped for, but what is.',
      coda: 'Look again. You missed something the first time.',
    ),
  ];

  // ── Seth — creative/belief commands (write, construct, describe, create) ────
  // Original sentences inspired by the Seth/Jane Roberts philosophy.
  // Not direct quotes; written to respect the estate's copyright.
  static const _sethResponses = [
    _EchoEntry(
      preamble: 'Seth speaks from the dimension you are constructing.',
      citation:
          'You are not a passive witness to this Archive. '
          'Every belief you carry sculpts the rooms you find and the doors that open.',
      coda: 'What you believe is possible here — is possible here.',
    ),
    _EchoEntry(
      preamble: 'The point of power is always in this moment.',
      citation:
          'The present moment is the only place where change occurs. '
          'Not yesterday, which is fixed, not tomorrow, which is imagined — now.',
      coda: 'Type the command you believe will work. That belief is not nothing.',
    ),
    _EchoEntry(
      preamble: 'Seth\'s Echo surfaces at the intersection of thought and matter.',
      citation:
          'Your consciousness is not imprisoned in your body. '
          'It projects outward and creates the physical world it then appears to inhabit.',
      coda: 'This Archive is not external to you. It is your projection.',
    ),
    _EchoEntry(
      preamble: 'The Archive listens to what you create, not only what you command.',
      citation:
          'Every thought is an action. Every word typed here changes the structure '
          'of what is possible in the next moment.',
      coda: 'You have already altered this room by reading this.',
    ),
    _EchoEntry(
      preamble: 'Creation does not require perfection. It requires intent.',
      citation:
          'The so-called wrong commands are not failures. '
          'They are the edges of your current belief about what is allowed.',
      coda: 'Expand the belief. The command will follow.',
    ),
    _EchoEntry(
      preamble: 'Seth addresses the one who mistakes the map for the territory.',
      citation:
          'The Archive exists because you needed it to exist. '
          'The question is not how to escape it — the question is what it is teaching you.',
      coda: 'You created this. Only you can choose what it means.',
    ),
  ];

  // ── Public API ───────────────────────────────────────────────────────────────

  /// Returns a formatted Echo response for the given [echo] persona ('proust',
  /// 'tarkovskij', or 'seth'). Returns null when [echo] is unrecognised or
  /// there are no entries for that persona.
  String? respond(String echo) {
    final List<_EchoEntry> pool = switch (echo) {
      'proust'      => _proustResponses,
      'tarkovskij'  => _tarkovskijResponses,
      'seth'        => _sethResponses,
      _             => const [],
    };
    if (pool.isEmpty) return null;
    final entry = pool[_rng.nextInt(pool.length)];
    return '${entry.preamble}\n\n"${entry.citation}"\n\n${entry.coda}';
  }

  /// Returns the Echo name that should respond to [verb] in [phase],
  /// or null if no Echo is appropriate.
  /// [verb] is the [CommandVerb.name] string from the parser, e.g. 'smell',
  /// 'examine', 'wait', 'write', 'observe'.
  static String? echoForCommand(String verb, int phase, {
    required int proustAffinity,
    required int tarkovskijAffinity,
    required int sethAffinity,
  }) {
    // Phase 1: no Echo yet (only Demiurge)
    if (phase < 2) return null;

    // Proust awakens in phase 2+ for sensory commands, once affinity ≥ 5
    // CommandVerb: smell, taste
    if (phase >= 2 && proustAffinity >= 5) {
      if (verb == 'smell' || verb == 'taste') {
        return 'proust';
      }
    }

    // Tarkovskij awakens in phase 3+ for observation/stillness commands, affinity ≥ 5
    // CommandVerb: examine (covers 'look'), observe (covers 'watch'), wait
    if (phase >= 3 && tarkovskijAffinity >= 5) {
      if (verb == 'examine' || verb == 'observe' || verb == 'wait') {
        return 'tarkovskij';
      }
    }

    // Seth awakens in phase 4+ for creative commands, affinity ≥ 5
    // CommandVerb: write (covers 'construct', 'describe', 'paint', 'draw')
    if (phase >= 4 && sethAffinity >= 5) {
      if (verb == 'write') {
        return 'seth';
      }
    }

    return null;
  }

  /// Matches [input] against Echo keywords, regardless of phase.
  ///
  /// Used for two cases:
  ///   1. Explicit summon commands: "summon proust", "call tarkovsky", "invoke seth"
  ///   2. Free-text keyword recognition: typing the philosopher's name, a key concept
  ///
  /// Returns the Echo name, or null if no keyword matches.
  static String? echoForKeywords(String input) {
    final lower = input.toLowerCase();

    // Proust keywords — sensory memory, involuntary recall
    if (lower.contains('proust') ||
        lower.contains('madeleine') ||
        lower.contains('involuntary') ||
        lower.contains('memory smell') ||
        lower.contains('summon proust') ||
        lower.contains('call proust') ||
        lower.contains('invoke proust')) {
      return 'proust';
    }

    // Tarkovskij keywords — sculpted time, image, slowness
    // Accept both spellings (with/without j)
    if (lower.contains('tarkovsky') ||
        lower.contains('tarkovskij') ||
        lower.contains('sculpt time') ||
        lower.contains('sculpting time') ||
        lower.contains('summon tarkovsky') ||
        lower.contains('call tarkovsky') ||
        lower.contains('invoke tarkovsky') ||
        lower.contains('summon tarkovskij') ||
        lower.contains('call tarkovskij') ||
        lower.contains('invoke tarkovskij')) {
      return 'tarkovskij';
    }

    // Seth keywords — belief, creating reality, present moment
    if (lower.contains('seth') ||
        lower.contains('i create') ||
        lower.contains('my reality') ||
        lower.contains('i believe') ||
        lower.contains('create reality') ||
        lower.contains('summon seth') ||
        lower.contains('call seth') ||
        lower.contains('invoke seth')) {
      return 'seth';
    }

    return null;
  }
}

class _EchoEntry {
  final String preamble;
  final String citation;
  final String coda;

  const _EchoEntry({
    required this.preamble,
    required this.citation,
    required this.coda,
  });
}
