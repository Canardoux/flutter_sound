@interface Track : NSObject {
    NSString *path;
    NSString *title;
    NSString *author;
    NSString *albumArt;
}

@property(nonatomic, retain) NSString *path;
@property(nonatomic, retain) NSString *title;
@property(nonatomic, retain) NSString *author;
@property(nonatomic, retain) NSString *albumArt;

- (id) initFromJson: (NSString*) jsonString;

@end
