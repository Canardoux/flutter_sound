///
class AndroidAudioSource {
  final int _value;
  const AndroidAudioSource._internal(this._value);
  String toString() => 'AndroidAudioSource.$_value';

  ///
  int get value => _value;

  ///
  static const defaultSource = AndroidAudioSource._internal(0);

  ///
  static const mic = AndroidAudioSource._internal(1);

  ///
  static const voiceUplink = AndroidAudioSource._internal(2);

  ///
  static const voiceDownlink = AndroidAudioSource._internal(3);

  ///
  static const camcorder = AndroidAudioSource._internal(4);

  ///
  static const voiceRecognition = AndroidAudioSource._internal(5);

  ///
  static const voiceCommunication = AndroidAudioSource._internal(6);

  ///
  static const remoteSubmix = AndroidAudioSource._internal(7);

  ///
  static const unprocessed = AndroidAudioSource._internal(8);

  ///
  static const radioTuner = AndroidAudioSource._internal(9);

  ///
  static const hotword = AndroidAudioSource._internal(10);
}
