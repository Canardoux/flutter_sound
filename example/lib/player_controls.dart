import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';

import 'active_codec.dart';
import 'common.dart';
import 'grayed_out.dart';
import 'media_path.dart';
import 'player_slider.dart';
import 'player_state.dart';

/// The UI for a example player.
class PlayerControls extends StatefulWidget {
  /// ctor
  const PlayerControls({
    Key key,
  }) : super(key: key);

  @override
  _PlayerControlsState createState() => _PlayerControlsState();
}

class _PlayerControlsState extends State<PlayerControls> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        buildDurationText(),
        Row(
          children: <Widget>[
            buildPlayButton(),
            buildStopButton(),
          ],
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
        ),
        PlayerSlider(),
        buildDuration(),
      ],
    );
  }

  Container buildDurationText() {
    return Container(
      margin: EdgeInsets.only(top: 12.0, bottom: 16.0),
      child: StreamBuilder<PlaybackDisposition>(
          stream: PlayerState().playStatusStream,
          initialData: PlaybackDisposition.zero(),
          builder: (context, snapshot) {
            var playStatus = snapshot.data;
            return Text(
              formatDuration(playStatus.duration),
              style: TextStyle(
                fontSize: 35.0,
                color: Colors.black,
              ),
            );
          }),
    );
  }

  Widget buildDuration() {
    return FutureBuilder<double>(
        future: getDuration(ActiveCodec().codec),
        initialData: 0.0,
        builder: (context, snapshot) {
          var duration = snapshot.data;
          duration ??= 0;
          return Container(
            height: 30.0,
            child: Text(duration != 0 ? "Duration: $duration sec." : ''),
          );
        });
  }

  Container buildStopButton() {
    return Container(
      width: 56.0,
      height: 50.0,
      child: ClipOval(
        child: GrayedOut(
            grayedOut: PlayerState().isStopped,
            child: FlatButton(
              onPressed: stopPlayer,
              disabledColor: Colors.white,
              padding: EdgeInsets.all(8.0),
              child: Image(
                width: 28.0,
                height: 28.0,
                image: AssetImage(
                    PlayerState().isPlaying || PlayerState().isPaused
                        ? 'res/icons/ic_stop.png'
                        : 'res/icons/ic_stop_disabled.png'),
              ),
            )),
      ),
    );
  }

  void stopPlayer() {
    PlayerState().stopPlayer();

    setState(() {});
  }

  Container buildPlayButton() {
    return Container(
      width: 56.0,
      height: 50.0,
      child: ClipOval(
          child: FlatButton(
        onPressed: startPlayer,
        disabledColor: Colors.white,
        padding: EdgeInsets.all(8.0),
        child: Image(
          image: getPlayIcon(),
        ),
      )),
    );
  }

  void startPlayer() async {
    var canPlay = true;
    if (MediaPath().isExampleFile) {
      if (ActiveCodec().codec != Codec.CODEC_MP3) {
        canPlay = false;
        var error = SnackBar(
            backgroundColor: Colors.red,
            content: Text('You must set the Coded to MP3 to '
                'play the "Remote Example File"'));
        Scaffold.of(context).showSnackBar(error);
      }
    } else if (!MediaPath().isAsset &&
        !MediaPath().exists(ActiveCodec().codec)) {
      canPlay = false;
      var error = SnackBar(
          content: Text('Record a message first or select '
              '"Remote Example File" from Media'));
      Scaffold.of(context).showSnackBar(error);
    }

    if (canPlay) {
      if (PlayerState().isStopped) {
        await PlayerState().startPlayer(whenFinished: playbackFinished);
      } else {
        await PlayerState().pauseResumePlayer();
      }

      setState(() {});
    }
  }

  AssetImage getPlayIcon() {
    var path = 'res/icons/ic_play.png';
    if ((PlayerState().isPlaying)) {
      path = 'res/icons/ic_pause.png';
    } else if (PlayerState().isPaused) {
      path = 'res/icons/ic_play.png';
    } else if (PlayerState().canStart) {
      path = 'res/icons/ic_play.png';
    }

    return AssetImage(path);
  }

  void playbackFinished() {
    PlayerState().stopPlayer();
    setState(() {});
  }
}
