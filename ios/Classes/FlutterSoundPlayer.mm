/*
 * Copyright 2018, 2019, 2020 Dooboolab.
 *
 * This file is part of Flutter-Sound.
 *
 * Flutter-Sound is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License version 3 (LGPL-V3), as published by
 * the Free Software Foundation.
 *
 * Flutter-Sound is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with Flutter-Sound.  If not, see <https://www.gnu.org/licenses/>.
 */





#import "FlutterSoundPlayer.h"
#import "TrackPlayer.h"
#import <AVFoundation/AVFoundation.h>
#import "FlautoPlayerManager.h"
#import "PlayerEngine.h"



#define IS_STOPPED 0
#define IS_PLAYING 1
#define IS_PAUSED 2




static bool _isIosDecoderSupported [] =
{
		true, // DEFAULT
		true, // aacADTS
		true, // opusOGG
		true, // opusCAF
		true, // MP3
		false, // vorbisOGG
		false, // pcm16
		true, // pcm16WAV
		true, // pcm16AIFF
		true, // pcm16CAF
		true, // flac
		true, // aacMP4
                false, // amrNB
                false, // amrWB
};

//--------------------------------------------------------------------------------------------------------------------------------------------

@interface AudioPlayerEngine  : NSObject <PlayerInterface>
{
        FlutterSoundPlayer* flutterSoundPlayer; // Owner
}
       - (AudioPlayerEngine*)init: (/*FlutterSoundPlayer**/NSObject*)owner  audioSettings: (NSMutableDictionary*) audioSettings;

@end

