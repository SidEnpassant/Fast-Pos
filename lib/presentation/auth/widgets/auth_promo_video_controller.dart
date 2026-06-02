import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

/// Single looping promo video shared across login and signup (ref-counted).
final class AuthPromoVideoController {
  AuthPromoVideoController._();

  static final AuthPromoVideoController instance = AuthPromoVideoController._();

  static const assetPath = 'assets/video_asset/app_video_asset.mp4';

  VideoPlayerController? _controller;
  int _refs = 0;
  Future<void>? _initFuture;

  final ValueNotifier<bool> initialized = ValueNotifier<bool>(false);

  VideoPlayerController? get controller => _controller;

  Future<void> acquire() {
    _refs++;
    _initFuture ??= _initialize();
    return _initFuture!;
  }

  void release() {
    if (_refs <= 0) return;
    _refs--;
    if (_refs == 0) {
      _controller?.pause();
    }
  }

  void disposeIfUnused() {
    if (_refs > 0) return;
    _controller?.dispose();
    _controller = null;
    _initFuture = null;
    initialized.value = false;
  }

  Future<void> _initialize() async {
    if (_controller != null && _controller!.value.isInitialized) {
      initialized.value = true;
      await _controller!.play();
      return;
    }

    final controller = VideoPlayerController.asset(
      assetPath,
      videoPlayerOptions: VideoPlayerOptions(
        mixWithOthers: true,
        allowBackgroundPlayback: false,
      ),
    );
    _controller = controller;

    await controller.initialize();
    await controller.setLooping(true);
    await controller.setVolume(0);
    initialized.value = true;
    await controller.play();
  }
}
