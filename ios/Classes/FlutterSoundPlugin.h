#import <Flutter/Flutter.h>
#import <AVFoundation/AVFoundation.h>

@interface FlutterSoundPlugin : NSObject<FlutterPlugin, AVAudioPlayerDelegate>
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player
        successfully:(BOOL)flag;
- (void)updateProgress:(NSTimer*) timer;
- (void)startTimer;
@end