@implementation AudioPlayerEngine
{
        AVAudioEngine* engine;
        AVAudioPlayerNode* playerNode;
        AVAudioFormat* playerFormat;
        //AVAudioConverter* converter;
        AVAudioFormat* outputFormat;
        //AVAudioMixerNode* mixerNode;
        //AVAudioInputNode* inputNode;
        AVAudioOutputNode* outputNode;
        NSNumber* sampleRate;
        NSNumber* nbChannels;
        CFTimeInterval mStartPauseTime ; // The time when playback was paused
	CFTimeInterval systemTime ; //The time when  StartPlayer() ;
        double mPauseTime ; // The number of seconds during the total Pause mode


}

       - (AudioPlayerEngine*)init: (/*FlutterSoundPlayer**/NSObject*)owner  audioSettings: (NSMutableDictionary*) audioSettings
       {
                flutterSoundPlayer = (FlutterSoundPlayer*)owner;
                
                // Setup the nodes
                engine = [[AVAudioEngine alloc] init];
                outputNode = [engine outputNode];
                //mixerNode = [engine mainMixerNode];
                //mixerNode = [[AVAudioMixerNode alloc] init];
                //inputNode = [engine inputNode];
                playerNode = [[AVAudioPlayerNode alloc] init];
                
                outputFormat = [outputNode inputFormatForBus: 0];
                //[[AVAudioSession sharedInstance] setCategory:  AVAudioSessionCategoryPlayback error: nil ];
                //[playerNode prepareWithFrameCount: 2048];

                
                // Attach and connect the nodes
                [engine attachNode: playerNode];
                nbChannels = audioSettings [@"numChannels"];
                sampleRate = audioSettings [@"sampleRate"];
 
                [engine connect: playerNode to: outputNode format: outputFormat];
                //[engine connect: inputNode to: outputNode format: [playerNode outputFormatForBus: 0]];
                //[engine attachNode: mixerNode];
                //[engine connect: mixerNode to: outputNode format: nil];
                
                // The Audio buffer
                  //[engine prepare];
                [engine startAndReturnError: nil];
 
   
/*
                    AVAudioConverterInputBlock inputBlock = ^AVAudioBuffer*(AVAudioPacketCount inNumberOfPackets, AVAudioConverterInputStatus* outStatus)
                        {
                                *outStatus = AVAudioConverterInputStatus_HaveData ;
                                //inputStatus =  AVAudioConverterInputStatus_NoDataNow;
                                int ln = [data length];
                                AVAudioPCMBuffer* thePCMInputBuffer =  [[AVAudioPCMBuffer alloc] initWithPCMFormat: playerFormat frameCapacity: [data length]/2];
                                memcpy((unsigned char*)thePCMInputBuffer.int16ChannelData[0], [data bytes], [data length]);
                                return thePCMInputBuffer;
                        };
                                audioInputNode.installTapOnBus(0, bufferSize:frameLength, format: audioInputNode.outputFormatForBus(0), block: {(buffer, time) in
*/
                 

 /*
                for (int i = 0; i < 10; ++i)
                {
                        //memcpy((unsigned char*)thePCMOutputBuffer.floatChannelData[0], [data bytes], 512);
                        memset((unsigned char*)thePCMOutputBuffer.floatChannelData[0],127, 2048);
                        memset((unsigned char*)thePCMOutputBuffer.floatChannelData[1],30, 2048);
                        [playerNode scheduleBuffer: thePCMOutputBuffer completionHandler:
                        ^(void)
                        {
                        }];
                }
 

                //AVAudioPlayerNode* playerNode = [ [AVAudioPlayerNode alloc] init];
                 //AVAudioInputNode* inputNode = [engine inputNode];
                //AVAudioMixerNode* mixerNode = [engine mainMixerNode];
                
                

                /*
                [inputNode installTapOnBus: 0 bufferSize: 2048 format: inputFormat block:^(AVAudioPCMBuffer * _Nonnull buffer, AVAudioTime * _Nonnull when)
                {
                        //inputStatus = AVAudioConverterInputStatus_HaveData ;
                        AVAudioPCMBuffer* convertedBuffer = [[AVAudioPCMBuffer alloc]initWithPCMFormat:recordingFormat frameCapacity: [buffer frameCapacity]];

                        AVAudioConverterInputBlock inputBlock = ^AVAudioBuffer*(AVAudioPacketCount inNumberOfPackets, AVAudioConverterInputStatus *outStatus)
                        {
                                *outStatus = inputStatus;
                                inputStatus =  AVAudioConverterInputStatus_NoDataNow;
                                return buffer;
                        };
                        BOOL r = [converter convertToBuffer: convertedBuffer error: nil withInputFromBlock: inputBlock];
                        int n = [convertedBuffer frameLength];
                        int16_t *const  bb = [convertedBuffer int16ChannelData][0];
                        NSData* b = [[NSData alloc] initWithBytes: bb length: n * 2 ];
                        if (n > 0)
                        {
                                if (fileHandle != nil)
                                {
                                        [fileHandle writeData: b];
                                } else
                                {
                                        //NSDictionary* dic = [[NSMutableDictionary alloc] init];
                                        //[dic setValue: b forKey: @"recordingData"];
                                        NSDictionary* dico = @{ @"slotNo": [NSNumber numberWithInt: [session getSlotNo]], @"recordingData": b,};
                                        [session invokeMethod: @"recordingData" dico: dico];
                                }
                                
                                int16_t* pt = [convertedBuffer int16ChannelData][0];
                                for (int i = 0; i < [buffer frameLength]; ++pt, ++i)
                                {
                                        short curSample = *pt;
                                        if ( curSample > maxAmplitude )
                                        {
                                                maxAmplitude = curSample;
                                        }
                        
                                }
                        }
                }];
                */
                mPauseTime = 0.0; // Total number of seconds in pause mode
		mStartPauseTime = -1; // Not in paused mode
		systemTime = CACurrentMediaTime(); // The time when started
                [playerNode play];

                return [super init];
       }
       
       -(bool) startPlayerFromBuffer: (NSData*) dataBuffer
       {
                 return [self feed: dataBuffer] > 0;
       }
        static int ready = 0;
       
       -(bool)  startPlayerFromURL: (NSURL*) url
       {
                assert(url == nil || url == [NSNull null]);
                ready = 0;
                [playerNode play];
                return true;
       }

       
       -(long)  getDuration
       {
		return [self getPosition]; // It would be better if we add what is in the input buffers and not still played
       }
       
       -(long)  getPosition // TODO
       {
		double time ;
		if (mStartPauseTime >= 0) // In pause mode
			time =   mStartPauseTime - systemTime - mPauseTime ;
		else
			time = CACurrentMediaTime() - systemTime - mPauseTime;
		return (long)(time * 1000);
       }
       
       -(void)  stop // TODO
       {
 
                if (engine != nil)
                {
                        if (playerNode != nil)
                        {
                                [playerNode stop];
                                // Does not work !!! // [engine detachNode:  playerNode];
                                playerNode = nil;
                         }
                        [engine stop];
                        engine = nil;
                }
       }
       
       -(bool)  resume // TODO
       {
		if (mStartPauseTime >= 0)
			mPauseTime += CACurrentMediaTime() - mStartPauseTime;
		mStartPauseTime = -1;

		[playerNode play];
                return true;
       }
        
       -(bool)  pause // TODO
       {
		mStartPauseTime = CACurrentMediaTime();
		[playerNode pause];
                return true;
       }
       
       -(bool)  setVolume: (double) volume // TODO
       {
                return true; // TODO
       }
       
       -(bool)  seek: (double) pos // TODO
       {
                return false;
       }
       
       -(int)  getStatus // TODO
       {
                if (engine == nil)
                        return IS_STOPPED;
                if (mStartPauseTime > 0)
                        return IS_PAUSED;
                if ( [playerNode isPlaying])
                        return IS_PLAYING;
                return IS_PLAYING; // ??? Not sure !!!
       }

        - (int) feed: (NSData*)data
        {
                int frameLength = 2048;
                assert( frameLength >= [data length]);
             //while (true)
                if (ready < 1)
                {
                        int ln = [data length];
                        int frameLn = ln/2; // Two octets for a frame (Monophony, INT Linear 16)
                        
                        playerFormat = [[AVAudioFormat alloc] initWithCommonFormat: AVAudioPCMFormatInt16 sampleRate: sampleRate.doubleValue channels: nbChannels.intValue interleaved: NO];
                        /*----
                        AudioStreamBasicDescription desc;
                        desc.mBitsPerChannel = 16;
                        desc.mBytesPerFrame = frameLength;
                        desc.mBytesPerPacket = frameLength;
                        desc.mChannelsPerFrame = nbChannels.intValue;
                        desc.mFormatFlags = kAudioFormatFlagIsNonInterleaved || kAudioFormatFlagIsSignedInteger || kAppleLosslessFormatFlag_16BitSourceData;
                        desc.mFormatID = kAudioFormatLinearPCM;
                        desc.mFramesPerPacket = 1;
                        desc.mSampleRate = sampleRate.doubleValue;
                        AVAudioFormat* playerFormat3 =  [[AVAudioFormat alloc] initWithStreamDescription: &desc channelLayout: nil];
                        //----*/
                        
                     
                                                  
  
                                AVAudioPCMBuffer* thePCMInputBuffer =  [[AVAudioPCMBuffer alloc] initWithPCMFormat: playerFormat frameCapacity: frameLength];
                                memcpy((unsigned char*)(thePCMInputBuffer.int16ChannelData[0]), [data bytes], ln);
                                //memcpy((unsigned char*)thePCMInputBuffer.int16ChannelData[1], [data bytes], ln);
                                /*
                                unsigned char* pt = (unsigned char*)[data bytes];
                                for (int i = 0; i < frameLn; ++i, pt +=2)
                                {
                                       int v = ((*(pt+1)) << 8) | (*(pt+0)) ;
                                        thePCMInputBuffer.int16ChannelData[0][i] = v;
                                }
                                */
                        thePCMInputBuffer.frameLength = frameLn;
                        static bool hasData = true;
                        hasData = true;
                        AVAudioConverterInputBlock inputBlock = ^AVAudioBuffer*(AVAudioPacketCount inNumberOfPackets, AVAudioConverterInputStatus* outStatus)
                        {
                                *outStatus = hasData ? AVAudioConverterInputStatus_HaveData : AVAudioConverterInputStatus_NoDataNow;
                                hasData = false;
                                //*outStatus =  AVAudioConverterInputStatus_NoDataNow;
                                return thePCMInputBuffer;
                        };
                        
                        AVAudioPCMBuffer* thePCMOutputBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat: outputFormat frameCapacity: frameLength];
                        thePCMOutputBuffer.frameLength = frameLn;

                        AVAudioConverter* converter = [[AVAudioConverter alloc]initFromFormat: playerFormat toFormat: outputFormat];
                        BOOL r = [converter convertToBuffer: thePCMOutputBuffer error: nil withInputFromBlock: inputBlock];
                        //BOOL r = [converter convertToBuffer: thePCMOutputBuffer fromBuffer: thePCMInputBuffer error: nil ];
                        
                        //thePCMOutputBuffer.frameLength = frameLn;
                        /*
                        for (int i = 0; i < ln/2; ++i)
                        {
                                        // doing my real time stuff
                                        thePCMOutputBuffer.floatChannelData[0][i] = 100000 * (float)i;
                                        thePCMOutputBuffer.floatChannelData[1][i] = 100000 * (float)i;
                        }
                        */
                         //[playerNode reset];
                         if (r)
                         {
                                ++ready ;
                                [playerNode scheduleBuffer: thePCMOutputBuffer  completionHandler:
                                ^(void)
                                {
                                        --ready;
                                }];
                                return ln;
                         }
                         return 0;
              
                 }
 
                return 0;
                //[inputNode installTapOnBus: 0 bufferSize: 2048 format: inputFormat block:^(AVAudioPCMBuffer * _Nonnull buffer, AVAudioTime * _Nonnull when)
                //{
                        //AVAudioConverterInputStatus inputStatus = AVAudioConverterInputStatus_HaveData ;
                         //AVAudioPCMBuffer* thePCMOutputBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat: outputFormat frameCapacity: [data length]/2];
 
                         //int n = [convertedBuffer frameLength];
                        //int16_t *const  bb = [convertedBuffer int16ChannelData][0];
                        //NSData* b = [[NSData alloc] initWithBytes: bb length: n * 2 ];
   
                // make a silent stereo buffer
                //AVAudioChannelLayout *chLayout = [[AVAudioChannelLayout alloc] initWithLayoutTag:kAudioChannelLayoutTag_Mono];
 
                //AVAudioPCMBuffer* thePCMBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat: playerFormat frameCapacity: [data length]/2];
                //thePCMBuffer.frameLength = thePCMBuffer.frameCapacity;
                //memset(thePCMBuffer.int16ChannelData[0], 0, thePCMBuffer.frameLength * playerFormat.streamDescription ->mBytesPerFrame);
                //memset(thePCMBuffer.int16ChannelData[1], 0, thePCMBuffer.frameLength * playerFormat.streamDescription ->mBytesPerFrame);
                //memcpy(thePCMBuffer.int16ChannelData[0], [data bytes], [data length]);
                //memcpy(thePCMBuffer.int16ChannelData[1], [data bytes], [data length]);

