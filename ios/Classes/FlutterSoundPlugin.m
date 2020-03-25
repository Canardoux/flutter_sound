/*
 * flauto is a flutter_sound module.
 * flutter_sound is distributed with a MIT License
 *
 * Copyright (c) 2018 dooboolab
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 */

 
#import "FlutterSoundPlugin.h"
#import "flauto.h" // Just to register it
#import <AVFoundation/AVFoundation.h>

NSString* defaultExtensions [] =
{
	  @"sound.aac" 	// CODEC_DEFAULT
	  @"sound.aac" 	// CODEC_AAC
	, @"sound.opus"	// CODEC_OPUS
	, @"sound.caf"	// CODEC_CAF_OPUS
	, @"sound.mp3"	// CODEC_MP3
	, @"sound.ogg"	// CODEC_VORBIS
	, @"sound.wav"	// CODE_PCM
};

AudioFormatID formats [] =
{
	  kAudioFormatMPEG4AAC	// CODEC_DEFAULT
        , kAudioFormatMPEG4AAC	// CODEC_AAC
	, 0			// CODEC_OPUS
	, kAudioFormatOpus	// CODEC_CAF_OPUS
	, 0			// CODEC_MP3
	, 0			// CODEC_OGG
	, 0			// CODEC_PCM
};


bool _isIosEncoderSupported [] =
{
    true, // DEFAULT
    true, // AAC
    false, // OGG/OPUS
    true, // CAF/OPUS
    false, // MP3
    false, // OGG/VORBIS
    false, // WAV/PCM
};


bool _isIosDecoderSupported [] =
{
    true, // DEFAULT
    true, // AAC
    false, // OGG/OPUS
    true, // CAF/OPUS
    true, // MP3
    false, // OGG/VORBIS
    true, // WAV/PCM
};

extern t_SET_CATEGORY_DONE setCategoryDone = NOT_SET;
extern t_SET_CATEGORY_DONE setActiveDone = NOT_SET;

extern bool isPaused = false;

// post fix with _FlutterSound to avoid conflicts with common libs including path_provider
NSString* GetDirectoryOfType_FlutterSound(NSSearchPathDirectory dir) {
  NSArray* paths = NSSearchPathForDirectoriesInDomains(dir, NSUserDomainMask, YES);
  return [paths.firstObject stringByAppendingString:@"/"];
}

@implementation FlutterSoundPlugin{
  NSURL *audioFileURL;
  AVAudioRecorder *audioRecorder;
  NSTimer *timer;
  NSTimer *dbPeakTimer;
}
double subscriptionDuration;

double dbPeakInterval = 0.8;
bool shouldProcessDbLevel = false;
FlutterMethodChannel* _channel;

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
  NSLog(@"audioPlayerDidFinishPlaying");
  if ( (setActiveDone != BY_USER) && (setActiveDone != NOT_SET) ) {
      [[AVAudioSession sharedInstance] setActive: NO error: nil];
      setActiveDone = NOT_SET;
  }

  NSNumber *duration = [NSNumber numberWithDouble:audioPlayer.duration * 1000];
  NSNumber *currentTime = [NSNumber numberWithDouble:audioPlayer.currentTime * 1000];

  NSString* status = [NSString stringWithFormat:@"{\"duration\": \"%@\", \"current_position\": \"%@\"}", [duration stringValue], [currentTime stringValue]];
  
  [[ self getChannel] invokeMethod:@"audioPlayerFinishedPlaying" arguments: status];
  isPaused = false;
  [self stopTimer];
}

- (void) stopTimer{
    if (timer != nil) {
        [timer invalidate];
        timer = nil;
    }
}

- (void) stopDbPeakTimer {
        if (self -> dbPeakTimer != nil) {
               [dbPeakTimer invalidate];
               self -> dbPeakTimer = nil;
        }

}

- (void)updateRecorderProgress:(NSTimer*) atimer
{
  assert (timer == timer);
  NSNumber *currentTime = [NSNumber numberWithDouble:audioRecorder.currentTime * 1000];
    [audioRecorder updateMeters];

  NSString* status = [NSString stringWithFormat:@"{\"current_position\": \"%@\"}", [currentTime stringValue]];
  [[ self getChannel] invokeMethod:@"updateRecorderProgress" arguments:status];
}


