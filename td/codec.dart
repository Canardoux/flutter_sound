/*
 * Copyright 2024 Canardoux.
 *
 * This file is part of the τ project.
 *
 * τ is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 3 (GPL3), as published by
 * the Free Software Foundation.
 *
 * τ is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with τ.  If not, see <https://www.gnu.org/licenses/>.
 */

enum EContainer {
  RAW16,
  RAW32,
  WAV,
  MP4,
  ADTS,
  C3GP,
  MOV,
  OGG,
  CFLAC,
  RTP,
  WebRTC,
  MPEG, // MP3
  WebM,
}

List<CodecContainer> containers = [
  RAW16(),
  RAW32(),
  WAV(),
  MP4(),
  ADTS(),
  C3GP(),
  MOV(),
  OGG(),
  CFLAC(),
  RTP(),
  WebRTC(),
  MPEG(), // MP3
  WebM(),
];

class CodecContainer {
  late EContainer eContainer;
  /* ctor */
  CodecContainer(this.eContainer);
}

class RAW16 extends CodecContainer {
  /* ctor */
  RAW16() : super(EContainer.RAW16);
}

class RAW32 extends CodecContainer {
  /* ctor */
  RAW32() : super(EContainer.RAW32);
}

class WAV extends CodecContainer {
  /* ctor */
  WAV() : super(EContainer.WAV);
}

class MP4 extends CodecContainer {
  /* ctor */
  MP4() : super(EContainer.MP4);
}

class ADTS extends CodecContainer {
  /* ctor */
  ADTS() : super(EContainer.ADTS);
}

class C3GP extends CodecContainer {
  /* ctor */
  C3GP() : super(EContainer.C3GP);
}

class MOV extends CodecContainer {
  /* ctor */
  MOV() : super(EContainer.MOV);
}

class OGG extends CodecContainer {
  /* ctor */
  OGG() : super(EContainer.OGG);
}

class CFLAC extends CodecContainer {
  /* ctor */
  CFLAC() : super(EContainer.CFLAC);
}

class RTP extends CodecContainer {
  /* ctor */
  RTP() : super(EContainer.RTP);
}

class WebRTC extends CodecContainer {
  /* ctor */
  WebRTC() : super(EContainer.WebRTC);
}

class MPEG extends CodecContainer {
  /* ctor */
  MPEG() : super(EContainer.MPEG);
}

class WebM extends CodecContainer {
  /* ctor */
  WebM() : super(EContainer.WebM);
}

enum ETcodecs { PCM, AAC, ALAC, AMR, FLAC, G711, G722, MP3, OPUS, VORBIS }

List<TCodec> tcodecs = [
  PCM(),
  AAC(),
  ALAC(),
  AMR(),
  FLAC(),
  G711(),
  G722(),
  MP3(),
  OPUS(),
  VORBIS(),
];

abstract class TCodec {
  late ETcodecs etContainer;
  /* ctor */
  TCodec(this.etContainer);
}

class PCM extends TCodec {
  /* ctor */
  PCM() : super(ETcodecs.PCM);
}

class AAC extends TCodec {
  /* ctor */
  AAC() : super(ETcodecs.AAC);
}

class ALAC extends TCodec {
  /* ctor */
  ALAC() : super(ETcodecs.ALAC);
}

class AMR extends TCodec {
  /* ctor */
  AMR() : super(ETcodecs.AMR);
}

class FLAC extends TCodec {
  /* ctor */
  FLAC() : super(ETcodecs.FLAC);
}

class G711 extends TCodec {
  /* ctor */
  G711() : super(ETcodecs.G711);
}

class G722 extends TCodec {
  /* ctor */
  G722() : super(ETcodecs.G722);
}

class MP3 extends TCodec {
  /* ctor */
  MP3() : super(ETcodecs.MP3);
}

class OPUS extends TCodec {
  /* ctor */
  OPUS() : super(ETcodecs.OPUS);
}

class VORBIS extends TCodec {
  /* ctor */
  VORBIS() : super(ETcodecs.VORBIS);
}

enum ECodec {
  PCM_RAW16,
  PCM_RAW32,
  PCM_WAV,
  AAC_MP4,
  AAC_ADTS,
  AAC_3GP,
  ALAC_MP4,
  ALAC_MOV,
  AMR_3GP,
  FLAC_MP4,
  FLAC_OGG,
  FLAC_FLAC,
  G711_RTP,
  G711_WebRTC,
  G722_RTP,
  G722_WebRTC,
  MP3_MP4,
  MP3_ADTS,
  MP3_MPEG,
  MP3_3GP,
  OPUS_WebM,
  OPUS_MP4,
  OPUS_OGG,
  VORBIS_WebM,
  VORBIS_OGG,
}

List<TaudioCodec> TaudioCodecs = [
  PCM_RAW16(),
  PCM_RAW32(),
  PCM_WAV(),
  AAC_ADTS(),
  AAC_3GP(),
  ALAC_MP4(),
  ALAC_MOV(),
  AMR_3GP(),
  FLAC_MP4(),
  FLAC_OGG(),
  FLAC_FLAC(),
  G711_RTP(),
  G711_WebRTC(),
  G722_RTP(),
  G722_WebRTC(),
  MP3_MP4(),
  MP3_ADTS(),
  MP3_MPEG(),
  MP3_3GP(),
  OPUS_WebM(),
  OPUS_MP4(),
  OPUS_OGG(),
  VORBIS_WebM(),
  VORBIS_OGG(),
];