/*
                if (ready)
                {
                        ready = false;
                        AVAudioPCMBuffer* thePCMOutputBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat: outputFormat frameCapacity: 512];
                         //memcpy((unsigned char*)thePCMOutputBuffer.floatChannelData[0], [data bytes], 512);
                        memset((unsigned char*)thePCMOutputBuffer.floatChannelData[0],127, 512);
                        memset((unsigned char*)thePCMOutputBuffer.floatChannelData[1],30, 512);
                        [playerNode scheduleBuffer: thePCMOutputBuffer completionHandler:
                        ^(void)
                        {
                                bool ready = true;
                        }];
  
                        return [data length];
                }
                return 0;
                */
        }




@end

//-----------------------------------------------------------------------------------------------------------------------------------------

@implementation AudioPlayer 
{
        FlutterSoundPlayer* flutterSoundPlayer; // Owner
        AVAudioPlayer* player;
}

       - (AVAudioPlayer*) getAudioPlayer
       {
                return player;
       }
       
        - (void) setAudioPlayer: (AVAudioPlayer*)thePlayer
        {
                player = thePlayer;
        }


       - (AudioPlayer*)init: (/*FlutterSoundPlayer**/NSObject*)owner
       {
                flutterSoundPlayer = (FlutterSoundPlayer*)owner;
                return [super init];
       }
       
       -(bool) startPlayerFromBuffer: (NSData*) dataBuffer
       {
                [self setAudioPlayer:  [[AVAudioPlayer alloc] initWithData:dataBuffer error: nil]];
                [self getAudioPlayer].delegate = flutterSoundPlayer;
                bool b = [[self getAudioPlayer] play];
                return b;
       }
       
       -(bool)  startPlayerFromURL: (NSURL*) url
       {
                [self setAudioPlayer: [[AVAudioPlayer alloc] initWithContentsOfURL: url error:nil] ];
                [self getAudioPlayer].delegate = flutterSoundPlayer;
                bool b = [ [self getAudioPlayer] play];
                return b;
        }

       
       -(long)  getDuration
       {
                long duration = (long)( [self getAudioPlayer].duration * 1000);
                return duration;
       }
       
       -(long)  getPosition
       {
                long position = (long)( [self getAudioPlayer].currentTime * 1000);
                return position;
       }
       
       -(void)  stop
       {
                [ [self getAudioPlayer] stop];
                  [self setAudioPlayer: nil];
       }
       
       -(bool)  resume
       {
                bool b = [ [self getAudioPlayer] play];
                return b;
       }
        
       -(bool)  pause
       {
                [ [self getAudioPlayer] pause];
                return true;
       }
       
       -(bool)  setVolume: (double) volume
       {
                [ [self getAudioPlayer] setVolume: volume];
                return true;
       }
       
       -(bool)  seek: (double) pos
       {
                [self getAudioPlayer].currentTime = pos / 1000.0;
                return true;
       }
       
       -(int)  getStatus
       {
                if (  [self getAudioPlayer] == nil )
                        return IS_STOPPED;
                if ( [ [self getAudioPlayer] isPlaying])
                        return IS_PLAYING;
                return IS_PAUSED;
       }


        - (int) feed: (NSData*)data
        {
                return -1;
        }



