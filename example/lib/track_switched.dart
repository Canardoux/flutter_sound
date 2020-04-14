import 'package:flutter/material.dart';

import 'grayed_out.dart';
import 'player_state.dart';

class TrackSwitch extends StatefulWidget {
  final void Function(bool allowTracks) switchPlayer;

  const TrackSwitch({
    Key key,
    @required bool isAudioPlayer,
    @required this.switchPlayer,
  })  : _isAudioPlayer = isAudioPlayer,
        super(key: key);

  final bool _isAudioPlayer;

  @override
  _TrackSwitchState createState() => _TrackSwitchState();
}

class _TrackSwitchState extends State<TrackSwitch> {
  _TrackSwitchState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Text('"Allow Tracks":'),
          ),
          GrayedOut(
              grayedOut: !PlayerState().isStopped,
              child: Switch(
                value: widget._isAudioPlayer,
                onChanged: (allow) =>
                    onAudioPlayerSwitchChanged(allowTracks: allow),
              )),
          Padding(
            padding: const EdgeInsets.only(right: 4.0),
            child: Text('Duck Others:'),
          ),
          Switch(
            value: PlayerState().duckOthers,
            onChanged: (duckOthers) =>
                duckOthersSwitchChanged(duckOthers: duckOthers),
          ),
        ],
      ),
    );
  }

  void onAudioPlayerSwitchChanged({bool allowTracks = false}) async {
    widget.switchPlayer(allowTracks);
  }

  void duckOthersSwitchChanged({bool duckOthers}) {
    PlayerState().setDuck(duckOthers: duckOthers);
  }
}
