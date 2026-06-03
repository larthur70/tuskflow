import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class TuskMascotAvatar extends StatefulWidget {
  const TuskMascotAvatar({
    super.key,
    this.size = 144,
  });

  final double size;

  @override
  State<TuskMascotAvatar> createState() => TuskMascotAvatarState();
}

class TuskMascotAvatarState extends State<TuskMascotAvatar> {
  static const _imagePath = 'assets/images/tusk_images/tusk_1.png';
  static const _videoPath = 'assets/images/tusk_images/succes_gif.mp4';
  static const _padding = 18.0;
  static const _videoScaleBoost = 1.36;

  VideoPlayerController? _controller;
  bool _playing = false;

  double get _elephantSize => widget.size - _padding * 2;

  @override
  void initState() {
    super.initState();
    _preloadVideo();
  }

  Future<void> _preloadVideo() async {
    _controller = VideoPlayerController.asset(_videoPath)
      ..setLooping(false);
    await _controller!.initialize();
    if (mounted) setState(() {});
  }

  Future<void> celebrate() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      await _preloadVideo();
    }
    if (!mounted || _controller == null) return;

    _controller!
      ..removeListener(_onVideoTick)
      ..addListener(_onVideoTick)
      ..seekTo(Duration.zero)
      ..play();

    setState(() => _playing = true);
  }

  void _onVideoTick() {
    final controller = _controller;
    if (controller == null || !_playing || !controller.value.isInitialized) {
      return;
    }

    final duration = controller.value.duration;
    if (duration == Duration.zero) return;

    final nearEnd = controller.value.position >=
        duration - const Duration(milliseconds: 100);
    if (nearEnd ||
        (!controller.value.isPlaying &&
            controller.value.position > Duration.zero)) {
      controller
        ..removeListener(_onVideoTick)
        ..pause();
      if (mounted) {
        setState(() => _playing = false);
      }
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_onVideoTick);
    _controller?.dispose();
    super.dispose();
  }

  Widget _buildViewport({required Widget child, double scale = 1}) {
    return SizedBox(
      width: _elephantSize,
      height: _elephantSize,
      child: ClipRect(
        child: Center(
          child: Transform.scale(
            scale: scale,
            child: SizedBox(
              width: _elephantSize,
              height: _elephantSize,
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    return _buildViewport(
      child: Image.asset(
        _imagePath,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildVideo() {
    final controller = _controller!;
    return _buildViewport(
      scale: _videoScaleBoost,
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: controller.value.size.width,
          height: controller.value.size.height,
          child: VideoPlayer(controller),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showVideo =
        _playing && _controller != null && _controller!.value.isInitialized;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(_padding),
          child: Center(
            child: showVideo ? _buildVideo() : _buildImage(),
          ),
        ),
      ),
    );
  }
}