- (void)updateProgress:(NSTimer*) atimer
{
  assert(timer == atimer);
  NSNumber *duration = [NSNumber numberWithDouble:audioPlayer.duration * 1000];
  NSNumber *currentTime = [NSNumber numberWithDouble:audioPlayer.currentTime * 1000];

  // [LARPOUX] I do not understand why ...
  // if ([duration intValue] == 0 && timer != nil) {
  //   [self stopTimer];
  //   return;
  // }
  
    NSString* status = [NSString stringWithFormat:@"{\"duration\": \"%@\", \"current_position\": \"%@\"}", [duration stringValue], [currentTime stringValue]];
    [[ self getChannel] invokeMethod:@"updateProgress" arguments:status];
//        if (![audioPlayer isPlaying] )
//        {
//                  [self stopPlayer];
//                  return;
//        }

}



- (void)updateDbPeakProgress:(NSTimer*) atimer
{
        assert (dbPeakTimer == atimer);
        NSNumber *normalizedPeakLevel = [NSNumber numberWithDouble:MIN(pow(10.0, [audioRecorder peakPowerForChannel:0] / 20.0) * 160.0, 160.0)];
        [[ self getChannel] invokeMethod:@"updateDbPeakProgress" arguments:normalizedPeakLevel];
}

- (void)startRecorderTimer
{
  [self stopTimer];
  //dispatch_async(dispatch_get_main_queue(), ^{
      self->timer = [NSTimer scheduledTimerWithTimeInterval: subscriptionDuration
                                           target:self
                                           selector:@selector(updateRecorderProgress:)
                                           userInfo:nil
                                           repeats:YES];
  //});
}

- (void)startTimer
{
      [self stopTimer];
      //dispatch_async(dispatch_get_main_queue(), ^{ // ??? Why Async ?  (no async for recorder)
      self -> timer = [NSTimer scheduledTimerWithTimeInterval:subscriptionDuration
                                           target:self
                                           selector:@selector(updateProgress:)
                                           userInfo:nil
                                           repeats:YES];
  //});
}

- (void)startDbTimer
{
    // Stop Db Timer
    [self stopDbPeakTimer];
    //dispatch_async(dispatch_get_main_queue(), ^{
        self -> dbPeakTimer = [NSTimer scheduledTimerWithTimeInterval:dbPeakInterval
                                                       target:self
                                                     selector:@selector(updateDbPeakProgress:)
                                                     userInfo:nil
                                                      repeats:YES];
    //});
}