@end

//-------------------------------------------------------------------------------------------------------------------------------

@implementation FlutterSoundPlayer
{
        NSTimer *timer;
        double subscriptionDuration;

}


- (FlutterSoundPlayer*)init: (FlutterMethodCall*)call
{
        return [super init: call];
}

- (void)isDecoderSupported:(t_CODEC)codec result: (FlutterResult)result
{
        NSLog(@"IOS:--> isDecoderSupported");
        NSNumber*  b = [NSNumber numberWithBool: _isIosDecoderSupported[codec] ];
        result(b);
        NSLog(@"IOS:<-- isDecoderSupported");
}



-(FlautoPlayerManager*) getPlugin
{
        return flautoPlayerManager;
}


- (void)initializeFlautoPlayer: (FlutterMethodCall*)call result: (FlutterResult)result
{
        NSLog(@"IOS:--> initializeFlautoPlayer");
        BOOL r = [self setAudioFocus: call ];
        [self invokeMethod:@"openAudioSessionCompleted" boolArg: r];

        if (r)
                result( [self getPlayerStatus]);
        else
                [FlutterError
                                errorWithCode:@"Audio Player"
                                message:@"Open session failure"
                                details:nil];
        NSLog(@"IOS:<-- initializeFlautoPlayer");
}


- (void)setAudioFocus: (FlutterMethodCall*)call result: (FlutterResult)result
{
        NSLog(@"IOS:--> setAudioFocus");
        BOOL r = [self setAudioFocus: call ];
        if (r)
                result([self getPlayerStatus]);
        else
                [FlutterError
                                errorWithCode:@"Audio Player"
                                message:@"Open session failure"
                                details:nil];
        NSLog(@"IOS:<-- setAudioFocus");
}


