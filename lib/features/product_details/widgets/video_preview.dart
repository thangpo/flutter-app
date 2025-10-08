import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:video_player/video_player.dart';

class VideoPreview extends StatefulWidget {
  final String url;
  final String fileName;
  const VideoPreview({super.key, required this.url, required this.fileName});

  @override
  State<VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<VideoPreview> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.url),
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );

    _controller.addListener(() {
      setState(() {});
    });
    _controller.setLooping(true);
    _controller.initialize();

    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }


  void _toggleFullScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => FullScreenVideoPlayer(controller: _controller)),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.3,
      width: MediaQuery.of(context).size.height * 0.9,
      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(
          color: Theme.of(context).hintColor.withValues(alpha:0.50),
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault)
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(widget.fileName,
                    style: titilliumSemiBold.copyWith(fontSize: Dimensions.fontSizeLarge), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: Dimensions.paddingSizeSmall),

              SizedBox(
                  height: 20, width: 20,
                  child: IconButton(
                      padding: EdgeInsets.zero,
                      onPressed: ()=> Navigator.of(context, rootNavigator: true).pop(),
                      icon: Icon(Icons.close, color: Theme.of(context).hintColor, size: 20,)
                  )
              ),
            ],
          ),
          const SizedBox(height: Dimensions.paddingSizeDefault),

          Expanded(
            child: Stack(
              children: [
                if (_controller.value.isInitialized)
                  Center(
                    child: AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    ),
                  )
                else
                  const Center(child: CircularProgressIndicator()),
                Positioned(top: 0, bottom: 0, left: 0, right: 0,
                    child: IconButton(
                      onPressed: () {
                        setState(() {
                          _controller.value.isPlaying ? _controller.pause() : _controller.play();
                        });
                      },
                      icon: Icon( _controller.value.isPlaying ? Icons.pause_sharp : Icons.play_arrow, color: Theme.of(context).primaryColor),
                    )
                ),

                Positioned(
                    bottom: 5, right: 5,
                    child: IconButton(
                      onPressed: () => _toggleFullScreen(context),
                      icon: Icon( Icons.fullscreen, color: Theme.of(context).primaryColor),
                    )
                ),

                Positioned(
                  bottom: 10,
                  child:SizedBox(
                    width: MediaQuery.of(context).size.height * 0.7,
                    child: VideoProgressIndicator(
                      _controller,
                      allowScrubbing: true,
                      colors: VideoProgressColors(
                        backgroundColor: Colors.grey,
                        playedColor: Theme.of(context).primaryColor,
                        bufferedColor: Colors.white,
                      ),
                    ),
                  ),
                ),

              ],
            ),
          )


        ],
      ),
    );
  }
}



class FullScreenVideoPlayer extends StatelessWidget {
  final VideoPlayerController controller;

  const FullScreenVideoPlayer({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: AspectRatio(
          aspectRatio: controller.value.aspectRatio,
          child: VideoPlayer(controller),
        ),
      ),

      floatingActionButton: FloatingActionButton (
        backgroundColor: Theme.of(context).cardColor,
        onPressed: () => Navigator.pop(context),
        child: Icon(Icons.fullscreen_exit, color: Theme.of(context).primaryColor),
      ),

    );
  }
}