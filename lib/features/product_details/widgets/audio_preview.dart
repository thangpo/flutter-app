import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';


class AudioPreview extends StatefulWidget {
  final String url;
  final String fileName;
  const AudioPreview({super.key, required this.url, required this.fileName});

  @override
  State<AudioPreview> createState() => _AudioPreviewState();
}

class _AudioPreviewState extends State<AudioPreview> {
  late AudioPlayer _audioPlayer;
  bool isPlaying = false;
  Duration _duration = const Duration();
  Duration _position = const Duration();


  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();

    _audioPlayer.onDurationChanged.listen((Duration d) {
      setState(() {
        _duration = d;
      });
    });

    _audioPlayer.onPositionChanged.listen((Duration p) {
      setState(() {
        _position = p;
      });
    });
  }


  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }



  void _playPause() {
    if (isPlaying) {
      _audioPlayer.pause();
    } else {
      _audioPlayer.play(UrlSource(widget.url));
    }
    setState(() {
      isPlaying = !isPlaying;
    });
  }

  // void _stop() {
  //   _audioPlayer.stop();
  //   setState(() {
  //     isPlaying = false;
  //   });
  // }

  String _formatDuration(Duration d) {
    String minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    String seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }





  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.15,
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
                    style: titilliumRegular.copyWith(fontSize: Dimensions.fontSizeLarge), maxLines: 1, overflow: TextOverflow.ellipsis),
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

          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
              color: Theme.of(context).cardColor,
            ),
            child: Row(
              children: [

                IconButton(
                  onPressed: _playPause,
                  icon : Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                ),
                const SizedBox(width: Dimensions.paddingSizeSmall),

                Slider(
                  value: _position.inSeconds.toDouble(),
                  min: 0.0,
                  inactiveColor: Theme.of(context).hintColor,
                  max: _duration.inSeconds.toDouble(),
                  onChanged: (double value) {
                    setState(() {
                      _audioPlayer.seek(Duration(seconds: value.toInt()));
                    });
                  },
                ),
                const SizedBox(width: Dimensions.paddingSizeSmall),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_formatDuration(_position)),
                    const SizedBox(width: Dimensions.paddingSizeSmall),
                    Text(_formatDuration(_duration)),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}