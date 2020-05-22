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




#import "TrackPlayer.h"
#import "Track.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>








//---------------------------------------------------------------------------------------------

@implementation TrackPlayer
{
       NSURL *audioFileURL;
       Track *track;
       id forwardTarget;
       id backwardTarget;
       id pauseTarget;
       int slotNo;

}

- (TrackPlayer*)init: (FlutterMethodCall*)call
{
        return [super init: call];
}


- (void)releaseTrackPlayer:(FlutterMethodCall*)call result:(FlutterResult)result
{
        // The code used to release all the media player resources is the same of the one needed
         // to stop the media playback. Then, use that one.
         // [self stopRecorder:result];
         [self stopPlayer];
         MPRemoteCommandCenter *commandCenter = [MPRemoteCommandCenter sharedCommandCenter];
         if (pauseTarget != nil)
         {
                 [commandCenter.togglePlayPauseCommand removeTarget: pauseTarget action: nil];
                 pauseTarget = nil;
         }
         if (forwardTarget != nil)
         {
                 [commandCenter.nextTrackCommand removeTarget: forwardTarget action: nil];
                 forwardTarget = nil;
         }

         if (backwardTarget != nil)
         {
                 [commandCenter.previousTrackCommand removeTarget: backwardTarget action: nil];
                 backwardTarget = nil;
         }

        [super releaseSession];
        result(@"The player has been successfully released");

}




