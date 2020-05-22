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



#import <Flutter/Flutter.h>

@interface Track : NSObject
{
    NSString *path;
    NSString *title;
    NSString *author;
    NSString *albumArtUrl;
    NSString *albumArtAsset;
    FlutterStandardTypedData *dataBuffer;
}

@property(nonatomic, retain) NSString *path;
@property(nonatomic, retain) NSString *title;
@property(nonatomic, retain) NSString *author;
@property(nonatomic, retain) NSString *albumArtUrl;
@property(nonatomic, retain) NSString *albumArtAsset;
@property(nonatomic, retain) NSString *albumArtFile;
@property(nonatomic, retain) FlutterStandardTypedData *dataBuffer;

- (id)initFromJson:(NSString *)jsonString;
- (id)initFromDictionary:(NSDictionary *)jsonData;
- (bool)isUsingPath;

@end
