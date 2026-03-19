import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'menu_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  VideoPlayerController? _controller;
  bool _isReady = false;
  bool _hasNavigated = false;
  bool _isFadingOut = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _initializeAndPlay();
  }

  Future<void> _initializeAndPlay() async {
    final candidate =
        VideoPlayerController.asset('assets/splash/ST-Splash.mp4');
    try {
      await candidate.initialize();
    } catch (_) {
      await candidate.dispose();
      _navigateToMenu();
      return;
    }

    if (!mounted) {
      await candidate.dispose();
      return;
    }

    _controller = candidate;
    await _controller!.setLooping(false);
    await _controller!.setVolume(1.0);
    _controller!.addListener(_handlePlaybackProgress);

    if (!mounted) {
      return;
    }

    setState(() {
      _isReady = true;
    });

    _fadeController.forward();

    try {
      await _controller!.play();
    } catch (e) {
      _navigateToMenu();
    }
  }

  void _handlePlaybackProgress() {
    final controller = _controller;
    if (controller == null ||
        !controller.value.isInitialized ||
        _hasNavigated) {
      return;
    }

    if (controller.value.hasError) {
      _navigateToMenu();
      return;
    }

    final duration = controller.value.duration;
    final position = controller.value.position;

    if (!_isFadingOut &&
        duration > Duration.zero &&
        position >= duration - const Duration(milliseconds: 600)) {
      _isFadingOut = true;
      _fadeController.reverse().then((_) {
        _navigateToMenu();
      });
    }
  }

  void _navigateToMenu() {
    if (!mounted || _hasNavigated) {
      return;
    }

    _hasNavigated = true;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const MenuScreen(),
        transitionDuration: const Duration(milliseconds: 450),
        reverseTransitionDuration: const Duration(milliseconds: 250),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller?.removeListener(_handlePlaybackProgress);
    _controller?.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final isInitialized =
        _isReady && controller != null && controller.value.isInitialized;

    return Scaffold(
      backgroundColor: Colors.black,
      body: isInitialized
          ? FadeTransition(
              opacity: _fadeAnimation,
              child: SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  clipBehavior: Clip.hardEdge,
                  child: SizedBox(
                    width: controller.value.size.width,
                    height: controller.value.size.height,
                    child: VideoPlayer(controller),
                  ),
                ),
              ),
            )
          : const ColoredBox(color: Colors.black),
    );
  }
}
