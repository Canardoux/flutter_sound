import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';

import 'active_codec.dart';
import 'common.dart';
import 'main.dart';
import 'media_path.dart';

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
          child: Text('Media:'),
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: mediaDropdown,
          ),
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
        ActiveCodec().setCodec(newCodec);

        setState(() {
          getDuration(ActiveCodec().codec);
        });
      },
      items: <DropdownMenuItem<Codec>>[
        DropdownMenuItem<Codec>(
          value: Codec.CODEC_AAC,
          child: Text('AAC'),
        ),
        DropdownMenuItem<Codec>(
          value: Codec.CODEC_OPUS,
          child: Text('OGG/Opus'),
        ),
        DropdownMenuItem<Codec>(
          value: Codec.CODEC_CAF_OPUS,
          child: Text('CAF/Opus'),
        ),
        DropdownMenuItem<Codec>(
          value: Codec.CODEC_MP3,
          child: Text('MP3'),
        ),
        DropdownMenuItem<Codec>(
          value: Codec.CODEC_VORBIS,
          child: Text('OGG/Vorbis'),
        ),
        DropdownMenuItem<Codec>(
          value: Codec.CODEC_PCM,
          child: Text('PCM'),
        ),
      ],
    );
  }

  DropdownButton<MediaStorage> buildMediaDropdown() {
    return DropdownButton<MediaStorage>(
      value: MediaPath().media,
      onChanged: (newMedia) {
        if (newMedia == MediaStorage.remoteExampleFile) {
          ActiveCodec().setCodec(Codec.CODEC_MP3);
          MediaPath().setCodecPath(ActiveCodec().codec, exampleAudioFilePath);
        } // Actually this is the only example we use in this example
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
        DropdownMenuItem<MediaStorage>(
          value: MediaStorage.asset,
          child: Text('Asset'),
        ),
        DropdownMenuItem<MediaStorage>(
          value: MediaStorage.remoteExampleFile,
          child: Text('Remote Example File'),
        ),
      ],
    );
  }
}
