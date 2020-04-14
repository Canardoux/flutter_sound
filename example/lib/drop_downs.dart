import 'package:flutter/material.dart';
import 'package:flutter_sound/flauto.dart';

import 'active_codec.dart';
import 'common.dart';
import 'main.dart';
import 'media_path.dart';

class Dropdowns extends StatefulWidget {
  final BuildContext context;
  final void Function(t_CODEC) onCodecChanged;

  const Dropdowns({
    Key key,
    @required this.context,
    @required this.onCodecChanged,
  }) : super(key: key);

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

  DropdownButton<t_CODEC> buildCodecDropdown() {
    return DropdownButton<t_CODEC>(
      value: ActiveCodec().codec,
      onChanged: (newCodec) {
        widget.onCodecChanged(newCodec);
        ActiveCodec().setCodec(newCodec);

        setState(() {
          getDuration(ActiveCodec().codec);
        });
      },
      items: <DropdownMenuItem<t_CODEC>>[
        DropdownMenuItem<t_CODEC>(
          value: t_CODEC.CODEC_AAC,
          child: Text('AAC'),
        ),
        DropdownMenuItem<t_CODEC>(
          value: t_CODEC.CODEC_OPUS,
          child: Text('OGG/Opus'),
        ),
        DropdownMenuItem<t_CODEC>(
          value: t_CODEC.CODEC_CAF_OPUS,
          child: Text('CAF/Opus'),
        ),
        DropdownMenuItem<t_CODEC>(
          value: t_CODEC.CODEC_MP3,
          child: Text('MP3'),
        ),
        DropdownMenuItem<t_CODEC>(
          value: t_CODEC.CODEC_VORBIS,
          child: Text('OGG/Vorbis'),
        ),
        DropdownMenuItem<t_CODEC>(
          value: t_CODEC.CODEC_PCM,
          child: Text('PCM'),
        ),
      ],
    );
  }

  DropdownButton<t_MEDIA> buildMediaDropdown() {
    return DropdownButton<t_MEDIA>(
      value: MediaPath().media,
      onChanged: (newMedia) {
        if (newMedia == t_MEDIA.remoteExampleFile) {
          ActiveCodec().setCodec(t_CODEC.CODEC_MP3);
          MediaPath()
              .setCodecPath(ActiveCodec().codec, exampleAudioFilePath);
        } // Actually this is the only example we use in this example
        MediaPath().media = newMedia;

        setState(() {});
      },
      items: <DropdownMenuItem<t_MEDIA>>[
        DropdownMenuItem<t_MEDIA>(
          value: t_MEDIA.file,
          child: Text('File'),
        ),
        DropdownMenuItem<t_MEDIA>(
          value: t_MEDIA.buffer,
          child: Text('Buffer'),
        ),
        DropdownMenuItem<t_MEDIA>(
          value: t_MEDIA.asset,
          child: Text('Asset'),
        ),
        DropdownMenuItem<t_MEDIA>(
          value: t_MEDIA.remoteExampleFile,
          child: Text('Remote Example File'),
        ),
      ],
    );
  }
}
