class IosQuality {
  final _value;
  const IosQuality._internal(this._value);
  toString() => 'IOSQuality.$_value';
  int get value => _value;

  static const MIN = const IosQuality._internal(0);
  static const LOW = const IosQuality._internal(0x20);
  static const MEDIUM = const IosQuality._internal(0x40);
  static const HIGH = const IosQuality._internal(0x60);
  static const MAX = const IosQuality._internal(0x7F);
}