- (void)startPlayerFromTrack:(FlutterMethodCall*)call result: (FlutterResult)result
{
         bool r = FALSE;
         NSDictionary* trackDict = (NSDictionary*) call.arguments[@"track"];
         track = [[Track alloc] initFromDictionary:trackDict];
         BOOL canPause  = [call.arguments[@"canPause"] boolValue];
         BOOL canSkipForward = [call.arguments[@"canSkipForward"] boolValue];
         BOOL canSkipBackward = [call.arguments[@"canSkipBackward"] boolValue];


        if(!track)
        {
                result([FlutterError errorWithCode:@"UNAVAILABLE"
                                   message:@"The track passed to startPlayer is not valid."
                                   details:nil]);
                return;
        }


        // Check whether the audio file is stored as a path to a file or a buffer
        if([track isUsingPath])
        {
                // The audio file is stored as a path to a file

                NSString *path = track.path;

                bool isRemote = false;
                // Check whether a path was given
                if ([path class] == [NSNull class])
                {
                        // No path was given, get the path to a default sound
                        audioFileURL = [NSURL fileURLWithPath:[GetDirectoryOfType_FlutterSound(NSCachesDirectory) stringByAppendingString:@"sound.aac"]];
                // This file name is not good. Perhaps the codec is not AAC. !
                } else
                {
                        // A path was given, then create a NSURL with it
                        NSURL *remoteUrl = [NSURL URLWithString:path];

                        // Check whether the URL points to a local or remote file
                        if(remoteUrl && remoteUrl.scheme && remoteUrl.host)
                        {
                                audioFileURL = remoteUrl;
                                isRemote = true;
                        } else
                        {
                                audioFileURL = [NSURL URLWithString:path];
                        }
                }

                 isPaused = false;
                if (!hasFocus) // We always acquire the Audio Focus (It could have been released by another session)
                {
                        hasFocus = TRUE;
                        r = [[AVAudioSession sharedInstance]  setActive: hasFocus error:nil] ;
                }
         


                // Check whether the file path points to a remote or local file
                if (isRemote)
                {
                        NSURLSessionDataTask *downloadTask = [[NSURLSession sharedSession]
                                                  dataTaskWithURL:audioFileURL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                      // The file to play has been downloaded, then initialize the audio player
                                                      // and start playing.

                                                      // We must create a new Audio Player instance to be able to play a different Url
                                                      audioPlayer = [[AVAudioPlayer alloc] initWithData:data error:nil];
                                                      audioPlayer.delegate = self;

                                                      dispatch_async(dispatch_get_main_queue(), ^{
                                                          [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
                                                      });

                                                      [audioPlayer play];
                                                   }];
                        r = true; // ??? not sure
                        [downloadTask resume];
                        [self startTimer];
                } else
                {
                        // Initialize the audio player with the file that the given path points to,
                        // and start playing.

                        // if (!audioPlayer) { // Fix sound distoring when playing recorded audio again.
                        audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:audioFileURL error:nil];
                        audioPlayer.delegate = self;
                        // }

                        // Able to play in silent mode
                        dispatch_async(dispatch_get_main_queue(),
                        ^{
                                [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
                        });

                        r = [audioPlayer play];
                        [self startTimer];
                }
        } else
        {
        // The audio file is stored as a buffer
                FlutterStandardTypedData* dataBuffer = (FlutterStandardTypedData*) track.dataBuffer;
                NSData* bufferData = [dataBuffer data];
                audioPlayer = [[AVAudioPlayer alloc] initWithData: bufferData error: nil];
                audioPlayer.delegate = self;
                dispatch_async(dispatch_get_main_queue(),
                ^{
                        [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
                });
                r = [audioPlayer play];
                [self startTimer];
        }
        //[ self invokeMethod:@"updatePlaybackState" arguments:playingState];

        // Display the notification with the media controls
        [self setupRemoteCommandCenter:canPause canSkipForward:canSkipForward   canSkipBackward:canSkipBackward result:result];
        [self setupNowPlaying];
        if (r)
                result([NSNumber numberWithBool: r]);
        else
             result([FlutterError errorWithCode:@"FAILED"
                                   message:@"startPlayerFromTrack()"
                                   details:nil]);
}


- (void)updateProgress:(NSTimer*) atimer
{
        NSNumber *duration = [NSNumber numberWithLong: (long)(audioPlayer.duration * 1000)];
        NSNumber *position = [NSNumber numberWithLong: (long)(audioPlayer.currentTime * 1000)];
        /*
        NSMutableDictionary *songInfo = [[NSMutableDictionary alloc] init];
        [songInfo setObject:position forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
        [songInfo setObject:duration forKey:MPMediaItemPropertyPlaybackDuration];
        MPNowPlayingInfoCenter *playingInfoCenter = [MPNowPlayingInfoCenter defaultCenter];
        [playingInfoCenter setNowPlayingInfo:songInfo];
        */
        [super updateProgress: atimer];
}



// Give the system information about what the audio player
// is currently playing. Takes in the image to display in the
// notification to control the media playback.
- (void)setupNowPlaying
{
        // Initialize the MPNowPlayingInfoCenter

        MPNowPlayingInfoCenter* playingInfoCenter = [MPNowPlayingInfoCenter defaultCenter];
        NSMutableDictionary* songInfo = [[NSMutableDictionary alloc] init];
        // The caller specify an asset to be used.
        // Probably good in the future to allow the caller to specify the image itself, and not a resource.
        if ((track.albumArtUrl != nil) && ([track.albumArtUrl class] != [NSNull class])   )         // The albumArt is accessed in a URL
        {
                // Retrieve the album art for the
                // current track .
                NSURL* url = [NSURL URLWithString:self->track.albumArtUrl];
                UIImage* artworkImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:url]];
                if(artworkImage)
                {
                        MPMediaItemArtwork* albumArt = [[MPMediaItemArtwork alloc] initWithImage: artworkImage];
                        [songInfo setObject:albumArt forKey:MPMediaItemPropertyArtwork];
                }
        } else
        if ((track.albumArtAsset) && ([track.albumArtAsset class] != [NSNull class])   )        // The albumArt is an Asset
        {
                UIImage* artworkImage = [UIImage imageNamed: track.albumArtAsset];
                if (artworkImage != nil)
                {
                        MPMediaItemArtwork* albumArt = [[MPMediaItemArtwork alloc] initWithImage: artworkImage];
                        [songInfo setObject:albumArt forKey: MPMediaItemPropertyArtwork];
                }
        } else
        if ((track.albumArtFile) && ([track.albumArtFile class] != [NSNull class])   )          //  The AlbumArt is a File
        {
                UIImage* artworkImage = [UIImage imageWithContentsOfFile: track.albumArtFile];
                if (artworkImage != nil)
                {
                        MPMediaItemArtwork* albumArt = [[MPMediaItemArtwork alloc] initWithImage: artworkImage];
                        [songInfo setObject:albumArt forKey: MPMediaItemPropertyArtwork];
                }
        } else // Nothing specified. We try to use the App Icon
        {
                UIImage* artworkImage = [UIImage imageNamed: @"AppIcon"];
                if (artworkImage != nil)
                {
                        MPMediaItemArtwork* albumArt = [[MPMediaItemArtwork alloc] initWithImage: artworkImage];
                        [songInfo setObject:albumArt forKey: MPMediaItemPropertyArtwork];
                }
        }

        NSNumber* progress = [NSNumber numberWithDouble: audioPlayer.currentTime];
        NSNumber* duration = [NSNumber numberWithDouble: audioPlayer.duration];

        [songInfo setObject:track.title forKey:MPMediaItemPropertyTitle];
        [songInfo setObject:track.author forKey:MPMediaItemPropertyArtist];
        [songInfo setObject:progress forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
        [songInfo setObject:duration forKey:MPMediaItemPropertyPlaybackDuration];
        bool b = [audioPlayer isPlaying];
        [songInfo setObject:[NSNumber numberWithDouble:(b ? 1.0f : 1.0f)] forKey:MPNowPlayingInfoPropertyPlaybackRate];

        [playingInfoCenter setNowPlayingInfo:songInfo];
}


