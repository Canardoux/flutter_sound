//
//  AudioRecInterface.h
//  Pods
//
//  Created by larpoux on 02/05/2020.
//

#ifndef AudioRecInterface_h
#define AudioRecInterface_h
#include "AudioRecorder.h"

class AudioRecInterface
{
public:
        virtual ~AudioRecInterface(){};
        virtual void stopRecorder() = 0;
        virtual void startRecorder( FlutterSoundRecorder* rec, bool shouldProcessDbLevel) = 0;
        virtual void resumeRecorder() = 0;
        virtual void pauseRecorder() = 0;
        virtual NSString* recorderProgress() = 0;
        virtual NSNumber* dbPeakProgress() = 0;
};

#endif /* AudioRecInterface_h */
