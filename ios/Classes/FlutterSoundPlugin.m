#import "FlutterSoundPlugin.h"
#import <AVFoundation/AVFoundation.h>

@implementation FlutterSoundPlugin{
  NSURL *audioFileURL;
  AVAudioRecorder *audioRecorder;
  AVAudioPlayer *audioPlayer;
  NSTimer *timer;
}
double subscriptionDuration = 0.01;
FlutterMethodChannel* _channel;

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
  NSLog(@"audioPlayerDidFinishPlaying");
  NSNumber *duration = [NSNumber numberWithDouble:audioPlayer.duration * 1000];
  NSNumber *currentTime = [NSNumber numberWithDouble:audioPlayer.currentTime * 1000];

  NSString* status = [NSString stringWithFormat:@"{\"duration\": \"%@\", \"current_position\": \"%@\"}", [duration stringValue], [currentTime stringValue]];
  /*
  NSDictionary *status = @{
                           @"duration" : [duration stringValue],
                           @"current_position" : [currentTime stringValue],
                           };
  */
  [_channel invokeMethod:@"audioPlayerDidFinishPlaying" arguments:status];

  if (timer != nil) {
    [timer invalidate];
    timer = nil;
  }
}

- (void)updateRecorderProgress:(NSTimer*) timer
{
  NSNumber *currentTime = [NSNumber numberWithDouble:audioRecorder.currentTime * 1000];

  NSString* status = [NSString stringWithFormat:@"{\"current_position\": \"%@\"}", [currentTime stringValue]];
  /*
  NSDictionary *status = @{
                           @"current_position" : [currentTime stringValue],
                           };
  */

  [_channel invokeMethod:@"updateRecorderProgress" arguments:status];
}

- (void)updateProgress:(NSTimer*) timer
{
  NSNumber *duration = [NSNumber numberWithDouble:audioPlayer.duration * 1000];
  NSNumber *currentTime = [NSNumber numberWithDouble:audioPlayer.currentTime * 1000];

  if ([duration intValue] == 0 && timer != nil) {
    [timer invalidate];
    timer = nil;
    return;
  }


  NSString* status = [NSString stringWithFormat:@"{\"duration\": \"%@\", \"current_position\": \"%@\"}", [duration stringValue], [currentTime stringValue]];
  /*
  NSDictionary *status = @{
                           @"duration" : [duration stringValue],
                           @"current_position" : [currentTime stringValue],
                           };
  */

  [_channel invokeMethod:@"updateProgress" arguments:status];
}

- (void)startRecorderTimer
{
  dispatch_async(dispatch_get_main_queue(), ^{
      self->timer = [NSTimer scheduledTimerWithTimeInterval: subscriptionDuration
                                           target:self
                                           selector:@selector(updateRecorderProgress:)
                                           userInfo:nil
                                           repeats:YES];
  });
}

- (void)startTimer
{
  dispatch_async(dispatch_get_main_queue(), ^{
      self->timer = [NSTimer scheduledTimerWithTimeInterval:subscriptionDuration
                                           target:self
                                           selector:@selector(updateProgress:)
                                           userInfo:nil
                                           repeats:YES];
  });
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"flutter_sound"
            binaryMessenger:[registrar messenger]];
  FlutterSoundPlugin* instance = [[FlutterSoundPlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
  _channel = channel;
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  if ([@"getPlatformVersion" isEqualToString:call.method]) {
    result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
  } else if ([@"startRecorder" isEqualToString:call.method]) {
    NSString* path = (NSString*)call.arguments[@"path"];
    [self startRecorder:path result:result];
  } else if ([@"stopRecorder" isEqualToString:call.method]) {
    [self stopRecorder:result];
  } else if ([@"startPlayer" isEqualToString:call.method]) {
      NSString* path = (NSString*)call.arguments[@"path"];
      [self startPlayer:path result:result];
  } else if ([@"stopPlayer" isEqualToString:call.method]) {
    [self stopPlayer:result];
  } else if ([@"pausePlayer" isEqualToString:call.method]) {
    [self pausePlayer:result];
  } else if ([@"resumePlayer" isEqualToString:call.method]) {
    [self resumePlayer:result];
  } else if ([@"seekToPlayer" isEqualToString:call.method]) {
    NSNumber* sec = (NSNumber*)call.arguments[@"sec"];
    [self seekToPlayer:sec result:result];
  } else if ([@"setSubscriptionDuration" isEqualToString:call.method]) {
    NSNumber* sec = (NSNumber*)call.arguments[@"sec"];
    [self setSubscriptionDuration:[sec doubleValue] result:result];
  } else if ([@"setVolume" isEqualToString:call.method]) {
    NSNumber* volume = (NSNumber*)call.arguments[@"volume"];
    [self setVolume:[volume doubleValue] result:result];
  } else {
    result(FlutterMethodNotImplemented);
  }
}

- (void)setSubscriptionDuration:(double)duration result: (FlutterResult)result {
  subscriptionDuration = duration;
  result(@"setSubscriptionDuration");
}

- (void)startRecorder:(NSString*)path result: (FlutterResult)result {
  if ([path class] == [NSNull class]) {
    audioFileURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingString:@"sound.m4a"]];
  } else {
    audioFileURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingString:path]];
  }

  NSDictionary *audioSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [NSNumber numberWithFloat:44100],AVSampleRateKey,
                                 [NSNumber numberWithInt: kAudioFormatAppleLossless],AVFormatIDKey,
                                 [NSNumber numberWithInt: 2],AVNumberOfChannelsKey,
                                 [NSNumber numberWithInt:AVAudioQualityMedium],AVEncoderAudioQualityKey,nil];

  // Setup audio session
  AVAudioSession *session = [AVAudioSession sharedInstance];
  [session setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];

  // set volume default to speaker
  UInt32 doChangeDefaultRoute = 1;
  AudioSessionSetProperty(kAudioSessionProperty_OverrideCategoryDefaultToSpeaker, sizeof(doChangeDefaultRoute), &doChangeDefaultRoute);

  audioRecorder = [[AVAudioRecorder alloc]
                        initWithURL:audioFileURL
                        settings:audioSettings
                        error:nil];

  [audioRecorder setDelegate:self];
  [audioRecorder record];
  [self startRecorderTimer];

  NSString *filePath = self->audioFileURL.absoluteString;
  result(filePath);
}