- (void)cleanTarget:(BOOL)canPause canSkipForward:(BOOL)canSkipForward  canSkipBackward:(BOOL)canSkipBackward
{
          // [commandCenter.playCommand setEnabled:YES];
          // [commandCenter.pauseCommand setEnabled:YES];
          //   [commandCenter.playCommand addTargetWithHandler: ^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
          //       // [[MediaController sharedInstance] playOrPauseMusic];    // Begin playing the current track.
          //       [self resumePlayer:result];
          //       return MPRemoteCommandHandlerStatusSuccess;
          //   }];
          //
          //   [commandCenter.pauseCommand addTargetWithHandler: ^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
          //       // [[MediaController sharedInstance] playOrPauseMusic];    // Begin playing the current track.
          //       [self pausePlayer:result];
          //       return MPRemoteCommandHandlerStatusSuccess;
          //   }];
          MPRemoteCommandCenter *commandCenter = [MPRemoteCommandCenter sharedCommandCenter];

          if (pauseTarget != nil)
          {
                [commandCenter.togglePlayPauseCommand removeTarget: pauseTarget action: nil];
                pauseTarget = nil;
          }
          if (forwardTarget != nil)
          {
                [commandCenter.nextTrackCommand removeTarget: forwardTarget action: nil];
                forwardTarget = nil;
          }

          if (backwardTarget != nil)
          {
                [commandCenter.previousTrackCommand removeTarget: backwardTarget action: nil];
                backwardTarget = nil;
          }
          [commandCenter.togglePlayPauseCommand setEnabled: true]; // If the caller does not want to control pause button, we will use our default action
          [commandCenter.nextTrackCommand setEnabled:canSkipForward];
          [commandCenter.previousTrackCommand setEnabled:canSkipBackward];

          {
                pauseTarget = [commandCenter.togglePlayPauseCommand addTargetWithHandler: ^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event)
                {
                        FlutterResult result;
                        bool b = [audioPlayer isPlaying];
                        // If the caller wants to control the pause button, just call him
                        if (b)
                        {
                                if (canPause)
                                        [self invokeMethod:@"pause" boolArg:true];
                                else
                                        [self pause];
                        } else
                        {
                                if (canPause)
                                {
                                        [self invokeMethod:@"pause" boolArg:false];

                                } else
                                        [self resume];
                        }
                        return MPRemoteCommandHandlerStatusSuccess;
                }];
        }

        if (canSkipForward)
        {
                forwardTarget = [commandCenter.nextTrackCommand addTargetWithHandler: ^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event)
                {
                        [self invokeMethod:@"skipForward" stringArg:@""];
                        // [[MediaController sharedInstance] fastForward];    // forward to next track.
                        return MPRemoteCommandHandlerStatusSuccess;
                }];
        }

        if (canSkipBackward)
        {
                backwardTarget = [commandCenter.previousTrackCommand addTargetWithHandler: ^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event)
                {
                        [self invokeMethod:@"skipBackward" stringArg:@""];
                        // [[MediaController sharedInstance] rewind];    // back to previous track.
                        return MPRemoteCommandHandlerStatusSuccess;
                }];
        }
}


- (void)stopPlayer
{
          [self stopTimer];
          isPaused = false;
          if (audioPlayer)
          {
                [audioPlayer stop];
                //audioPlayer = nil;
          }
          // ????  [self cleanTarget:false canSkipForward:false canSkipBackward:false];
        [self cleanTarget:false canSkipForward:false canSkipBackward:false]; // ???
}



// Give the system information about what to do when the notification
// control buttons are pressed.
- (void)setupRemoteCommandCenter:(BOOL)canPause canSkipForward:(BOOL)canSkipForward canSkipBackward:(BOOL)canSkipBackward result: (FlutterResult)result
{
        [self cleanTarget:canPause canSkipForward:canSkipForward canSkipBackward:canSkipBackward];
}


// post fix with _FlutterSound to avoid conflicts with common libs including path_provider
static NSString* GetDirectoryOfType_FlutterSound(NSSearchPathDirectory dir)
{
        NSArray* paths = NSSearchPathForDirectoriesInDomains(dir, NSUserDomainMask, YES);
        return [paths.firstObject stringByAppendingString:@"/"];
}

@end
