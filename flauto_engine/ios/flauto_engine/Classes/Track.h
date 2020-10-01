/*
 * Copyright 2018, 2019, 2020 Dooboolab.
 *
 * This file is part of Flutter-Sound.
 *
 * Flutter-Sound is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License version 3 (LGPL-V3), as published by
 * the Free Software Foundation.
 *
 * Flutter-Sound is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with Flutter-Sound.  If not, see <https://www.gnu.org/licenses/>.
 */


@interface FlutterStandardTypedData
{
// TODO
}
@end

@interface Track : NSObject
{
    NSString *path;
    NSString *title;
    NSString *author;
    NSString *albumArtUrl;
    NSString *albumArtAsset;
    FlutterStandardTypedData *dataBuffer;
}

@property(nonatomic, retain) NSString * _Nullable path;
@property(nonatomic, retain) NSString * _Nullable title;
@property(nonatomic, retain) NSString * _Nullable author;
@property(nonatomic, retain) NSString * _Nullable albumArtUrl;
@property(nonatomic, retain) NSString * _Nullable albumArtAsset;
@property(nonatomic, retain) NSString * _Nullable albumArtFile;
@property(nonatomic, retain) FlutterStandardTypedData * _Nullable dataBuffer;

- (_Nullable id)initFromJson:(NSString * _Nullable )jsonString;
- (_Nullable id)initFromDictionary:(NSDictionary * _Nullable )jsonData;
- (bool)isUsingPath;

@end
