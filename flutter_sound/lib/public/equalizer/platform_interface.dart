/// Information about an audio effect to be communicated with the platform
/// implementation.
abstract class AudioEffectMessage {
  final bool enabled;

  AudioEffectMessage({required this.enabled});

  Map<dynamic, dynamic> toMap();
}

/// Information communicated to the platform implementation when setting the
/// gain for an equalizer band.
class AndroidEqualizerBandSetGainRequest {
  final int bandIndex;
  final double gain;

  AndroidEqualizerBandSetGainRequest({
    required this.bandIndex,
    required this.gain,
  });

  Map<dynamic, dynamic> toMap() => <dynamic, dynamic>{
        'bandIndex': bandIndex,
        'gain': gain,
      };
}

/// Information about an equalizer band to be communicated with the platform
/// implementation.
class AndroidEqualizerBandMessage {
  /// A zero-based index of the position of this band within its [AndroidEqualizer].
  final int index;

  /// The lower frequency of this band in hertz.
  final double lowerFrequency;

  /// The upper frequency of this band in hertz.
  final double upperFrequency;

  /// The center frequency of this band in hertz.
  final double centerFrequency;

  /// The gain for this band in decibels.
  final double gain;

  AndroidEqualizerBandMessage({
    required this.index,
    required this.lowerFrequency,
    required this.upperFrequency,
    required this.centerFrequency,
    required this.gain,
  });

  Map<dynamic, dynamic> toMap() => <dynamic, dynamic>{
        'index': index,
        'lowerFrequency': lowerFrequency,
        'upperFrequency': upperFrequency,
        'centerFrequency': centerFrequency,
        'gain': gain,
      };

  static AndroidEqualizerBandMessage fromMap(Map<dynamic, dynamic> map) => AndroidEqualizerBandMessage(
        index: map['index'] as int,
        lowerFrequency: map['lowerFrequency'] as double,
        upperFrequency: map['upperFrequency'] as double,
        centerFrequency: map['centerFrequency'] as double,
        gain: map['gain'] as double,
      );
}

/// Information about the equalizer parameters to be communicated with the
/// platform implementation.
class AndroidEqualizerParametersMessage {
  final double minDecibels;
  final double maxDecibels;
  final List<AndroidEqualizerBandMessage> bands;

  AndroidEqualizerParametersMessage({
    required this.minDecibels,
    required this.maxDecibels,
    required this.bands,
  });

  Map<dynamic, dynamic> toMap() => <dynamic, dynamic>{
        'minDecibels': minDecibels,
        'maxDecibels': maxDecibels,
        'bands': bands.map((band) => band.toMap()).toList(),
      };

  static AndroidEqualizerParametersMessage fromMap(Map<dynamic, dynamic> map) => AndroidEqualizerParametersMessage(
        minDecibels: map['minDecibels'] as double,
        maxDecibels: map['maxDecibels'] as double,
        bands: (map['bands'] as List<dynamic>)
            .map((dynamic bandMap) => AndroidEqualizerBandMessage.fromMap(bandMap as Map<dynamic, dynamic>))
            .toList(),
      );
}

/// Information about the equalizer to be communicated with the platform
/// implementation.
class AndroidEqualizerMessage extends AudioEffectMessage {
  final AndroidEqualizerParametersMessage? parameters;

  AndroidEqualizerMessage({
    required bool enabled,
    required this.parameters,
  }) : super(enabled: enabled);

  @override
  Map<dynamic, dynamic> toMap() => <dynamic, dynamic>{
        'type': 'AndroidEqualizer',
        'enabled': enabled,
        'parameters': parameters?.toMap(),
      };
}

/// Information about the loudness enhancer to be communicated with the platform
abstract class AndroidPlatform {
  AndroidPlatform();

  /// Changes the enabled status of an audio effect.
  Future<AudioEffectSetEnabledResponse> audioEffectSetEnabled(AudioEffectSetEnabledRequest request) {
    throw UnimplementedError("audioEffectSetEnabled() has not been implemented.");
  }

  /// Sets the target gain on the Android loudness enhancer.
  Future<AndroidLoudnessEnhancerSetTargetGainResponse> androidLoudnessEnhancerSetTargetGain(
      AndroidLoudnessEnhancerSetTargetGainRequest request) {
    throw UnimplementedError("androidLoudnessEnhancerSetTargetGain() has not been implemented.");
  }

