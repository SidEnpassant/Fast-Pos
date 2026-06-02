import 'package:flutter/material.dart';
import 'package:inventopos/presentation/auth/widgets/auth_promo_video_controller.dart';
import 'package:video_player/video_player.dart';

/// Full-screen looping promo video; isolated in a [RepaintBoundary].
class AuthPromoVideoBackground extends StatefulWidget {
  const AuthPromoVideoBackground({super.key});

  @override
  State<AuthPromoVideoBackground> createState() =>
      _AuthPromoVideoBackgroundState();
}

class _AuthPromoVideoBackgroundState extends State<AuthPromoVideoBackground> {
  final _video = AuthPromoVideoController.instance;

  @override
  void initState() {
    super.initState();
    _video.acquire();
  }

  @override
  void dispose() {
    _video.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return RepaintBoundary(
      child: ValueListenableBuilder<bool>(
        valueListenable: _video.initialized,
        builder: (context, ready, _) {
          final controller = _video.controller;
          if (!ready || controller == null || !controller.value.isInitialized) {
            return ColoredBox(
              color: scheme.primary.withValues(alpha: 0.85),
            );
          }

          return SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: controller.value.size.width,
                height: controller.value.size.height,
                child: VideoPlayer(controller),
              ),
            ),
          );
        },
      ),
    );
  }
}
