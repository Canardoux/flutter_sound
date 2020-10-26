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

function newRecorderInstance() { return new FlutterSoundRecorder();}



class FlutterSoundRecorder
{
          static newInstance() { return new FlutterSoundRecorder();}

          constructor()
          {
          }



      initializeFlautoRecorder( focus, category, mode, audioFlags, device)
      {

      }


      releaseMediaPlayer()
      {

      }


      setAudioFocus( focus, category, mode, audioFlags, device)
      {

      }


      isEncoderSupported( codec)
      {
               return true;
      }


      setSubscriptionDuration( duration)
      {

      }


      startRecorder( path, sampleRate, numChannels, bitRate, codec, toStream, audioSource)
        {
               var constraints = { audio: true, video: false };
               navigator.mediaDevices.getUserMedia(constraints).then
               (function(mediaStream)
               {
                 /*
                         var audio = document.querySelector('audio');
                         audio.srcObject = mediaStream;
                         audio.onloadedmetadata = function(e)
                         {
                                   audio.play();
                         };
                         */
                         var audioCtx = new AudioContext();
                         var source = audioCtx.createMediaStreamSource(mediaStream);
                         source.connect(audioCtx.destination);

               })
               .catch(function(err) { console.log(err.name + ": " + err.message); }); // always check for errors at the end.
        }


      stopRecorder()
      {

      }


      pauseRecorder()
      {

      }


      resumeRecorder()
      {

      }


}
