#import "FlutterSoundPlugin.h"
#import <AVFoundation/AVFoundation.h>

@implementation FlutterSoundPlugin{
  NSURL *audioFileURL;
  AVAudioRecorder *audioRecorder;
  AVAudioPlayer *audioPlayer;
  NSTimer *timer;
  NSTimer *dbPeakTimer;
}
double subscriptionDuration = 0.01;
double dbPeakInterval = 0.8;
bool shouldProcessDbLevel = false;
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

  [self stopTimer];
}

- (void) stopTimer{
    if (timer != nil) {
        [timer invalidate];
        timer = nil;
    }
}

- (void)updateRecorderProgress:(NSTimer*) timer
{
  NSNumber *currentTime = [NSNumber numberWithDouble:audioRecorder.currentTime * 1000];
    [audioRecorder updateMeters];

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
    [self stopTimer];
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

- (void)updateDbPeakProgress:(NSTimer*) dbPeakTimer
{
      NSNumber *normalizedPeakLevel = [NSNumber numberWithDouble:MIN(pow(10.0, [audioRecorder peakPowerForChannel:0] / 20.0) * 160.0, 160.0)];
      [_channel invokeMethod:@"updateDbPeakProgress" arguments:normalizedPeakLevel];
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

- (void)startDbTimer
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self->dbPeakTimer = [NSTimer scheduledTimerWithTimeInterval:dbPeakInterval
                                                       target:self
                                                     selector:@selector(updateDbPeakProgress:)
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
  if ([@"startRecorder" isEqualToString:call.method]) {
    NSString* path = (NSString*)call.arguments[@"path"];
    NSNumber* sampleRate = (NSNumber*)call.arguments[@"sampleRate"];
    NSNumber* numChannels = (NSNumber*)call.arguments[@"numChannels"];
    NSNumber* iosQuality = (NSNumber*)call.arguments[@"iosQuality"];
    NSNumber* bitRate = (NSNumber*)call.arguments[@"bitRate"];
      [self startRecorder:path:numChannels:sampleRate:iosQuality:bitRate result:result];
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
  }
  else if ([@"setDbPeakLevelUpdate" isEqualToString:call.method]) {
      NSNumber* intervalInSecs = (NSNumber*)call.arguments[@"intervalInSecs"];
      [self setDbPeakLevelUpdate:[intervalInSecs doubleValue] result:result];
  }
  else if ([@"setDbLevelEnabled" isEqualToString:call.method]) {
      BOOL enabled = [call.arguments[@"enabled"] boolValue];
      [self setDbLevelEnabled:enabled result:result];
  }
  else {
    result(FlutterMethodNotImplemented);
  }
}

- (void)setSubscriptionDuration:(double)duration result: (FlutterResult)result {
  subscriptionDuration = duration;
  result(@"setSubscriptionDuration");
}

- (void)setDbPeakLevelUpdate:(double)intervalInSecs result: (FlutterResult)result {
    dbPeakInterval = intervalInSecs;
    result(@"setDbPeakLevelUpdate");
}

- (void)setDbLevelEnabled:(BOOL)enabled result: (FlutterResult)result {
    shouldProcessDbLevel = enabled == YES;
    result(@"setDbLevelEnabled");
}

- (void)startRecorder :(NSString*)path :(NSNumber*)numChannels :(NSNumber*)sampleRate :(NSNumber*)iosQuality :(NSNumber*)bitRate result: (FlutterResult)result {
  if ([path class] == [NSNull class]) {
    audioFileURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingString:@"sound.m4a"]];
  } else {
    audioFileURL = [NSURL fileURLWithPath:path];
  }

  NSMutableDictionary *audioSettings = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                 [NSNumber numberWithFloat:[sampleRate doubleValue]],AVSampleRateKey,
                                 [NSNumber numberWithInt: kAudioFormatMPEG4AAC],AVFormatIDKey,
                                 [NSNumber numberWithInt: [numChannels intValue]],AVNumberOfChannelsKey,
                                 [NSNumber numberWithInt: [iosQuality intValue]],AVEncoderAudioQualityKey,nil];
    
    // If bitrate is defined, the use it, otherwise use the OS default
    if(![bitRate isEqual:[NSNull null]]) {
        [audioSettings setValue:[NSNumber numberWithInt: [bitRate intValue]]
                    forKey:AVEncoderBitRateKey];
    }

  // Setup audio session
  AVAudioSession *session = [AVAudioSession sharedInstance];
  [session setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];

  // set volume default to speaker
  UInt32 doChangeDefaultRoute = 1;
  AudioSessionSetProperty(kAudioSessionProperty_OverrideCategoryDefaultToSpeaker, sizeof(doChangeDefaultRoute), &doChangeDefaultRoute);
  
  // set up for bluetooth microphone input
  UInt32 allowBluetoothInput = 1;
  AudioSessionSetProperty (kAudioSessionProperty_OverrideCategoryEnableBluetoothInput,sizeof (allowBluetoothInput),&allowBluetoothInput);
 
  audioRecorder = [[AVAudioRecorder alloc]
                        initWithURL:audioFileURL
                        settings:audioSettings
                        error:nil];

  [audioRecorder setDelegate:self];
  [audioRecorder record];
  [self startRecorderTimer];

  [audioRecorder setMeteringEnabled:shouldProcessDbLevel];
  if(shouldProcessDbLevel == true) {
        [self startDbTimer];
  }

  NSString *filePath = self->audioFileURL.absoluteString;
  result(filePath);
}

- (void)stopRecorder:(FlutterResult)result {
  [audioRecorder stop];

  // Stop Db Timer
  [dbPeakTimer invalidate];
  dbPeakTimer = nil;
  [self stopTimer];
    
  AVAudioSession *audioSession = [AVAudioSession sharedInstance];
  [audioSession setActive:NO error:nil];

  NSString *filePath = audioFileURL.absoluteString;
  result(filePath);
}

- (void)startPlayer:(NSString*)path result: (FlutterResult)result {
  bool isRemote = false;
  if ([path class] == [NSNull class]) {
    audioFileURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingString:@"sound.m4a"]];
  } else {
    NSURL *remoteUrl = [NSURL URLWithString:path];
    if(remoteUrl && remoteUrl.scheme && remoteUrl.host){
        audioFileURL = remoteUrl;
        isRemote = true;
    } else {
        audioFileURL = [NSURL fileURLWithPath:path];
    }
  }

  if (isRemote) {
    NSURLSessionDataTask *downloadTask = [[NSURLSession sharedSession]
        dataTaskWithURL:audioFileURL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            // NSData *data = [NSData dataWithContentsOfURL:audioFileURL];
            
        // We must create a new Audio Player instance to be able to play a different Url
        self->audioPlayer = [[AVAudioPlayer alloc] initWithData:data error:nil];
        self->audioPlayer.delegate = self;

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
    // if (!audioPlayer) { // Fix sound distoring when playing recorded audio again.
      audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:audioFileURL error:nil];
      audioPlayer.delegate = self;
    // }

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
      audioPlayer.currentTime = [time doubleValue] / 1000;
      [self updateProgress:nil];
      result([time stringValue]);
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
