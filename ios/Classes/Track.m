/*
 * This file is part of Flutter-Sound (Flauto).
 *
 *   Flutter-Sound (Flauto) is free software: you can redistribute it and/or modify
 *   it under the terms of the Lesser GNU General Public License
 *   version 3 (LGPL3) as published by the Free Software Foundation.
 *
 *   Flutter-Sound (Flauto) is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details.
 *
 *   You should have received a copy of the Lesser GNU General Public License
 *   along with Flutter-Sound (Flauto).  If not, see <https://www.gnu.org/licenses/>.
 */

#import <Foundation/Foundation.h>
#import "Track.h"

@implementation Track

@synthesize path;
@synthesize title;
@synthesize author;
@synthesize albumArtUrl;
@synthesize albumArtAsset;
@synthesize dataBuffer;

// Returns true if the audio file is stored as a path represented by a string, false if
// it is stored as a buffer.
-(bool) isUsingPath {
    return [path class] != [NSNull class];
}

-(id) initFromJson:(NSString*) jsonString {
    NSData* jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];

    NSError *error = nil;
    NSDictionary *responseObj = [NSJSONSerialization
                                 JSONObjectWithData:jsonData
                                 options:0
                                 error:&error];

    if(! error) {
        NSString *pathString = [responseObj objectForKey:@"path"];
        path = pathString;

        NSString *titleString = [responseObj objectForKey:@"title"];
        title = titleString;

        NSString *authorString = [responseObj objectForKey:@"author"];
        author = authorString;

        NSString *albumArtUrlString = [responseObj objectForKey:@"albumArtUrl"];
        albumArtUrl = albumArtUrlString;

        NSString *albumArtAssetString = [responseObj objectForKey:@"albumArtAsset"];
        albumArtAsset = albumArtAssetString;

        FlutterStandardTypedData *dataBufferJson = [responseObj objectForKey:@"dataBuffer"];
        dataBuffer = dataBufferJson;
    } else {
        NSLog(@"Error in parsing JSON");
        return nil;
    }

    return self;
}

-(id) initFromDictionary:(NSDictionary*) jsonData {
    NSString *pathString = [jsonData objectForKey:@"path"];
    path = pathString;

    NSString *titleString = [jsonData objectForKey:@"title"];
    title = titleString;

    NSString *authorString = [jsonData objectForKey:@"author"];
    author = authorString;

    NSString *albumArtUrlString = [jsonData objectForKey:@"albumArtUrl"];
    albumArtUrl = albumArtUrlString;

    NSString *albumArtAssetString = [jsonData objectForKey:@"albumArtAsset"];
    albumArtAsset = albumArtAssetString;

    FlutterStandardTypedData *dataBufferJson = [jsonData objectForKey:@"dataBuffer"];
    dataBuffer = dataBufferJson;

    return self;
}

@end
