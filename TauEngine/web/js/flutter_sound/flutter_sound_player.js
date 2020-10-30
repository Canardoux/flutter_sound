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




function newPlayerInstance(theFlutterSoundPlayerCallback) { return new FlutterSoundPlayer();}

class FlutterSoundPlayer
{

          static newInstance() { return new FlutterSoundPlayer();}

          initializeMediaPlayer( aCallback, focus, category, mode, audioFlags, device, withUI)
          {
                this.callback = aCallback;
                aCallback.openAudioSessionCompleted(true);
                return 0;
          }

          constructor()
          {
          }

          releaseMediaPlayer()
          {
          }

          playAudioFromURL(path, codec)
          {

                var audio = new Howl({
                  src: [path],
                  format: tabFormat[codec]
                });
                audio.play();
                this.callback.startPlayerCompleted(777);
                return 0;
          }



          playAudioFromBuffer(dataBuffer)
          {
              //var audioData = request.response;

              var audioCtx = new (window.AudioContext || window.webkitAudioContext)();
              var source = audioCtx.createBufferSource();
              console.log(dataBuffer.constructor.name)
              audioCtx.decodeAudioData
              (
                dataBuffer, //dataBuffer.buffer,
                function(buffer)
                {
                    source.buffer = buffer;

                    source.connect(audioCtx.destination);
                    source.loop = false;
                           // start the source playing
                    source.start();

                },
                function(e){ console.log("Error with decoding audio data" + e.err); }
              );
              this.callback.startPlayerCompleted(777);
              return 0;
          }





        setAudioFocus( focus, category, mode, audioFlags, device,)
        {
                return 0;
        }

        getPlayerState()
        {
                return 0;
        }

        isDecoderSupported( codec,)
        {
                return true;
        }

        setSubscriptionDuration( duration)
        {
                return 0;
        }

        startPlayer( codec, fromDataBuffer,  fromURI, numChannels, sampleRate)
        {
                if (fromDataBuffer != null)
                {
                         console.log(fromDataBuffer.constructor.name)

                        this.playAudioFromBuffer(fromDataBuffer.buffer)
                } else
                if (fromURI != null && fromURI != '')
                {
                        var data = window.sessionStorage.getItem(fromURI);
                        if (data != null)
                        {
                                console.log('session storage');
                        } else
                        {
                                data = window.localStorage.getItem(fromURI);
                        }
                        if (data != null)
                        {
                                console.log('++++++++++' + data.constructor.name);
                                fromURI = data;
                                //var buffer = JSON.parse(data);
                                //console.log('++++++++++' + buffer.constructor.name);
                                //buffer.arrayBuffer().then(buf => this.playAudioFromBuffer(buf) );
                                //this.playAudioFromBuffer(buffer);
                                //var myArrayBuffer = await data.arrayBuffer();
                                //console.log('data ln = ' + myArrayBuffer.byteLength);
                                //playAudioFromBuffer(myArrayBuffer);
                        }
                        //else
                        //{
                                console.log('fromURI');
                                this.playAudioFromURL(fromURI, codec);
                        //}

                }
                return 0;
        }

        feed( data,)
        {
                return 0;
        }

        startPlayerFromTrack( progress, duration, track, canPause, canSkipForward, canSkipBackward, defaultPauseResume, removeUIWhenStopped, )
        {
                return 0;
        }

        nowPlaying( progress, duration, track, canPause, canSkipForward, canSkipBackward, defaultPauseResume, )
        {
                return 0;
        }

        stopPlayer()
        {
                return 0;
        }

        pausePlayer()
        {
                return 0;
        }

        resumePlayer()
        {
                return 0;
        }

        seekToPlayer(  duration)
        {
                return 0;
        }

        setVolume( volume)
        {
                return 0;
        }

        setUIProgressBar( duration,  progress)
        {
                return 0;
        }


}