+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"flutter_sound"
            binaryMessenger:[registrar messenger]];
  FlutterSoundPlugin* instance = [[FlutterSoundPlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
  _channel = channel;
  
  //flutterSoundModule = instance;
  extern void flautoreg(NSObject<FlutterPluginRegistrar>*);
  flautoreg(registrar); // Here, this is not a nice place to do that, but someone has to do it somewhere...

}
-(FlutterMethodChannel*) getChannel {
  return _channel;
}


- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
if ([@"startRecorder" isEqualToString:call.method]) {
    NSString* path = (NSString*)call.arguments[@"path"];
    NSNumber* sampleRateArgs = (NSNumber*)call.arguments[@"sampleRate"];
    NSNumber* numChannelsArgs = (NSNumber*)call.arguments[@"numChannels"];
    NSNumber* iosQuality = (NSNumber*)call.arguments[@"iosQuality"];
    NSNumber* bitRate = (NSNumber*)call.arguments[@"bitRate"];
    NSNumber* codec = (NSNumber*)call.arguments[@"codec"];
    
    t_CODEC coder = CODEC_AAC;
    if (![codec isKindOfClass:[NSNull class]])
    {
            coder = [codec intValue];
    }

    float sampleRate = 44100;
    if (![sampleRateArgs isKindOfClass:[NSNull class]]) {
      sampleRate = [sampleRateArgs integerValue];
    }

    int numChannels = 2;
    if (![numChannelsArgs isKindOfClass:[NSNull class]]) {
      numChannels = [numChannelsArgs integerValue];
    }

    [self startRecorder:path:[NSNumber numberWithInt:numChannels]:[NSNumber numberWithInt:sampleRate]:coder:iosQuality:bitRate result:result];
    
  } else if ([@"initializeMediaPlayer" isEqualToString:call.method]) {
  
  } else if ([@"releaseMediaPlayer" isEqualToString:call.method]) {

  } else if ([@"isEncoderSupported" isEqualToString:call.method]) {
    NSNumber* codec = (NSNumber*)call.arguments[@"codec"];
    [self isEncoderSupported:[codec intValue] result:result];
  } else if ([@"isDecoderSupported" isEqualToString:call.method]) {
     NSNumber* codec = (NSNumber*)call.arguments[@"codec"];
     [self isDecoderSupported:[codec intValue] result:result];
  } else if ([@"stopRecorder" isEqualToString:call.method]) {
    [self stopRecorder: result];
  } else if ([@"startPlayer" isEqualToString:call.method]) {
      NSString* path = (NSString*)call.arguments[@"path"];
      [self startPlayer:path result:result];
  } else if ([@"startPlayerFromBuffer" isEqualToString:call.method]) {
      FlutterStandardTypedData* dataBuffer = (FlutterStandardTypedData*)call.arguments[@"dataBuffer"];
      [self startPlayerFromBuffer:dataBuffer result:result];
  } else if ([@"stopPlayer" isEqualToString:call.method]) {
    [self stopPlayer];
    result(@"stop play");
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
  else if ([@"iosSetCategory" isEqualToString:call.method]) {
      NSString* categ = (NSString*)call.arguments[@"category"];
      NSString* mode = (NSString*)call.arguments[@"mode"];
      NSNumber* options = (NSNumber*)call.arguments[@"options"];
      [self setCategory: categ mode: mode options: [options intValue] result:result];
  }
  else if ([@"setActive" isEqualToString:call.method]) {
    BOOL enabled = [call.arguments[@"enabled"] boolValue];
    [self setActive:enabled result:result];
  }
  
  else {
    result(FlutterMethodNotImplemented);
  }
}

- (t_AUDIO_STATE)audioState
{
        if ( [audioPlayer isPlaying] )
                return IS_PLAYING;
        if (isPaused)
                return IS_PAUSED;
        return IS_PLAYING;
}

- (void)setCategory: (NSString*)categ mode:(NSString*)mode options:(int)options result:(FlutterResult)result {
        // Able to play in silent mode
  BOOL b = [[AVAudioSession sharedInstance]
     setCategory:  categ // AVAudioSessionCategoryPlayback 
     mode: mode
     options: options
     error: nil];
  setCategoryDone = BY_USER;
  setActiveDone = NOT_SET;
  NSNumber* r = [NSNumber numberWithBool: b];
  result(r);
}

- (void)setActive:(BOOL)enabled result:(FlutterResult)result {
  if (enabled) {
        if (setActiveDone != NOT_SET) { // Already activated. Nothing todo;
                setActiveDone = BY_USER;
                result(0);
                return;
        }
        setActiveDone = BY_USER;

  } else {
        if (setActiveDone == NOT_SET) { // Already desactivated
                result(0);
                return;
        }
        setActiveDone = NOT_SET;
  }
  BOOL b = [[AVAudioSession sharedInstance]  setActive:enabled error:nil] ;
  NSNumber* r = [NSNumber numberWithBool: b];
  result(r);
}
  

- (void)isDecoderSupported:(t_CODEC)codec result: (FlutterResult)result {
  NSNumber* b = [NSNumber numberWithBool: _isIosDecoderSupported[codec] ];
  result(b);
}

- (void)isEncoderSupported:(t_CODEC)codec result: (FlutterResult)result {
  NSNumber*  b = [NSNumber numberWithBool: _isIosEncoderSupported[codec] ];
  result(b);
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

- (void)startRecorder
        :(NSString*)path
        :(NSNumber*)numChannels
        :(NSNumber*)sampleRate
        :(t_CODEC) codec
        :(NSNumber*)iosQuality
        :(NSNumber*)bitRate
        result: (FlutterResult)result {
  if ([path class] == [NSNull class]) {
    audioFileURL = [NSURL fileURLWithPath:[GetDirectoryOfType_FlutterSound(NSCachesDirectory) stringByAppendingString:defaultExtensions[codec] ]];
  } else {
    audioFileURL = [NSURL fileURLWithPath: path];
  }
  NSMutableDictionary *audioSettings = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                 [NSNumber numberWithFloat:[sampleRate doubleValue]],AVSampleRateKey,
                                 [NSNumber numberWithInt: formats[codec] ],AVFormatIDKey,
                                 [NSNumber numberWithInt: [numChannels intValue]],AVNumberOfChannelsKey,
                                 [NSNumber numberWithInt: [iosQuality intValue]],AVEncoderAudioQualityKey,
                                 nil];
    
    // If bitrate is defined, the use it, otherwise use the OS default
    if(![bitRate isEqual:[NSNull null]]) {
        [audioSettings setValue:[NSNumber numberWithInt: [bitRate intValue]]
                    forKey:AVEncoderBitRateKey];
    }

  // Setup audio session
  if ((setCategoryDone == NOT_SET) || (setCategoryDone == FOR_PLAYING) ) {
        AVAudioSession *session = [AVAudioSession sharedInstance];
        [session setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
        setCategoryDone = FOR_RECORDING;
  }

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

  NSString *filePath = self->audioFileURL.path;
  result(filePath);
}

- (void)stopRecorder:(FlutterResult)result {
  [audioRecorder stop];

  [self stopDbPeakTimer];
  [self stopTimer];
    
  AVAudioSession *audioSession = [AVAudioSession sharedInstance];

  NSString *filePath = audioFileURL.absoluteString;
  result(filePath);
}

- (void)startPlayer:(NSString*)path result: (FlutterResult)result {
  bool isRemote = false;
  if ([path class] == [NSNull class]) {
    audioFileURL = [NSURL fileURLWithPath:[GetDirectoryOfType_FlutterSound(NSCachesDirectory) stringByAppendingString:@"sound.aac"]];
  } else {
    NSURL *remoteUrl = [NSURL URLWithString:path];
    if(remoteUrl && remoteUrl.scheme && remoteUrl.host){
        audioFileURL = remoteUrl;
        isRemote = true;
    } else {
        audioFileURL = [NSURL URLWithString:path];
    }
  }
  // Able to play in silent mode
  if (setCategoryDone == NOT_SET) {
          [[AVAudioSession sharedInstance]
              setCategory: AVAudioSessionCategoryPlayback
              error: nil];
           setCategoryDone = FOR_PLAYING;
  }
  // Able to play in background
  if (setActiveDone == NOT_SET) {
          [[AVAudioSession sharedInstance] setActive: YES error: nil];
          setActiveDone = FOR_PLAYING;
  }
  [self stopDbPeakTimer]; // This is not be possible. Just in case ...

  isPaused = false;

  if (isRemote) {
    NSURLSessionDataTask *downloadTask = [[NSURLSession sharedSession]
        dataTaskWithURL:audioFileURL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            
        // We must create a new Audio Player instance to be able to play a different Url
        audioPlayer = [[AVAudioPlayer alloc] initWithData:data error:nil];
        audioPlayer.delegate = self;

        [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];

        bool b = [self->audioPlayer play];
        if (!b)
        {
                [self stopPlayer];
                ([FlutterError
                errorWithCode:@"Audio Player"
                message:@"Play failure"
                details:nil]);

        }
    }];

     [self startTimer];
     NSString *filePath = self->audioFileURL.absoluteString;
     result(filePath);
     [downloadTask resume];
  } else {
    // if (!audioPlayer) { // Fix sound distoring when playing recorded audio again.
      audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:audioFileURL error:nil];
      audioPlayer.delegate = self;
    // }
    bool b = [audioPlayer play];
    if (!b)
    {
             [self stopPlayer];
             ([FlutterError
             errorWithCode:@"Audio Player"
             message:@"Play failure"
             details:nil]);
    } else
    {
            [self startTimer];
            NSString *filePath = audioFileURL.absoluteString;
            result(filePath);
    }
  }
}


