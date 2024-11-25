import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';

class VideoPreviewPage extends StatefulWidget {
  final String filePath;

  /// 播放视频页
  const VideoPreviewPage({super.key, required this.filePath});

  @override
  _VideoPreviewPageState createState() => _VideoPreviewPageState();
}

class _VideoPreviewPageState extends State<VideoPreviewPage> {
  late VideoPlayerController _controller;
  late Future<void> _initializeVideoPlayerFuture;

  @override
  void initState() {
    super.initState();
    // 初始化视频播放器控制器
    _controller = VideoPlayerController.file(File(widget.filePath));

    // 初始化视频播放器并保存 Future
    _initializeVideoPlayerFuture = _controller.initialize().then((_) {
      // 确保初始化完成后开始播放
      setState(() {});
      _controller.play();
    });
  }

  @override
  void dispose() {
    // 释放视频资源
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Video Preview")),
      body: Center(
        child: FutureBuilder(
          future: _initializeVideoPlayerFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              // 视频加载完成时，显示视频播放器
              return AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              );
            } else {
              // 否则显示加载指示器
              return CircularProgressIndicator();
            }
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            // 播放/暂停控制
            _controller.value.isPlaying
                ? _controller.pause()
                : _controller.play();
          });
        },
        child: Icon(
          _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
        ),
      ),
    );
  }
}
