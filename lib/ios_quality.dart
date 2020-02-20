/*
 * This is a flutter_sound module.
 * flutter_sound is distributed with a MIT License
 *
 * Copyright (c) 2018 dooboolab
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 */

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
