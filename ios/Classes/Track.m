#import <Foundation/Foundation.h>
#import "Track.h"

@implementation Track

@synthesize path;
@synthesize title;
@synthesize author;
@synthesize albumArt;

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
        
        NSString *albumArtString = [responseObj objectForKey:@"albumArt"];
        albumArt = albumArtString;
    } else {
        NSLog(@"Error in parsing JSON");
        return nil;
    }
    
    return self;
}

@end