- (void)releaseFlautoPlayer: (FlutterMethodCall*)call result: (FlutterResult)result
{
        NSLog(@"IOS:--> releaseFlautoPlayer");
        [super releaseSession];
        result([self getPlayerStatus]);
        NSLog(@"IOS:<-- releaseFlautoPlayer");
}

- (void)setCategory: (NSString*)categ mode:(NSString*)mode options:(int)options result:(FlutterResult)result
{
       NSLog(@"IOS:--> setCategory");
         // Able to play in silent mode
        BOOL b = [[AVAudioSession sharedInstance]
                setCategory:  categ // AVAudioSessionCategoryPlayback
                mode: mode
                options: options
                error: nil];

        if (b)
                result([self getPlayerStatus]);
        else
                [FlutterError
                                errorWithCode:@"Audio Player"
                                message:@"setCategory failure"
                                details:nil];
      NSLog(@"IOS:<-- setCategory");
}

- (void)setActive:(BOOL)enabled result:(FlutterResult)result
{
        NSLog(@"IOS:--> setActive");
        BOOL b = [[AVAudioSession sharedInstance]  setActive:enabled error:nil] ;
        if (b)
                result([self getPlayerStatus]);
        else
                [FlutterError
                                errorWithCode:@"Audio Player"
                                message:@"setActive failure"
                                details:nil];
       NSLog(@"IOS:<-- setActive");
}


- (void)stopPlayer:(FlutterMethodCall*)call  result:(FlutterResult)result
{
        NSLog(@"IOS:--> stopPlayer");
        [self stopPlayer];
        NSNumber* status = [self getPlayerStatus];
        result(status);
        NSLog(@"IOS:<-- stopPlayer - status = %s" , [[status stringValue] cString]);
}



