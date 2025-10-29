import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoAutoPlayer extends StatefulWidget {
  final String url;
  const VideoAutoPlayer({super.key, required this.url});

  @override
  State<VideoAutoPlayer> createState() => _VideoAutoPlayerState();
}

class _VideoAutoPlayerState extends State<VideoAutoPlayer> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _muted = true;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..setLooping(true)
      ..setVolume(0.0)
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() => _initialized = true);
        _controller.play();
      }).catchError((_) {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return Container(
        color: Colors.black,
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        FittedBox(
          fit: BoxFit.cover,
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            width: _controller.value.size.width,
            height: _controller.value.size.height,
            child: VideoPlayer(_controller),
          ),
        ),
        Positioned(
          right: 8,
          bottom: 8,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _muted = !_muted;
                _controller.setVolume(_muted ? 0.0 : 1.0);
              });
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                _muted ? Icons.volume_off : Icons.volume_up,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
