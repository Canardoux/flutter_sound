///
class AndroidOutputFormat {
  final int _value;
  const AndroidOutputFormat._internal(this._value);
  String toString() => 'AndroidOutputFormat.$_value';

  ///
  int get value => _value;

  ///
  static const defaultFormat = AndroidOutputFormat._internal(0);

  ///
  static const threeGpp = AndroidOutputFormat._internal(1);

  ///
  static const mpeg_4 = AndroidOutputFormat._internal(2);

  ///
  static const amrNb = AndroidOutputFormat._internal(3);

  ///
  static const amrWb = AndroidOutputFormat._internal(4);

  ///
  static const aacAdts = AndroidOutputFormat._internal(6);

  ///
  static const outputFormatRtpAvp = AndroidOutputFormat._internal(7);

  ///
  static const mpeg_2Ts = AndroidOutputFormat._internal(8);

  ///
  static const webm = AndroidOutputFormat._internal(9);

  ///
  static const ogg = AndroidOutputFormat._internal(11);
}
