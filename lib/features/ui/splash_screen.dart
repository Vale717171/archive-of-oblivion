// lib/features/ui/splash_screen.dart
//
// Cinematic opening splash for The Archive of Oblivion.
//
// Sequence (normal mode):
//   1. Black screen → bg_soglia fades in over 1 500 ms.
//   2. A random Bach sector track starts simultaneously (soft fade-in via
//      AudioService._isFirstTrack).
//   3. After 1 600 ms the title container becomes visible; the typewriter
//      begins writing "The Archive of Oblivion" at ~75 ms / char.
//   4. Once the title is complete, a "Play" button appears and waits for the
//      player, giving the opening music time to breathe.
//   5. Tapping while the title is still typing fills it instantly, but does
//      not navigate automatically.
//
// With reduceMotion:
//   All animations are instant; the full title and "Play" button are shown
//   immediately, but the screen still waits for explicit confirmation.

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../audio/audio_service.dart';
import '../settings/app_settings_provider.dart';
import 'home_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key, this.audioFailed = false});

  /// Passed through to HomeScreen so the audio-failure banner can be shown.
  final bool audioFailed;

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  static const String _fullTitle = 'The Archive of Oblivion';

  // All six sector base tracks — one is chosen at random each launch.
  static const List<String> _splashTracks = [
    'soglia',
    'giardino',
    'osservatorio',
    'galleria',
    'laboratorio',
    'memoria',
  ];

  // ── state ──────────────────────────────────────────────────────────────────
  String _displayedTitle = '';
  int _charIndex = 0;
  bool _bgVisible = false;
  bool _titleVisible = false;
  bool _showPlayButton = false;
  bool _exiting = false;

  Timer? _typewriterTimer;

  // ── lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    // Defer to the first frame so that the widget tree (and Riverpod providers)
    // are fully initialised before we read settings or push to the navigator.
    WidgetsBinding.instance.addPostFrameCallback((_) => _startSequence());
  }

  @override
  void dispose() {
    _typewriterTimer?.cancel();
    super.dispose();
  }

  // ── sequence ───────────────────────────────────────────────────────────────

  void _startSequence() {
    if (!mounted) return;

    final settings = ref.read(appSettingsProvider).valueOrNull;
    final reduceMotion = settings?.reduceMotion ?? false;

    // Show background (instant with reduceMotion, animated otherwise).
    setState(() => _bgVisible = true);

    // Start music (respects the musicEnabled setting inside AudioService).
    _playRandomTrack();

    if (reduceMotion) {
      // Skip all animation but still let the player control when to enter.
      setState(() {
        _titleVisible = true;
        _displayedTitle = _fullTitle;
        _charIndex = _fullTitle.length;
        _showPlayButton = true;
      });
    } else {
      // Wait for the background to finish fading before typing begins.
      Future.delayed(const Duration(milliseconds: 1600), () {
        if (!mounted || _exiting) return;
        setState(() => _titleVisible = true);
        _startTypewriter();
      });
    }
  }

  void _playRandomTrack() {
    final key = _splashTracks[Random().nextInt(_splashTracks.length)];
    // handleTrigger is a no-op when music is disabled (checked inside AudioService).
    AudioService().handleTrigger(key);
  }

  void _startTypewriter() {
    _typewriterTimer = Timer.periodic(const Duration(milliseconds: 75), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_charIndex < _fullTitle.length) {
        setState(() {
          _charIndex++;
          _displayedTitle = _fullTitle.substring(0, _charIndex);
        });
      } else {
        timer.cancel();
        if (!mounted || _exiting) return;
        setState(() => _showPlayButton = true);
      }
    });
  }

  // ── interaction ────────────────────────────────────────────────────────────

  void _onTap() {
    if (_exiting) return;

    // Haptic only when allowed.
    final settings = ref.read(appSettingsProvider).valueOrNull;
    if ((settings?.enableHaptics ?? true) && !(settings?.reduceMotion ?? false)) {
      HapticFeedback.lightImpact();
    }

    if (_charIndex >= _fullTitle.length) return;

    _typewriterTimer?.cancel();

    setState(() {
      _displayedTitle = _fullTitle;
      _charIndex = _fullTitle.length;
      _showPlayButton = true;
    });
  }

  // ── navigation ─────────────────────────────────────────────────────────────

  void _navigateToHome() {
    if (_exiting) return;
    _exiting = true;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            HomeScreen(audioFailed: widget.audioFailed),
        transitionDuration: const Duration(milliseconds: 800),
        reverseTransitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider).valueOrNull;
    final reduceMotion = settings?.reduceMotion ?? false;
    final bgFadeDuration =
        reduceMotion ? Duration.zero : const Duration(milliseconds: 1500);

    return GestureDetector(
      onTap: _onTap,
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // ── Background image ───────────────────────────────────────────
            AnimatedOpacity(
              opacity: _bgVisible ? 1.0 : 0.0,
              duration: bgFadeDuration,
              curve: Curves.easeIn,
              child: Image.asset(
                'assets/images/bg_soglia.jpg',
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),

            // ── Dark veil (lighter than in-game to let the image breathe) ─
            Container(color: Colors.black.withValues(alpha: 0.38)),

            // ── Title ──────────────────────────────────────────────────────
            AnimatedOpacity(
              opacity: _titleVisible ? 1.0 : 0.0,
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 250),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 36.0),
                  child: Text(
                    _displayedTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFE9E3D6),
                      fontSize: 30,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.4,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ),

            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                minimum: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                child: AnimatedOpacity(
                  opacity: _showPlayButton ? 1.0 : 0.0,
                  duration: reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 280),
                  child: IgnorePointer(
                    ignoring: !_showPlayButton || _exiting,
                    child: FilledButton(
                      onPressed: _navigateToHome,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFE9E3D6),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      child: const Text('PLAY'),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
