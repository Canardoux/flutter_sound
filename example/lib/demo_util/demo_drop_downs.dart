import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';

import 'demo_active_codec.dart';
import 'demo_common.dart';
import 'demo_media_path.dart';

/// Widget containing the set of drop downs used in the UI
/// Media
/// Codec
class Dropdowns extends StatefulWidget {
  final void Function(Codec) _onCodecChanged;

  /// ctor
  const Dropdowns({
    Key key,
    @required void Function(Codec) onCodecChanged,
  })  : _onCodecChanged = onCodecChanged,
        super(key: key);

  @override
  _DropdownsState createState() => _DropdownsState();
}

class _DropdownsState extends State<Dropdowns> {
  _DropdownsState();

  @override
  Widget build(BuildContext context) {
    final mediaDropdown = Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Text('Record To:'),
        ),
        buildMediaDropdown(),
      ],
    );

    final codecDropdown = Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Text('Codec:'),
        ),
        buildCodecDropdown(),
      ],
    );

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          mediaDropdown,
          codecDropdown,
        ],
      ),
    );
  }

  DropdownButton<Codec> buildCodecDropdown() {
    return DropdownButton<Codec>(
      value: ActiveCodec().codec,
      onChanged: (newCodec) {
        widget._onCodecChanged(newCodec);

        /// this is hacky as we should be passing the actually
        /// useOSUI flag.
        ActiveCodec().setCodec(withUI: false, codec: newCodec);

        setState(() {
          getDuration(ActiveCodec().codec);
        });
      },
      items: <DropdownMenuItem<Codec>>[
        DropdownMenuItem<Codec>(
          value: Codec.aacADTS,
          child: Text('AAC'),
        ),
        DropdownMenuItem<Codec>(
          value: Codec.opusOGG,
          child: Text('OGG/Opus'),
        ),
        DropdownMenuItem<Codec>(
          value: Codec.cafOpus,
          child: Text('CAF/Opus'),
        ),
        DropdownMenuItem<Codec>(
          value: Codec.mp3,
          child: Text('MP3'),
        ),
        DropdownMenuItem<Codec>(
          value: Codec.vorbisOGG,
          child: Text('OGG/Vorbis'),
        ),
        DropdownMenuItem<Codec>(
          value: Codec.pcm,
          child: Text('PCM'),
        ),
      ],
    );
  }

  DropdownButton<MediaStorage> buildMediaDropdown() {
    return DropdownButton<MediaStorage>(
      value: MediaPath().media,
      onChanged: (newMedia) {
        MediaPath().media = newMedia;

        setState(() {});
      },
      items: <DropdownMenuItem<MediaStorage>>[
        DropdownMenuItem<MediaStorage>(
          value: MediaStorage.file,
          child: Text('File'),
        ),
        DropdownMenuItem<MediaStorage>(
          value: MediaStorage.buffer,
          child: Text('Buffer'),
        ),
      ],
    );
  }
}