- (void)startPlayerFromBuffer:(FlutterStandardTypedData*)dataBuffer result: (FlutterResult)result {
  audioPlayer = [[AVAudioPlayer alloc] initWithData: [dataBuffer data] error: nil];
  audioPlayer.delegate = self;
  // Able to play in silent mode
  if (setCategoryDone == NOT_SET) {
          [[AVAudioSession sharedInstance]
              setCategory: AVAudioSessionCategoryPlayback
              error: nil];
           setCategoryDone = FOR_PLAYING;
  }
  // Able to play in background
  if (setActiveDone == NOT_SET) {
          [[AVAudioSession sharedInstance] setActive: YES error: nil];
          setActiveDone = FOR_PLAYING;
  }
  [self stopDbPeakTimer]; // This is not possible, but just in case ...
  isPaused = false;
  bool b = [audioPlayer play];
  if (!b)
  {
           [self stopPlayer];
           ([FlutterError
           errorWithCode:@"Audio Player"
           message:@"Play failure"
           details:nil]);
  } else
  {
        [self startTimer];
        result(@"Playing from buffer");
  }
}



- (void)stopPlayer {
  [self stopTimer];
  isPaused = false;
  [self stopDbPeakTimer]; // Just in case ...
  if (audioPlayer) {
    [audioPlayer stop];
    audioPlayer = nil;
  }
  if ( (setActiveDone != BY_USER) && (setActiveDone != NOT_SET) ) {
      [[AVAudioSession sharedInstance] setActive: NO error: nil];
      setActiveDone = NOT_SET;
  }
}

