class AndroidEncoder {
  final _value;
  const AndroidEncoder._internal(this._value);
  toString() => 'AndroidEncoder.$_value';
  int get value => _value;

  static const DEFAULT = const AndroidEncoder._internal(0);
  /// AMR (Narrowband) audio codec
  static const AMR_NB = const AndroidEncoder._internal(1);
  /// AMR (Wideband) audio codec
  static const AMR_WB = const AndroidEncoder._internal(2);
  /// AAC Low Complexity (AAC-LC) audio codec
  static const AAC = const AndroidEncoder._internal(3);
  /// High Efficiency AAC (HE-AAC) audio codec
  static const HE_AAC = const AndroidEncoder._internal(4);
  /// Enhanced Low Delay AAC (AAC-ELD) audio codec
  static const AAC_ELD = const AndroidEncoder._internal(5);
  /// Enhanced Low Delay AAC (AAC-ELD) audio codec
  static const VORBIS = const AndroidEncoder._internal(6);
}