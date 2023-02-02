import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_sound_platform_interface/method_channel_flutter_sound_player.dart';
import 'package:rxdart/rxdart.dart';

class DarwinEqualizerBand {
  final _platform = _DarwinPlatform();

  /// A zero-based index of the position of this band within its [DarwinEqualizer].
  final int index;

  /// The center frequency of this band in hertz.
  final double centerFrequency;
  final _gainSubject = BehaviorSubject<double>();

  DarwinEqualizerBand._({
    required this.index,
    required this.centerFrequency,
    required double gain,
  }) {
    _gainSubject.add(gain);
  }

  @override
  String toString() {
    return 'DarwinEqualizerBand(index: $index, centerFrequency: $centerFrequency, gain: $gain)';
  }

  /// The gain for this band in decibels.
  double get gain => _gainSubject.value;

  /// A stream of the current gain for this band in decibels.
  Stream<double> get gainStream => _gainSubject.stream;

  /// Sets the gain for this band in decibels.
  Future<void> setGain(double gain) async {
    _gainSubject.add(gain);
    await _platform.darwinEqualizerBandSetGain(DarwinEqualizerBandSetGainRequest(bandIndex: index, gain: gain));
  }

  /// Restores the gain after reactivating.
  Future<void> _restore() async {
    debugPrint('Restore bands: $index, $gain');
    await _platform.darwinEqualizerBandSetGain(DarwinEqualizerBandSetGainRequest(bandIndex: index, gain: gain));
  }

  static DarwinEqualizerBand _fromMessage(DarwinEqualizerBandMessage message) => DarwinEqualizerBand._(
        index: message.index,
        centerFrequency: message.centerFrequency,
        gain: message.gain,
      );
}

/// The parameter values of an [DarwinEqualizer].
class DarwinEqualizerParameters {
  /// The minimum gain value supported by the equalizer.
  final double minDecibels;

  /// The maximum gain value supported by the equalizer.
  final double maxDecibels;

  /// The frequency bands of the equalizer.
  final List<DarwinEqualizerBand> bands;

  DarwinEqualizerParameters({
    required this.minDecibels,
    required this.maxDecibels,
    required this.bands,
  });

  @override
  String toString() {
    return 'DarwinEqualizerParameters(minDecibels: $minDecibels, maxDecibels: $maxDecibels, bands: $bands)';
  }

  /// Restore platform state after reactivating.
  Future<void> _restore() async {
    debugPrint('Restore bands: $bands\n');
    for (var band in bands) {
      await band._restore();
    }
  }

  static DarwinEqualizerParameters _fromMessage(DarwinEqualizerParametersMessage message) => DarwinEqualizerParameters(
        minDecibels: message.minDecibels,
        maxDecibels: message.maxDecibels,
        bands: message.bands.map((bandMessage) => DarwinEqualizerBand._fromMessage(bandMessage)).toList(),
      );
}

class _DarwinPlatform extends DarwinPlatform {
  _DarwinPlatform();
  MethodChannelFlutterSoundPlayer get channel => MethodChannelFlutterSoundPlayer();

  static const MethodChannel _channel = MethodChannel('com.dooboolab.flutter_sound_player');

  // Set Darwin Equalizer Band Gain
  @override
  Future<int> darwinEqualizerBandSetGain(DarwinEqualizerBandSetGainRequest request) async {
    // debugPrint('darwinEqualizerBandSetGain: ${request.toMap()}');
    return await _channel.invokeMethod('darwinEqualizerBandSetGain', request.toMap());
  }

  /// Set Darwin Equalizer Enabled
  @override
  Future<int> enableEqualizer(AudioEffectSetEnabledRequest request) async {
    // debugPrint('enableEqualizer: ${request.toMap()}');
    return await _channel.invokeMethod('enableEqualizer', request.toMap());
  }

  // /// Init Darwin Equalizer
  // @override
  // Future<InitDarwinEqualizerResponse> init(InitDarwinEqualizer request) async {
  //   return InitDarwinEqualizerResponse.fromMap(
  //       (await Equalizer.methodChannel.invokeMethod<Map<dynamic, dynamic>>('init', request.toMap()))!);
  // }
}

abstract class DarwinAudioEffect {
  final _enabledSubject = BehaviorSubject.seeded(false);
  // FlutterSoundPlayer? _player;
  DarwinAudioEffect();

  Future<void> activate() async {}

  bool get enabled => _enabledSubject.value;
  final _DarwinPlatform _platform = _DarwinPlatform();

  /// A stream of the current [enabled] value.
  Stream<bool> get enabledStream => _enabledSubject.stream;
  DarwinEqualizerParameters? _parameters;

  String get _type;

  /// Set the [enabled] status of this audio effect.
  Future<void> setEnabled(bool enabled) async {
    _enabledSubject.add(enabled);
    await _platform.enableEqualizer(AudioEffectSetEnabledRequest(type: _type, enabled: enabled));
  }
}

class DarwinEqualizer extends DarwinAudioEffect {
  final DarwinEqualizerParametersMessage _darwinMessageParameters;
  final Completer<DarwinEqualizerParameters> _parametersCompleter = Completer<DarwinEqualizerParameters>();

  DarwinEqualizer({required DarwinEqualizerParametersMessage darwinMessageParameters})
      : _darwinMessageParameters = darwinMessageParameters;

  @override
  String get _type => 'DarwinEqualizer';

  /// The parameter values of this equalizer.
  Future<DarwinEqualizerParameters> get parameters => _parametersCompleter.future;

  @override
  Future<void> activate() async {
    await super.activate();
    if (_parametersCompleter.isCompleted) {
      await (await parameters)._restore();
      return;
    }

    _parameters = DarwinEqualizerParameters._fromMessage(_darwinMessageParameters);
    debugPrint('Paramaters: ${_parameters.toString()}');
    _parametersCompleter.complete(_parameters);
  }
}