abstract class TaudioCodec {
  String get type;
  bool get isPCM => tcodec is PCM;
  late TCodec tcodec;
  late CodecContainer container;
  late ECodec ecodec;

  /* ctor */
  TaudioCodec(this.ecodec, this.tcodec, this.container);
}

class PCM_RAW16 extends TaudioCodec {
  String get type => '?';
  int sampleRate = 44100;
  /* ctor */
  PCM_RAW16({this.sampleRate = 44100})
    : super(ECodec.PCM_RAW16, PCM(), RAW16()) {}
}

class PCM_RAW32 extends TaudioCodec {
  String get type => '?';
  int sampleRate = 44100;
  /* ctor */
  PCM_RAW32({this.sampleRate = 44100})
    : super(ECodec.PCM_RAW32, PCM(), RAW32()) {}
}

class PCM_WAV extends TaudioCodec {
  String get type => '?';
  int sampleRate = 44100;
  /* ctor */
  PCM_WAV({this.sampleRate = 44100}) : super(ECodec.PCM_WAV, PCM(), WAV()) {}
}

class AAC_MP4 extends TaudioCodec {
  String get type => '?';
  /* ctor */
  AAC_MP4() : super(ECodec.AAC_MP4, AAC(), MP4()) {}
}

class AAC_ADTS extends TaudioCodec {
  String get type => '?';
  /* ctor */
  AAC_ADTS() : super(ECodec.AAC_ADTS, AAC(), ADTS()) {}
}

class AAC_3GP extends TaudioCodec {
  String get type => '?';
  /* ctor */
  AAC_3GP() : super(ECodec.AAC_3GP, AAC(), C3GP()) {}
}

class ALAC_MP4 extends TaudioCodec {
  String get type => '?';
  /* ctor */
  ALAC_MP4() : super(ECodec.ALAC_MP4, ALAC(), MP4()) {}
}

class ALAC_MOV extends TaudioCodec {
  String get type => '?';
  /* ctor */
  ALAC_MOV() : super(ECodec.ALAC_MOV, ALAC(), MOV()) {}
}

class AMR_3GP extends TaudioCodec {
  String get type => '?';
  /* ctor */
  AMR_3GP() : super(ECodec.AMR_3GP, AMR(), C3GP()) {}
}

class FLAC_MP4 extends TaudioCodec {
  String get type => '?';
  /* ctor */
  FLAC_MP4() : super(ECodec.FLAC_MP4, FLAC(), MP4()) {}
}

class FLAC_OGG extends TaudioCodec {
  String get type => '?';
  /* ctor */
  FLAC_OGG() : super(ECodec.FLAC_OGG, FLAC(), OGG()) {}
}

class FLAC_FLAC extends TaudioCodec {
  String get type => '?';
  /* ctor */
  FLAC_FLAC() : super(ECodec.FLAC_FLAC, FLAC(), CFLAC()) {}
}

class G711_RTP extends TaudioCodec {
  String get type => '?';
  /* ctor */
  G711_RTP() : super(ECodec.G711_RTP, G711(), RTP()) {}
}

class G711_WebRTC extends TaudioCodec {
  String get type => '?';
  /* ctor */
  G711_WebRTC() : super(ECodec.G711_WebRTC, G711(), WebRTC()) {}
}

class G722_RTP extends TaudioCodec {
  String get type => '?';
  /* ctor */
  G722_RTP() : super(ECodec.G722_RTP, G722(), RTP()) {}
}

class G722_WebRTC extends TaudioCodec {
  String get type => '?';
  /* ctor */
  G722_WebRTC() : super(ECodec.G722_WebRTC, G722(), WebRTC()) {}
}

class MP3_MP4 extends TaudioCodec {
  String get type => '?';
  /* ctor */
  MP3_MP4() : super(ECodec.MP3_MP4, MP3(), MP4()) {}
}

class MP3_ADTS extends TaudioCodec {
  String get type => '?';
  /* ctor */
  MP3_ADTS() : super(ECodec.MP3_ADTS, MP3(), ADTS()) {}
}

class MP3_MPEG
    extends
        TaudioCodec // MP3
        {
  String get type => '?';
  /* ctor */
  MP3_MPEG() : super(ECodec.MP3_MPEG, MP3(), MPEG()) {}
}

class MP3_3GP extends TaudioCodec {
  String get type => '?';
  /* ctor */
  MP3_3GP() : super(ECodec.MP3_3GP, MP3(), C3GP()) {}
}

class OPUS_WebM extends TaudioCodec {
  String get type => '?';
  /* ctor */
  OPUS_WebM() : super(ECodec.OPUS_WebM, OPUS(), WebM()) {}
}

class OPUS_MP4 extends TaudioCodec {
  String get type => '?';
  /* ctor */
  OPUS_MP4() : super(ECodec.OPUS_MP4, OPUS(), MP4()) {}
}

class OPUS_OGG extends TaudioCodec {
  String get type => '?';
  /* ctor */
  OPUS_OGG() : super(ECodec.OPUS_OGG, OPUS(), OGG()) {}
}

class VORBIS_WebM extends TaudioCodec {
  String get type => '?';
  /* ctor */
  VORBIS_WebM() : super(ECodec.VORBIS_WebM, OPUS(), WebM()) {}
}

class VORBIS_OGG extends TaudioCodec {
  String get type => '?';
  /* ctor */
  VORBIS_OGG() : super(ECodec.VORBIS_OGG, OPUS(), OGG()) {}
}
