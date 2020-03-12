#import <Flutter/Flutter.h>

@interface Track : NSObject {
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
@property(nonatomic, retain) FlutterStandardTypedData *dataBuffer;

- (id) initFromJson: (NSString*) jsonString;
- (id) initFromDictionary: (NSDictionary*) jsonData;
- (bool) isUsingPath;

@end
