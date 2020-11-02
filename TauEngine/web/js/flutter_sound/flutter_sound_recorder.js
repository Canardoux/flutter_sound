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



function newRecorderInstance(aCallback, callbackTable) { return new FlutterSoundRecorder(aCallback, callbackTable);}


const CB_updateRecorderProgress = 0;
const CB_recordingData = 1;

class FlutterSoundRecorder
{
        static newInstance(aCallback, callbackTable) { return new FlutterSoundRecorder(aCallback, callbackTable);}

        constructor(aCallback, callbackTable)
        {
                this.callback = aCallback;
                this.callbackTable = callbackTable;
                this.subscriptionDuration = 0;
                this.timerId = null;
                this.deltaTime = 0;
                this.localObjects = [];
        }



        initializeFlautoRecorder(  focus, category, mode, audioFlags, device)
        {
                console.log( 'initializeFlautoRecorder');
        }


        releaseFlautoRecorder()
        {
                console.log( 'releaseFlautoRecorder');
                this.stopRecorder();
                var myStorage = window.sessionStorage;
                for (var url in this.localObjects)
                {
                        if (this.localObjects[url] != null )
                        {
                                var objId = myStorage.getItem(this.localObjects[url]);
                                if ( objId != null)
                                {
                                        console.log( 'Deleting object ' + objId + ' : ' +  this.localObjects[url] );
                                        URL.revokeObjectURL(objId);
                                } else
                                        console.log('NULL2');
                        } else
                                console.log('NULL1');
                }
                this.localObjects = [];

        }


        setAudioFocus( focus, category, mode, audioFlags, device)
        {
               console.log( 'setAudioFocus');
        }


        isEncoderSupported( codec)
        {
/*
                for (var i in mime_types)
                {
                        console.log( "Is " + mime_types[i] + " supported? " + (MediaRecorder.isTypeSupported(mime_types[i]) ? "Maybe!" : "Nope :("));
                }
*/
               return MediaRecorder.isTypeSupported(mime_types[codec]);
        }


        setSubscriptionDuration( duration)
        {
                console.log( 'setSubscriptionDuration');
                this.subscriptionDuration = duration;
        }