  /// Gets the Android equalizer parameters.
  Future<AndroidEqualizerGetParametersResponse> androidEqualizerGetParameters(
      AndroidEqualizerGetParametersRequest request) {
    throw UnimplementedError("androidEqualizerGetParameters() has not been implemented.");
  }

  /// Sets the gain for an Android equalizer band.
  Future<AndroidEqualizerBandSetGainResponse> androidEqualizerBandSetGain(AndroidEqualizerBandSetGainRequest request) {
    throw UnimplementedError("androidEqualizerBandSetGain() has not been implemented.");
  }
}

/// Information communicated to the platform implementation when setting the
/// enabled status of an audio effect.
class AudioEffectSetEnabledRequest {
  final String type;
  final bool enabled;

  AudioEffectSetEnabledRequest({
    required this.type,
    required this.enabled,
  });

  Map<dynamic, dynamic> toMap() => <dynamic, dynamic>{
        'type': type,
        'enabled': enabled,
      };
}

/// Information returned by the platform implementation after setting the
/// enabled status of an audio effect.
class AudioEffectSetEnabledResponse {
  static AudioEffectSetEnabledResponse fromMap(Map<dynamic, dynamic> map) => AudioEffectSetEnabledResponse();
}

/// Information communicated to the platform implementation when setting the
/// target gain on the loudness enhancer audio effect.
class AndroidLoudnessEnhancerSetTargetGainRequest {
  /// The target gain in decibels.
  final double targetGain;

  AndroidLoudnessEnhancerSetTargetGainRequest({
    required this.targetGain,
  });

  Map<dynamic, dynamic> toMap() => <dynamic, dynamic>{
        'targetGain': targetGain,
      };
}

/// Information returned by the platform implementation after setting the target
/// gain on the loudness enhancer audio effect.
class AndroidLoudnessEnhancerSetTargetGainResponse {
  static AndroidLoudnessEnhancerSetTargetGainResponse fromMap(Map<dynamic, dynamic> map) =>
      AndroidLoudnessEnhancerSetTargetGainResponse();
}

/// Information communicated to the platform implementation when requesting the
/// equalizer parameters.
class AndroidEqualizerGetParametersRequest {
  AndroidEqualizerGetParametersRequest();

  Map<dynamic, dynamic> toMap() => <dynamic, dynamic>{};
}

/// Information communicated to the platform implementation after requesting the
/// equalizer parameters.
class AndroidEqualizerGetParametersResponse {
  final AndroidEqualizerParametersMessage parameters;

  AndroidEqualizerGetParametersResponse({required this.parameters});

  static AndroidEqualizerGetParametersResponse fromMap(Map<dynamic, dynamic> map) =>
      AndroidEqualizerGetParametersResponse(
        parameters: AndroidEqualizerParametersMessage.fromMap(map['parameters'] as Map<dynamic, dynamic>),
      );
  @override
  String toString() {
    return 'AndroidEqualizerGetParametersResponse{parameters: $parameters}';
  }
}

/// Information returned by the platform implementation after setting the gain
/// for an equalizer band.
class AndroidEqualizerBandSetGainResponse {
  AndroidEqualizerBandSetGainResponse();

  static AndroidEqualizerBandSetGainResponse fromMap(Map<dynamic, dynamic> map) =>
      AndroidEqualizerBandSetGainResponse();
}

//======================DARWIN======================

/// Information about the equalizer parameters to be communicated with the
/// platform implementation.
class DarwinEqualizerParametersMessage {
  final double minDecibels;
  final double maxDecibels;
  final List<DarwinEqualizerBandMessage> bands;

  DarwinEqualizerParametersMessage({
    required this.minDecibels,
    required this.maxDecibels,
    required this.bands,
  });

  Map<dynamic, dynamic> toMap() => <dynamic, dynamic>{
        'minDecibels': minDecibels,
        'maxDecibels': maxDecibels,
        'bands': bands.map((band) => band.toMap()).toList(),
      };