- (void)stopRecorder:(FlutterResult)result {
  [audioRecorder stop];
  AVAudioSession *audioSession = [AVAudioSession sharedInstance];
  [audioSession setActive:NO error:nil];

  NSString *filePath = audioFileURL.absoluteString;
  result(filePath);
}

- (void)startPlayer:(NSString*)path result: (FlutterResult)result {
  if ([path class] == [NSNull class]) {
    path = @"sound.m4a";
  }

  if ([[path substringToIndex:4] isEqualToString:@"http"]) {
    audioFileURL = [NSURL URLWithString:path];

    NSURLSessionDataTask *downloadTask = [[NSURLSession sharedSession]
        dataTaskWithURL:audioFileURL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            // NSData *data = [NSData dataWithContentsOfURL:audioFileURL];
      if (!self->audioPlayer) {
        self->audioPlayer = [[AVAudioPlayer alloc] initWithData:data error:nil];
        self->audioPlayer.delegate = self;
      }

        // Able to play in silent mode
        [[AVAudioSession sharedInstance]
            setCategory: AVAudioSessionCategoryPlayback
            error: nil];
        // Able to play in background
        [[AVAudioSession sharedInstance] setActive: YES error: nil];
        [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];

        [self->audioPlayer play];
        [self startTimer];
        NSString *filePath = self->audioFileURL.absoluteString;
        result(filePath);
    }];

    [downloadTask resume];
  } else {
    audioFileURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingString:path]];

    if (!audioPlayer) {
      audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:audioFileURL error:nil];
      audioPlayer.delegate = self;
    }

    // Able to play in silent mode
    [[AVAudioSession sharedInstance]
        setCategory: AVAudioSessionCategoryPlayback
        error: nil];

    [audioPlayer play];
    [self startTimer];

    NSString *filePath = audioFileURL.absoluteString;
    result(filePath);
  }
}

- (void)stopPlayer:(FlutterResult)result {
  if (audioPlayer) {
    if (timer != nil) {
        [timer invalidate];
        timer = nil;
    }
    [audioPlayer stop];
    audioPlayer = nil;
    result(@"stop play");
  } else {
    result([FlutterError
        errorWithCode:@"Audio Player"
        message:@"player is not set"
        details:nil]);
  }
}

- (void)pausePlayer:(FlutterResult)result {
  if (audioPlayer && [audioPlayer isPlaying]) {
    [audioPlayer pause];
    if (timer != nil) {
        [timer invalidate];
        timer = nil;
    }
    result(@"pause play");
  } else {
    result([FlutterError
        errorWithCode:@"Audio Player"
        message:@"player is not set"
        details:nil]);
  }
}

- (void)resumePlayer:(FlutterResult)result {
  if (!audioFileURL) {
    result([FlutterError
            errorWithCode:@"Audio Player"
            message:@"fileURL is not defined"
            details:nil]);
    return;
  }

  if (!audioPlayer) {
    result([FlutterError
            errorWithCode:@"Audio Player"
            message:@"player is not set"
            details:nil]);
    return;
  }

  [[AVAudioSession sharedInstance]
    setCategory: AVAudioSessionCategoryPlayback
    error: nil];
  [audioPlayer play];
  [self startTimer];
  NSString *filePath = audioFileURL.absoluteString;
  result(filePath);
}

- (void)seekToPlayer:(nonnull NSNumber*) time result: (FlutterResult)result {
  if (audioPlayer) {
    audioPlayer.currentTime = [time doubleValue];
    result(time);
  } else {
    result([FlutterError
        errorWithCode:@"Audio Player"
        message:@"player is not set"
        details:nil]);
  }
}

- (void)setVolume:(double) volume result: (FlutterResult)result {
    if (audioPlayer) {
        [audioPlayer setVolume: volume];
        result(@"volume set");
    } else {
        result([FlutterError
                errorWithCode:@"Audio Player"
                message:@"player is not set"
                details:nil]);
    }
}

@end