- (void)getPlayerState:(FlutterMethodCall*)call result: (FlutterResult)result
{
                result([self getPlayerStatus]);
}




- (void)startPlayer:(FlutterMethodCall*)call result: (FlutterResult)result
{
        NSLog(@"IOS:--> startPlayer");
        bool b = FALSE;
        if (!hasFocus) // We always acquire the Audio Focus (It could have been released by another session)
        {
                hasFocus = TRUE;
                b = [[AVAudioSession sharedInstance]  setActive: hasFocus error:nil] ;
        }

        [self stopPlayer]; // To start a fresh new playback

        NSString* path = (NSString*)call.arguments[@"fromURI"];
        t_CODEC codec = (t_CODEC)([(NSNumber*)call.arguments[@"codec"] intValue]);
        if ( (path == nil ||  [path class] == [NSNull class] ) && codec == pcm16)
                player = [[AudioPlayerEngine alloc] init: self audioSettings: call.arguments];
        else
                player = [[AudioPlayer alloc]init: self];
        FlutterStandardTypedData* dataBuffer = (FlutterStandardTypedData*)call.arguments[@"fromDataBuffer"];
        if ([dataBuffer class] != [NSNull class])
        {
                b = [player startPlayerFromBuffer:  [dataBuffer data] ];
                if (!b)
                {
                        [self stopPlayer];
                        [FlutterError
                        errorWithCode:@"Audio Player"
                        message:@"Play failure"
                        details:nil];
                } else
                {
                        [self startTimer];
                        long duration = [player getDuration];
                        int d = (int)duration;
                        NSNumber* nd = [NSNumber numberWithInt: d];
                        [self invokeMethod:@"startPlayerCompleted" numberArg: nd ];
                        result([self getPlayerStatus]);
                }
                NSLog(@"IOS:<-- startPlayer");
                return;
        }

        bool isRemote = false;
   
        if (path != [NSNull null])
        {
                NSURL* remoteUrl = [NSURL URLWithString: path];
                NSURL* audioFileURL = [NSURL URLWithString:path];
        
                if (remoteUrl && remoteUrl.scheme && remoteUrl.host)
                {
                        audioFileURL = remoteUrl;
                        isRemote = true;
                }

                  if (isRemote)
                  {
                        NSURLSessionDataTask *downloadTask = [[NSURLSession sharedSession]
                                dataTaskWithURL:audioFileURL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
                        {

                                // We must create a new Audio Player instance to be able to play a different Url
                                bool b = [player startPlayerFromBuffer: data];
                                if (!b)
                                {
                                        [self stopPlayer];
                                        result([FlutterError
                                        errorWithCode:@"Audio Player"
                                        message:@"Play failure"
                                        details:nil]);

                                }
                        }];

                        [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
                        NSString *filePath = audioFileURL.absoluteString;
                        [downloadTask resume];
                        b = true;
                } else
                {
                        b = [player startPlayerFromURL: audioFileURL];
                }
        } else
        {
                b = [player startPlayerFromURL: nil];
        }
        if (b)
        {
                long duration = [player getDuration];
                int d = (int)duration;
                NSNumber* nd = [NSNumber numberWithInt: d];
                [self invokeMethod:@"startPlayerCompleted" numberArg: nd ];
                [self startTimer];
                result([self getPlayerStatus]);
        } else
        {
                        [self stopPlayer];
                        result([FlutterError
                        errorWithCode:@"Audio Player"
                        message:@"Play failure"
                        details:nil]);
        }
        NSLog(@"IOS:<-- startPlayer");
}


- (void)startPlayerFromTrack:(FlutterMethodCall*)call result: (FlutterResult)result
{
                       result([FlutterError
                                errorWithCode:@"Audio Player"
                                message:@"Start Player From Track failure"
                                details:nil]);
}

- (void)nowPlaying:(FlutterMethodCall*)call result: (FlutterResult)result
{
                       result([FlutterError
                                errorWithCode:@"Audio Player"
                                message:@"Now Playing failure"
                                details:nil]);
}


- (void)setUIProgressBar:(FlutterMethodCall*)call result: (FlutterResult)result;
{
                       result([FlutterError
                                errorWithCode:@"Audio Player"
                                message:@"setUIProgressBar failure"
                                details:nil]);
}


- (void)stopPlayer
{
        NSLog(@"IOS:--> stopPlayer");
        [self stopTimer];
        if ( ([self getStatus] == IS_PLAYING) || ([self getStatus] == IS_PAUSED) )
        {
                NSLog(@"IOS: ![audioPlayer stop]");
                [player stop];
        }
        player = nil;
        NSLog(@"IOS:<-- stopPlayer");
}

- (bool)pause
{
          NSLog(@"IOS:--> pause");
          if (timer != nil)
          {
              [timer invalidate];
              timer = nil;
          }
          if ([self getStatus] == IS_PLAYING)
          {
                [player pause];
          }
          else
                NSLog(@"IOS: audioPlayer is not Playing");

         long duration =   [player getDuration];
         long position =   [player getPosition];
         /*
         if (duration - position < 80) // PATCH [LARPOUX]
          {
                NSLog (@"IOS: !patch [LARPOUX]");
                [self stopPlayer];
                dispatch_async(dispatch_get_main_queue(), ^{
                        NSLog(@"IOS:--> ^audioPlayerFinishedPlaying");
                        [self invokeMethod:@"audioPlayerFinishedPlaying" numberArg: [self getPlayerStatus]];
                        NSLog(@"IOS:<-- ^audioPlayerFinishedPlaying");
                 });

          }
          */


          bool b =  ( [self getStatus] == IS_PAUSED);
          if (!b)
          {
                NSLog(@"IOS: AudioPlayer : cannot pause!!!");
          }

          NSLog(@"IOS:<-- pause");
          return b;
 }

- (bool)resume
{
        NSLog(@"IOS:--> resume");
        long duration =   [player getDuration];
        long position =   [player getPosition];
        /*
        if (duration - position < 80) // PATCH [LARPOUX]
        {
                NSLog (@"IOS: !patch [LARPOUX]");
                [self stopPlayer];
                dispatch_async(dispatch_get_main_queue(), ^{
                        NSLog(@"IOS:--> ^audioPlayerFinishedPlaying");
                        [self invokeMethod:@"audioPlayerFinishedPlaying" numberArg: [self getPlayerStatus]];
                        NSLog(@"IOS:<-- ^audioPlayerFinishedPlaying");
                 });

        } else
        */
        {

                // if ( [self getStatus] == IS_PAUSED ) // (after a long pause with the lock screen, the status is not "PAUSED"
                {
                       // [audioPlayer setDelegate: self]; // TRY
                        NSLog(@"IOS: play!");
                        bool b = [player resume];
                } //else
                {
                        //NSLog(@"IOS: ~play! (status is not paused)" );
                }
                [self startTimer];
        }
        bool b = ([self getStatus] == IS_PLAYING);
        if (!b)
        {
                 NSLog(@"IOS: AudioPlayer : cannot resume!!!");
        }
        NSLog(@"IOS:<-- resume");
        return b;
}

- (void)pausePlayer:(FlutterResult)result
{
        NSLog(@"IOS:--> pausePlayer");
        if ([self pause])
        {
                result([self getPlayerStatus]);
        } else
        {
                       result([FlutterError
                                  errorWithCode:@"Audio Player"
                                  message:@"audioPlayer pause failure"
                                  details:nil]);

        }
        NSLog(@"IOS:<-- pausePlayer");
}

- (void)resumePlayer:(FlutterResult)result
{
        NSLog(@"IOS:--> resumePlayer");
        if ([self resume])
        {
                result([self getPlayerStatus]);
        } else
        {
                       result([FlutterError
                                  errorWithCode:@"Audio Player"
                                  message:@"audioPlayer resumePlayer failure"
                                  details:nil]);

        }
         NSLog(@"IOS:<-- resumePlayer");

}



- (void)feed:(FlutterMethodCall*)call result: (FlutterResult)result
{
		try
		{
                        FlutterStandardTypedData* x = call.arguments[ @"data" ] ;
                        assert ([x elementSize] == 1);
			NSData* data = [x data];
                        assert ([data length] == [x elementCount]);
                        int r = [player feed: data];
			result([NSNumber numberWithInt: r]);
		} catch (NSException* e)
		{
                        result([FlutterError
                                errorWithCode:@"feed"
                                message:@"error"
                                details:nil]);
		}

}

- (void)seekToPlayer:(FlutterMethodCall*)call result: (FlutterResult)result
{
        NSLog(@"IOS:--> seekToPlayer");
        if (player != nil)
        {
                NSNumber* milli = (NSNumber*)(call.arguments[@"duration"]);
                double t = [milli doubleValue];
                [player seek: t];
                [self updateProgress: nil];
                result([self getPlayerStatus]);
        } else
        {
                result([FlutterError
                        errorWithCode:@"Audio Player"
                        message:@"player is not set"
                        details:nil]);
        }
         NSLog(@"IOS:<-- seekToPlayer");
}

- (void)setVolume:(double) volume result: (FlutterResult)result
{
        NSLog(@"IOS:--> setVolume");
        if (player)
        {
                [player setVolume: volume ];
                result([self getPlayerStatus]);
        } else
        {
                result([FlutterError
                        errorWithCode:@"Audio Player"
                        message:@"player is not set"
                        details:nil]);
        }
        NSLog(@"IOS:<-- setVolume");
}


- (void) stopTimer{
        NSLog(@"IOS:--> stopTimer");
        if (timer != nil) {
                [timer invalidate];
                timer = nil;
        }
        NSLog(@"IOS:<-- stopTimer");}


- (long)getPosition
{
        return [player getPosition];
}

- (long)getDuration
{
         return [player getDuration];
}


- (void)updateProgress:(NSTimer*) atimer
{
dispatch_async(dispatch_get_main_queue(), ^{
        NSNumber *duration = [NSNumber numberWithLong: [player getDuration]];
        NSNumber *position = [NSNumber numberWithLong: [player getPosition]];
        NSDictionary* dico = @{ @"slotNo": [NSNumber numberWithInt: slotNo], @"position": position, @"duration": duration, @"playerStatus": [self getPlayerStatus] };
        [self invokeMethod:@"updateProgress" dico: dico];
});
}

- (void)getProgress:(FlutterMethodCall*)call result: (FlutterResult)result
{
        NSLog(@"IOS:--> getProgress");
        NSNumber *duration = [NSNumber numberWithLong: [player getDuration]];
        NSNumber *position = [NSNumber numberWithLong: [player getPosition]];
        NSDictionary* dico = @{ @"slotNo": [NSNumber numberWithInt: slotNo], @"position": position, @"duration": duration, @"playerStatus": [self getPlayerStatus] };
        result(dico);
        NSLog(@"IOS:--> getProgress");

}


- (void)startTimer
{
        NSLog(@"IOS:--> startTimer");
        [self stopTimer];
        dispatch_async(dispatch_get_main_queue(), ^{ // ??? Why Async ?  (no async for recorder)
        self -> timer = [NSTimer scheduledTimerWithTimeInterval:subscriptionDuration
                                           target:self
                                           selector:@selector(updateProgress:)
                                           userInfo:nil
                                           repeats:YES];
        });
        NSLog(@"IOS:<-- startTimer");
}


- (void)setSubscriptionDuration:(FlutterMethodCall*)call  result: (FlutterResult)result
{
        NSLog(@"IOS:--> setSubscriptionDuration");
        NSNumber* milliSec = (NSNumber*)call.arguments[@"milliSec"];
        subscriptionDuration = [milliSec doubleValue]/1000;
        result([self getPlayerStatus]);
        NSLog(@"IOS:<-- setSubscriptionDuration");
}


// post fix with _FlutterSound to avoid conflicts with common libs including path_provider
- (NSString*) GetDirectoryOfType_FlutterSound: (NSSearchPathDirectory) dir
{
        NSArray* paths = NSSearchPathForDirectoriesInDomains(dir, NSUserDomainMask, YES);
        return [paths.firstObject stringByAppendingString:@"/"];
}


- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)thePlayer successfully:(BOOL)flag
{
        NSLog(@"IOS:--> @audioPlayerDidFinishPlaying");
        [self stopTimer];
        [player stop];
        player = nil;
        dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"IOS:--> ^audioPlayerFinishedPlaying");
                [self invokeMethod:@"audioPlayerFinishedPlaying" numberArg: [self getPlayerStatus]];
                NSLog(@"IOS:<-- ^audioPlayerFinishedPlaying");
         });

       NSLog(@"IOS:<-- @audioPlayerDidFinishPlaying");
}

- (int)getStatus
{
        if ( player == nil )
                return IS_STOPPED;
        return [player getStatus];
}

- (NSNumber*)getPlayerStatus
{
        return [NSNumber numberWithInt: [self getStatus]];
}
@end
//---------------------------------------------------------------------------------------------

