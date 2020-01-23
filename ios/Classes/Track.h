#import <Flutter/Flutter.h>

@interface Track : NSObject {
    NSString *path;
    NSString *title;
    NSString *author;
    NSString *albumArt;
    FlutterStandardTypedData *dataBuffer;
}

@property(nonatomic, retain) NSString *path;
@property(nonatomic, retain) NSString *title;
@property(nonatomic, retain) NSString *author;
@property(nonatomic, retain) NSString *albumArt;
@property(nonatomic, retain) FlutterStandardTypedData *dataBuffer;

- (id) initFromJson: (NSString*) jsonString;
- (id) initFromDictionary: (NSDictionary*) jsonData;
- (bool) isUsingPath;

@end
