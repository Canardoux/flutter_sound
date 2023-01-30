import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

import 'equalizer.dart';
import 'platform_interface.dart';

/// A frequency band within an [AndroidEqualizer].
class AndroidEqualizerBand {
  final _platform = _AndroidPlatform();

  /// A zero-based index of the position of this band within its [AndroidEqualizer].
  final int index;

  /// The lower frequency of this band in hertz.
  final double lowerFrequency;

  /// The upper frequency of this band in hertz.
  final double upperFrequency;

  /// The center frequency of this band in hertz.
  final double centerFrequency;
  final _gainSubject = BehaviorSubject<double>();

  AndroidEqualizerBand._({
    required this.index,
    required this.lowerFrequency,
    required this.upperFrequency,
    required this.centerFrequency,
    required double gain,
  }) {
    _gainSubject.add(gain);
  }

  @override
  String toString() {
    return 'AndroidEqualizerBand(index: $index, lowerFrequency: $lowerFrequency, upperFrequency: $upperFrequency, centerFrequency: $centerFrequency, gain: $gain)';
  }

  /// A stream of the current gain for this band in decibels.
  Stream<double> get gainStream => _gainSubject.stream;

  /// The gain for this band in decibels.
  double get gain => _gainSubject.value;

  /// Sets the gain for this band in decibels.
  Future<void> setGain(double gain) async {
    _gainSubject.add(gain);
    await _platform.androidEqualizerBandSetGain(AndroidEqualizerBandSetGainRequest(bandIndex: index, gain: gain));
  }

  /// Restores the gain after reactivating.
  Future<void> _restore() async {
    await _platform.androidEqualizerBandSetGain(AndroidEqualizerBandSetGainRequest(bandIndex: index, gain: gain));
  }

  static AndroidEqualizerBand _fromMessage(AndroidEqualizerBandMessage message) => AndroidEqualizerBand._(
        index: message.index,
        lowerFrequency: message.lowerFrequency,
        upperFrequency: message.upperFrequency,
        centerFrequency: message.centerFrequency,
        gain: message.gain,
      );
}

// The parameter values of an [AndroidEqualizer].
class AndroidEqualizerParameters {
  /// The minimum gain value supported by the equalizer.
  final double minDecibels;

  /// The maximum gain value supported by the equalizer.
  final double maxDecibels;

  /// The frequency bands of the equalizer.
  final List<AndroidEqualizerBand> bands;

  AndroidEqualizerParameters({
    required this.minDecibels,
    required this.maxDecibels,
    required this.bands,
  });

  @override
  String toString() {
    return 'AndroidEqualizerParameters(minDecibels: $minDecibels, maxDecibels: $maxDecibels, bands: ${bands.toString()})';
  }

  /// Restore platform state after reactivating.
  Future<void> _restore() async {
    for (var band in bands) {
      await band._restore();
    }
  }

  static AndroidEqualizerParameters _fromMessage(AndroidEqualizerParametersMessage message) =>
      AndroidEqualizerParameters(
        minDecibels: message.minDecibels,
        maxDecibels: message.maxDecibels,
        bands: message.bands.map((bandMessage) => AndroidEqualizerBand._fromMessage(bandMessage)).toList(),
      );
}

class _AndroidPlatform extends AndroidPlatform {
  _AndroidPlatform();

  /// Get Andorid Equalizer Parameters
  @override
  Future<AndroidEqualizerGetParametersResponse> androidEqualizerGetParameters(
      AndroidEqualizerGetParametersRequest request) async {
    return AndroidEqualizerGetParametersResponse.fromMap((await Equalizer.methodChannel
        .invokeMethod<Map<dynamic, dynamic>>('androidEqualizerGetParameters', request.toMap()))!);
  }

  /// Set Andorid Equalizer Band Gain
  @override
  Future<AndroidEqualizerBandSetGainResponse> androidEqualizerBandSetGain(
      AndroidEqualizerBandSetGainRequest request) async {
    return AndroidEqualizerBandSetGainResponse.fromMap((await Equalizer.methodChannel
        .invokeMethod<Map<dynamic, dynamic>>('androidEqualizerBandSetGain', request.toMap()))!);
  }

  /// Set Andorid Equalizer Enabled
  @override
  Future<AudioEffectSetEnabledResponse> audioEffectSetEnabled(AudioEffectSetEnabledRequest request) async {
    return AudioEffectSetEnabledResponse.fromMap(
        (await Equalizer.methodChannel.invokeMethod<Map<dynamic, dynamic>>('audioEffectSetEnabled', request.toMap()))!);
  }

  /// Set Android Loudness Enhancer Target Gain
  @override
  Future<AndroidLoudnessEnhancerSetTargetGainResponse> androidLoudnessEnhancerSetTargetGain(
      AndroidLoudnessEnhancerSetTargetGainRequest request) async {
    return AndroidLoudnessEnhancerSetTargetGainResponse.fromMap((await Equalizer.methodChannel
        .invokeMethod<Map<dynamic, dynamic>>('androidLoudnessEnhancerSetTargetGain', request.toMap()))!);
  }
}

abstract class AudioEffect {
  final _enabledSubject = BehaviorSubject.seeded(false);
  AudioEffect();

  Future<void> activate() async {}

  bool get enabled => _enabledSubject.value;
  final _AndroidPlatform _platform = _AndroidPlatform();

  /// A stream of the current [enabled] value.
  Stream<bool> get enabledStream => _enabledSubject.stream;
  AndroidEqualizerParameters? _parameters;

  String get _type;

  /// Set the [enabled] status of this audio effect.
  Future<void> setEnabled(bool enabled) async {
    _enabledSubject.add(enabled);
    _platform.audioEffectSetEnabled(AudioEffectSetEnabledRequest(type: _type, enabled: enabled));
  }
}

class AndroidEqualizer extends AudioEffect {
  final Completer<AndroidEqualizerParameters> _parametersCompleter = Completer<AndroidEqualizerParameters>();

  @override
  String get _type => 'AndroidEqualizer';

  /// The parameter values of this equalizer.
  Future<AndroidEqualizerParameters> get parameters => _parametersCompleter.future;

  @override
  Future<void> activate() async {
    await super.activate();
    if (_parametersCompleter.isCompleted) {
      await (await parameters)._restore();
      return;
    }

    final response = await _platform.androidEqualizerGetParameters(AndroidEqualizerGetParametersRequest());
    _parameters = AndroidEqualizerParameters._fromMessage(response.parameters);
    debugPrint(_parameters.toString());
    _parametersCompleter.complete(_parameters);
  }
}