- (void)pause
{
          [audioPlayer pause];
          isPaused = true;
          if (timer != nil)
          {
              [timer invalidate];
              timer = nil;
          }
          if ( (setActiveDone != BY_USER) && (setActiveDone != NOT_SET) ) {
              [[AVAudioSession sharedInstance] setActive: NO error: nil];
              setActiveDone = NOT_SET;
          }
}

- (bool)resume
{
        isPaused = true;

        bool b = false;
        if ( [audioPlayer isPlaying] )
        {
                printf("audioPlayer is already playing!\n");
        } else
        {
                b = [audioPlayer play];
                if (b)
                {
                        [self startTimer];
                        if (setActiveDone == NOT_SET) {
                                [[AVAudioSession sharedInstance] setActive: YES error: nil];
                                setActiveDone = FOR_PLAYING;
                        }
                } else
                {
                        printf("resume : resume failed!\n");
                }
        }
        return b;
}

- (void)pausePlayer:(FlutterResult)result
{
        if (audioPlayer)
        {
                 if (! [audioPlayer isPlaying] )
                 {
                        isPaused = false;

                         printf("audioPlayer is not playing!\n");
                         result([FlutterError
                                  errorWithCode:@"Audio Player"
                                  message:@"audioPlayer is not playing"
                                  details:nil]);

                 } else
                 {
                        [self pause];
                        result(@"pause play");
                 }
        } else
        {
                printf("resumePlayer : player is not set\n");
                result([FlutterError
                        errorWithCode:@"Audio Player"
                        message:@"player is not set"
                        details:nil]);
        }
}

- (void)resumePlayer:(FlutterResult)result
{
 
   isPaused = false;

   if (!audioPlayer)
   {
            printf("resumePlayer : player is not set\n");
            result([FlutterError
                    errorWithCode:@"Audio Player"
                    message:@"player is not set"
                    details:nil]);
            return;
   }
   if ( [audioPlayer isPlaying] )
   {
           printf("audioPlayer is already playing!\n");
           result([FlutterError
                    errorWithCode:@"Audio Player"
                    message:@"audioPlayer is already playing"
                    details:nil]);

   } else
   {
        [[AVAudioSession sharedInstance]  setActive:YES error:nil] ;
        bool b = [self resume];
        if (b)
        {
                NSString *filePath = audioFileURL.absoluteString;
                result(filePath);
        } else
        {
                result([FlutterError
                         errorWithCode:@"Audio Player"
                         message:@"resume failed"
                         details:nil]);
        }
   }
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
