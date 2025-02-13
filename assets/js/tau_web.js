/*
 * Copyright 2024 Canardoux.
 *
 * This file is part of the τ project.
 *
 * τ is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 3 (GPL3), as published by
 * the Free Software Foundation.
 *
 * τ is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with τ.  If not, see <https://www.gnu.org/licenses/>.
 */


class TauwebJS
{
   recorder;
   constructor()
   {
   }

   papa(mediaRecorder)
   {
      mediaRecorder.ondataavailable = (event) => {
         let x = event.data;
         console.log('Rcv ' + event.data);
      }
      return 3;
   }

   zozo(stream)
   {
       this.recorder = new MediaRecorder(stream);
       this.recorder.ondataavailable = (event) => {
         let x = event.data;
         console.log('Rcv ' + event.data);
       }
       return 4;
   }

   bloBEventData(blobEvent)
   {
      return blobEvent.data;
   }

   blobArrayBuffer(blob)
   {
      return blob.arrayBuffer(blob);
   }

   arrayBufferFloat32List(arrayBuffer)
   {
       console.log('arg ' + arrayBuffer);
       return new Int32Array(arrayBuffer[0]);
       //console.log('z=' + f32);
       //console.log('Ln2 ' + f32.length);
       //return f32;
   }
}


// Need to expose the type to the global scope.
globalThis.TauwebJS = TauwebJS;


class TauRecorder extends MediaRecorder
{

    constructor(stream, type, options)
    {
        if (options == null)
        {
            options = { mimeType: type };
        } else
        {
            options.mimeType = type;
        }
        super(stream, options);
        this.type = type;
        //this.blob = null;
        this.chunks = [];
    }


    start(timeslice)
    {
        this.chunks = [];

        this.ondataavailable = (e) => {
          this.chunks.push(e.data);
        };

        super.start(timeslice);
    }

    makeUrl()
    {
          const blob = new Blob(this.chunks, { type: this.type });
          const url = URL.createObjectURL(blob);
          console.log(url);
          return url;//URL.createObjectURL(this.blob);
    }

    makeFile(fileName)
    {
                const blob = new Blob(this.chunks, { type: this.type });
                const elem = document.createElement('a');
                elem.href = URL.createObjectURL(blob);
                elem.download = fileName;
                document.body.appendChild(elem);
                elem.click();
                const path = elem.download;
                document.body.removeChild(elem);
                return path;
    }

    makeBuffer()
    {
          const blob = new Blob(this.chunks, { type: this.type });
          return blob.arrayBuffer();
          //return blob.bytes();
          //return Buffer.from(blob)
    }
}


// Need to expose the type to the global scope.
globalThis.TauRecorder = TauRecorder;