        startRecorder( path, sampleRate, numChannels, bitRate, codec, toStream, audioSource)
        {
                console.log( 'startRecorder');
                var constraints = { audio: true};
                var chunks ;//= [];
                var me = this;
                var myStorage;
                if ((path != null) && (path != ''))
                {
                        if (path.substring(0,1) == '_')
                        {
                                myStorage = window.sessionStorage;
                                console.log('sessionStorage');
                        } else
                        {
                                myStorage = window.sessionStorage;
                                console.log('localStorage'); // Actually we do not use 'sessionStorage'
                                //console.log('sessionStorage');
                       }
                }

                navigator.mediaDevices.getUserMedia(constraints).then
                (function(mediaStream)
                {
                        /*
                                var audioCtx = new AudioContext();


                                var source = audioCtx.createMediaStreamSource(mediaStream);
                                //var dest = new audioCtx.createMediaStreamDestination();
                                var offlineCtx = new OfflineAudioContext(2,44100*40,44100);
                                var sourceOfflineCtx = offlineCtx.createBufferSource();
                                //source.connect(sourceOfflineCtx);
                                //source.connect(offlineCtx.source);
                                //source.start();
                                offlineCtx.startRendering().then(function(renderedBuffer)
                                {
                                        console.log('Rendering completed successfully');
                                        console.log('++++++++++' + renderedBuffer.constructor.name);
                                        //this.caller.toto(chunks);
                                        onStop(renderedBuffer);
                                        console.log('toto done');


                                }
                                ).catch(function(err)
                                {
                                        console.log('Rendering failed: ' + err);
                                        // Note: The promise should reject when startRendering is called a second time on an OfflineAudioContext
                                }
                                );
*/

                        //       var buffer = audioCtx.createBuffer(numChannels, tenMinutes, sampleRate); // Play back ???
                        //      source.connect(audioCtx.destination); // This ouput to speaker // TODO : not yet supported


                        // ===========================================================================

                        var chunks = [];
                        var options =
                        {
                              audioBitsPerSecond : bitRate,
                              mimeType : mime_types[codec]
                        }

                        var mediaRecorder = new MediaRecorder(mediaStream, options);
                        me.mediaRecorder = mediaRecorder;
                        if (toStream) // not yet implemented !
                                mediaRecorder.start(30); // 30 milliseconds for a chunk
                        else
                                mediaRecorder.start();
                        console.log("recorder started : " + mediaRecorder.state);


                        mediaRecorder.ondataavailable = function(e)
                        {
                                if (toStream) // not yet implemented !
                                {
                                        me.callbackTable[CB_recordingData](me.callback, e.data);

                                }
                                if (path != null && path != '')
                                {
                                        console.log('On data available : ' + e.data.constructor.name);
                                        chunks.push(e.data);
                                }
                        }

                        mediaRecorder.onstart = function(e)
                        {
                                me.deltaTime = 0;
                                me.startTimer();
                                console.log('mediaRecorder OnStart : ' + me.mediaRecorder.state);
                        }

                        mediaRecorder.onerror = function(e)
                        {
                                console.log("mediaRecorder OnError : " + e.error);
                                me.stopRecorder()
                        }

                        mediaRecorder.onpause = function(e)
                        {
                                console.log('mediaRecorder OnPause : ' + me.mediaRecorder.state);
                        }

                        mediaRecorder.onresume = function(e)
                        {
                                console.log('mediaRecorder OnResume : ' + me.mediaRecorder.state);
                        }

                         mediaRecorder.onstop = function(e)
                        {
                                if (path != null && path != '')
                                {
                                        var blob = new Blob(chunks, {'type' : mime_types[codec]} );
                                        var url = URL.createObjectURL(blob);
                                        var objId = myStorage.getItem(path);
                                        if (objId != null && objId != '')
                                        {
                                                console.log( 'Deleting object ' +  url.toString() +  ' : ' + objId.toString()  );
                                                URL.revokeObjectURL(objId);
                                                var found = me.localObjects.findIndex(element => element == path);
                                                if (found != null && found >= 0)
                                                {
                                                        console.log("Found : " + found);
                                                        me.localObjects[found] = path;
                                                } else
                                                {
                                                        console.log("NOT FOUND! : " + path);
                                                        me.localObjects.push(path);
                                                }
                                        } else
                                        {
                                                me.localObjects.push(path);
                                        }
                                        myStorage.setItem(path, url);
/*
                                        var xhr = new XMLHttpRequest();
                                        var blob;
                                        var fileReader = new FileReader();
                                        xhr.open("GET", url, true);
                                        xhr.responseType = "arraybuffer";


                                        xhr.addEventListener("load", function ()
                                        {
                                                if (xhr.status === 200)
                                                {
                                                        // Create a blob from the response
                                                        blob = new Blob([xhr.response], {type: "audio/webm\;codecs=opus"});

                                                        // onload needed since Google Chrome doesn't support addEventListener for FileReader
                                                        fileReader.onload = function (evt)
                                                        {
                                                                // Read out file contents as a Data URL
                                                                var result = evt.target.result;
                                                                // Set image src to Data URL
                                                                //rhino.setAttribute("src", result);
                                                                // Store Data URL in localStorage
                                                                try
                                                                {
                                                                        //localStorage.setItem("rhino", result);
                                                                        onStop(result);
                                                                        myStorage.setItem(path, JSON.stringify(result));
                                                                } catch (e)
                                                                {
                                                                        console.log("Storage failed: " + e);
                                                                }
                                                        };
                                                        // Load blob as Data URL
                                                        fileReader.readAsDataURL(blob);
                                                }
                                        }, false);
                                        // Send XHR
                                        xhr.send();
*/
                                }
                                chunks = null;///[];
                                console.log('recorder stopped' );
                                me.mediaRecorder = null;
                       }
                });
        }

        stopRecorder()
        {
                console.log( 'stopRecorder');
                if (this.mediaRecorder != null)
                {
                        this.mediaRecorder.stop();
                }
                this.stopTimer();
                this.mediaRecorder = null;
                console.log("recorder stopped" );
       }


        pauseRecorder()
        {
                console.log( 'pauseRecorder');
                this.mediaRecorder.pause();
                this.stopTimer();
                console.log("recorder paused : " + this.mediaRecorder.state);

        }


        resumeRecorder()
        {
                console.log( 'resumeRecorder');
                this.mediaRecorder.resume();
                this.startTimer();
                console.log("recorder resumed : " + this.mediaRecorder.state);
        }

        startTimer()
        {
                console.log('startTimer()');
                this.stopTimer();
                var me = this;

                if (this.subscriptionDuration > 0)
                {
                        this.countDownDate = new Date().getTime();
                        this.timerId = setInterval
                        (
                                function()
                                {
                                        var now = new Date().getTime();
                                        var distance = now - me.countDownDate;
                                        //console.log('top : ' + distance);
                                        me.callbackTable[CB_updateRecorderProgress](me.callback,  me.deltaTime + distance,  0);

                                },
                                this.subscriptionDuration
                        );
                }
        }

        stopTimer()
        {
                console.log('stopTimer()');
                if (this.timerId != null)
                {
                        clearInterval(this.timerId);
                        var now = new Date().getTime();
                        var distance = now - this.countDownDate;
                        this.deltaTime += distance;
                        this.timerId = null;
                }
        }

}

