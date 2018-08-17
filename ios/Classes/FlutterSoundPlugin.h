#import <Flutter/Flutter.h>

@interface FlutterSoundPlugin : NSObject<FlutterPlugin, AVAudioPlayerDelegate>
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player
        successfully:(BOOL)flag;
- (void)updateProgress:(NSTimer*) timer;
- (void)startTimer;
@end
