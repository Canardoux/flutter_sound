#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "Flauto.h"
#import "FlautoPlayer.h"
#import "FlautoPlayerEngine.h"
#import "FlautoRecorder.h"
#import "FlautoRecorderEngine.h"
#import "FlautoSession.h"
#import "FlautoTrack.h"
#import "FlautoTrackPlayer.h"

FOUNDATION_EXPORT double flauto_engine_iosVersionNumber;
FOUNDATION_EXPORT const unsigned char flauto_engine_iosVersionString[];