  static DarwinEqualizerParametersMessage fromMap(Map<dynamic, dynamic> map) => DarwinEqualizerParametersMessage(
        minDecibels: map['minDecibels'] as double,
        maxDecibels: map['maxDecibels'] as double,
        bands: (map['bands'] as List<dynamic>)
            .map((dynamic bandMap) => DarwinEqualizerBandMessage.fromMap(bandMap as Map<dynamic, dynamic>))
            .toList(),
      );
}

/// Information communicated to the platform implementation when setting the
/// gain for an equalizer band.
class DarwinEqualizerBandSetGainRequest {
  final int bandIndex;
  final double gain;

  DarwinEqualizerBandSetGainRequest({
    required this.bandIndex,
    required this.gain,
  });

  Map<dynamic, dynamic> toMap() => <dynamic, dynamic>{
        'bandIndex': bandIndex,
        'gain': gain,
      };
}

/// Information returned by the platform implementation after setting the gain
/// for an equalizer band.
class DarwinEqualizerBandSetGainResponse {
  DarwinEqualizerBandSetGainResponse();

  static DarwinEqualizerBandSetGainResponse fromMap(Map<dynamic, dynamic> map) => DarwinEqualizerBandSetGainResponse();
}

class DarwinWriteOutputToFileResponse {
  final String outputFileFullPath;

  DarwinWriteOutputToFileResponse({required this.outputFileFullPath});

  static DarwinWriteOutputToFileResponse fromMap(Map<dynamic, dynamic> map) =>
      DarwinWriteOutputToFileResponse(outputFileFullPath: map["outputFileFullPath"] as String);
}

abstract class DarwinPlatform {
  DarwinPlatform();

  /// Changes the enabled status of an audio effect.
  Future<AudioEffectSetEnabledResponse> audioEffectSetEnabled(AudioEffectSetEnabledRequest request) {
    throw UnimplementedError("audioEffectSetEnabled() has not been implemented.");
  }

  Future<DarwinEqualizerBandSetGainResponse> darwinEqualizerBandSetGain(DarwinEqualizerBandSetGainRequest request) {
    throw UnimplementedError("darwinEqualizerBandSetGain() has not been implemented.");
  }
}

/// Information about an equalizer band to be communicated with the platform
/// implementation.
class DarwinEqualizerBandMessage {
  /// A zero-based index of the position of this band within its [DarwinEqualizer].
  final int index;

  /// The center frequency of this band in hertz.
  final double centerFrequency;

  /// The gain for this band in decibels.
  final double gain;

  DarwinEqualizerBandMessage({
    required this.index,
    required this.centerFrequency,
    required this.gain,
  });

  Map<dynamic, dynamic> toMap() => <dynamic, dynamic>{
        'index': index,
        'centerFrequency': centerFrequency,
        'gain': gain,
      };

  static DarwinEqualizerBandMessage fromMap(Map<dynamic, dynamic> map) => DarwinEqualizerBandMessage(
        index: map['index'] as int,
        centerFrequency: map['centerFrequency'] as double,
        gain: map['gain'] as double,
      );
}

class DarwinEqualizerMessage extends AudioEffectMessage {
  final DarwinEqualizerParametersMessage? parameters;

  DarwinEqualizerMessage({
    required bool enabled,
    required this.parameters,
  }) : super(enabled: enabled);

  @override
  Map<dynamic, dynamic> toMap() => <dynamic, dynamic>{
        'type': 'DarwinEqualizer',
        'enabled': enabled,
        'parameters': parameters?.toMap(),
      };
}

class InitDarwinEqualizerRequest {
  // final List<DarwinEqualizerMessage> darwinAudioEffects;
  final List<AudioEffectMessage> darwinAudioEffects;

  InitDarwinEqualizerRequest({
    this.darwinAudioEffects = const [],
  });

  Map<dynamic, dynamic> toMap() => <dynamic, dynamic>{
        'DarwinEqualizer': darwinAudioEffects.map((audioEffect) => audioEffect.toMap()).toList(),
      };
}

class InitDarwinEqualizerResponse {
  final DarwinEqualizerParametersMessage parameters;

  InitDarwinEqualizerResponse({required this.parameters});

  static InitDarwinEqualizerResponse fromMap(Map<dynamic, dynamic> map) => InitDarwinEqualizerResponse(
        parameters: DarwinEqualizerParametersMessage.fromMap(map['parameters'] as Map<dynamic, dynamic>),
      );
}
