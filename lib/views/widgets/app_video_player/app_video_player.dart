// import 'package:better_player_plus/better_player_plus.dart';
// import 'package:flutter/material.dart';

// class AppVideoPlayer extends StatefulWidget {
//   const AppVideoPlayer({super.key, required this.url, this.ratio});
//   final String url;
//   final double? ratio;

//   @override
//   State<AppVideoPlayer> createState() => _AppVideoPlayerState();
// }

// class _AppVideoPlayerState extends State<AppVideoPlayer> {
//   late BetterPlayerController _betterPlayerController;
//   late BetterPlayerDataSource _betterPlayerDataSource;
//   bool _isMuted = true;

//   @override
//   void initState() {
//     super.initState();
//     _initializePlayer();
//   }

//   void _initializePlayer() {
//     // Configuration for feed view (autoplay, muted, minimal controls)
//     final betterPlayerConfiguration = BetterPlayerConfiguration(
//       fit: BoxFit.cover,
//       // routePageBuilder: (
//       //   context,
//       //   animation,
//       //   secondaryAnimation,
//       //   controllerProvider,
//       // ) {
//       //   return AnimatedBuilder(
//       //     animation: animation,
//       //     builder: (BuildContext context, Widget? child) =>
//       //         FullScreenVideoPlayer(
//       //       url: widget.url,
//       //       provider: controllerProvider,
//       //     ),
//       //   );
//       // },
//       controlsConfiguration: const BetterPlayerControlsConfiguration(
//         enableSubtitles: false,
//       ),
//     );

//     _betterPlayerDataSource = BetterPlayerDataSource(
//       BetterPlayerDataSourceType.network,
//       widget.url,
//     );

//     _betterPlayerController = BetterPlayerController(betterPlayerConfiguration);
//     _betterPlayerController.setupDataSource(_betterPlayerDataSource);

//     // Start muted
//     _betterPlayerController.setVolume(0);
//   }

//   // void _toggleMute() {
//   //   setState(() {
//   //     _isMuted = !_isMuted;
//   //     _betterPlayerController.setVolume(_isMuted ? 0 : 1);
//   //   });
//   // }

//   // void _openFullScreen() {
//   //   _betterPlayerController
//   //       .postEvent(BetterPlayerEvent(BetterPlayerEventType.openFullscreen));

//   //   Navigator.of(context).push(
//   //     HeroDialogRoute<void>(
//   //       builder: (context) => FullScreenVideoPlayer(
//   //         url: widget.url,
//   //         controller: _betterPlayerController,
//   //       ),
//   //     ),
//   //   );
//   // }

//   @override
//   void dispose() {
//     _betterPlayerController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return AspectRatio(
//       aspectRatio: widget.ratio ?? 16 / 9,
//       child: Stack(
//         children: [
//           BetterPlayer(controller: _betterPlayerController),

//           // Transparent overlay to capture taps and trigger fullscreen
//           // Positioned.fill(
//           //   child: GestureDetector(
//           //     onTap: () {
//           //       _betterPlayerController.enterFullScreen();
//           //     },
//           //     behavior: HitTestBehavior.translucent,
//           //     child: Container(
//           //       color: Colors.transparent,
//           //     ),
//           //   ),
//           // ),
//         ],
//       ),
//     );
//   }
// }
