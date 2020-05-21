// Provides additional functionality required when recording
import 'dart:io';

import 'package:path/path.dart';

import '../codec.dart';
import '../sound_recorder.dart';
import '../track.dart';

import '../util/file_util.dart' as fm;
import 'codec_conversions.dart';

/// a track.
class RecordingTrack {
  ///
  Track track;

  /// The codec that we will use when asking the OS to
  /// record.
  /// The OS doesn't support all codec so we sometimes have
  /// to record in some native codec and then remux the
  /// recording to the codec required by the Track.
  Codec nativeCodec;

  /// The path we will be recording to.
  /// This is often the same as [track.file] unless
  /// we need to record to a different codec and then remux
  /// the file after recording finishes.
  String recordingPath;

  /// Create a [RecordingTrack] fro a [Track].
  ///
  /// The recording track causes recording to use a native codec
  /// if the requested codec is not supported.
  ///
  /// When [recode] is called the recording is transcoded to the
  /// originally requested codec. If the requested codec was
  /// supported by the OS then remix just returns.
  ///
  RecordingTrack(this.track) {
    assert(track.isFile);
    // If we want to record OGG/OPUS on iOS, we record with CAF/OPUS and we remux the CAF file format to a regular OGG/OPUS.
    // We use FFmpeg for that task.
    // The remux occurs when we call stopRecorder
    if ((Platform.isIOS && (track.codec == Codec.opusOGG))) {
      nativeCodec = Codec.cafOpus;

      /// temp file to record CAF/OPUS file to
      recordingPath = fm.FileUtil().tempFile(suffix: '.caf');
    } else {
      nativeCodec = track.codec;
      recordingPath = track.path;
    }

    if (fm.FileUtil().exists(recordingPath)) {
      fm.FileUtil().truncate(recordingPath);
    }
  }

  /// Used by the [SoundRecorder] to update the [Track]'s duration
  /// as the track is recorded into.
  //ignore: avoid_setters_without_getters
  set duration(Duration duration) {
    setTrackDuration(track, duration);
  }

  /// If the requested coded wasn't supported by the OS then we
  /// record in a native codec and this call translates from
  /// the native codec to the requested codec.
  ///
  void recode() {
    if (track.codec == nativeCodec) {
      // no recode required.
    } else if (track.codec == Codec.opusOGG && nativeCodec == Codec.cafOpus) {
      /// currently only support one transcription.
      /// TODO: expand recording here to support a wider variety
      /// of codecs. We can support anything that the ffmpeg library
      /// supports.
      CodecConversions.cafOpusToOpus(recordingPath, track.path);
    } else {
      // we should never get here as the call to start recording should
      // have failed first.
      throw CodecNotSupportedException(
          'The recoding of ${track.codec} to $nativeCodec is unsupported.');
    }
  }

  /// Check that the target recording path is valid
  void validatePath() {
    /// the directory where we are recording to MUST exist.
    if (!fm.FileUtil().directoryExists(dirname(track.path))) {
      throw DirectoryNotFoundException(
          'The directory ${dirname(track.path)} must exists');
    }
  }

  /// Release all system resources for the track.
  void release() {
    if (track != null) {
      trackRelease(track);
    }
  }
}
