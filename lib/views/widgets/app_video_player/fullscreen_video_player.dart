import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';

import '../../gallery_view/gallery_view.dart';
import 'dismissible_page.dart';

class FullScreenVideoPlayer extends StatefulWidget {
  const FullScreenVideoPlayer({
    super.key,
    required this.url,
    required this.provider,
  });

  final String url;
  final ChewieControllerProvider provider;

  @override
  State<FullScreenVideoPlayer> createState() => _FullScreenVideoPlayerState();
}

class _FullScreenVideoPlayerState extends State<FullScreenVideoPlayer> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DisplayGesture(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: DismissiblePage(
          onDismissed: () => Navigator.of(context).pop(),
          child: widget.provider,
        ),
      ),
    );
  }
}
